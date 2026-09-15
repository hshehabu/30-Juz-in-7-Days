import 'package:flutter/material.dart';
import '../entities/challenge.dart';
import '../entities/day_portion.dart';

abstract class ChallengeRepository {
  /// Returns the current active challenge if any exists
  Future<Challenge?> getActiveChallenge();

  /// Starts a new challenge from [startDate] with daily [reminderTime]
  Future<Challenge> startChallenge({
    required DateTime startDate,
    required TimeOfDay reminderTime,
  });

  /// Marks a specific day's portion as complete
  Future<Challenge> markDayCompleted(int dayNumber);

  /// Undoes completion for a specific day
  Future<Challenge> undoDayCompletion(int dayNumber);

  /// Redistributes remaining uncompleted portions across remaining days
  Future<Challenge> adjustRemainingPlan(List<DayPortion> updatedPortions);

  /// Resets portions to the authentic traditional 7-part schedule while preserving completion status
  Future<Challenge> resetToTraditionalSchedule();

  /// Restarts the current challenge back to Day 1
  Future<Challenge> restartCurrentChallenge();

  /// Ends and archives current challenge, allowing a new one to be started
  Future<void> endChallengeAndArchive();

  /// Updates the daily reminder settings
  Future<void> updateReminderSettings({
    required bool enabled,
    required TimeOfDay reminderTime,
  });
}
