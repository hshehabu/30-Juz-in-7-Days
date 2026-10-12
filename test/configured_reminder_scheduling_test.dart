import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/notification_service.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/datasources/challenge_local_data_source.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/repositories/challenge_repository_impl.dart';

class _CapturingNotificationService extends NotificationService {
  TimeOfDay? capturedReminderTime;
  DateTime? capturedStartDate;
  int? canceledDayNumber;
  Set<int>? capturedCompletedDays;

  @override
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
  }) async {
    capturedStartDate = startDate;
    capturedReminderTime = reminderTime;
    capturedCompletedDays = completedDays;
  }

  @override
  Future<void> cancelDayReminder(int dayNumber) async {
    canceledDayNumber = dayNumber;
  }
}

void main() {
  test('startChallenge uses the onboarding configured reminder time for scheduling',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final localDataSource = ChallengeLocalDataSourceImpl(storage);
    final notifService = _CapturingNotificationService();

    final repo = ChallengeRepositoryImpl(
      localDataSource: localDataSource,
      storageService: storage,
      notificationService: notifService,
    );

    final startDate = DateTime(2026, 10, 15);
    const customReminderTime = TimeOfDay(hour: 20, minute: 45); // 8:45 PM

    final challenge = await repo.startChallenge(
      startDate: startDate,
      reminderTime: customReminderTime,
    );

    // Verify stored challenge has the configured reminder time
    expect(challenge.reminderHour, 20);
    expect(challenge.reminderMinute, 45);
    expect(storage.reminderTime.hour, 20);
    expect(storage.reminderTime.minute, 45);

    // Verify notification service was called with the exact custom reminder time
    expect(notifService.capturedReminderTime, customReminderTime);
    expect(notifService.capturedStartDate, startDate);
  });

  test('updateReminderSettings reschedules reminders with the new configured time',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final localDataSource = ChallengeLocalDataSourceImpl(storage);
    final notifService = _CapturingNotificationService();

    final repo = ChallengeRepositoryImpl(
      localDataSource: localDataSource,
      storageService: storage,
      notificationService: notifService,
    );

    final startDate = DateTime(2026, 10, 15);
    const initialTime = TimeOfDay(hour: 18, minute: 0);

    await repo.startChallenge(
      startDate: startDate,
      reminderTime: initialTime,
    );

    const updatedTime = TimeOfDay(hour: 21, minute: 30); // 9:30 PM
    await repo.updateReminderSettings(
      enabled: true,
      reminderTime: updatedTime,
    );

    expect(storage.reminderTime.hour, 21);
    expect(storage.reminderTime.minute, 30);
    expect(notifService.capturedReminderTime, updatedTime);
  });

  test('updateReminderSettings passes completed days so completed portions are not rescheduled',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final localDataSource = ChallengeLocalDataSourceImpl(storage);
    final notifService = _CapturingNotificationService();

    final repo = ChallengeRepositoryImpl(
      localDataSource: localDataSource,
      storageService: storage,
      notificationService: notifService,
    );

    final startDate = DateTime.now();
    await repo.startChallenge(
      startDate: startDate,
      reminderTime: const TimeOfDay(hour: 18, minute: 0),
    );

    // Complete Day 1
    await repo.markDayCompleted(1);

    // Update reminder time in Settings
    const newTime = TimeOfDay(hour: 20, minute: 15);
    await repo.updateReminderSettings(
      enabled: true,
      reminderTime: newTime,
    );

    // Notification service correctly received completedDays containing day 1
    expect(notifService.capturedCompletedDays, contains(1));
    expect(notifService.capturedReminderTime, newTime);
  });
}
