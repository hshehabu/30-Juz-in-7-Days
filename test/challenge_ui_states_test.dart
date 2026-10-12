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
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

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
      'HomePage displays Khatmah Period Ended when challenge is expired and no fake today card',
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

    // Expect Concluded card
    expect(find.text('Khatmah Period Ended'), findsOneWidget);
    expect(find.text('Start New Khatmah'), findsOneWidget);

    // Must NOT show "Today's portion" card
    expect(find.text("TODAY'S PORTION • DAY 7"), findsNothing);
    expect(find.text('I\'ve read my portion today'), findsNothing);

    // Must NOT show behind schedule banner
    expect(find.text('Behind Schedule'), findsNothing);
    expect(find.text('Adjust Plan'), findsNothing);
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
          child: ProgressPage(
            onStartNewKhatmah: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Must NOT say "Challenge Completed" when 0 completed
    expect(find.text('Challenge Completed'), findsNothing);

    // MUST say "7-Day Khatmah Period Ended"
    expect(find.text('7-Day Khatmah Period Ended'), findsOneWidget);
    expect(find.textContaining('Completed: 0 of 7 portions'), findsOneWidget);
    expect(find.text('Start New Khatmah'), findsOneWidget);
  });
}

class _FakeChallengeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeChallengeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
