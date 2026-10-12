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
  static const String _channelId = 'khatmah_daily_reminders_v3';
  static const String _channelName = 'Daily Khatmah Reminders';
  static const String _channelDesc =
      'Gentle daily reminders for your 7-day Qur\'an completion';

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

  /// Schedules a daily notification at the user-configured [reminderTime] for each day of the challenge.
  /// Total: 7 scheduled notifications. Notification ID: portion.dayNumber (1 to 7).
  /// Any day in [completedDays] is skipped.
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
  }) async {
    if (!_initialized) await initialize();

    await cancelAll();

    final tzNow = tz.TZDateTime.now(tz.local);
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);

    for (int i = 0; i < schedule.length; i++) {
      final portion = schedule[i];
      if (completedDays.contains(portion.dayNumber)) {
        continue; // Skip already completed days
      }

      final targetDate = DateTime(
        normalizedStart.year,
        normalizedStart.month,
        normalizedStart.day + i,
      );
      final scheduledDate = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        reminderTime.hour,
        reminderTime.minute,
        0,
      );

      // Only schedule future reminder times
      if (scheduledDate.isAfter(tzNow)) {
        try {
          await _plugin.zonedSchedule(
            portion.dayNumber,
            'Daily Qur\'an Portion 📖',
            'Day ${portion.dayNumber}: ${portion.rangeDisplay}',
            scheduledDate,
            _buildNotificationDetails(),
            payload: portion.dayNumber.toString(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (_) {
          // If exact alarm mode throws on Android (e.g. restriction without permission),
          // fallback to inexact without crashing or stopping remaining days
          await _plugin.zonedSchedule(
            portion.dayNumber,
            'Daily Qur\'an Portion 📖',
            'Day ${portion.dayNumber}: ${portion.rangeDisplay}',
            scheduledDate,
            _buildNotificationDetails(),
            payload: portion.dayNumber.toString(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  }

  /// Cancels the scheduled reminder for a given day (e.g. when completed).
  Future<void> cancelDayReminder(int dayNumber) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(dayNumber);
  }

  /// Immediately shows the daily reminder for a portion.
  Future<void> showDailyReminderNow({
    required int dayNumber,
    required String rangeDisplay,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.show(
      dayNumber,
      'Daily Qur\'an Portion 📖',
      'Day $dayNumber: $rangeDisplay',
      _buildNotificationDetails(),
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
  /// Also cancels the scheduled reminder for the day (kill switch).
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

      // Cancel notification for completed day
      try {
        final plugin = FlutterLocalNotificationsPlugin();
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        await plugin.initialize(
          const InitializationSettings(android: androidSettings),
        );
        await plugin.cancel(dayNumber);
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
