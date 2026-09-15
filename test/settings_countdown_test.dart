import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Settings Reminder Countdown Logic', () {
    test('Calculates next occurrence correctly when reminder is in future today', () {
      final now = DateTime(2026, 9, 6, 14, 0); // 2:00 PM
      final reminder = const TimeOfDay(hour: 16, minute: 30); // 4:30 PM

      var target = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }

      final diff = target.difference(now);
      expect(diff.inHours, 2);
      expect(diff.inMinutes.remainder(60), 30);
    });

    test('Calculates next occurrence correctly when reminder has already passed today', () {
      final now = DateTime(2026, 9, 6, 20, 0); // 8:00 PM
      final reminder = const TimeOfDay(hour: 6, minute: 0); // 6:00 AM

      var target = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }

      final diff = target.difference(now);
      // Next day at 6:00 AM is 10 hours away
      expect(diff.inHours, 10);
      expect(diff.inMinutes.remainder(60), 0);
      expect(target.day, 7);
    });

    test('Identifies Due now condition when current time matches reminder minute', () {
      final now = DateTime(2026, 9, 6, 16, 30, 15); // 4:30:15 PM
      final reminder = const TimeOfDay(hour: 16, minute: 30); // 4:30 PM

      final isDueNow = now.hour == reminder.hour && now.minute == reminder.minute;
      expect(isDueNow, isTrue);
    });
  });
}
