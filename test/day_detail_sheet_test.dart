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
      'Upcoming day portion has no "Mark as completed" button rendered',
      (tester) async {
    await tester.pumpWidget(
      buildSheetWrapper(
        DayDetailSheet(
          portion: testPortionDay3,
          portionDate: DateTime.now().add(const Duration(days: 2)),
          currentDayNumber: 1,
          onToggleCompletion: () {},
        ),
      ),
    );

    // Button should be completely removed, not rendered
    expect(find.text('Mark as completed'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets(
      'Missed past day portion has no "Mark as completed" button rendered',
      (tester) async {
    await tester.pumpWidget(
      buildSheetWrapper(
        DayDetailSheet(
          portion: testPortionDay1,
          portionDate: DateTime.now().subtract(const Duration(days: 2)),
          currentDayNumber: 3,
          onToggleCompletion: () {},
        ),
      ),
    );

    expect(find.text('Missed Portion'), findsOneWidget);
    // Button should be completely removed, not rendered
    expect(find.text('Mark as completed'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets(
      'Adjusted day portion renders without RenderFlex overflow on narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSheetWrapper(
        DayDetailSheet(
          portion: testPortionDay1.copyWith(isAdjusted: true),
          portionDate: DateTime.now(),
          currentDayNumber: 1,
          onToggleCompletion: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Schedule Status'), findsOneWidget);
    expect(find.text('Adjusted to fit remaining window'), findsOneWidget);
  });
}
