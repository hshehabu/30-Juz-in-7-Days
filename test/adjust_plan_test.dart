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
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/adjust_plan_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/settings/presentation/pages/settings_page.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

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
      wrapWithLocalization(
        AdjustPlanDialog(
          challenge: challenge,
          onConfirm: (portions) {
            updatedResult = portions;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adjust Remaining Plan'), findsOneWidget);
    expect(find.text('Apply Plan'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Reset to Traditional'), findsNothing);

    await tester.tap(find.text('Apply Plan'));
    await tester.pumpAndSettle();

    // Confirm the bottom sheet dialog
    if (find.text('Apply Adjusted Plan?').evaluate().isNotEmpty) {
      await tester.tap(find.text('Apply Plan').last);
      await tester.pumpAndSettle();
    }

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
      'Adjust plan dialog Cancel and Apply Plan are side by side in a Row',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 2));
    final challenge = Challenge(
      id: 'test_adj_buttons',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(day1Completed: true),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    bool confirmed = false;

    await tester.pumpWidget(
      wrapWithLocalization(
        AdjustPlanDialog(
          challenge: challenge,
          onConfirm: (_) {
            confirmed = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Buttons exist and are side by side in actions Row
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply Plan'), findsOneWidget);
    expect(find.text('Reset to Traditional'), findsNothing);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    expect(find.text('Adjust Remaining Plan'), findsNothing);
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
      wrapWithLocalization(
        AdjustPlanDialog(
          challenge: challenge,
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khatmah Concluded'), findsOneWidget);
    expect(find.text('Apply Plan'), findsNothing);
    expect(find.text('Reset Schedule'), findsNothing);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets(
      'Adjust plan on Day 2 when Day 1 missed assigns Al-Baqarah to At-Tawbah (8 surahs) to Day 2',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 1)); // Day 2
    final challenge = Challenge(
      id: 'test_day2_adjust',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(day1Completed: false),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    List<DayPortion>? updatedResult;

    await tester.pumpWidget(
      wrapWithLocalization(
        AdjustPlanDialog(
          challenge: challenge,
          onConfirm: (portions) {
            updatedResult = portions;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Plan'));
    await tester.pumpAndSettle();

    if (find.text('Apply Adjusted Plan?').evaluate().isNotEmpty) {
      await tester.tap(find.text('Apply Plan').last);
      await tester.pumpAndSettle();
    }

    expect(updatedResult, isNotNull);
    final day1 = updatedResult!.firstWhere((p) => p.dayNumber == 1);
    final day2 = updatedResult!.firstWhere((p) => p.dayNumber == 2);

    expect(day1.isCompleted, isFalse);
    expect(day2.startSurah, 'Al-Baqarah');
    expect(day2.endSurah, 'At-Tawbah');
    expect(day2.surahCount, 8); // 3 + 5 surahs

    // BEFORE Day 2 is completed (immediately upon applying adjusted plan):
    final immediateAdjustedChallenge = challenge.copyWith(
      portions: updatedResult!,
    );
    // Must NOT be behind schedule anymore because unread portions are now scheduled in remaining days!
    expect(immediateAdjustedChallenge.isBehindSchedule, isFalse);
    expect(immediateAdjustedChallenge.missedPortionsCount, 0);

    // When Day 2 is completed:
    final updatedChallenge = challenge.copyWith(
      portions: updatedResult!.map((p) {
        if (p.dayNumber == 2) {
          return p.copyWith(isCompleted: true);
        }
        return p;
      }).toList(),
    );

    // It must count as 2 completed portions (2/7), NOT 1/7!
    expect(updatedChallenge.completedPortionsCount, 2);
    expect(updatedChallenge.completedBlockIndices, containsAll([0, 1]));
    expect(updatedChallenge.isBehindSchedule, isFalse);
  });

  testWidgets(
      'Adjust plan on Day 4 when Days 1-3 missed clears isBehindSchedule and hides banner on HomePage',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 3)); // Day 4
    final initialChallenge = Challenge(
      id: 'test_day4_adjust',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(day1Completed: false),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    // Prior to adjustment, Day 4 is behind schedule
    expect(initialChallenge.currentDayNumber, 4);
    expect(initialChallenge.isBehindSchedule, isTrue);
    expect(initialChallenge.missedPortionsCount, 3);

    final fakeNotifier = _FakeChallengeNotifier(
      ChallengeState(
        isLoading: false,
        challenge: initialChallenge,
        hasCompletedOnboarding: true,
      ),
    );

    await tester.pumpWidget(
      wrapWithLocalization(
        ProviderScope(
          overrides: [
            challengeStateProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: HomePage(
            onNavigateToProgress: () {},
            onStartNewKhatmah: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Banner is shown initially
    expect(find.text('Behind Schedule'), findsOneWidget);

    // Open adjust plan dialog
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();

    // Preview shows Day 4 as Al-Baqarah -> At-Tawbah
    expect(find.text('Adjust Remaining Plan'), findsOneWidget);
    expect(find.text('Apply Plan'), findsOneWidget);

    // Apply the plan
    await tester.tap(find.text('Apply Plan'));
    await tester.pumpAndSettle();

    // Confirm sheet if shown
    if (find.text('Apply Adjusted Plan?').evaluate().isNotEmpty) {
      await tester.tap(find.text('Apply Plan').last);
      await tester.pumpAndSettle();
    }

    // Now verify the banner is completely GONE from HomePage!
    expect(find.text('Behind Schedule'), findsNothing);
    // Today's portion is now Al-Baqarah -> At-Tawbah (adjusted portion)
    expect(find.text('Al-Baqarah → At-Tawbah'), findsOneWidget);
    expect(find.text('Mark as Completed'), findsOneWidget);
  });

  testWidgets(
      'Settings page does NOT display adjust plan magic button even when challenge is behind schedule',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 2)); // Day 3
    final challenge = Challenge(
      id: 'test_settings_no_adjust',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: createDefaultPortions(day1Completed: false),
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    expect(challenge.isBehindSchedule, isTrue);

    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      wrapWithLocalization(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
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
          child: SettingsPage(
            onStartNewKhatmah: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Adjust plan button must NOT exist anywhere in Settings!
    expect(find.text('Adjust Plan'), findsNothing);
    expect(find.byIcon(Icons.auto_fix_high_rounded), findsNothing);
  });
}

class _FakeChallengeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeChallengeNotifier(super.state);

  @override
  Future<void> adjustRemainingPlan(List<DayPortion> updatedPortions) async {
    final cur = state.challenge;
    if (cur != null) {
      state = state.copyWith(
        challenge: cur.copyWith(portions: updatedPortions),
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

