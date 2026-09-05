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
  static const String _channelId = 'khatmah_reminders';
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
      importance: Importance.high,
      playSound: true,
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

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? false;

    // Also request exact alarm permission if available on Android 13/14+
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

  /// Schedules daily notifications for the 7 days of the challenge starting at [startDate]
  /// at the given [reminderTime].
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    required TimeOfDay reminderTime,
    required List<DefaultPortionData> schedule,
  }) async {
    if (!_initialized) await initialize();

    // Cancel existing scheduled notifications
    await cancelAll();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact =
        await androidImpl?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final tzNow = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < schedule.length; i++) {
      final portion = schedule[i];
      final scheduledDate = tz.TZDateTime(
        tz.local,
        startDate.year,
        startDate.month,
        startDate.day + i,
        reminderTime.hour,
        reminderTime.minute,
      );

      // Only schedule if the date/time is in the future
      if (scheduledDate.isAfter(tzNow)) {
        final id = 100 + portion.dayNumber;

        await _plugin.zonedSchedule(
          id,
          'Your Qur\'an portion is waiting 📖',
          'Day ${portion.dayNumber} of 7 — ${portion.rangeDisplay}',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
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
          payload: portion.dayNumber.toString(),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Cancels reminder for a specific day when marked complete
  Future<void> cancelDayReminder(int dayNumber) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(100 + dayNumber);
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
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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
      'Alhamdulillah 🤍',
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

  /// Handles marking day completed in background isolate
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
    } catch (_) {
      // Background execution error suppressed
    }
  }
}
