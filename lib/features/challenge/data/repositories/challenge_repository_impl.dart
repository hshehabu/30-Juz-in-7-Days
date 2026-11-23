import 'dart:convert';
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
    bool needsSanitize = false;
    final sanitizedPortions = challenge.portions.map((p) {
      if (challenge.rescheduledToDay(p) != null &&
          (p.isCompleted || p.completedAt != null)) {
        needsSanitize = true;
        return p.copyWith(
          isCompleted: false,
          clearCompletedAt: true,
        );
      }
      return p;
    }).toList();

    if (needsSanitize) {
      final updatedChallenge = _withDerivedCompletion(
        ChallengeModel.fromEntity(challenge).copyWithModel(
          portions: sanitizedPortions,
        ),
      );
      await localDataSource.saveActiveChallenge(updatedChallenge);
      return updatedChallenge;
    }

    return challenge;
  }

  // Decoded history, rebuilt only when storage reports a change.
  List<Challenge>? _historyCache;
  int _historyCacheRevision = -1;

  @override
  Future<List<Challenge>> getHistory() async {
    final revision = storageService.historyRevision;
    final cached = _historyCache;
    if (cached != null && revision == _historyCacheRevision) return cached;

    final result = <Challenge>[];
    for (final raw in storageService.getHistoryJsonList()) {
      try {
        result.add(
            ChallengeModel.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    _historyCache = List.unmodifiable(result);
    _historyCacheRevision = revision;
    return _historyCache!;
  }

  /// Keeps the stored `isCompleted` flag in sync with the single derived
  /// definition ([Challenge.isAllPortionsCompleted]).
  ChallengeModel _withDerivedCompletion(ChallengeModel model) {
    return model.copyWithModel(isCompleted: model.isAllPortionsCompleted);
  }

  @override
  Future<Challenge> startChallenge({
    required DateTime startDate,
    required TimeOfDay reminderTime,
  }) async {
    final start = AppDateUtils.dateOnly(startDate);
    final end = start.add(const Duration(days: 6));

    final planParts = storageService.readingPlanParts;
    final portions = KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: false,
        partsCount: planParts > 0 ? planParts : DayPortion.defaultPartsCount,
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

    await _scheduleFor(challenge);

    return challenge;
  }

  @override
  Future<Challenge> markDayCompleted(int dayNumber) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final wasAllCompleted = current.isAllPortionsCompleted;
    final now = DateTime.now();
    final updatedPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber && !p.isCompleted) {
        return p.copyWith(
          isCompleted: true,
          completedAt: now,
        );
      }
      return p;
    }).toList();

    final updatedChallenge = _withDerivedCompletion(
      ChallengeModel.fromEntity(current).copyWithModel(portions: updatedPortions),
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);

    // Cancel the day's reminder + follow-up (best-effort)
    try {
      await notificationService.cancelDayReminder(dayNumber);

      if (updatedChallenge.isCompleted && !wasAllCompleted) {
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

    final updatedChallenge = _withDerivedCompletion(
      ChallengeModel.fromEntity(current).copyWithModel(portions: updatedPortions),
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);

    // Restore the day's reminder (it was cancelled on completion).
    await _scheduleFor(updatedChallenge);
    return updatedChallenge;
  }

  @override
  Future<Challenge> updateReadParts(int dayNumber, List<int> readParts) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final updatedPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber) {
        final count = p.parts.length;
        final cleaned = readParts
            .where((i) => i >= 0 && i < count)
            .toSet()
            .toList()
          ..sort();
        return p.copyWith(readParts: cleaned);
      }
      return p;
    }).toList();

    final updatedChallenge =
        current.copyWithModel(portions: updatedPortions);
    await localDataSource.saveActiveChallenge(updatedChallenge);
    return updatedChallenge;
  }

  @override
  Future<Challenge?> setReadingPlanParts(int parts) async {
    await storageService.setReadingPlanParts(parts);
    final current = await localDataSource.getActiveChallenge();
    if (current == null || parts < 1) return current;

    // Only unfinished, non-customized days adopt the new default. Completed
    // days keep the plan they were read with (and their ticks), and days
    // given their own split keep it.
    final updated = current.copyWithModel(
      portions: current.portions
          .map((p) =>
              p.isCompleted || p.partsCustom ? p : p.withPartsCount(parts))
          .toList(),
    );
    await localDataSource.saveActiveChallenge(updated);
    return updated;
  }

  @override
  Future<Challenge> setDayPartsCount(int dayNumber, int? parts) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }
    final defaultParts = storageService.readingPlanParts > 0
        ? storageService.readingPlanParts
        : DayPortion.defaultPartsCount;

    final updated = current.copyWithModel(
      portions: current.portions.map((p) {
        if (p.dayNumber != dayNumber || p.isCompleted) return p;
        if (parts == null) {
          return p.withPartsCount(defaultParts).copyWith(partsCustom: false);
        }
        return p.withPartsCount(parts).copyWith(partsCustom: true);
      }).toList(),
    );
    await localDataSource.saveActiveChallenge(updated);
    return updated;
  }

  @override
  Future<Challenge> adjustRemainingPlan(List<DayPortion> updatedPortions) async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    final updatedChallenge = _withDerivedCompletion(
      current.copyWithModel(portions: updatedPortions),
    );

    await localDataSource.saveActiveChallenge(updatedChallenge);
    await _scheduleFor(updatedChallenge);

    return updatedChallenge;
  }

  @override
  Future<Challenge> restartCurrentChallenge() async {
    final current = await localDataSource.getActiveChallenge();
    if (current == null) {
      throw StateError('No active challenge found');
    }

    // Keep the previous attempt in history if any reading was recorded,
    // so restarting never silently erases the user's past effort.
    final hasProgress = current.portions
        .any((p) => p.isCompleted || p.readParts.isNotEmpty);
    if (hasProgress) {
      await localDataSource.archiveCompletedChallenge(current);
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
    }

    await refreshReminders();
  }

  @override
  Future<void> updateFollowUpSettings({
    required bool enabled,
    required TimeOfDay followUpTime,
  }) async {
    await storageService.setFollowUpEnabled(enabled);
    await storageService.setFollowUpTime(followUpTime);
    await refreshReminders();
  }

  @override
  Future<void> refreshReminders() async {
    final active = await localDataSource.getActiveChallenge();
    if (active == null) {
      try {
        await notificationService.cancelAll();
      } catch (_) {}
      return;
    }
    await _scheduleFor(active);
  }

  /// Schedules (or clears) reminders for [challenge] using current settings.
  Future<void> _scheduleFor(Challenge challenge) async {
    try {
      if (!storageService.isReminderEnabled) {
        await notificationService.cancelAll();
        return;
      }
      final completedDays = challenge.portions
          .where((p) => p.isCompleted)
          .map((p) => p.dayNumber)
          .toSet();
      await notificationService.scheduleChallengeReminders(
        startDate: challenge.startDate,
        reminderTime: storageService.reminderTime,
        schedule: _portionsToScheduleData(challenge.portions),
        completedDays: completedDays,
        followUpTime: storageService.isFollowUpEnabled
            ? storageService.followUpTime
            : null,
        languageCode: storageService.languageCode,
      );
    } catch (_) {
      // Best-effort notification scheduling
    }
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
        startSurahIndex: p.startSurahNumber,
        endSurahIndex: p.endSurahNumber,
      );
    }).toList();
  }

  @override
  String exportBackup() => storageService.exportBackup();

  @override
  Future<bool> importBackup(String raw) async {
    final ok = await storageService.importBackup(raw);
    if (ok) await refreshReminders();
    return ok;
  }
}
