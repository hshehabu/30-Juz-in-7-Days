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
    final challenge = await localDataSource.getActiveChallenge();
    if (challenge == null) return null;

    // Sanitize any corrupted past portions that were falsely auto-completed by legacy code:
    // If a later portion was adjusted (isAdjusted == true) and encompasses earlier
    // portions' blocks, those earlier portions were missed and rescheduled.
    // They must remain as missed historical records (isCompleted: false, completedAt: null).
    final portions = challenge.portions;
    bool needsSanitize = false;
    final sanitizedPortions = portions.map((p) {
      final pBlocks = KhatmahConstants.getBlocksCovered(p.startSurah, p.endSurah);
      final isRescheduledLater = portions.any((other) =>
          other.dayNumber > p.dayNumber &&
          other.isAdjusted &&
          pBlocks.isNotEmpty &&
          pBlocks.every(KhatmahConstants.getBlocksCovered(other.startSurah, other.endSurah).contains));

      if (isRescheduledLater && (p.isCompleted || p.completedAt != null)) {
        needsSanitize = true;
        return p.copyWith(
          isCompleted: false,
          clearCompletedAt: true,
        );
      }
      return p;
    }).toList();

    if (needsSanitize) {
      final updatedChallenge = ChallengeModel.fromEntity(challenge).copyWithModel(
        portions: sanitizedPortions,
        isCompleted: sanitizedPortions.every((p) => p.isCompleted),
      );
      await localDataSource.saveActiveChallenge(updatedChallenge);
      return updatedChallenge;
    }

    return challenge;
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
      try {
        await notificationService.scheduleChallengeReminders(
          startDate: start,
          reminderTime: reminderTime,
          schedule: KhatmahConstants.traditionalSchedule,
        );
      } catch (_) {
        // Best-effort notification scheduling
      }
    }

    return challenge;
  }

  @override
  Future<Challenge> markDayCompleted(int dayNumber) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final now = DateTime.now();
    final updatedPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber) {
        return p.copyWith(
          isCompleted: true,
          completedAt: now,
        );
      }
      return p;
    }).toList();

    final tempChallenge = ChallengeModel.fromEntity(current).copyWithModel(
      portions: updatedPortions,
    );
    final allCompleted = tempChallenge.isAllPortionsCompleted ||
        updatedPortions.every((p) => p.isCompleted);

    final updatedChallenge = tempChallenge.copyWithModel(
      isCompleted: allCompleted,
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);

    // Cancel notification for today's completed portion (best-effort)
    try {
      await notificationService.cancelDayReminder(dayNumber);

      if (allCompleted) {
        await notificationService.showCompletionNotification();
      }
    } catch (_) {
      // Best-effort notification handling
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
          clearCompletedAt: true,
        );
      }
      return p;
    }).toList();

    final updatedChallenge = ChallengeModel.fromEntity(current).copyWithModel(
      portions: updatedPortions,
      isCompleted: false,
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);
    return updatedChallenge;
  }

  List<DefaultPortionData> _portionsToScheduleData(List<DayPortion> portions) {
    return portions.map((p) {
      return DefaultPortionData(
        dayNumber: p.dayNumber,
        startSurah: p.startSurah,
        endSurah: p.endSurah,
        startSurahAr: p.startSurahAr,
        endSurahAr: p.endSurahAr,
        surahCount: p.surahCount,
        startSurahIndex: KhatmahConstants.getBlockIndexByStartSurah(p.startSurah),
        endSurahIndex: KhatmahConstants.getBlockIndexByEndSurah(p.endSurah),
      );
    }).toList();
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

    if (storageService.isReminderEnabled && !updatedChallenge.isCompleted) {
      try {
        final completedDays = updatedChallenge.portions
            .where((p) => p.isCompleted)
            .map((p) => p.dayNumber)
            .toSet();
        await notificationService.scheduleChallengeReminders(
          startDate: updatedChallenge.startDate,
          reminderTime: updatedChallenge.reminderTime,
          schedule: _portionsToScheduleData(updatedChallenge.portions),
          completedDays: completedDays,
        );
      } catch (_) {
        // Best-effort notification rescheduling
      }
    }

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
    try {
      await notificationService.cancelAll();
    } catch (_) {}
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

      if (enabled && !updatedChallenge.isCompleted) {
        try {
          final completedDays = updatedChallenge.portions
              .where((p) => p.isCompleted)
              .map((p) => p.dayNumber)
              .toSet();
          await notificationService.scheduleChallengeReminders(
            startDate: updatedChallenge.startDate,
            reminderTime: reminderTime,
            schedule: _portionsToScheduleData(updatedChallenge.portions),
            completedDays: completedDays,
          );
        } catch (_) {}
      } else {
        try {
          await notificationService.cancelAll();
        } catch (_) {}
      }
    }
  }
}
