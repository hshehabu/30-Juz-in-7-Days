import 'package:flutter/material.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_local_data_source.dart';
import '../models/challenge_model.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final ChallengeLocalDataSource localDataSource;
  final NotificationService notificationService;
  final StorageService storageService;

  ChallengeRepositoryImpl({
    required this.localDataSource,
    required this.notificationService,
    required this.storageService,
  });

  @override
  Future<Challenge?> getActiveChallenge() async {
    return localDataSource.getActiveChallenge();
  }

  @override
  Future<Challenge> startChallenge({
    required DateTime startDate,
    required TimeOfDay reminderTime,
  }) async {
    final start = AppDateUtils.dateOnly(startDate);
    final end = start.add(const Duration(days: 6));

    final portions = KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: false,
      );
    }).toList();

    final challenge = ChallengeModel(
      id: 'khatmah_${DateTime.now().millisecondsSinceEpoch}',
      startDate: start,
      endDate: end,
      portions: portions,
      reminderHour: reminderTime.hour,
      reminderMinute: reminderTime.minute,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await localDataSource.saveActiveChallenge(challenge);
    await storageService.setReminderTime(reminderTime);
    await storageService.setOnboardingCompleted(true);

    if (storageService.isReminderEnabled) {
      await notificationService.scheduleChallengeReminders(
        startDate: start,
        reminderTime: reminderTime,
        schedule: KhatmahConstants.traditionalSchedule,
      );
    }

    return challenge;
  }

  @override
  Future<Challenge> markDayCompleted(int dayNumber) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final updatedPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber) {
        return p.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
      }
      return p;
    }).toList();

    final allCompleted = updatedPortions.every((p) => p.isCompleted);

    final updatedChallenge = current.copyWithModel(
      portions: updatedPortions,
      isCompleted: allCompleted,
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);

    // Cancel notification for today's completed portion
    await notificationService.cancelDayReminder(dayNumber);

    if (allCompleted) {
      await notificationService.showCompletionNotification();
    }

    return updatedChallenge;
  }

  @override
  Future<Challenge> undoDayCompletion(int dayNumber) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final updatedPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber) {
        return p.copyWith(
          isCompleted: false,
          completedAt: null,
        );
      }
      return p;
    }).toList();

    final updatedChallenge = current.copyWithModel(
      portions: updatedPortions,
      isCompleted: false,
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);
    return updatedChallenge;
  }

  @override
  Future<Challenge> adjustRemainingPlan(List<DayPortion> updatedPortions) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final updatedChallenge = current.copyWithModel(
      portions: updatedPortions,
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);
    return updatedChallenge;
  }

  @override
  Future<Challenge> restartCurrentChallenge() async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final now = AppDateUtils.dateOnly(DateTime.now());
    return startChallenge(
      startDate: now,
      reminderTime: current.reminderTime,
    );
  }

  @override
  Future<void> endChallengeAndArchive() async {
    final current = await localDataSource.getActiveChallenge();
    if (current != null) {
      await localDataSource.archiveCompletedChallenge(current);
    }
    await notificationService.cancelAll();
  }

  @override
  Future<void> updateReminderSettings({
    required bool enabled,
    required TimeOfDay reminderTime,
  }) async {
    await storageService.setReminderEnabled(enabled);
    await storageService.setReminderTime(reminderTime);

    final current = await localDataSource.getActiveChallenge();
    if (current != null) {
      final updatedChallenge = current.copyWithModel(
        reminderHour: reminderTime.hour,
        reminderMinute: reminderTime.minute,
      );
      await localDataSource.saveActiveChallenge(updatedChallenge);

      if (enabled && !current.isCompleted) {
        await notificationService.scheduleChallengeReminders(
          startDate: current.startDate,
          reminderTime: reminderTime,
          schedule: KhatmahConstants.traditionalSchedule,
        );
      } else {
        await notificationService.cancelAll();
      }
    }
  }
}
