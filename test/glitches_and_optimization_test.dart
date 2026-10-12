import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/core/utils/date_utils.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/navigation/main_navigation_shell.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  List<DayPortion> createPortions() {
    return KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: data.dayNumber == 1,
      );
    }).toList();
  }

  Challenge createTestChallenge() {
    final now = DateTime.now();
    return Challenge(
      id: 'glitch_test_challenge',
      startDate: now,
      endDate: now.add(const Duration(days: 6)),
      portions: createPortions(),
      reminderHour: 19,
      reminderMinute: 0,
      createdAt: now,
    );
  }

  group('Glitch 1 & 2: Journey Navigation & Back Button Flow', () {
    testWidgets(
      'Switching to Home/Settings tab and returning to Journey tab resets Step 2 back to Step 1',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        final challenge = createTestChallenge();

        await tester.pumpWidget(
          wrapWithLocalization(
            ProviderScope(
              overrides: [
                storageServiceProvider.overrideWithValue(storage),
                challengeStateProvider.overrideWith(
                  (ref) => _TestNotifier(
                    ChallengeState(
                      isLoading: false,
                      challenge: challenge,
                      hasCompletedOnboarding: true,
                    ),
                  ),
                ),
              ],
              child: const MainNavigationShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initially on Home tab (index 0). Tap Journey tab (index 1).
        await tester.tap(find.byIcon(Icons.timeline_rounded));
        await tester.pumpAndSettle();

        // We are on Step 1: "Your Journey" header & "Current Cycle"
        expect(find.text('Your Journey'), findsOneWidget);
        expect(find.text('Current Cycle'), findsOneWidget);

        // 2. Open Step 2 ("Where am I in the plan?") by tapping Current Cycle
        await tester.tap(find.text('Current Cycle'));
        await tester.pumpAndSettle();

        // Verify Step 2 is visible
        expect(find.text('Cycle 1'), findsOneWidget);
        expect(find.byKey(const Key('journey_step2_back_button')), findsOneWidget);

        // 3. Switch away to Settings tab (index 2)
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsWidgets);

        // 4. Switch back to Journey tab (index 1)
        await tester.tap(find.byIcon(Icons.timeline_rounded));
        await tester.pumpAndSettle();

        // 5. Must now show Step 1 ("Your Journey"), NOT Step 2!
        expect(find.text('Your Journey'), findsOneWidget);
        expect(find.text('Current Cycle'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping "View Journey" from Home page opens Step 2 directly; back button returns to Home page',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        final challenge = createTestChallenge();

        await tester.pumpWidget(
          wrapWithLocalization(
            ProviderScope(
              overrides: [
                storageServiceProvider.overrideWithValue(storage),
                challengeStateProvider.overrideWith(
                  (ref) => _TestNotifier(
                    ChallengeState(
                      isLoading: false,
                      challenge: challenge,
                      hasCompletedOnboarding: true,
                    ),
                  ),
                ),
              ],
              child: const MainNavigationShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // We start on Home page. Find "View Journey" button and tap it.
        expect(find.text('View Journey'), findsOneWidget);
        await tester.tap(find.text('View Journey'));
        await tester.pumpAndSettle();

        // Step 2 is directly opened!
        expect(find.text('Cycle 1'), findsOneWidget);
        expect(find.byKey(const Key('journey_step2_back_button')), findsOneWidget);

        // Tap the back button
        await tester.tap(find.byKey(const Key('journey_step2_back_button')));
        await tester.pumpAndSettle();

        // Returns directly to Home page (where "View Journey" and "TODAY'S PORTION" exist)!
        expect(find.text('View Journey'), findsOneWidget);
        expect(find.textContaining("TODAY'S PORTION"), findsOneWidget);
      },
    );
  });

  group('Glitch 3: Arabic Dates & Translations', () {
    test('AppDateUtils formats Arabic dates with proper month names and years', () {
      final date = DateTime(2026, 10, 12);
      final formattedWithYear = AppDateUtils.formatDateWithYear(date, 'ar');
      // Must contain October in Arabic ('أكتوبر') and year 2026 or ٢٠٢٦
      expect(formattedWithYear.contains('أكتوبر'), isTrue);
      expect(formattedWithYear.contains('2026') || formattedWithYear.contains('٢٠٢٦'), isTrue);

      final formattedShort = AppDateUtils.formatShortDate(date, 'ar');
      expect(formattedShort.contains('أكتوبر'), isTrue);

      final formattedMonth = AppDateUtils.formatMonthYear(date, 'ar');
      expect(formattedMonth.contains('أكتوبر'), isTrue);
    });

    test('SchedulePreviewStrip portions completed text is localized in Arabic', () {
      final rawArJson = jsonDecode(File('assets/translations/ar.json').readAsStringSync()) as Map<String, dynamic>;
      final homeSection = rawArJson['home'] as Map<String, dynamic>;
      expect(homeSection['portions_completed_count'], 'تم إكمال {} من أصل {} أجزاء');
      expect(homeSection['view_journey'], 'عرض المسيرة');

      final rawEnJson = jsonDecode(File('assets/translations/en.json').readAsStringSync()) as Map<String, dynamic>;
      final enHomeSection = rawEnJson['home'] as Map<String, dynamic>;
      expect(enHomeSection['portions_completed_count'], '{} of {} portions completed');
      expect(enHomeSection['view_journey'], 'View Journey');
    });
  });

  group('Glitch 4: Robust Storage & Corruption Recovery', () {
    test('StorageService saves valid challenge, supports fast in-memory caching, and recovers from backup if primary corrupted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final validJson1 = jsonEncode({
        'id': 'khatmah_1',
        'startDate': '2026-10-12T00:00:00.000',
        'endDate': '2026-10-18T00:00:00.000',
        'portions': [],
      });

      final validJson2 = jsonEncode({
        'id': 'khatmah_2',
        'startDate': '2026-10-19T00:00:00.000',
        'endDate': '2026-10-25T00:00:00.000',
        'portions': [],
      });

      // 1. Save valid challenge 1
      final saved1 = await storage.saveActiveChallengeJson(validJson1);
      expect(saved1, isTrue);
      expect(storage.getActiveChallengeJson(), validJson1);

      // 2. Save valid challenge 2 -> challenge 1 becomes backup
      final saved2 = await storage.saveActiveChallengeJson(validJson2);
      expect(saved2, isTrue);
      expect(storage.getActiveChallengeJson(), validJson2);

      // 3. Attempt to save malformed / corrupted JSON -> must be rejected
      final savedCorrupt = await storage.saveActiveChallengeJson('NOT_VALID_JSON{:::');
      expect(savedCorrupt, isFalse);
      // Data remains intact as challenge 2!
      expect(storage.getActiveChallengeJson(), validJson2);

      // 4. Simulate catastrophic primary slot corruption on disk
      await prefs.setString('active_khatmah_challenge', 'corrupted_garbage_text');
      // Create new StorageService instance without memory cache
      final freshStorage = StorageService(prefs);

      // Must recover from backup slot (validJson1)!
      final recovered = freshStorage.getActiveChallengeJson();
      expect(recovered, validJson1);
      // Verify primary slot was self-healed on disk
      expect(prefs.getString('active_khatmah_challenge'), validJson1);
    });

    test('StorageService history filters corrupted entries and maintains backup', () async {
      SharedPreferences.setMockInitialValues({
        'completed_khatmah_history': [
          jsonEncode({'id': 'h1', 'startDate': '2026-09-01T00:00:00.000', 'portions': []}),
          'corrupted_entry_that_is_not_json',
          jsonEncode({'id': 'h2', 'startDate': '2026-09-08T00:00:00.000', 'portions': []}),
        ],
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final history = storage.getHistoryJsonList();
      // Corrupted entry is safely filtered out, leaving 2 valid entries
      expect(history.length, 2);
      expect(history[0].contains('h1'), isTrue);
      expect(history[1].contains('h2'), isTrue);
    });
  });
}

class _TestNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _TestNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
