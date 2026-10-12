import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thirty_juz_in_7_days/core/widgets/app_confirmation_sheet.dart';
import 'package:thirty_juz_in_7_days/core/widgets/countdown_undo_toast.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/pages/home_page.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/portion_card.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  group('AppConfirmationSheet', () {
    testWidgets('Displays title, message and returns true on confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmationSheet.show(
                    context,
                    title: 'Confirm Completion',
                    message: 'Are you sure you want to mark today completed?',
                    confirmLabel: 'Yes, Complete',
                    cancelLabel: 'Dismiss',
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Completion'), findsOneWidget);
      expect(find.text('Are you sure you want to mark today completed?'), findsOneWidget);
      expect(find.text('Yes, Complete'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Yes, Complete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('Returns false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmationSheet.show(
                    context,
                    title: 'Confirm Completion',
                    message: 'Are you sure you want to mark today completed?',
                    confirmLabel: 'Yes, Complete',
                    cancelLabel: 'Dismiss',
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('PortionCard in-place button transition', () {
    final uncompletedPortion = DayPortion(
      dayNumber: 1,
      startSurah: 'Al-Baqarah',
      endSurah: 'An-Nisa',
      startSurahAr: 'البقرة',
      endSurahAr: 'النساء',
      surahCount: 3,
      isCompleted: false,
    );

    final completedPortion = uncompletedPortion.copyWith(isCompleted: true);

    testWidgets('Renders Mark as Completed when uncompleted', (tester) async {
      bool markCalled = false;

      await tester.pumpWidget(
        wrapWithLocalization(
          PortionCard(
            portion: uncompletedPortion,
            currentDayNumber: 1,
            onMarkCompleted: () {
              markCalled = true;
            },
            onUndoCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark as Completed'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);

      await tester.tap(find.text('Mark as Completed'));
      await tester.pumpAndSettle();

      expect(markCalled, isTrue);
    });

    testWidgets('Renders Completed Today button in place when completed without extra undo row', (tester) async {
      bool undoCalled = false;

      await tester.pumpWidget(
        wrapWithLocalization(
          PortionCard(
            portion: completedPortion,
            currentDayNumber: 1,
            onMarkCompleted: () {},
            onUndoCompleted: () {
              undoCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Completed button is rendered with single checkmark icon and clean text
      expect(find.text('Completed Today'), findsOneWidget);
      // Single checkmark icon
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.tap(find.text('Completed Today'));
      await tester.pumpAndSettle();

      expect(undoCalled, isTrue);
    });
  });

  group('CountdownUndoToast', () {
    testWidgets('Renders countdown toast and invokes onUndo on tap', (tester) async {
      bool undoCalled = false;

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CountdownUndoToast.show(
                      context,
                      message: 'Portion completed',
                      undoLabel: 'Undo',
                      onUndo: () {
                        undoCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Portion completed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('5s'), findsOneWidget);

      // Tap undo
      await tester.tap(find.byKey(const ValueKey('countdown_undo_button')));
      await tester.pump();

      expect(undoCalled, isTrue);
    });
  });

  group('BehindScheduleBanner Confirmations & Restored Bar', () {
    testWidgets('Tapping Continue Today prompts confirmation and collapsing into accessible bar', (tester) async {
      final start = DateTime.now().subtract(const Duration(days: 2)); // Day 3
      final challenge = Challenge(
        id: 'test_behind_schedule',
        startDate: start,
        endDate: start.add(const Duration(days: 6)),
        portions: [
          DayPortion(
            dayNumber: 1,
            startSurah: 'Al-Baqarah',
            endSurah: 'An-Nisa',
            startSurahAr: 'البقرة',
            endSurahAr: 'النساء',
            surahCount: 3,
            isCompleted: false, // missed
          ),
          DayPortion(
            dayNumber: 2,
            startSurah: 'Al-Ma\'idah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'المائدة',
            endSurahAr: 'التوبة',
            surahCount: 5,
            isCompleted: false, // missed
          ),
          DayPortion(
            dayNumber: 3,
            startSurah: 'Yunus',
            endSurah: 'Al-Isra',
            startSurahAr: 'يونس',
            endSurahAr: 'الإسراء',
            surahCount: 8,
            isCompleted: false,
          ),
        ],
        reminderHour: 18,
        reminderMinute: 0,
        createdAt: start,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ProviderScope(
            overrides: [
              challengeStateProvider.overrideWith(
                (ref) => _FakeChallengeNotifier(
                  ChallengeState(
                    isLoading: false,
                    challenge: challenge,
                    hasCompletedOnboarding: true,
                  ),
                ),
              ),
            ],
            child: HomePage(
              onNavigateToProgress: () {},
              onStartNewKhatmah: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner should be visible initially
      expect(find.text('Behind Schedule'), findsOneWidget);
      expect(find.text('Continue Today'), findsOneWidget);
      expect(find.text('Adjust Plan'), findsOneWidget);

      // Tap "Continue Today" on banner
      await tester.tap(find.text('Continue Today'));
      await tester.pumpAndSettle();

      // Confirmation sheet MUST appear!
      expect(find.text("Continue Today's Portion?"), findsOneWidget);
      expect(find.text("You have missed portions from earlier days. Do you want to proceed with today's portion without adjusting your schedule?"), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Continue Today').last);
      await tester.pumpAndSettle();

      // Collapsed bar appears so user never loses adjust plan banner
      expect(find.text('Adjust Plan'), findsOneWidget);
      expect(find.byIcon(Icons.unfold_more_rounded), findsOneWidget);

      // Tap unfold icon to restore the full banner
      await tester.ensureVisible(find.byIcon(Icons.unfold_more_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.unfold_more_rounded));
      await tester.pumpAndSettle();

      // Full banner is restored!
      expect(find.text('Continue Today'), findsOneWidget);
      expect(find.text("You have missed portions. You can continue today's portion or adjust your plan."), findsOneWidget);
    });

    testWidgets('Tapping Adjust Plan directly opens dialog without pre-confirmation, and confirms at Apply step', (tester) async {
      final start = DateTime.now().subtract(const Duration(days: 2));
      final challenge = Challenge(
        id: 'test_behind_schedule_adj',
        startDate: start,
        endDate: start.add(const Duration(days: 6)),
        portions: [
          DayPortion(
            dayNumber: 1,
            startSurah: 'Al-Baqarah',
            endSurah: 'An-Nisa',
            startSurahAr: 'البقرة',
            endSurahAr: 'النساء',
            surahCount: 3,
            isCompleted: false,
          ),
          DayPortion(
            dayNumber: 2,
            startSurah: 'Al-Ma\'idah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'المائدة',
            endSurahAr: 'التوبة',
            surahCount: 5,
            isCompleted: false,
          ),
          DayPortion(
            dayNumber: 3,
            startSurah: 'Yunus',
            endSurah: 'Al-Isra',
            startSurahAr: 'يونس',
            endSurahAr: 'الإسراء',
            surahCount: 8,
            isCompleted: false,
          ),
        ],
        reminderHour: 18,
        reminderMinute: 0,
        createdAt: start,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ProviderScope(
            overrides: [
              challengeStateProvider.overrideWith(
                (ref) => _FakeChallengeNotifier(
                  ChallengeState(
                    isLoading: false,
                    challenge: challenge,
                    hasCompletedOnboarding: true,
                  ),
                ),
              ),
            ],
            child: HomePage(
              onNavigateToProgress: () {},
              onStartNewKhatmah: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Adjust Plan" on the banner
      await tester.tap(find.text('Adjust Plan'));
      await tester.pumpAndSettle();

      // No redundant pre-confirmation popup: dialog opens directly!
      expect(find.text('Adjust Khatmah Plan?'), findsNothing);
      expect(find.text('Adjust Remaining Plan'), findsOneWidget);
      expect(find.text('Apply Plan'), findsOneWidget);

      // Tap "Apply Plan" in the dialog: confirmation sheet appears at the last step!
      await tester.tap(find.text('Apply Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Apply Adjusted Plan?'), findsOneWidget);
      expect(find.text('This will redistribute your remaining portions across your remaining days. This updates your daily schedule.'), findsOneWidget);
    });

    testWidgets('Multi-block adjusted portion (Baqarah - Tawbah) counts as 2 completed portions and resolves catch-up', (tester) async {
      final start = DateTime.now().subtract(const Duration(days: 1));
      final challenge = Challenge(
        id: 'test_adjusted_multi_block',
        startDate: start,
        endDate: start.add(const Duration(days: 6)),
        portions: [
          DayPortion(
            dayNumber: 1,
            startSurah: 'Al-Baqarah',
            endSurah: 'An-Nisa',
            startSurahAr: 'البقرة',
            endSurahAr: 'النساء',
            surahCount: 3,
            isCompleted: false,
          ),
          DayPortion(
            dayNumber: 2,
            startSurah: 'Al-Baqarah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'البقرة',
            endSurahAr: 'التوبة',
            surahCount: 8,
            isCompleted: true,
            isAdjusted: true,
          ),
        ],
        reminderHour: 18,
        reminderMinute: 0,
        createdAt: start,
      );

      // Covers both Block 0 (Al-Baqarah - An-Nisa) and Block 1 (Al-Ma'idah - At-Tawbah)
      expect(challenge.completedBlockIndices, containsAll([0, 1]));
      expect(challenge.completedPortionsCount, 2);
      expect(challenge.isBehindSchedule, isFalse);
      expect(challenge.missedPortionsCount, 0);
    });
  });
}

class _FakeChallengeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeChallengeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

