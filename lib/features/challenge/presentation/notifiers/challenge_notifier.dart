import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
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
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final challenge = await repository.getActiveChallenge();
      final hasOnboarded = storageService.hasCompletedOnboarding;
      state = state.copyWith(
        isLoading: false,
        challenge: challenge,
        hasCompletedOnboarding: hasOnboarded,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
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
    var current = state.challenge;
    if (current == null) {
      current = await repository.getActiveChallenge();
      if (current == null) return;
    }

    final now = DateTime.now();
    final optimisticPortions = current.portions.map((p) {
      if (p.dayNumber == dayNumber) {
        return p.copyWith(
          isCompleted: true,
          completedAt: now,
        );
      }
      return p;
    }).toList();

    final allDone = optimisticPortions.every((p) => p.isCompleted);
    final wasCompletedBefore = current.isAllPortionsCompleted;
    final optimisticChallenge = current.copyWith(
      portions: optimisticPortions,
      isCompleted: allDone,
    );

    // Optimistically update state immediately so all screens re-render instantaneously
    state = state.copyWith(
      challenge: optimisticChallenge,
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

    final optimisticChallenge = current.copyWith(
      portions: optimisticPortions,
      isCompleted: false,
    );

    // Optimistically update state immediately
    state = state.copyWith(
      challenge: optimisticChallenge,
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

  Future<void> adjustRemainingPlan(List<DayPortion> updatedPortions) async {
    try {
      final updated = await repository.adjustRemainingPlan(updatedPortions);
      state = state.copyWith(challenge: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }


  Future<void> restartCurrentChallenge() async {
    state = state.copyWith(isLoading: true);
    try {
      final restarted = await repository.restartCurrentChallenge();
      state = state.copyWith(
        isLoading: false,
        challenge: restarted,
        showCelebration: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
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
      state = state.copyWith(
        isLoading: false,
        challenge: newChallenge,
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
      state = state.copyWith(challenge: refreshed);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> rescheduleReminders() async {
    if (storageService.isReminderEnabled) {
      final time = state.challenge?.reminderTime ?? storageService.reminderTime;
      await updateReminderSettings(
        enabled: true,
        reminderTime: time,
      );
    }
  }

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false);
  }
}

