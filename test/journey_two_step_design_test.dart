import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/pages/progress_page.dart';
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

  testWidgets(
      'Journey tab initially renders Step 1 ("What do I do now?"), answers today reading with prominence',
      (tester) async {
    final now = DateTime.now();
    final challenge = Challenge(
      id: 'step_test_1',
      startDate: now.subtract(const Duration(days: 2)), // Today is Day 3
      endDate: now.add(const Duration(days: 4)),
      portions: createPortions(completedDays: 2), // Day 1 & 2 done, Day 3 is Today
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: now.subtract(const Duration(days: 2)),
    );

    await tester.pumpWidget(
      wrapWithLocalization(
        ProviderScope(
          overrides: [
            challengeStateProvider.overrideWith(
              (ref) => _FakeNotifier(
                ChallengeState(
                  isLoading: false,
                  challenge: challenge,
                  hasCompletedOnboarding: true,
                ),
              ),
            ),
          ],
          child: ProgressPage(onStartNewKhatmah: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 Header & Greeting
    expect(find.text('Your Journey'), findsOneWidget);
    expect(find.text('Small steps. A closer connection.'), findsOneWidget);
    expect(find.text('Assalamu Alaikum'), findsOneWidget);
    expect(find.text("Keep going! You're making progress."), findsOneWidget);

    // Current Cycle Hero Card
    expect(find.text('Current Cycle'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('2/7'), findsOneWidget); // 2 of 7 completed

    // Today's Journey Section Header
    expect(find.text("Today's Journey"), findsOneWidget);
    expect(find.text('Complete the surahs in order'), findsOneWidget);

    // Verify Surah ranges are visible
    expect(find.text('Al-Baqarah → An-Nisa'), findsOneWidget);
    expect(find.text("Al-Ma'idah → At-Tawbah"), findsOneWidget);
    expect(find.text('Yunus → An-Nahl'), findsOneWidget);

    // Day 3 is Today -> renders Today badge
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets(
      'Tapping Current Cycle card in Step 1 navigates to Step 2 ("Where am I in the plan?"), back button returns to Step 1',
      (tester) async {
    final now = DateTime.now();
    final challenge = Challenge(
      id: 'step_test_2',
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 4)),
      portions: createPortions(completedDays: 2),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: now.subtract(const Duration(days: 2)),
    );

    await tester.pumpWidget(
      wrapWithLocalization(
        ProviderScope(
          overrides: [
            challengeStateProvider.overrideWith(
              (ref) => _FakeNotifier(
                ChallengeState(
                  isLoading: false,
                  challenge: challenge,
                  hasCompletedOnboarding: true,
                ),
              ),
            ),
          ],
          child: ProgressPage(onStartNewKhatmah: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on Current Cycle card
    await tester.tap(find.text('Current Cycle'));
    await tester.pumpAndSettle();

    // Step 2 view is now active:
    // Header title is "Journey" with a back chevron
    expect(find.text('Journey'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);

    // Cycle card is visible (new minimal design — just cycle label + completion text)
    expect(find.text('Cycle 1'), findsOneWidget);
    // Completion summary shows "In Progress" (since cycle is active)
    expect(find.text('In Progress'), findsOneWidget);

    // Now tap the back button on the top-left of the AppBar
    await tester.tap(find.byKey(const Key('journey_step2_back_button')));
    await tester.pumpAndSettle();

    // Back to Step 1!
    expect(find.text('Your Journey'), findsOneWidget);
    expect(find.text('Assalamu Alaikum'), findsOneWidget);
    expect(find.text("Today's Journey"), findsOneWidget);
  });

  testWidgets(
      'Tapping "Full Plan →" on the Greeting card navigates to Step 2, and changing month updates displayed cycle or displays empty state',
      (tester) async {
    final now = DateTime.now();
    final challenge = Challenge(
      id: 'step_test_month_switch',
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 5)),
      portions: createPortions(completedDays: 1),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: now.subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      wrapWithLocalization(
        ProviderScope(
          overrides: [
            challengeStateProvider.overrideWith(
              (ref) => _FakeNotifier(
                ChallengeState(
                  isLoading: false,
                  challenge: challenge,
                  hasCompletedOnboarding: true,
                ),
              ),
            ),
          ],
          child: ProgressPage(onStartNewKhatmah: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assalamu Alaikum greeting card has "Full Plan" chip affordance
    expect(find.text('Full Plan'), findsOneWidget);
    await tester.tap(find.text('Full Plan'));
    await tester.pumpAndSettle();

    // Now in Step 2:
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Cycle 1'), findsOneWidget);

    // Tap previous month button (no Khatmahs exist in that past month)
    await tester.tap(find.byKey(const Key('journey_prev_month_button')));
    await tester.pumpAndSettle();

    // Should now show empty state card because previous month has no cycles
    expect(find.textContaining('No Khatmahs recorded in'), findsOneWidget);
    expect(find.byKey(const Key('journey_today_jump_button')), findsOneWidget);

    // Tap "Current Month" jump button to restore current month view
    await tester.tap(find.byKey(const Key('journey_today_jump_button')));
    await tester.pumpAndSettle();

    // Current month cycle is displayed again!
    expect(find.text('Cycle 1'), findsOneWidget);
    expect(find.textContaining('No Khatmahs recorded in'), findsNothing);
  });
}

class _FakeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
