import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/monthly_cycle_heatmap.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  List<DayPortion> createPortions({int completedDays = 2}) {
    return KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: data.dayNumber <= completedDays,
      );
    }).toList();
  }

  testWidgets('MonthlyCycleHeatmap renders current month cycles, stepper, and legend',
      (tester) async {
    final now = DateTime.now();
    final cycleStart = DateTime(now.year, now.month, 5);
    final challenge = Challenge(
      id: 'cycle_test_1',
      startDate: cycleStart,
      endDate: cycleStart.add(const Duration(days: 6)),
      portions: createPortions(completedDays: 2),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: cycleStart,
    );

    DayPortion? tappedPortion;

    await tester.pumpWidget(
      wrapWithLocalization(
        MonthlyCycleHeatmap(
          challenges: [challenge],
          onTapPortion: (portion, date, c) {
            tappedPortion = portion;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Stepper
    expect(find.text('MONTHLY KHATMAH STREAM'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    // Verify Stats bar
    expect(find.text('Cycles'), findsOneWidget);
    expect(find.text('Portions'), findsOneWidget);
    expect(find.text('Consistency'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // 1 cycle

    // Verify Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // Verify Cycle Card
    expect(find.text('Cycle 1'), findsOneWidget);
    expect(find.text('D1'), findsOneWidget);
    expect(find.text('D7'), findsOneWidget);

    // Verify Legend and Filter (both contain "Completed")
    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);

    // Tap day 1 tile
    await tester.tap(find.byIcon(Icons.check_rounded).first);
    await tester.pumpAndSettle();
    expect(tappedPortion, isNotNull);
    expect(tappedPortion!.dayNumber, 1);
  });

  testWidgets('MonthlyCycleHeatmap time navigation steps month and shows jump button',
      (tester) async {
    final now = DateTime.now();
    final challenge = Challenge(
      id: 'cycle_test_nav',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, 7),
      portions: createPortions(completedDays: 7),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: now,
    );

    await tester.pumpWidget(
      wrapWithLocalization(
        MonthlyCycleHeatmap(
          challenges: [challenge],
          onTapPortion: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Currently on current month -> "Current Month" button not shown
    expect(find.text('Current Month'), findsNothing);

    // Step to previous month
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    // Now viewing previous month -> "Current Month" button is shown (in header and/or empty state)
    expect(find.text('Current Month'), findsWidgets);

    // Empty state should be visible for previous month (no challenge recorded there)
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

    // Tap "Current Month" jump button
    await tester.tap(find.text('Current Month').first);
    await tester.pumpAndSettle();

    // Returned to current month
    expect(find.text('Current Month'), findsNothing);
    expect(find.text('Cycle 1'), findsOneWidget);
  });

  testWidgets('MonthlyCycleHeatmap filter pills filter completed vs active cycles',
      (tester) async {
    final now = DateTime.now();
    final completedCycle = Challenge(
      id: 'cycle_completed',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, 7),
      portions: createPortions(completedDays: 7),
      isCompleted: true,
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: now,
    );

    final activeCycle = Challenge(
      id: 'cycle_active',
      startDate: DateTime(now.year, now.month, 8),
      endDate: DateTime(now.year, now.month, 14),
      portions: createPortions(completedDays: 1),
      isCompleted: false,
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: now,
    );

    await tester.pumpWidget(
      wrapWithLocalization(
        MonthlyCycleHeatmap(
          challenges: [completedCycle, activeCycle],
          onTapPortion: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In 'All' filter: both cycles shown
    expect(find.text('Cycle 1'), findsOneWidget);
    expect(find.text('Cycle 2'), findsOneWidget);

    // Tap 'Completed' filter pill (the first 'Completed' text)
    await tester.tap(find.text('Completed').first);
    await tester.pumpAndSettle();

    expect(find.text('Cycle 1'), findsOneWidget);
    expect(find.text('Cycle 2'), findsNothing);

    // Tap 'Active' filter pill
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    expect(find.text('Cycle 1'), findsNothing);
    expect(find.text('Cycle 2'), findsOneWidget);
  });
}
