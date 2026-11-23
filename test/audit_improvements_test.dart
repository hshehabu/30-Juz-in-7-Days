import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/constants/quran_data.dart';
import 'package:thirty_juz_in_7_days/core/localization/notification_copy.dart';
import 'package:thirty_juz_in_7_days/core/services/notification_service.dart';
import 'package:thirty_juz_in_7_days/core/services/reminder_planner.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/datasources/challenge_local_data_source.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/repositories/challenge_repository_impl.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/pages/home_page.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/day_detail_sheet.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/lifetime_stats_card.dart';
import 'test_helper.dart';

List<DayPortion> _portions({int completedDays = 0, DateTime? completedAt}) {
  return KhatmahConstants.traditionalSchedule.map((d) {
    final done = d.dayNumber <= completedDays;
    return DayPortion(
      dayNumber: d.dayNumber,
      startSurah: d.startSurah,
      endSurah: d.endSurah,
      startSurahAr: d.startSurahAr,
      endSurahAr: d.endSurahAr,
      surahCount: d.surahCount,
      isCompleted: done,
      completedAt: done ? completedAt : null,
    );
  }).toList();
}

Challenge _challenge(DateTime start, {int completedDays = 0, List<DayPortion>? portions}) {
  final s = DateTime(start.year, start.month, start.day);
  return Challenge(
    id: 'c_${s.millisecondsSinceEpoch}',
    startDate: s,
    endDate: s.add(const Duration(days: 6)),
    portions: portions ?? _portions(completedDays: completedDays),
    reminderHour: 19,
    reminderMinute: 0,
    createdAt: s,
  );
}

class _RecordingNotificationService extends NotificationService {
  int scheduleCalls = 0;
  final cancelledDays = <int>[];
  TimeOfDay? lastFollowUp;
  String? lastLanguage;

  @override
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
    TimeOfDay? followUpTime,
    String? languageCode,
  }) async {
    scheduleCalls++;
    lastFollowUp = followUpTime;
    lastLanguage = languageCode;
  }

  @override
  Future<void> cancelDayReminder(int dayNumber) async => cancelledDays.add(dayNumber);

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> showCompletionNotification() async {}
}

Future<(ChallengeRepositoryImpl, StorageService, _RecordingNotificationService)>
    _repo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final notif = _RecordingNotificationService();
  final repo = ChallengeRepositoryImpl(
    localDataSource: ChallengeLocalDataSourceImpl(storage),
    notificationService: notif,
    storageService: storage,
  );
  return (repo, storage, notif);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  group('QuranData', () {
    test('daily portions cover the whole mushaf from Al-Baqarah to An-Nas', () {
      final pages = KhatmahConstants.traditionalSchedule
          .map((d) => QuranData.pageCount(d.startSurahIndex, d.endSurahIndex))
          .toList();
      expect(pages, [104, 102, 74, 85, 79, 72, 87]);
      expect(pages.reduce((a, b) => a + b), 603); // pages 2..604
    });

    test('estimated time is realistic (hours, not minutes) for Day 1', () {
      final day1 = _portions().first;
      expect(day1.pageCount, 104);
      expect(day1.estimatedMinutes, greaterThan(120));
    });

    test('sitting split covers every page exactly once', () {
      final sittings = QuranData.splitIntoSittings(2, 4, count: 5);
      expect(sittings, hasLength(5));
      expect(sittings.first.startPage, 2);
      expect(sittings.last.endPage, 105);
      for (var i = 1; i < sittings.length; i++) {
        expect(sittings[i].startPage, sittings[i - 1].endPage + 1);
      }
      expect(sittings.first.startSurah.number, 2);
    });
  });

  group('DayPortion reading progress', () {
    test('day is split into five parts that track where the reader stopped', () {
      final day1 = _portions().first;
      expect(day1.parts, hasLength(5));
      expect(day1.continueFromPage, isNull); // nothing started yet

      final started = day1.copyWith(readParts: [0, 1]);
      expect(started.readPartCount, 2);
      expect(started.continueFromPage, started.parts[2].startPage);
      expect(started.readingProgress, closeTo(0.4, 0.02));
    });

    test('completed portion reports full progress', () {
      final day1 = _portions(completedDays: 1).first.copyWith(readParts: [0]);
      expect(day1.readingProgress, 1.0);
      expect(day1.continueFromPage, isNull);
    });
  });

  group('Challenge lifecycle', () {
    test('future start is upcoming, not missed', () {
      final c = _challenge(DateTime.now().add(const Duration(days: 3)));
      expect(c.isUpcoming, isTrue);
      expect(c.daysUntilStart, 3);
      expect(c.isActive, isFalse);
      expect(c.isExpired, isFalse);
      expect(c.missedPortionsCount, 0);
    });

    test('late check-in allowed for a missed day, not for rescheduled ones', () {
      final c = _challenge(DateTime.now().subtract(const Duration(days: 2)));
      final day1 = c.portions.first;
      expect(c.canLateCheckIn(day1), isTrue);
      expect(c.canMarkCompleted(day1), isTrue);
      expect(c.canMarkCompleted(c.portions[5]), isFalse); // future day 6

      final adjusted = c.copyWith(
        portions: [
          ...c.portions.take(2),
          c.portions[2].copyWith(
            startSurah: 'Al-Baqarah',
            startSurahAr: 'البقرة',
            isAdjusted: true,
          ),
          ...c.portions.skip(3),
        ],
      );
      expect(adjusted.rescheduledToDay(adjusted.portions.first), 3);
      expect(adjusted.canLateCheckIn(adjusted.portions.first), isFalse);
    });

    test('isKhatmahComplete agrees with Challenge.isAllPortionsCompleted', () {
      final c = _challenge(DateTime.now(), completedDays: 7);
      expect(c.isAllPortionsCompleted, isTrue);
      expect(
        KhatmahConstants.isKhatmahComplete(c.portions.map(
            (p) => (p.startSurah, p.endSurah, p.dayNumber, p.isCompleted))),
        isTrue,
      );
    });
  });

  group('ReminderPlanner', () {
    const seven = TimeOfDay(hour: 19, minute: 0);

    test('future start schedules Day 1 on the start date, not tomorrow', () {
      final now = DateTime(2026, 11, 17, 10);
      final plan = ReminderPlanner.plan(
        now: now,
        startDate: DateTime(2026, 11, 27),
        reminderTime: seven,
      );
      final portions = plan.where((r) => r.kind == ReminderKind.portion).toList();
      expect(portions.first.dayNumber, 1);
      expect(portions.first.when, DateTime(2026, 11, 27, 19));
      expect(portions, hasLength(7));
    });

    test('skips completed days and plans follow-ups after the main reminder', () {
      final now = DateTime(2026, 11, 17, 10);
      final plan = ReminderPlanner.plan(
        now: now,
        startDate: DateTime(2026, 11, 17),
        reminderTime: seven,
        completedDays: {1},
        followUpTime: const TimeOfDay(hour: 22, minute: 0),
      );
      expect(plan.any((r) => r.dayNumber == 1), isFalse);
      final day2 = plan.where((r) => r.dayNumber == 2).toList();
      expect(day2.map((r) => r.kind),
          containsAll([ReminderKind.portion, ReminderKind.followUp]));
      expect(day2.firstWhere((r) => r.kind == ReminderKind.followUp).id, 202);
    });

    test('re-planning during or after the reminder minute never re-fires it', () {
      // Regression: reminder at 11:15; the app was opened from the
      // notification and the language switched within that minute, and each
      // re-plan used to fire another copy two seconds later.
      const quarterPast = TimeOfDay(hour: 11, minute: 15);
      for (final now in [
        DateTime(2026, 11, 17, 11, 15, 0),
        DateTime(2026, 11, 17, 11, 15, 30),
        DateTime(2026, 11, 17, 11, 15, 59),
        DateTime(2026, 11, 17, 11, 20),
      ]) {
        final plan = ReminderPlanner.plan(
          now: now,
          startDate: DateTime(2026, 11, 17),
          reminderTime: quarterPast,
        );
        final todays = plan.where((r) =>
            r.when.year == 2026 && r.when.month == 11 && r.when.day == 17);
        expect(todays, isEmpty, reason: 're-planned at $now');
        expect(plan.first.when, DateTime(2026, 11, 18, 11, 15));
      }

      // Just before the minute, today's reminder is still scheduled once.
      final before = ReminderPlanner.plan(
        now: DateTime(2026, 11, 17, 11, 14, 59),
        startDate: DateTime(2026, 11, 17),
        reminderTime: quarterPast,
      );
      expect(before.first.when, DateTime(2026, 11, 17, 11, 15));
      expect(before.where((r) => r.dayNumber == 1), hasLength(1));
    });

    test('follow-up earlier than the main reminder is ignored', () {
      final plan = ReminderPlanner.plan(
        now: DateTime(2026, 11, 17, 6),
        startDate: DateTime(2026, 11, 17),
        reminderTime: seven,
        followUpTime: const TimeOfDay(hour: 8, minute: 0),
      );
      expect(plan.where((r) => r.kind == ReminderKind.followUp), isEmpty);
    });

    test('after the window ends only habit reminders are planned', () {
      final plan = ReminderPlanner.plan(
        now: DateTime(2026, 11, 17, 10),
        startDate: DateTime(2026, 11, 1),
        reminderTime: seven,
      );
      expect(plan, isNotEmpty);
      expect(plan.every((r) => r.kind == ReminderKind.habit), isTrue);
      expect(plan.first.when, DateTime(2026, 11, 17, 19));
    });
  });

  group('Notification copy', () {
    test('Arabic notifications use Arabic text and ranges', () {
      final copy = NotificationCopy.of('ar');
      expect(copy.portionBody(3, 'يونس ← النحل'), 'اليوم 3: يونس ← النحل');
      expect(copy.markCompletedAction, isNot('Mark as completed'));
      expect(NotificationCopy.of('en').portionTitle, contains('Portion'));
    });
  });

  group('Repository', () {
    test('undo restores the day reminder', () async {
      final (repo, _, notif) = await _repo();
      await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 23, minute: 0));
      await repo.markDayCompleted(1);
      expect(notif.cancelledDays, contains(1));
      final before = notif.scheduleCalls;
      await repo.undoDayCompletion(1);
      expect(notif.scheduleCalls, before + 1);
    });

    test('reminders use stored language and follow-up settings', () async {
      final (repo, storage, notif) = await _repo();
      await storage.setLanguageCode('ar');
      await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 19, minute: 0));
      await repo.updateFollowUpSettings(
          enabled: true, followUpTime: const TimeOfDay(hour: 22, minute: 0));
      expect(notif.lastLanguage, 'ar');
      expect(notif.lastFollowUp, const TimeOfDay(hour: 22, minute: 0));
    });

    test('restart archives an attempt that had progress', () async {
      final (repo, _, _) = await _repo();
      await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 19, minute: 0));
      await repo.markDayCompleted(1);
      await repo.restartCurrentChallenge();
      final history = await repo.getHistory();
      expect(history, hasLength(1));
      expect(history.first.portions.first.isCompleted, isTrue);
    });

    test('updateReadParts keeps only valid part indexes', () async {
      final (repo, _, _) = await _repo();
      await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 19, minute: 0));
      final updated = await repo.updateReadParts(1, [3, 1, 9, -1, 3]);
      expect(updated.portions.first.readParts, [1, 3]);
      final reloaded = await repo.getActiveChallenge();
      expect(reloaded!.portions.first.readParts, [1, 3]);
    });

    test('backup round-trips progress and rejects garbage', () async {
      final (repo, storage, _) = await _repo();
      await repo.startChallenge(
          startDate: DateTime.now(), reminderTime: const TimeOfDay(hour: 20, minute: 30));
      await repo.markDayCompleted(1);
      final backup = repo.exportBackup();

      expect(await repo.importBackup('not a backup'), isFalse);

      await storage.clearActiveChallenge();
      expect(await repo.getActiveChallenge(), isNull);

      expect(await repo.importBackup(backup), isTrue);
      final restored = await repo.getActiveChallenge();
      expect(restored!.portions.first.isCompleted, isTrue);
      expect(storage.reminderTime, const TimeOfDay(hour: 20, minute: 30));
    });
  });

  group('Lifetime stats', () {
    test('counts finished khatmahs and on-time rate', () {
      final start = DateTime(2026, 10, 1);
      final finished = _challenge(start).copyWith(
        portions: [
          for (final p in _portions())
            p.copyWith(
              isCompleted: true,
              completedAt: start.add(Duration(days: p.dayNumber - 1, hours: 20)),
            ),
        ],
      );
      final stats = LifetimeStats.from([finished]);
      expect(stats.khatmahsCompleted, 1);
      expect(stats.onTimeRate, 1.0);
      expect(stats.averageDaysToFinish, 7);
    });
  });

  group('UI', () {
    testWidgets('Home shows an upcoming state for a future start date', (tester) async {
      final upcoming = _challenge(DateTime.now().add(const Duration(days: 4)));
      await tester.pumpWidget(
        wrapWithLocalization(
          ProviderScope(
            overrides: [
              challengeStateProvider.overrideWith(
                (ref) => _FakeNotifier(ChallengeState(
                  isInitialized: true,
                  challenge: upcoming,
                  hasCompletedOnboarding: true,
                )),
              ),
            ],
            child: HomePage(onNavigateToProgress: () {}, onStartNewKhatmah: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your khatmah begins soon'), findsOneWidget);
      expect(find.text('Starts in 4 days'), findsWidgets);
      expect(find.textContaining('Day 0'), findsNothing);
      expect(find.text('Mark as Completed'), findsNothing);
      expect(find.textContaining('FIRST PORTION'), findsOneWidget);
    });

    testWidgets('Missed day offers a late check-in when allowed', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        wrapWithLocalization(
          DayDetailSheet(
            portion: _portions().first,
            portionDate: DateTime.now().subtract(const Duration(days: 2)),
            currentDayNumber: 3,
            allowLateCheckIn: true,
            onToggleCompletion: () => toggled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.text('I read this portion');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(toggled, isTrue);
    });

    testWidgets('Rescheduled missed day explains where it moved', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          DayDetailSheet(
            portion: _portions().first,
            portionDate: DateTime.now().subtract(const Duration(days: 2)),
            currentDayNumber: 3,
            rescheduledToDay: 3,
            onToggleCompletion: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Moved into Day 3'), findsOneWidget);
      expect(find.text('I read this portion'), findsNothing);
    });
  });
}

class _FakeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
