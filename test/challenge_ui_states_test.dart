import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/pages/home_page.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/pages/progress_page.dart';

void main() {
  List<DayPortion> createDefaultPortions({bool allCompleted = false}) {
    return KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: allCompleted,
      );
    }).toList();
  }

  testWidgets(
      'HomePage displays Khatmah Concluded when challenge is expired and no fake today card',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 9)); // Day 10 (expired)
    final challenge = Challenge(
      id: 'test_exp_home',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(allCompleted: false),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    await tester.pumpWidget(
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
        child: MaterialApp(
          home: HomePage(
            onNavigateToProgress: () {},
            onStartNewKhatmah: () {},
          ),
        ),
      ),
    );

    // Expect Concluded card
    expect(find.text('7-Day Khatmah Concluded'), findsOneWidget);
    expect(find.text('Start a New 7-Day Khatmah'), findsOneWidget);

    // Must NOT show "Today's portion" card
    expect(find.text("TODAY'S PORTION • DAY 7"), findsNothing);
    expect(find.text('I\'ve read my portion today'), findsNothing);

    // Must NOT show behind schedule banner
    expect(find.text('A gentle note on your progress'), findsNothing);
    expect(find.text('Adjust my remaining plan'), findsNothing);
  });

  testWidgets(
      'ProgressPage displays 7-Day Khatmah Period Ended when expired with incomplete portions',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 9)); // Day 10 (expired)
    final challenge = Challenge(
      id: 'test_exp_prog',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(allCompleted: false),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    await tester.pumpWidget(
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
        child: MaterialApp(
          home: ProgressPage(
            onStartNewKhatmah: () {},
          ),
        ),
      ),
    );

    // Must NOT say "Challenge Completed" when 0 completed
    expect(find.text('Challenge Completed'), findsNothing);

    // MUST say "7-Day Khatmah Period Ended"
    expect(find.text('7-Day Khatmah Period Ended'), findsOneWidget);
    expect(find.textContaining('You completed 0 of 7 daily portions'), findsOneWidget);
    expect(find.text('Start a New 7-Day Khatmah'), findsOneWidget);
  });
}

class _FakeChallengeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeChallengeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
