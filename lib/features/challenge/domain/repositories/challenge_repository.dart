import 'package:flutter/material.dart';
import '../entities/challenge.dart';
import '../entities/day_portion.dart';

abstract class ChallengeRepository {
  /// Returns the current active challenge if any exists
  Future<Challenge?> getActiveChallenge();

  /// Archived (completed or concluded) challenges, newest first.
  Future<List<Challenge>> getHistory();

  /// Starts a new challenge from [startDate] with daily [reminderTime]
  Future<Challenge> startChallenge({
    required DateTime startDate,
    required TimeOfDay reminderTime,
  });

  /// Marks a specific day's portion as complete
  Future<Challenge> markDayCompleted(int dayNumber);

  /// Undoes completion for a specific day
  Future<Challenge> undoDayCompletion(int dayNumber);

  /// Records which parts (0..4) of a day's portion have been read so far.
  Future<Challenge> updateReadParts(int dayNumber, List<int> readParts);

  /// Changes the default split (0 = off). Unfinished days that were not
  /// customized are re-split, keeping fully covered parts ticked.
  Future<Challenge?> setReadingPlanParts(int parts);

  /// Sets the split for one unfinished day only ([parts] null = follow the
  /// default again).
  Future<Challenge> setDayPartsCount(int dayNumber, int? parts);

  /// Redistributes remaining uncompleted portions across remaining days
  Future<Challenge> adjustRemainingPlan(List<DayPortion> updatedPortions);

  /// Archives the current attempt and restarts from Day 1 today
  Future<Challenge> restartCurrentChallenge();

  /// Ends and archives current challenge, allowing a new one to be started
  Future<void> endChallengeAndArchive();

  /// Updates the daily reminder settings
  Future<void> updateReminderSettings({
    required bool enabled,
    required TimeOfDay reminderTime,
  });

  /// Updates the optional follow-up ("still unread") reminder
  Future<void> updateFollowUpSettings({
    required bool enabled,
    required TimeOfDay followUpTime,
  });

  /// Re-plans all scheduled notifications from the current state.
  /// Idempotent; safe to call on every launch and resume.
  Future<void> refreshReminders();

  /// Portable JSON backup of all progress and preferences.
  String exportBackup();

  /// Restores a backup. Returns false if the payload is invalid.
  Future<bool> importBackup(String raw);
}
