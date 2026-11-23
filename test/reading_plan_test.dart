import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/notification_service.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/datasources/challenge_local_data_source.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/repositories/challenge_repository_impl.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/pages/home_page.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/reading_plan.dart';
import 'test_helper.dart';

Challenge _today({List<int> readParts = const []}) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return Challenge(
    id: 'plan',
    startDate: start,
    endDate: start.add(const Duration(days: 6)),
    portions: KhatmahConstants.traditionalSchedule
        .map((d) => DayPortion(
              dayNumber: d.dayNumber,
              startSurah: d.startSurah,
              endSurah: d.endSurah,
              startSurahAr: d.startSurahAr,
              endSurahAr: d.endSurahAr,
              surahCount: d.surahCount,
              readParts: d.dayNumber == 1 ? readParts : const [],
            ))
        .toList(),
    reminderHour: 19,
    reminderMinute: 0,
    createdAt: start,
  );
}

/// Records calls instead of touching storage.
class _RecordingNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _RecordingNotifier(super.state);

  final completedDays = <int>[];

  @override
  Future<void> setReadParts(int dayNumber, List<int> readParts) async {
    final c = state.challenge!;
    state = state.copyWith(
      challenge: c.copyWith(
        portions: c.portions
            .map((p) => p.dayNumber == dayNumber ? p.copyWith(readParts: readParts) : p)
            .toList(),
      ),
    );
  }

  @override
  Future<void> markDayCompleted(int dayNumber) async => completedDays.add(dayNumber);

  @override
  Future<void> undoDayCompletion(int dayNumber) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_RecordingNotifier> _pumpHome(WidgetTester tester, Challenge challenge) async {
  final notifier = _RecordingNotifier(ChallengeState(
    isInitialized: true,
    challenge: challenge,
    hasCompletedOnboarding: true,
  ));
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapWithLocalization(
    ProviderScope(
      overrides: [challengeStateProvider.overrideWith((ref) => notifier)],
      child: HomePage(onNavigateToProgress: () {}, onStartNewKhatmah: () {}),
    ),
  ));
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  customizableSplitTests();

  testWidgets('Read-only plan shows five parts with page ranges', (tester) async {
    await tester.pumpWidget(wrapWithLocalization(
      SingleChildScrollView(child: ReadingPlan(portion: _today().portions.first)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('READING PLAN'), findsOneWidget);
    expect(find.text('After Fajr'), findsOneWidget);
    expect(find.text('After Isha'), findsOneWidget);
    expect(find.text('p. 2–22'), findsOneWidget);
    expect(find.textContaining('of 5 done'), findsNothing); // read-only
  });

  testWidgets('Today card shows the plan inline and ticking saves progress',
      (tester) async {
    final notifier = await _pumpHome(tester, _today());
    expect(find.text('0 of 5 done'), findsOneWidget);
    expect(find.text('Track reading'), findsNothing); // no second sheet

    await tester.tap(find.byKey(const ValueKey('reading_part_0')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 5 done'), findsOneWidget);
    expect(notifier.completedDays, isEmpty);
  });

  testWidgets('Ticking the last part completes the day', (tester) async {
    final notifier = await _pumpHome(tester, _today(readParts: [0, 1, 2, 3]));
    expect(find.text('4 of 5 done'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading_part_4')));
    await tester.pumpAndSettle();
    expect(notifier.completedDays, [1]);
    // Let the undo toast's countdown finish.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}

// ── Customizable split ───────────────────────────────────────────────────────

class _PlanNotifier extends _RecordingNotifier {
  _PlanNotifier(super.state);
  final chosenSplits = <int>[];

  @override
  Future<void> setReadingPlanParts(int parts) async => chosenSplits.add(parts);

  final dayChoices = <(int, int?)>[];

  @override
  Future<void> setDayReadingPlan(int dayNumber, int? parts) async =>
      dayChoices.add((dayNumber, parts));
}

Future<StorageService> _storage({int? planParts}) async {
  SharedPreferences.setMockInitialValues(
      planParts == null ? {} : {'reading_plan_parts': planParts});
  return StorageService(await SharedPreferences.getInstance());
}

Future<_PlanNotifier> _pumpHomeWith(
  WidgetTester tester,
  Challenge challenge,
  StorageService storage,
) async {
  final notifier = _PlanNotifier(ChallengeState(
    isInitialized: true,
    challenge: challenge,
    hasCompletedOnboarding: true,
    readingPlanParts: storage.readingPlanParts,
  ));
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapWithLocalization(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        challengeStateProvider.overrideWith((ref) => notifier),
      ],
      child: HomePage(onNavigateToProgress: () {}, onStartNewKhatmah: () {}),
    ),
  ));
  await tester.pumpAndSettle();
  return notifier;
}

void customizableSplitTests() {
  group('Customizable split', () {
    test('re-splitting keeps parts whose pages were fully read', () {
      final day1 = _today().portions.first; // 5 parts: 2-22, 23-43, ...
      final threeWay = day1.copyWith(readParts: [0, 1]).withPartsCount(3);
      expect(threeWay.parts, hasLength(3));
      expect(threeWay.readParts, [0]); // pages 2-36 were covered by 2-43

      final back = threeWay.withPartsCount(5);
      expect(back.readParts, [0]); // 2-22 covered, 23-43 only partly
    });

    test('repository applies the chosen split to new and active khatmahs', () async {
      final storage = await _storage();
      final repo = ChallengeRepositoryImpl(
        localDataSource: ChallengeLocalDataSourceImpl(storage),
        notificationService: _SilentNotifications(),
        storageService: storage,
      );
      await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 19, minute: 0));
      await repo.updateReadParts(1, [0, 1]);

      final updated = await repo.setReadingPlanParts(2);
      expect(storage.readingPlanParts, 2);
      expect(updated!.portions.first.partsCount, 2);
      expect(updated.portions.first.readParts, isEmpty); // half not finished

      final off = await repo.setReadingPlanParts(0);
      expect(storage.readingPlanParts, 0);
      expect(off!.portions.first.partsCount, 2); // data kept while off

      // A completed day keeps the split it was read with.
      await repo.setReadingPlanParts(3);
      await repo.updateReadParts(2, [0, 1, 2]);
      await repo.markDayCompleted(2);
      final switched = await repo.setReadingPlanParts(5);
      final day2 = switched!.portions[1];
      expect(day2.partsCount, 3);
      expect(day2.readParts, [0, 1, 2]);
      expect(switched.portions[2].partsCount, 5); // unfinished day follows

      // Undoing keeps that day's own 3-sitting plan and ticks.
      final undone = await repo.undoDayCompletion(2);
      expect(undone.portions[1].partsCount, 3);
      expect(undone.portions[1].readParts, [0, 1, 2]);

      await repo.endChallengeAndArchive();
      await storage.setReadingPlanParts(3);
      final fresh = await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 19, minute: 0));
      expect(fresh.portions.first.partsCount, 3);
    });

    testWidgets('3-sitting plan uses numbered sittings', (tester) async {
      final portion = _today().portions.first.copyWith(partsCount: 3);
      await tester.pumpWidget(wrapWithLocalization(
        SingleChildScrollView(child: ReadingPlan(portion: portion)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Sitting 1'), findsOneWidget);
      expect(find.text('Sitting 3'), findsOneWidget);
      expect(find.text('After Fajr'), findsNothing);
    });

    testWidgets('plan off hides the plan but keeps Mark as Completed', (tester) async {
      await _pumpHomeWith(tester, _today(), await _storage(planParts: 0));
      expect(find.text('READING PLAN'), findsNothing);
      expect(find.text('Mark as Completed'), findsOneWidget);
    });

    testWidgets('gear on a day opens a per-day picker that changes only that day',
        (tester) async {
      final notifier = await _pumpHomeWith(tester, _today(), await _storage());
      await tester.tap(find.byKey(const ValueKey('reading_plan_customize')));
      await tester.pumpAndSettle();
      expect(find.text('Day 1 reading plan'), findsOneWidget);
      expect(find.text('Use default'), findsOneWidget);
      expect(find.text('Off'), findsNothing); // turning off is a global choice

      await tester.tap(find.byKey(const ValueKey('reading_plan_day_option_3')));
      await tester.pumpAndSettle();
      expect(notifier.dayChoices, [(1, 3)]);
      expect(notifier.chosenSplits, isEmpty);
    });

    testWidgets('a customized day shows a "This day only" badge', (tester) async {
      final portion =
          _today().portions.first.copyWith(partsCount: 2, partsCustom: true);
      await tester.pumpWidget(wrapWithLocalization(
        SingleChildScrollView(child: ReadingPlan(portion: portion)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('This day only'), findsOneWidget);
    });

    test('per-day split survives default changes until reset', () async {
      final storage = await _storage();
      final repo = ChallengeRepositoryImpl(
        localDataSource: ChallengeLocalDataSourceImpl(storage),
        notificationService: _SilentNotifications(),
        storageService: storage,
      );
      await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 19, minute: 0));

      var c = await repo.setDayPartsCount(2, 2);
      expect(c.portions[1].partsCount, 2);
      expect(c.portions[1].partsCustom, isTrue);
      expect(c.portions[0].partsCount, 5); // other days untouched

      c = (await repo.setReadingPlanParts(3))!;
      expect(c.portions[0].partsCount, 3); // follows the new default
      expect(c.portions[1].partsCount, 2); // customized day keeps its split

      c = await repo.setDayPartsCount(2, null);
      expect(c.portions[1].partsCount, 3); // back to the default
      expect(c.portions[1].partsCustom, isFalse);
    });
  });
}

class _SilentNotifications extends NotificationService {
  @override
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
    TimeOfDay? followUpTime,
    String? languageCode,
  }) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelDayReminder(int dayNumber) async {}
}
