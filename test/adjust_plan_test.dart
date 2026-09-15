import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/adjust_plan_dialog.dart';

void main() {
  Widget buildDialogWrapper(Widget dialog) {
    return MaterialApp(
      home: Scaffold(
        body: dialog,
      ),
    );
  }

  List<DayPortion> createDefaultPortions({bool day1Completed = false}) {
    return KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: data.dayNumber == 1 ? day1Completed : false,
      );
    }).toList();
  }

  testWidgets(
      'Adjust plan when Day 1 completed and adjusting on Day 3 starts Day 3 at Al-Ma\'idah',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 2)); // Day 3
    final challenge = Challenge(
      id: 'test_adj',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(day1Completed: true),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    List<DayPortion>? updatedResult;

    await tester.pumpWidget(
      buildDialogWrapper(
        AdjustPlanDialog(
          challenge: challenge,
          onConfirm: (portions) {
            updatedResult = portions;
          },
        ),
      ),
    );

    expect(find.text('Adjust Remaining Plan'), findsOneWidget);
    expect(find.text('Apply Plan'), findsOneWidget);

    await tester.tap(find.text('Apply Plan'));
    await tester.pumpAndSettle();

    expect(updatedResult, isNotNull);
    final day1 = updatedResult!.firstWhere((p) => p.dayNumber == 1);
    final day2 = updatedResult!.firstWhere((p) => p.dayNumber == 2);
    final day3 = updatedResult!.firstWhere((p) => p.dayNumber == 3);
    final day7 = updatedResult!.firstWhere((p) => p.dayNumber == 7);

    // Day 1 must remain completed
    expect(day1.isCompleted, isTrue);
    expect(day1.startSurah, 'Al-Baqarah');
    expect(day1.endSurah, 'An-Nisa');

    // Day 2 must remain as missed historical record
    expect(day2.isCompleted, isFalse);
    expect(day2.startSurah, 'Al-Ma\'idah');
    expect(day2.endSurah, 'At-Tawbah');

    // Day 3 MUST start from Al-Ma'idah (NOT Al-Baqarah!)
    expect(day3.startSurah, 'Al-Ma\'idah');
    expect(day3.isAdjusted, isTrue);

    // Day 7 must end at An-Nas
    expect(day7.endSurah, 'An-Nas');
  });

  testWidgets(
      'Adjust plan dialog for expired challenge shows Khatmah Concluded',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 10)); // Day 11
    final challenge = Challenge(
      id: 'test_exp',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(day1Completed: false),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    await tester.pumpWidget(
      buildDialogWrapper(
        AdjustPlanDialog(
          challenge: challenge,
          onConfirm: (_) {},
        ),
      ),
    );

    expect(find.text('Khatmah Concluded'), findsOneWidget);
    expect(find.text('Apply Plan'), findsNothing);
    expect(find.text('Close'), findsOneWidget);
  });
}
