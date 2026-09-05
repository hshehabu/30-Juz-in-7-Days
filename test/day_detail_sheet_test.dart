import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/day_detail_sheet.dart';

void main() {
  Widget buildSheetWrapper(Widget sheet) {
    return MaterialApp(
      home: Scaffold(
        body: sheet,
      ),
    );
  }

  final testPortionDay1 = DayPortion(
    dayNumber: 1,
    startSurah: 'Al-Baqarah',
    endSurah: 'An-Nisa',
    startSurahAr: 'البقرة',
    endSurahAr: 'النساء',
    surahCount: 3,
    isCompleted: false,
  );

  final testPortionDay3 = DayPortion(
    dayNumber: 3,
    startSurah: 'Yunus',
    endSurah: 'Al-Isra',
    startSurahAr: 'يونس',
    endSurahAr: 'الإسراء',
    surahCount: 8,
    isCompleted: false,
  );

  testWidgets('Current day portion displays normal "Mark as completed" button',
      (tester) async {
    bool toggled = false;

    await tester.pumpWidget(
      buildSheetWrapper(
        DayDetailSheet(
          portion: testPortionDay1,
          portionDate: DateTime.now(),
          currentDayNumber: 1,
          onToggleCompletion: () {
            toggled = true;
          },
        ),
      ),
    );

    expect(find.text('Mark as completed'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Mark as completed'));
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });

  testWidgets(
      'Upcoming day portion displays "Mark Day 3 ahead of schedule" and opens confirmation',
      (tester) async {
    bool toggled = false;

    await tester.pumpWidget(
      buildSheetWrapper(
        DayDetailSheet(
          portion: testPortionDay3,
          portionDate: DateTime.now().add(const Duration(days: 2)),
          currentDayNumber: 1,
          onToggleCompletion: () {
            toggled = true;
          },
        ),
      ),
    );

    expect(find.text('Mark Day 3 ahead of schedule'), findsOneWidget);

    // Tap ahead of schedule button
    await tester.tap(find.text('Mark Day 3 ahead of schedule'));
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('Mark ahead of schedule?'), findsOneWidget);
    expect(find.text('Keep Upcoming'), findsOneWidget);
    expect(find.text('Mark Completed'), findsOneWidget);

    // Tap confirm in dialog
    await tester.tap(find.text('Mark Completed'));
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });

  testWidgets('Missed past day portion displays "Catch up: Mark Day 1 completed"',
      (tester) async {
    bool toggled = false;

    await tester.pumpWidget(
      buildSheetWrapper(
        DayDetailSheet(
          portion: testPortionDay1,
          portionDate: DateTime.now().subtract(const Duration(days: 2)),
          currentDayNumber: 3,
          onToggleCompletion: () {
            toggled = true;
          },
        ),
      ),
    );

    expect(find.text('Catch up: Mark Day 1 completed'), findsOneWidget);
    expect(find.text('Missed Portion'), findsOneWidget);

    await tester.tap(find.text('Catch up: Mark Day 1 completed'));
    await tester.pumpAndSettle();

    expect(find.text('Catch up on Day 1?'), findsOneWidget);
    await tester.tap(find.text('Mark Completed'));
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });
}
