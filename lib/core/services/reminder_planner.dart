import 'package:flutter/material.dart';

enum ReminderKind { portion, followUp, habit }

/// A notification the app intends to schedule, in local wall-clock time.
class PlannedReminder {
  final int id;
  final DateTime when;
  final ReminderKind kind;

  /// Challenge day (1..7) for portion and follow-up reminders.
  final int? dayNumber;

  const PlannedReminder({
    required this.id,
    required this.when,
    required this.kind,
    this.dayNumber,
  });

  @override
  String toString() => 'PlannedReminder($id, $kind, day: $dayNumber, $when)';
}

/// Pure scheduling rules shared by the notification scheduler and the UI
/// countdown, so "next reminder" always matches what is actually scheduled.
class ReminderPlanner {
  ReminderPlanner._();

  static const int followUpIdOffset = 200;
  static const int habitIdOffset = 100;

  static int followUpId(int dayNumber) => followUpIdOffset + dayNumber;

  /// Plans reminders for every remaining challenge day (however far away the
  /// start date is), plus daily habit reminders for up to [habitHorizonDays]
  /// after the challenge window ends.
  static List<PlannedReminder> plan({
    required DateTime now,
    required DateTime startDate,
    required TimeOfDay reminderTime,
    int totalDays = 7,
    Set<int> completedDays = const {},
    TimeOfDay? followUpTime,
    int habitHorizonDays = 7,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final result = <PlannedReminder>[];

    DateTime at(DateTime date, TimeOfDay time) =>
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // 1. Challenge days
    for (var day = 1; day <= totalDays; day++) {
      final date = DateTime(start.year, start.month, start.day + day - 1);
      if (date.isBefore(today) || completedDays.contains(day)) continue;

      final main = at(date, reminderTime);
      if (main.isAfter(now)) {
        result.add(PlannedReminder(
          id: day,
          when: main,
          kind: ReminderKind.portion,
          dayNumber: day,
        ));
      }
      // A reminder whose time has passed, even by seconds, is never re-fired.
      // Re-planning happens on every resume and language change, so firing
      // "now" would duplicate a reminder that was already delivered.

      if (followUpTime != null) {
        final followUp = at(date, followUpTime);
        if (followUp.isAfter(main) && followUp.isAfter(now)) {
          result.add(PlannedReminder(
            id: followUpId(day),
            when: followUp,
            kind: ReminderKind.followUp,
            dayNumber: day,
          ));
        }
      }
    }

    // 2. Daily habit reminders once the challenge window is over
    final end = DateTime(start.year, start.month, start.day + totalDays - 1);
    final dayAfterEnd = DateTime(end.year, end.month, end.day + 1);
    final firstHabitDate = dayAfterEnd.isAfter(today) ? dayAfterEnd : today;
    final horizonEnd = DateTime(today.year, today.month, today.day + habitHorizonDays);
    for (var k = 0; k <= habitHorizonDays; k++) {
      final date = DateTime(
          firstHabitDate.year, firstHabitDate.month, firstHabitDate.day + k);
      if (date.isAfter(horizonEnd)) break;
      final when = at(date, reminderTime);
      if (!when.isAfter(now)) continue;
      result.add(PlannedReminder(
        id: habitIdOffset + k,
        when: when,
        kind: ReminderKind.habit,
      ));
    }

    result.sort((a, b) => a.when.compareTo(b.when));
    return result;
  }
}
