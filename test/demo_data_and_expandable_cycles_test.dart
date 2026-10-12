import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/challenge_model.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/day_portion_model.dart';
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

  group('Expandable Cycle Cards Widget Tests in Step 2', () {
    List<DayPortion> createPortions({int completedDays = 7}) {
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

    List<DayPortionModel> createPortionModels({int completedDays = 7}) {
      return KhatmahConstants.traditionalSchedule.map((data) {
        return DayPortionModel(
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
        'Step 2 places month stepper at top, renders cycle cards, and expands downward on tap',
        (tester) async {
      final activeChallenge = Challenge(
        id: 'active_october_cycle',
        startDate: DateTime(2026, 10, 12),
        endDate: DateTime(2026, 10, 18),
        portions: createPortions(completedDays: 3),
        reminderHour: 19,
        reminderMinute: 0,
        createdAt: DateTime(2026, 10, 12),
      );

      final pastChallenges = [
        // Completed earlier in October
        ChallengeModel(
          id: 'past_oct_1',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 7),
          portions: createPortionModels(completedDays: 7),
          reminderHour: 19,
          reminderMinute: 0,
          createdAt: DateTime(2026, 10, 1),
        ),
        // September cycles
        ChallengeModel(
          id: 'past_sep_1',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 7),
          portions: createPortionModels(completedDays: 7),
          reminderHour: 19,
          reminderMinute: 0,
          createdAt: DateTime(2026, 9, 1),
        ),
        ChallengeModel(
          id: 'past_sep_2',
          startDate: DateTime(2026, 9, 10),
          endDate: DateTime(2026, 9, 16),
          portions: createPortionModels(completedDays: 7),
          reminderHour: 19,
          reminderMinute: 0,
          createdAt: DateTime(2026, 9, 10),
        ),
      ];

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      await storage.saveHistoryJsonList(
        pastChallenges.map((c) => jsonEncode(c.toJson())).toList(),
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storage),
              challengeStateProvider.overrideWith(
                (ref) => _FakeNotifier(
                  ChallengeState(
                    isLoading: false,
                    challenge: activeChallenge,
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

      // Navigate to Step 2
      await tester.tap(find.text('Current Cycle'));
      await tester.pumpAndSettle();

      // Verify Month Stepper is rendered
      expect(find.byKey(const Key('journey_prev_month_button')), findsOneWidget);
      expect(find.byKey(const Key('journey_next_month_button')), findsOneWidget);

      // Verify Cycle cards are visible in current month (October has past_oct_1 and active)
      expect(find.text('Cycle 1'), findsOneWidget);
      expect(find.text('Cycle 2'), findsOneWidget);

      // Tapping Cycle 2 card header toggles expansion smoothly
      await tester.ensureVisible(find.text('Cycle 2'));
      await tester.tap(find.text('Cycle 2'));
      await tester.pumpAndSettle();

      // Step backwards to September (previous month)
      await tester.ensureVisible(find.byKey(const Key('journey_prev_month_button')));
      await tester.tap(find.byKey(const Key('journey_prev_month_button')));
      await tester.pumpAndSettle();

      // September past cycles should appear below the top month stepper
      expect(find.text('Cycle 1'), findsOneWidget);
      expect(find.text('Cycle 2'), findsOneWidget);

      // Step backwards to June (empty month with no past cycles)
      await tester.tap(find.byKey(const Key('journey_prev_month_button'))); // August
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journey_prev_month_button'))); // July
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journey_prev_month_button'))); // June
      await tester.pumpAndSettle();

      // June has no data -> shows clean empty state
      expect(find.textContaining('No Khatmahs recorded in'), findsOneWidget);
      expect(find.byKey(const Key('journey_today_jump_button')), findsOneWidget);

      // Tapping Current Month restores current month view
      await tester.tap(find.byKey(const Key('journey_today_jump_button')));
      await tester.pumpAndSettle();

      expect(find.text('Cycle 1'), findsOneWidget);
    });
  });
}

class _FakeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
