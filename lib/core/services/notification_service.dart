import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/khatmah_constants.dart';
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

class NotificationService {
  static const String markCompletedActionId = 'mark_completed';
  static const String _channelId = 'khatmah_reminders_v2';
  static const String _channelName = 'Daily Khatmah Reminders';
  static const String _channelDesc =
      'Gentle daily reminders for your 7-day Qur\'an completion';

  /// The 3 fixed drop hours per day: morning (6 AM), noon (12 PM), evening (6 PM)
  static const List<int> dropHours = [6, 12, 18];

  /// Distinct notification titles for each drop
  static const List<String> _dropTitles = [
    'Your morning portion is waiting \u{1F4D6}',
    'Your Qur\'an portion \u2014 midday reminder',
    'Your evening portion is waiting \u{1F319}',
  ];

  /// Distinct body copy tones: fresh start, midday check-in, evening reminder
  static const List<String> _dropBodies = [
    'A fresh morning. Begin with bismillah and open your portion.',
    'Midday check-in \u2014 have you read your portion today?',
    'An evening reminder. Don\'t let the day end without completing your portion.',
  ];

  /// Notification ID for a given day and drop: day1→[10,11,12] ... day7→[70,71,72]
  static int notifId(int dayNumber, int dropIndex) => dayNumber * 10 + dropIndex;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(int dayNumber)? _onMarkCompleted;

  Future<void> initialize({void Function(int dayNumber)? onMarkCompleted}) async {
    if (_initialized) {
      if (onMarkCompleted != null) _onMarkCompleted = onMarkCompleted;
      return;
    }
    _onMarkCompleted = onMarkCompleted;

    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      try {
        final currentOffset = DateTime.now().timeZoneOffset;
        final match = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == currentOffset.inMilliseconds,
          orElse: () => tz.getLocation('UTC'),
        );
        tz.setLocalLocation(match);
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'khatmah_reminder_category',
          actions: [
            DarwinNotificationAction.plain(
              markCompletedActionId,
              'Mark as completed',
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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == markCompletedActionId) {
          final day = int.tryParse(response.payload ?? '');
          if (day != null) {
            await NotificationService.markDayCompletedInBackground(day);
            _onMarkCompleted?.call(day);
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final response = launchDetails?.notificationResponse;
        if (response != null && response.actionId == markCompletedActionId) {
          final day = int.tryParse(response.payload ?? '');
          if (day != null) {
            await NotificationService.markDayCompletedInBackground(day);
            _onMarkCompleted?.call(day);
          }
        }
      }
    } catch (_) {}

    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
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

  /// Requests the user to allow exact alarms in system settings (Android 13/14+)
  Future<bool> requestExactAlarmsPermission() async {
    if (!_initialized) await initialize();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;
    final granted = await androidImpl.requestExactAlarmsPermission();
    return granted ?? false;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? false;

    // Also prompt exact alarm permission if available on Android 13/14+
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {
      // Ignored if not supported or not required
    }

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

  /// Schedules 3 notifications per day (6 AM, 12 PM, 6 PM) for all 7 days.
  /// Total: 21 scheduled notifications. IDs: dayNumber*10+dropIndex.
  /// Any day in [completedDays] is skipped.
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
  }) async {
    if (!_initialized) await initialize();

    await cancelAll();

    final canExact = await canScheduleExact();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final tzNow = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < schedule.length; i++) {
      final portion = schedule[i];
      if (completedDays.contains(portion.dayNumber)) {
        continue; // Skip already completed days
      }

      final targetDate = startDate.add(Duration(days: i));

      for (int d = 0; d < dropHours.length; d++) {
        final scheduledDate = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          dropHours[d],
          0,
          0,
        );

        // Only schedule future drop times
        if (scheduledDate.isAfter(tzNow)) {
          await _plugin.zonedSchedule(
            notifId(portion.dayNumber, d),
            _dropTitles[d],
            '${_dropBodies[d]} — Day ${portion.dayNumber}: ${portion.rangeDisplay}',
            scheduledDate,
            _buildNotificationDetails(),
            payload: portion.dayNumber.toString(),
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  }

  /// Kill switch: cancels all 3 drop notifications for a given day.
  Future<void> cancelDayReminder(int dayNumber) async {
    if (!_initialized) await initialize();
    for (int d = 0; d < dropHours.length; d++) {
      await _plugin.cancel(notifId(dayNumber, d));
    }
  }

  /// Immediately shows a drop-specific reminder for a portion.
  Future<void> showDropReminderNow({
    required int dayNumber,
    required String rangeDisplay,
    required int dropIndex,
  }) async {
    if (!_initialized) await initialize();
    final safeIndex = dropIndex.clamp(0, dropHours.length - 1);
    await _plugin.show(
      notifId(dayNumber, safeIndex),
      _dropTitles[safeIndex],
      '${_dropBodies[safeIndex]} — Day $dayNumber: $rangeDisplay',
      _buildNotificationDetails(),
      payload: dayNumber.toString(),
    );
  }

  /// Legacy compatibility — shows the drop that best matches the current hour.
  Future<void> showDailyReminderNow({
    required int dayNumber,
    required String rangeDisplay,
  }) async {
    final now = DateTime.now();
    int dropIndex = 0;
    if (now.hour >= dropHours[2]) {
      dropIndex = 2;
    } else if (now.hour >= dropHours[1]) {
      dropIndex = 1;
    }
    await showDropReminderNow(
      dayNumber: dayNumber,
      rangeDisplay: rangeDisplay,
      dropIndex: dropIndex,
    );
  }

  /// Sends immediate test notification
  Future<void> showTestNotification({int dayNumber = 1}) async {
    if (!_initialized) await initialize();
    await _plugin.show(
      999,
      '30 Juz\' in 7 Days 📖',
      'Reminder: Day $dayNumber portion is waiting for you.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              markCompletedActionId,
              'Mark as completed',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          categoryIdentifier: 'khatmah_reminder_category',
        ),
      ),
      payload: dayNumber.toString(),
    );
  }

  /// Sends immediate celebration notification
  Future<void> showCompletionNotification() async {
    if (!_initialized) await initialize();
    await _plugin.show(
      777,
      'Alhamdulillah',
      'You have completed your 7-day Qur\'an khatmah!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
    );
  }

  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  /// Handles marking day completed in background isolate.
  /// Also cancels all remaining drop notifications for the day (kill switch).
  static Future<void> markDayCompletedInBackground(int dayNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final jsonStr = storage.getActiveChallengeJson();
      if (jsonStr == null || jsonStr.isEmpty) return;

      final Map<String, dynamic> data =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final portions = (data['portions'] as List<dynamic>?) ?? [];
      bool anyModified = false;
      for (final p in portions) {
        if (p is Map<String, dynamic> && p['dayNumber'] == dayNumber) {
          p['isCompleted'] = true;
          p['completedAt'] = DateTime.now().toIso8601String();
          anyModified = true;
        }
      }

      if (anyModified) {
        final allDone = portions.every(
          (p) => p is Map<String, dynamic> && p['isCompleted'] == true,
        );
        data['isCompleted'] = allDone;
        await storage.saveActiveChallengeJson(jsonEncode(data));
      }

      // Kill switch: cancel remaining drop notifications for today
      try {
        final plugin = FlutterLocalNotificationsPlugin();
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        await plugin.initialize(
          const InitializationSettings(android: androidSettings),
        );
        for (int d = 0; d < dropHours.length; d++) {
          await plugin.cancel(notifId(dayNumber, d));
        }
      } catch (_) {
        // Background cancellation is best-effort
      }
    } catch (_) {
      // Background execution error suppressed
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  NotificationDetails _buildNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        onlyAlertOnce: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            markCompletedActionId,
            'Mark as completed',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        sound: 'default',
        categoryIdentifier: 'khatmah_reminder_category',
      ),
    );
  }
}
