import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/localization/app_language.dart';
import 'package:thirty_juz_in_7_days/core/localization/locale_keys.g.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/navigation/main_navigation_shell.dart';
import 'test_helper.dart';

class _FakeChallengeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeChallengeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Test localization helper renders English translated text', (tester) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (context) => Text(LocaleKeys.common.cancel.tr()),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Test localization helper renders Arabic translated text in RTL', (tester) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (context) => Text(LocaleKeys.common.cancel.tr()),
        ),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets(
      'Bottom navigation bar labels change immediately upon language switch without tapping tabs',
      (tester) async {
    final start = DateTime.now();
    final portions = KhatmahConstants.traditionalSchedule.map((data) {
      return DayPortion(
        dayNumber: data.dayNumber,
        startSurah: data.startSurah,
        endSurah: data.endSurah,
        startSurahAr: data.startSurahAr,
        endSurahAr: data.endSurahAr,
        surahCount: data.surahCount,
        isCompleted: false,
      );
    }).toList();

    final challenge = Challenge(
      id: 'test_locale_switch',
      startDate: start,
      endDate: start.add(const Duration(days: 6)),
      portions: portions,
      reminderHour: 18,
      reminderMinute: 0,
      createdAt: start,
    );

    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    BuildContext? testContext;

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
          child: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const MainNavigationShell();
            },
          ),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial English navigation items are displayed
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('اليوم'), findsNothing);

    // Now switch language to Arabic using AppLanguage.switchLanguage
    await AppLanguage.switchLanguage(testContext!, const Locale('ar'));
    await tester.pumpAndSettle();

    // Verify navigation bar labels IMMEDIATELY updated without tapping on any tab!
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.text('مسار الختمة'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Journey'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets(
      'Hadith texts and source references display in authentic Arabic when switched to Arabic',
      (tester) async {
    BuildContext? testContext;

    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (context) {
            testContext = context;
            final isAr = AppLanguage.isArabic(context);
            return Column(
              children: [
                Text(KhatmahConstants.getHadithText(isAr)),
                Text(KhatmahConstants.getHadithSource(isAr)),
              ],
            );
          },
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(KhatmahConstants.hadithText), findsOneWidget);
    expect(find.text(KhatmahConstants.hadithSource), findsOneWidget);

    // Switch to Arabic
    await AppLanguage.switchLanguage(testContext!, const Locale('ar'));
    await tester.pumpAndSettle();

    expect(find.text(KhatmahConstants.hadithTextAr), findsOneWidget);
    expect(find.text(KhatmahConstants.hadithSourceAr), findsOneWidget);
    expect(find.text(KhatmahConstants.hadithText), findsNothing);
  });
}
