import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/utils/date_utils.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/challenge_model.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/day_portion_model.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';

void main() {
  group('Date & Day Calculations', () {
    test('Day calculation gives Day 1 on start date', () {
      final start = DateTime(2026, 9, 1);
      final today = DateTime(2026, 9, 1);
      expect(AppDateUtils.calculateCurrentDayNumber(start, today), 1);
    });

    test('Day calculation gives Day 4 after 3 elapsed days', () {
      final start = DateTime(2026, 9, 1);
      final today = DateTime(2026, 9, 4);
      expect(AppDateUtils.calculateCurrentDayNumber(start, today), 4);
    });

    test('Day calculation gives Day 7 on final day', () {
      final start = DateTime(2026, 9, 1);
      final today = DateTime(2026, 9, 7);
      expect(AppDateUtils.calculateCurrentDayNumber(start, today), 7);
    });

    test('Day calculation detects expired challenge beyond day 7', () {
      final start = DateTime(2026, 9, 1);
      final today = DateTime(2026, 9, 9);
      expect(AppDateUtils.calculateCurrentDayNumber(start, today), 9);
    });
  });

  group('Portion Model & Serialization', () {
    test('Portion model serializes and deserializes properly', () {
      final portion = DayPortionModel(
        dayNumber: 1,
        startSurah: 'Al-Baqarah',
        endSurah: 'An-Nisa',
        startSurahAr: 'البقرة',
        endSurahAr: 'النساء',
        surahCount: 3,
        isCompleted: true,
        completedAt: DateTime(2026, 9, 1, 14, 30),
      );

      final json = portion.toJson();
      final fromJson = DayPortionModel.fromJson(json);

      expect(fromJson.dayNumber, 1);
      expect(fromJson.startSurah, 'Al-Baqarah');
      expect(fromJson.endSurah, 'An-Nisa');
      expect(fromJson.isCompleted, true);
      expect(fromJson.completedAt, DateTime(2026, 9, 1, 14, 30));
    });

    test('Traditional schedule has 7 days and starts with Al-Baqarah', () {
      expect(KhatmahConstants.traditionalSchedule.length, 7);
      expect(KhatmahConstants.traditionalSchedule.first.startSurah, 'Al-Baqarah');
      expect(KhatmahConstants.traditionalSchedule.last.endSurah, 'An-Nas');
    });
  });

  group('Challenge Entity Progress & Status', () {
    test('Computes progress percentage and behind-schedule status correctly', () {
      final start = AppDateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 2))); // Today is Day 3
      final end = start.add(const Duration(days: 6));

      final portions = List.generate(7, (i) {
        return DayPortion(
          dayNumber: i + 1,
          startSurah: 'SurahStart',
          endSurah: 'SurahEnd',
          startSurahAr: 'البداية',
          endSurahAr: 'النهاية',
          surahCount: 5,
          isCompleted: i == 0, // Only Day 1 is completed, Day 2 is missed!
        );
      });

      final challenge = Challenge(
        id: 'test_123',
        startDate: start,
        endDate: end,
        portions: portions,
        reminderHour: 19,
        reminderMinute: 0,
        createdAt: start,
      );

      expect(challenge.currentDayNumber, 3);
      expect(challenge.completedPortionsCount, 1);
      expect(challenge.isBehindSchedule, true); // Day 2 was missed
      expect(challenge.missedPortionsCount, 1);
      expect(challenge.isAllPortionsCompleted, false);
    });

    test('Challenge model serializes and deserializes accurately', () {
      final start = DateTime(2026, 9, 5);
      final end = DateTime(2026, 9, 11);

      final portions = List.generate(7, (i) {
        return DayPortion(
          dayNumber: i + 1,
          startSurah: 'Surah${i + 1}',
          endSurah: 'Surah${i + 2}',
          startSurahAr: 'سورة${i + 1}',
          endSurahAr: 'سورة${i + 2}',
          surahCount: 2,
          isCompleted: false,
        );
      });

      final challenge = ChallengeModel(
        id: 'c_999',
        startDate: start,
        endDate: end,
        portions: portions,
        reminderHour: 20,
        reminderMinute: 30,
        createdAt: start,
      );

      final map = challenge.toJson();
      final revived = ChallengeModel.fromJson(map);

      expect(revived.id, 'c_999');
      expect(revived.reminderHour, 20);
      expect(revived.reminderMinute, 30);
      expect(revived.portions.length, 7);
    });
  });
}
