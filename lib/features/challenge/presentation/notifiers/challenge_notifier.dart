import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';
import '../../domain/repositories/challenge_repository.dart';
import 'challenge_state.dart';

class ChallengeNotifier extends StateNotifier<ChallengeState> {
  final ChallengeRepository repository;
  final StorageService storageService;

  ChallengeNotifier({
    required this.repository,
    required this.storageService,
  }) : super(const ChallengeState(isLoading: true)) {
    _initialLoad = loadInitialData();
  }

  late final Future<void> _initialLoad;

  /// Completes once the first load has finished. Actions arriving early (e.g.
  /// a notification action that launched the app) wait for it so the initial
  /// load cannot overwrite their result.
  Future<void> get ready => _initialLoad;

  /// Loads the active challenge and history. The full-screen loading state is
  /// only used for the very first load; later calls refresh silently so the
  /// navigation shell (tab, scroll position, sheets) is never torn down.
  Future<void> loadInitialData() async {
    if (!state.isInitialized) {
      state = state.copyWith(isLoading: true);
    }
    try {
      var challenge = await repository.getActiveChallenge();
      var history = await repository.getHistory();
      var autoStarted = false;

      if (challenge != null && _shouldAutoContinue(challenge)) {
        await repository.endChallengeAndArchive();
        challenge = await repository.startChallenge(
          startDate: AppDateUtils.dateOnly(DateTime.now()),
          reminderTime: challenge.reminderTime,
        );
        history = await repository.getHistory();
        autoStarted = true;
      }

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        challenge: challenge,
        clearChallenge: challenge == null,
        history: history,
        hasCompletedOnboarding: storageService.hasCompletedOnboarding,
        autoStartedNewCycle: autoStarted,
        readingPlanParts: storageService.readingPlanParts,
        lastBackupAt: storageService.lastBackupAt,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// Re-reads storage from disk (picking up notification-action writes made
  /// in a background isolate), refreshes state and re-plans reminders.
  Future<void> refreshFromDisk() async {
    await storageService.reloadFromDisk();
    await loadInitialData();
    await refreshReminders();
  }

  /// Continuous mode: once a khatmah is fully read and the day of its final
  /// completion has passed, the next 7-day cycle begins automatically.
  bool _shouldAutoContinue(Challenge challenge) {
    if (!storageService.isAutoContinueEnabled ||
        !challenge.isAllPortionsCompleted) {
      return false;
    }
    DateTime? lastCompletion;
    for (final p in challenge.portions) {
      final at = p.completedAt;
      if (at != null && (lastCompletion == null || at.isAfter(lastCompletion))) {
        lastCompletion = at;
      }
    }
    final finishedOn = AppDateUtils.dateOnly(lastCompletion ?? challenge.endDate);
    final today = AppDateUtils.dateOnly(DateTime.now());
    return finishedOn.isBefore(today);
  }

  Future<void> startChallenge({
    required DateTime startDate,
    required TimeOfDay reminderTime,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final challenge = await repository.startChallenge(
        startDate: startDate,
        reminderTime: reminderTime,
      );
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        challenge: challenge,
        hasCompletedOnboarding: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markDayCompleted(int dayNumber) async {
    await _initialLoad;
    var current = state.challenge;
    if (current == null) {
      current = await repository.getActiveChallenge();
      if (current == null) return;
    }

    final now = DateTime.now();
    final optimisticPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber && !p.isCompleted) {
        return p.copyWith(
          isCompleted: true,
          completedAt: now,
        );
      }
      return p;
    }).toList();

    final wasCompletedBefore = current.isAllPortionsCompleted;
    final optimisticChallenge = current.copyWith(portions: optimisticPortions);
    final allDone = optimisticChallenge.isAllPortionsCompleted;

    // Optimistically update state immediately so all screens re-render instantaneously
    state = state.copyWith(
      challenge: optimisticChallenge.copyWith(isCompleted: allDone),
      showCelebration: !wasCompletedBefore && allDone,
    );

    try {
      final updated = await repository.markDayCompleted(dayNumber);
      state = state.copyWith(
        challenge: updated,
        showCelebration: !wasCompletedBefore && updated.isAllPortionsCompleted,
      );
    } catch (e) {
      // Revert if persistent save failed
      state = state.copyWith(
        challenge: current,
        showCelebration: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> undoDayCompletion(int dayNumber) async {
    var current = state.challenge;
    if (current == null) {
      current = await repository.getActiveChallenge();
      if (current == null) return;
    }

    final optimisticPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber) {
        return p.copyWith(
          isCompleted: false,
          clearCompletedAt: true,
        );
      }
      return p;
    }).toList();

    final optimisticChallenge = current.copyWith(portions: optimisticPortions);

    // Optimistically update state immediately
    state = state.copyWith(
      challenge: optimisticChallenge.copyWith(
        isCompleted: optimisticChallenge.isAllPortionsCompleted,
      ),
      showCelebration: false,
    );

    try {
      final updated = await repository.undoDayCompletion(dayNumber);
      state = state.copyWith(challenge: updated);
    } catch (e) {
      state = state.copyWith(
        challenge: current,
        errorMessage: e.toString(),
      );
    }
  }

  /// Saves which parts (0..4) of [dayNumber]'s portion have been read.
  Future<void> setReadParts(int dayNumber, List<int> readParts) async {
    final current = state.challenge;
    if (current == null) return;

    state = state.copyWith(
      challenge: current.copyWith(
        portions: current.portions
            .map((p) =>
                p.dayNumber == dayNumber ? p.copyWith(readParts: readParts) : p)
            .toList(),
      ),
    );

    try {
      final updated = await repository.updateReadParts(dayNumber, readParts);
      state = state.copyWith(challenge: updated);
    } catch (e) {
      state = state.copyWith(challenge: current, errorMessage: e.toString());
    }
  }

  Future<void> adjustRemainingPlan(List<DayPortion> updatedPortions) async {
    try {
      final updated = await repository.adjustRemainingPlan(updatedPortions);
      state = state.copyWith(challenge: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> restartCurrentChallenge() async {
    try {
      final restarted = await repository.restartCurrentChallenge();
      final history = await repository.getHistory();
      state = state.copyWith(
        challenge: restarted,
        history: history,
        showCelebration: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> startNewChallenge({
    required DateTime startDate,
    required TimeOfDay reminderTime,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.endChallengeAndArchive();
      final newChallenge = await repository.startChallenge(
        startDate: startDate,
        reminderTime: reminderTime,
      );
      final history = await repository.getHistory();
      state = state.copyWith(
        isLoading: false,
        challenge: newChallenge,
        history: history,
        showCelebration: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateReminderSettings({
    required bool enabled,
    required TimeOfDay reminderTime,
  }) async {
    try {
      await repository.updateReminderSettings(
        enabled: enabled,
        reminderTime: reminderTime,
      );
      final refreshed = await repository.getActiveChallenge();
      state = state.copyWith(
        challenge: refreshed,
        clearChallenge: refreshed == null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateFollowUpSettings({
    required bool enabled,
    required TimeOfDay followUpTime,
  }) async {
    try {
      await repository.updateFollowUpSettings(
        enabled: enabled,
        followUpTime: followUpTime,
      );
      // Trigger a rebuild so settings reflect the stored values.
      state = state.copyWith();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Changes the split for one day only (null = follow the default again).
  Future<void> setDayReadingPlan(int dayNumber, int? parts) async {
    try {
      final updated = await repository.setDayPartsCount(dayNumber, parts);
      state = state.copyWith(challenge: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Changes the daily reading plan split (0 = off).
  Future<void> setReadingPlanParts(int parts) async {
    try {
      final updated = await repository.setReadingPlanParts(parts);
      state = state.copyWith(challenge: updated, readingPlanParts: parts);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> setAutoContinue(bool enabled) async {
    await storageService.setAutoContinueEnabled(enabled);
    state = state.copyWith();
  }

  /// Re-plans scheduled notifications (idempotent).
  Future<void> refreshReminders() async {
    try {
      await repository.refreshReminders();
    } catch (_) {}
  }

  /// Kept for existing callers (e.g. after exact-alarm permission changes).
  Future<void> rescheduleReminders() => refreshReminders();

  String exportBackup() => repository.exportBackup();

  Future<bool> importBackup(String raw) async {
    final ok = await repository.importBackup(raw);
    if (ok) await loadInitialData();
    return ok;
  }

  /// Records that a backup file was just saved.
  Future<void> markBackupSaved(DateTime at) async {
    await storageService.setLastBackupAt(at);
    state = state.copyWith(lastBackupAt: at);
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false);
  }
}
