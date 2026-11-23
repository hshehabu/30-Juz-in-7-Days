import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/khatmah_constants.dart';
import '../localization/notification_copy.dart';
import 'reminder_planner.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (response.actionId == NotificationService.markCompletedActionId) {
    final day = int.tryParse(response.payload ?? '');
    if (day != null) {
      await NotificationService.markDayCompletedInBackground(day);
    }
  }
}

/// Snapshot of what the OS currently allows for reminders.
class ReminderPermissionStatus {
  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;

  const ReminderPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
  });

  bool get isHealthy => notificationsEnabled && exactAlarmsAllowed;
}

class NotificationService {
  static const String markCompletedActionId = 'mark_completed';
  static const String _iosCategoryId = 'khatmah_reminder_category';
  static const int completionNotificationId = 777;
  static const String _channelId = 'khatmah_reminders_v5';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(int dayNumber)? _onMarkCompleted;

  /// Language used for notification text.
  String _languageCode = 'en';

  NotificationCopy get _copy => NotificationCopy.of(_languageCode);

  Future<void> initialize({
    void Function(int dayNumber)? onMarkCompleted,
    String? languageCode,
  }) async {
    if (languageCode != null) _languageCode = languageCode;
    if (_initialized) {
      if (onMarkCompleted != null) _onMarkCompleted = onMarkCompleted;
      return;
    }
    _onMarkCompleted = onMarkCompleted;

    tz.initializeTimeZones();
    await syncTimeZone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _iosCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              markCompletedActionId,
              _copy.markCompletedAction,
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final response = launchDetails?.notificationResponse;
        if (response != null) await _handleForegroundResponse(response);
      }
    } catch (_) {}

    await _createChannel();
    _initialized = true;
  }

  Future<void> _createChannel() async {
    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _copy.channelName,
      description: _copy.channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// A "Mark as completed" tap while the app process is alive. Exactly one
  /// writer persists the change: the app's notifier when it is registered,
  /// otherwise the standalone storage path.
  Future<void> _handleForegroundResponse(NotificationResponse response) async {
    if (response.actionId != markCompletedActionId) return;
    final day = int.tryParse(response.payload ?? '');
    if (day == null) return;
    final handler = _onMarkCompleted;
    if (handler != null) {
      handler(day);
    } else {
      await NotificationService.markDayCompletedInBackground(day);
    }
  }

  /// Aligns `tz.local` with the device's current time zone. Safe to call
  /// repeatedly (e.g. on every app resume) to pick up travel / DST changes.
  Future<void> syncTimeZone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      _setLocationByOffset(fallback: tz.UTC);
    }

    // Safety check: ensure tz.local's offset matches the device's actual offset
    if (tz.local.currentTimeZone.offset !=
        DateTime.now().timeZoneOffset.inMilliseconds) {
      _setLocationByOffset(fallback: tz.local);
    }
  }

  void _setLocationByOffset({required tz.Location fallback}) {
    try {
      final currentOffset = DateTime.now().timeZoneOffset;
      final match = tz.timeZoneDatabase.locations.values.firstWhere(
        (loc) => loc.currentTimeZone.offset == currentOffset.inMilliseconds,
        orElse: () => fallback,
      );
      tz.setLocalLocation(match);
    } catch (_) {
      tz.setLocalLocation(fallback);
    }
  }

  /// Updates the language used for notification text.
  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    if (_initialized) {
      try {
        await _createChannel();
      } catch (_) {}
    }
  }

  void setMarkCompletedHandler(void Function(int dayNumber) handler) {
    _onMarkCompleted = handler;
  }

  /// Checks if the device allows scheduling exact alarms (Android 12+)
  Future<bool> canScheduleExact() async {
    if (!_initialized) await initialize();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;
    return await androidImpl.canScheduleExactNotifications() ?? false;
  }

  /// Whether the user currently allows this app to post notifications.
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? true;
      }
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final options = await iosImpl.checkPermissions();
        return options?.isEnabled ?? true;
      }
    } catch (_) {}
    return true;
  }

  Future<ReminderPermissionStatus> getPermissionStatus() async {
    final enabled = await areNotificationsEnabled();
    final exact = await canScheduleExact();
    return ReminderPermissionStatus(
      notificationsEnabled: enabled,
      exactAlarmsAllowed: exact,
    );
  }

  /// Opens the system "Alarms & reminders" page (Android 12+).
  Future<bool> requestExactAlarmsPermission() async {
    if (!_initialized) await initialize();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;
    final granted = await androidImpl.requestExactAlarmsPermission();
    return granted ?? false;
  }

  /// Requests permission to post notifications (Android 13+ / iOS).
  /// Exact-alarm access is requested separately, after explaining why.
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? false;

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;

    return androidGranted || iosGranted;
  }

  /// Schedules every planned reminder (see [ReminderPlanner]) for the
  /// challenge, replacing anything scheduled before.
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
    TimeOfDay? followUpTime,
    String? languageCode,
  }) async {
    if (languageCode != null) _languageCode = languageCode;
    if (!_initialized) await initialize();

    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final plan = ReminderPlanner.plan(
      now: DateTime(now.year, now.month, now.day, now.hour, now.minute,
          now.second),
      startDate: startDate,
      reminderTime: reminderTime,
      totalDays: schedule.length,
      completedDays: completedDays,
      followUpTime: followUpTime,
    );

    final copy = _copy;
    for (final reminder in plan) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        reminder.when.year,
        reminder.when.month,
        reminder.when.day,
        reminder.when.hour,
        reminder.when.minute,
        reminder.when.second,
      );

      switch (reminder.kind) {
        case ReminderKind.portion:
        case ReminderKind.followUp:
          final day = reminder.dayNumber!;
          final portion = schedule.firstWhere(
            (p) => p.dayNumber == day,
            orElse: () => schedule[(day - 1).clamp(0, schedule.length - 1)],
          );
          final range =
              copy.isArabic ? portion.rangeDisplayAr : portion.rangeDisplay;
          final isFollowUp = reminder.kind == ReminderKind.followUp;
          await _scheduleZonedNotification(
            id: reminder.id,
            title: isFollowUp ? copy.followUpTitle : copy.portionTitle,
            body: isFollowUp
                ? copy.followUpBody(day, range)
                : copy.portionBody(day, range),
            scheduledDate: scheduledDate,
            payload: day.toString(),
          );
        case ReminderKind.habit:
          await _scheduleZonedNotification(
            id: reminder.id,
            title: copy.habitTitle,
            body: copy.habitBody,
            scheduledDate: scheduledDate,
            payload: 'daily',
            withAction: false,
          );
      }
    }
  }

  /// Dispatches zoned schedule with exactAlarm mode, gracefully falling back to inexact while idle
  Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    bool withAction = true,
  }) async {
    final details = _buildNotificationDetails(withAction: withAction);
    final canExact = await canScheduleExact();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  /// Cancels the reminder and follow-up for a given day (e.g. when completed).
  Future<void> cancelDayReminder(int dayNumber) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(dayNumber);
    await _plugin.cancel(ReminderPlanner.followUpId(dayNumber));
  }

  /// Sends immediate celebration notification
  Future<void> showCompletionNotification() async {
    if (!_initialized) await initialize();
    final copy = _copy;
    await _plugin.show(
      completionNotificationId,
      copy.completionTitle,
      copy.completionBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          copy.channelName,
          channelDescription: copy.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(sound: 'default'),
      ),
    );
  }

  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  /// Marks a day completed directly in storage. Used when the notification
  /// action fires in a background isolate (or before the app UI exists).
  /// Also cancels the day's reminders (kill switch).
  static Future<void> markDayCompletedInBackground(int dayNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      await storage.reloadFromDisk();
      final jsonStr = storage.getActiveChallengeJson();
      if (jsonStr == null || jsonStr.isEmpty) return;

      final Map<String, dynamic> data =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final portions = (data['portions'] as List<dynamic>?) ?? [];
      bool anyModified = false;
      for (final p in portions) {
        if (p is Map<String, dynamic> &&
            p['dayNumber'] == dayNumber &&
            p['isCompleted'] != true) {
          p['isCompleted'] = true;
          p['completedAt'] = DateTime.now().toIso8601String();
          anyModified = true;
        }
      }

      final allDone = KhatmahConstants.isKhatmahComplete(
        portions.whereType<Map<String, dynamic>>().map((p) => (
              p['startSurah'] as String? ?? '',
              p['endSurah'] as String? ?? '',
              p['dayNumber'] as int? ?? 0,
              p['isCompleted'] == true,
            )),
      );

      if (anyModified) {
        data['isCompleted'] = allDone;
        await storage.saveActiveChallengeJson(jsonEncode(data));
      }

      try {
        final plugin = FlutterLocalNotificationsPlugin();
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        await plugin.initialize(
          const InitializationSettings(android: androidSettings),
        );
        await plugin.cancel(dayNumber);
        await plugin.cancel(ReminderPlanner.followUpId(dayNumber));

        if (anyModified && allDone) {
          final copy = NotificationCopy.of(storage.languageCode);
          await plugin.show(
            completionNotificationId,
            copy.completionTitle,
            copy.completionBody,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                copy.channelName,
                channelDescription: copy.channelDescription,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      } catch (_) {
        // Background notification handling is best-effort
      }
    } catch (_) {
      // Background execution error suppressed
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  NotificationDetails _buildNotificationDetails({bool withAction = true}) {
    final copy = _copy;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        copy.channelName,
        channelDescription: copy.channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        actions: withAction
            ? <AndroidNotificationAction>[
                AndroidNotificationAction(
                  markCompletedActionId,
                  copy.markCompletedAction,
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        sound: 'default',
        categoryIdentifier: withAction ? _iosCategoryId : null,
      ),
    );
  }
}
