import 'package:flutter/material.dart';
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

  /// Whether the challenge is currently active (today is within the 7-day window)
  bool get isActive {
    final day = currentDayNumber;
    return day >= 1 && day <= 7 && !isCompleted;
  }

  /// Whether the 7 calendar days have elapsed
  bool get isExpired {
    return currentDayNumber > 7;
  }

  /// Number of completed daily portions (0..7)
  int get completedPortionsCount {
    return portions.where((p) => p.isCompleted).length;
  }

  /// Completed percentage (0.0 .. 1.0)
  double get completionPercentage {
    if (portions.isEmpty) return 0.0;
    return completedPortionsCount / portions.length;
  }

  int get completionPercentInt {
    return (completionPercentage * 100).round();
  }

  /// Returns true if all 7 portions are marked complete
  bool get isAllPortionsCompleted {
    return completedPortionsCount == 7;
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

  /// True if any past day (day < currentDayNumber) is incomplete
  bool get isBehindSchedule {
    final day = currentDayNumber;
    if (day <= 1) return false;
    final maxPastDay = day > 7 ? 7 : day - 1;
    return portions.any((p) => p.dayNumber <= maxPastDay && !p.isCompleted);
  }

  /// Number of incomplete past portions
  int get missedPortionsCount {
    final day = currentDayNumber;
    if (day <= 1) return 0;
    final maxPastDay = day > 7 ? 7 : day - 1;
    return portions
        .where((p) => p.dayNumber <= maxPastDay && !p.isCompleted)
        .length;
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
