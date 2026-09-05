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

    try {
      final updated = await repository.markDayCompleted(dayNumber);
      final wasCompletedBefore = current.isAllPortionsCompleted;
      final isNowAllCompleted = updated.isAllPortionsCompleted;

      state = state.copyWith(
        challenge: updated,
        showCelebration: !wasCompletedBefore && isNowAllCompleted,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> undoDayCompletion(int dayNumber) async {
    try {
      final updated = await repository.undoDayCompletion(dayNumber);
      state = state.copyWith(challenge: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
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

  void dismissCelebration() {
    state = state.copyWith(showCelebration: false);
  }
}
