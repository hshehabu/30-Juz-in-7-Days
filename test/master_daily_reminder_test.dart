import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/notification_service.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/datasources/challenge_local_data_source.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/repositories/challenge_repository_impl.dart';

class _RecordingNotificationService extends NotificationService {
  int scheduleCallCount = 0;
  DateTime? lastStartDate;
  TimeOfDay? lastReminderTime;
  Set<int>? lastCompletedDays;

  @override
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
  }) async {
    scheduleCallCount++;
    lastStartDate = startDate;
    lastReminderTime = reminderTime;
    lastCompletedDays = completedDays;
  }
}

void main() {
  test('updateReminderSettings schedules reminders even when no active challenge exists',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final localDataSource = ChallengeLocalDataSourceImpl(storage);
    final notifService = _RecordingNotificationService();

    final repo = ChallengeRepositoryImpl(
      localDataSource: localDataSource,
      storageService: storage,
      notificationService: notifService,
    );

    // No challenge started yet (e.g. user just changed time in settings)
    const newTime = TimeOfDay(hour: 11, minute: 15);
    await repo.updateReminderSettings(
      enabled: true,
      reminderTime: newTime,
    );

    expect(notifService.scheduleCallCount, 1);
    expect(notifService.lastReminderTime, newTime);
    expect(storage.reminderTime, newTime);
    expect(storage.isReminderEnabled, isTrue);
  });

  test('updateReminderSettings schedules reminders when challenge is completed',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final localDataSource = ChallengeLocalDataSourceImpl(storage);
    final notifService = _RecordingNotificationService();

    final repo = ChallengeRepositoryImpl(
      localDataSource: localDataSource,
      storageService: storage,
      notificationService: notifService,
    );

    await repo.startChallenge(
      startDate: DateTime.now().subtract(const Duration(days: 8)),
      reminderTime: const TimeOfDay(hour: 9, minute: 0),
    );

    // Mark all portions completed
    for (int i = 1; i <= 7; i++) {
      await repo.markDayCompleted(i);
    }

    const testTime = TimeOfDay(hour: 11, minute: 15);
    await repo.updateReminderSettings(
      enabled: true,
      reminderTime: testTime,
    );

    // Previously, completed challenge canceled all reminders and skipped scheduling.
    // Now, it reliably schedules the daily recurring reminder.
    expect(notifService.scheduleCallCount, greaterThanOrEqualTo(1));
    expect(notifService.lastReminderTime, testTime);
  });
}
