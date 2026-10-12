import 'package:flutter/material.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/utils/date_utils.dart';
import 'day_portion.dart';

class Challenge {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<DayPortion> portions;
  final int reminderHour;
  final int reminderMinute;
  final bool isCompleted;
  final DateTime createdAt;

  const Challenge({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.portions,
    required this.reminderHour,
    required this.reminderMinute,
    this.isCompleted = false,
    required this.createdAt,
  });

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  /// Day index (1 to 7) based on today's calendar date relative to startDate.
  /// If today is before startDate, returns 0.
  /// If beyond Day 7, returns 8+.
  int get currentDayNumber {
    return AppDateUtils.calculateCurrentDayNumber(startDate);
  }

  /// Clamped day number for display (1 to 7)
  int get displayDayNumber {
    final day = currentDayNumber;
    if (day < 1) return 1;
    if (day > 7) return 7;
    return day;
  }

  /// Whether the challenge is currently active (today is within the 7-day window and not all completed)
  bool get isActive {
    final day = currentDayNumber;
    return day >= 1 && day <= 7 && !isAllPortionsCompleted;
  }

  /// Whether the 7 calendar days have elapsed without completing all portions
  bool get isExpired {
    return currentDayNumber > 7 && !isAllPortionsCompleted;
  }

  /// Set of traditional block indices (0..6) that are covered by completed portions
  Set<int> get completedBlockIndices {
    final blocks = <int>{};
    for (final p in portions) {
      if (p.isCompleted) {
        final covered = KhatmahConstants.getBlocksCovered(p.startSurah, p.endSurah);
        if (covered.isNotEmpty) {
          blocks.addAll(covered);
        } else {
          blocks.add((p.dayNumber - 1).clamp(0, 6));
        }
      }
    }
    return blocks;
  }

  /// Set of traditional block indices (0..6) that are scheduled in the remaining active days
  Set<int> get upcomingScheduledBlockIndices {
    final blocks = <int>{};
    final day = currentDayNumber;
    for (final p in portions) {
      if (p.dayNumber >= day && p.dayNumber <= KhatmahConstants.totalDays) {
        final covered = KhatmahConstants.getBlocksCovered(p.startSurah, p.endSurah);
        if (covered.isNotEmpty) {
          blocks.addAll(covered);
        } else {
          blocks.add((p.dayNumber - 1).clamp(0, KhatmahConstants.totalDays - 1));
        }
      }
    }
    return blocks;
  }

  /// Number of completed portions (0..7).
  /// Accurately counts all 7 traditional Quran portions covered,
  /// including when adjusted portions cover multiple portions.
  int get completedPortionsCount {
    return completedBlockIndices.length.clamp(0, KhatmahConstants.totalDays);
  }

  /// Completed percentage (0.0 .. 1.0)
  double get completionPercentage {
    return (completedPortionsCount / KhatmahConstants.totalDays).clamp(0.0, 1.0);
  }

  int get completionPercentInt {
    return (completionPercentage * 100).round();
  }

  /// Returns true if all 7 portions are marked complete
  bool get isAllPortionsCompleted {
    return completedPortionsCount >= KhatmahConstants.totalDays;
  }

  /// Days remaining in the 7-day challenge window
  int get daysRemaining {
    final day = currentDayNumber;
    if (day < 1) return 7;
    if (day > 7) return 0;
    return 7 - day;
  }

  /// Portion corresponding to today (if today is within 1..7)
  DayPortion? get todayPortion {
    final day = currentDayNumber;
    if (day < 1 || day > 7) return null;
    for (final p in portions) {
      if (p.dayNumber == day) return p;
    }
    return portions.isNotEmpty ? portions.first : null;
  }

  /// True only if challenge is active and any past day (day < currentDayNumber) is incomplete
  /// and its reading is neither completed nor scheduled in the remaining days.
  bool get isBehindSchedule {
    if (!isActive) return false;
    final day = currentDayNumber;
    if (day <= 1) return false;
    final coveredOrScheduled = {
      ...completedBlockIndices,
      ...upcomingScheduledBlockIndices,
    };
    return portions.any((p) {
      if (p.dayNumber >= day || p.isCompleted) return false;
      final covered = KhatmahConstants.getBlocksCovered(p.startSurah, p.endSurah);
      if (covered.isNotEmpty) {
        return !covered.every(coveredOrScheduled.contains);
      }
      return !coveredOrScheduled.contains((p.dayNumber - 1).clamp(0, KhatmahConstants.totalDays - 1));
    });
  }

  /// Number of incomplete past portions neither completed nor scheduled in remaining days
  int get missedPortionsCount {
    final day = currentDayNumber;
    if (day <= 1) return 0;
    final maxPastDay = day > KhatmahConstants.totalDays ? KhatmahConstants.totalDays : day - 1;
    final coveredOrScheduled = {
      ...completedBlockIndices,
      ...upcomingScheduledBlockIndices,
    };
    return portions.where((p) {
      if (p.dayNumber > maxPastDay || p.isCompleted) return false;
      final covered = KhatmahConstants.getBlocksCovered(p.startSurah, p.endSurah);
      if (covered.isNotEmpty) {
        return !covered.every(coveredOrScheduled.contains);
      }
      return !coveredOrScheduled.contains((p.dayNumber - 1).clamp(0, KhatmahConstants.totalDays - 1));
    }).length;
  }

  Challenge copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    List<DayPortion>? portions,
    int? reminderHour,
    int? reminderMinute,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      portions: portions ?? this.portions,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
