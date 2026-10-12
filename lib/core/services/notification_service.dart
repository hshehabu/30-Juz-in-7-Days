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
  static const int dailyReminderId = 0;
  static const String _channelId = 'khatmah_reminders_v5';
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

    // Safety check: ensure tz.local's offset strictly matches the device's actual offset
    if (tz.local.currentTimeZone.offset !=
        DateTime.now().timeZoneOffset.inMilliseconds) {
      try {
        final currentOffset = DateTime.now().timeZoneOffset;
        final match = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == currentOffset.inMilliseconds,
          orElse: () => tz.local,
        );
        tz.setLocalLocation(match);
      } catch (_) {}
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

  /// Schedules daily notifications at the user-configured [reminderTime].
  /// Guarantees that:
  /// 1. If today has an uncompleted portion and [reminderTime] is in the future today
  ///    (or within the current minute), today's portion is scheduled immediately for today.
  /// 2. Reminders for upcoming days of the challenge are scheduled directly at [reminderTime].
  /// 3. Reminders are resilient even if challenge startDate is in the past or expired.
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
  }) async {
    if (!_initialized) await initialize();

    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);

    // Calculate which challenge day number today corresponds to (1-indexed)
    final diffDays = today.difference(normalizedStart).inDays;
    final currentDayNumber = diffDays + 1;

    // Determine today's portion:
    DefaultPortionData? todayPortion;
    if (currentDayNumber >= 1 && currentDayNumber <= schedule.length) {
      todayPortion = schedule.firstWhere(
        (p) => p.dayNumber == currentDayNumber,
        orElse: () => schedule[currentDayNumber - 1],
      );
    } else {
      // Challenge finished or expired or out of bounds:
      // Pick the earliest uncompleted portion from the schedule
      for (final p in schedule) {
        if (!completedDays.contains(p.dayNumber)) {
          todayPortion = p;
          break;
        }
      }
    }

    // 1. TODAY'S NOTIFICATION:
    // If today's portion is NOT completed, schedule it for today if the time is in the future
    // (or within the current minute):
    if (todayPortion != null && !completedDays.contains(todayPortion.dayNumber)) {
      final todayScheduledDate = tz.TZDateTime(
        tz.local,
        today.year,
        today.month,
        today.day,
        reminderTime.hour,
        reminderTime.minute,
        0,
      );

      final isFutureToday = todayScheduledDate.isAfter(now);
      final isCurrentMinute = now.year == todayScheduledDate.year &&
          now.month == todayScheduledDate.month &&
          now.day == todayScheduledDate.day &&
          now.hour == todayScheduledDate.hour &&
          now.minute == todayScheduledDate.minute;

      if (isFutureToday || isCurrentMinute) {
        final fireTime = isFutureToday
            ? todayScheduledDate
            : now.add(const Duration(seconds: 2));

        await _scheduleZonedNotification(
          id: todayPortion.dayNumber,
          title: 'Daily Qur\'an Portion 📖',
          body: 'Day ${todayPortion.dayNumber}: ${todayPortion.rangeDisplay}',
          scheduledDate: fireTime,
          payload: todayPortion.dayNumber.toString(),
        );
      }
    }

    // 2. UPCOMING DAYS (Tomorrow, Day after tomorrow, up to 7 days ahead):
    for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final futureDate = today.add(Duration(days: dayOffset));
      final futureTzDate = tz.TZDateTime(
        tz.local,
        futureDate.year,
        futureDate.month,
        futureDate.day,
        reminderTime.hour,
        reminderTime.minute,
        0,
      );

      final targetDayNumber =
          (currentDayNumber >= 1 && currentDayNumber <= schedule.length)
              ? currentDayNumber + dayOffset
              : dayOffset + 1;

      if (targetDayNumber <= schedule.length) {
        final portion = schedule.firstWhere(
          (p) => p.dayNumber == targetDayNumber,
          orElse: () => schedule[targetDayNumber - 1],
        );
        if (!completedDays.contains(portion.dayNumber)) {
          await _scheduleZonedNotification(
            id: portion.dayNumber,
            title: 'Daily Qur\'an Portion 📖',
            body: 'Day ${portion.dayNumber}: ${portion.rangeDisplay}',
            scheduledDate: futureTzDate,
            payload: portion.dayNumber.toString(),
          );
        }
      } else {
        // Daily habit reminder after completion or past Day 7
        await _scheduleZonedNotification(
          id: 100 + dayOffset,
          title: 'Daily Qur\'an Reminder 📖',
          body: 'Time for your daily Qur\'an reading. Keep up your blessed habit!',
          scheduledDate: futureTzDate,
          payload: 'daily',
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
  }) async {
    final details = _buildNotificationDetails();
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
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
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
