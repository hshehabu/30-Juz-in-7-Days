import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/notification_service.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/challenge_model.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';

void main() {
  test('Background notification action marks day completed in storage', () async {
    final portions = KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: false,
      );
    }).toList();

    final testChallenge = ChallengeModel(
      id: 'test_challenge',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 6)),
      portions: portions,
      reminderHour: 19,
      reminderMinute: 0,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    SharedPreferences.setMockInitialValues({
      'active_khatmah_challenge': jsonEncode(testChallenge.toJson()),
    });

    // Simulate background notification action for Day 1
    await NotificationService.markDayCompletedInBackground(1);

    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final rawJson = storage.getActiveChallengeJson();
    expect(rawJson, isNotNull);

    final Map<String, dynamic> data = jsonDecode(rawJson!);
    final updatedList = (data['portions'] as List<dynamic>);
    final day1 = updatedList.firstWhere((p) => p['dayNumber'] == 1);
    expect(day1['isCompleted'], isTrue);
    expect(day1['completedAt'], isNotNull);

    final day2 = updatedList.firstWhere((p) => p['dayNumber'] == 2);
    expect(day2['isCompleted'], isFalse);
  });
}
