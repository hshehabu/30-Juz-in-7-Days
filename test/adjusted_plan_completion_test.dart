import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/notification_service.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/datasources/challenge_local_data_source.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/challenge_model.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/repositories/challenge_repository_impl.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/day_detail_sheet.dart';
import 'test_helper.dart';

class _FakeNotificationService extends NotificationService {
  int cancelDayReminderCalledWith = -1;
  bool showCompletionNotificationCalled = false;

  @override
  Future<void> cancelDayReminder(int dayNumber) async {
    cancelDayReminderCalledWith = dayNumber;
  }

  @override
  Future<void> showCompletionNotification() async {
    showCompletionNotificationCalled = true;
  }

  TimeOfDay? scheduledReminderTime;

  @override
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
  }) async {
    scheduledReminderTime = reminderTime;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  group('DayPortion copyWith & completion tests', () {
    test('copyWith(isCompleted: false) automatically clears completedAt', () {
      final portion = DayPortion(
        dayNumber: 4,
        startSurah: 'Al-Baqarah',
        endSurah: 'At-Tawbah',
        startSurahAr: 'البقرة',
        endSurahAr: 'التوبة',
        surahCount: 8,
        isCompleted: true,
        completedAt: DateTime(2026, 10, 8, 11, 24),
      );

      final undone = portion.copyWith(isCompleted: false);
      expect(undone.isCompleted, isFalse);
      expect(undone.completedAt, isNull);
    });

    test('copyWith with clearCompletedAt: true clears completedAt', () {
      final portion = DayPortion(
        dayNumber: 4,
        startSurah: 'Al-Baqarah',
        endSurah: 'At-Tawbah',
        startSurahAr: 'البقرة',
        endSurahAr: 'التوبة',
        surahCount: 8,
        isCompleted: true,
        completedAt: DateTime(2026, 10, 8, 11, 24),
      );

      final cleared = portion.copyWith(clearCompletedAt: true);
      expect(cleared.completedAt, isNull);
    });
  });

  group('Adjusted Plan Single-Day Completion (no retroactive past mutations)', () {
    late StorageService storageService;
    late ChallengeLocalDataSource localDataSource;
    late _FakeNotificationService notificationService;
    late ChallengeRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      localDataSource = ChallengeLocalDataSourceImpl(storageService);
      notificationService = _FakeNotificationService();
      repository = ChallengeRepositoryImpl(
        localDataSource: localDataSource,
        notificationService: notificationService,
        storageService: storageService,
      );
    });

    test('Marking Day 4 (Baqarah -> Tawbah) completed does NOT mark Days 1, 2, 3 complete',
        () async {
      final start = DateTime.now().subtract(const Duration(days: 3)); // Today is Day 4
      final initialChallenge = ChallengeModel(
        id: 'test_adjusted_challenge',
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
            isCompleted: false, // Missed
          ),
          DayPortion(
            dayNumber: 2,
            startSurah: 'Al-Ma\'idah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'المائدة',
            endSurahAr: 'التوبة',
            surahCount: 5,
            isCompleted: false, // Missed
          ),
          DayPortion(
            dayNumber: 3,
            startSurah: 'Yunus',
            endSurah: 'An-Nahl',
            startSurahAr: 'يونس',
            endSurahAr: 'النحل',
            surahCount: 7,
            isCompleted: false, // Missed
          ),
          DayPortion(
            dayNumber: 4,
            startSurah: 'Al-Baqarah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'البقرة',
            endSurahAr: 'التوبة',
            surahCount: 8,
            isCompleted: false,
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 5,
            startSurah: 'Yunus',
            endSurah: 'Al-Furqan',
            startSurahAr: 'يونس',
            endSurahAr: 'الفرقان',
            surahCount: 16,
            isCompleted: false,
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 6,
            startSurah: 'Ash-Shu\'ara',
            endSurah: 'As-Saffat',
            startSurahAr: 'الشعراء',
            endSurahAr: 'الصافات',
            surahCount: 12,
            isCompleted: false,
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 7,
            startSurah: 'Sad',
            endSurah: 'An-Nas',
            startSurahAr: 'ص',
            endSurahAr: 'الناس',
            surahCount: 77,
            isCompleted: false,
            isAdjusted: true,
          ),
        ],
        reminderHour: 18,
        reminderMinute: 0,
        createdAt: start,
      );

      await localDataSource.saveActiveChallenge(initialChallenge);

      // Mark Day 4 as completed
      final updated = await repository.markDayCompleted(4);

      // Verify past days MUST STAY MISSED (isCompleted: false)
      final day1 = updated.portions.firstWhere((p) => p.dayNumber == 1);
      final day2 = updated.portions.firstWhere((p) => p.dayNumber == 2);
      final day3 = updated.portions.firstWhere((p) => p.dayNumber == 3);
      final day4 = updated.portions.firstWhere((p) => p.dayNumber == 4);
      final day5 = updated.portions.firstWhere((p) => p.dayNumber == 5);

      expect(day1.isCompleted, isFalse, reason: 'Day 1 was missed in history');
      expect(day1.completedAt, isNull);

      expect(day2.isCompleted, isFalse, reason: 'Day 2 was missed in history');
      expect(day2.completedAt, isNull);

      expect(day3.isCompleted, isFalse, reason: 'Day 3 was missed in history');
      expect(day3.completedAt, isNull);

      expect(day4.isCompleted, isTrue, reason: 'Day 4 was completed today');
      expect(day4.completedAt, isNotNull);

      expect(day5.isCompleted, isFalse, reason: 'Day 5 is upcoming');

      // Verify portions count and completion percentage:
      // Day 4 covers blocks 0 and 1, so 2 portions out of 7 are read
      expect(updated.completedBlockIndices, containsAll([0, 1]));
      expect(updated.completedPortionsCount, 2);
      expect(updated.completionPercentInt, 29);
      expect(updated.isAllPortionsCompleted, isFalse);
    });

    test('getActiveChallenge sanitizes corrupted legacy storage where Days 1 & 2 were auto-completed',
        () async {
      final start = DateTime.now().subtract(const Duration(days: 3));
      final corruptedChallenge = ChallengeModel(
        id: 'corrupted_by_old_bug',
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
            isCompleted: true, // Falsely auto-completed by old bug
            completedAt: DateTime.now(),
          ),
          DayPortion(
            dayNumber: 2,
            startSurah: 'Al-Ma\'idah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'المائدة',
            endSurahAr: 'التوبة',
            surahCount: 5,
            isCompleted: true, // Falsely auto-completed by old bug
            completedAt: DateTime.now(),
          ),
          DayPortion(
            dayNumber: 3,
            startSurah: 'Yunus',
            endSurah: 'An-Nahl',
            startSurahAr: 'يونس',
            endSurahAr: 'النحل',
            surahCount: 7,
            isCompleted: false, // Missed
          ),
          DayPortion(
            dayNumber: 4,
            startSurah: 'Al-Baqarah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'البقرة',
            endSurahAr: 'التوبة',
            surahCount: 8,
            isCompleted: true,
            completedAt: DateTime.now(),
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 5,
            startSurah: 'Yunus',
            endSurah: 'Al-Furqan',
            startSurahAr: 'يونس',
            endSurahAr: 'الفرقان',
            surahCount: 16,
            isCompleted: false,
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 6,
            startSurah: 'Ash-Shu\'ara',
            endSurah: 'As-Saffat',
            startSurahAr: 'الشعراء',
            endSurahAr: 'الصافات',
            surahCount: 12,
            isCompleted: false,
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 7,
            startSurah: 'Sad',
            endSurah: 'An-Nas',
            startSurahAr: 'ص',
            endSurahAr: 'الناس',
            surahCount: 77,
            isCompleted: false,
            isAdjusted: true,
          ),
        ],
        reminderHour: 18,
        reminderMinute: 0,
        createdAt: start,
      );

      await localDataSource.saveActiveChallenge(corruptedChallenge);

      // Loading active challenge should automatically sanitize Days 1 and 2
      final sanitized = await repository.getActiveChallenge();
      expect(sanitized, isNotNull);

      final day1 = sanitized!.portions.firstWhere((p) => p.dayNumber == 1);
      final day2 = sanitized.portions.firstWhere((p) => p.dayNumber == 2);
      final day3 = sanitized.portions.firstWhere((p) => p.dayNumber == 3);
      final day4 = sanitized.portions.firstWhere((p) => p.dayNumber == 4);

      expect(day1.isCompleted, isFalse);
      expect(day1.completedAt, isNull);

      expect(day2.isCompleted, isFalse);
      expect(day2.completedAt, isNull);

      expect(day3.isCompleted, isFalse);
      expect(day3.completedAt, isNull);

      // Day 4 stays completed
      expect(day4.isCompleted, isTrue);
      expect(day4.completedAt, isNotNull);
    });

    test('Undoing Day 4 only resets Day 4 without affecting other days',
        () async {
      final start = DateTime.now().subtract(const Duration(days: 3));
      final challenge = ChallengeModel(
        id: 'test_undo',
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
            endSurah: 'An-Nahl',
            startSurahAr: 'يونس',
            endSurahAr: 'النحل',
            surahCount: 7,
            isCompleted: false,
          ),
          DayPortion(
            dayNumber: 4,
            startSurah: 'Al-Baqarah',
            endSurah: 'At-Tawbah',
            startSurahAr: 'البقرة',
            endSurahAr: 'التوبة',
            surahCount: 8,
            isCompleted: true,
            completedAt: DateTime.now(),
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 5,
            startSurah: 'Yunus',
            endSurah: 'Al-Furqan',
            startSurahAr: 'يونس',
            endSurahAr: 'الفرقان',
            surahCount: 16,
            isCompleted: false,
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 6,
            startSurah: 'Ash-Shu\'ara',
            endSurah: 'As-Saffat',
            startSurahAr: 'الشعراء',
            endSurahAr: 'الصافات',
            surahCount: 12,
            isCompleted: false,
            isAdjusted: true,
          ),
          DayPortion(
            dayNumber: 7,
            startSurah: 'Sad',
            endSurah: 'An-Nas',
            startSurahAr: 'ص',
            endSurahAr: 'الناس',
            surahCount: 77,
            isCompleted: false,
            isAdjusted: true,
          ),
        ],
        reminderHour: 18,
        reminderMinute: 0,
        createdAt: start,
      );

      await localDataSource.saveActiveChallenge(challenge);

      final undoneChallenge = await repository.undoDayCompletion(4);
      final day4 = undoneChallenge.portions.firstWhere((p) => p.dayNumber == 4);

      expect(day4.isCompleted, isFalse);
      expect(day4.completedAt, isNull);
    });
  });

  group('DayDetailSheet UI guards', () {
    testWidgets('Uncompleted portion does NOT render "Completed On" row even if completedAt is non-null',
        (tester) async {
      final portion = DayPortion(
        dayNumber: 4,
        startSurah: 'Al-Baqarah',
        endSurah: 'At-Tawbah',
        startSurahAr: 'البقرة',
        endSurahAr: 'التوبة',
        surahCount: 8,
        isCompleted: false, // NOT completed
        completedAt: DateTime(2026, 10, 8), // Stray timestamp
        isAdjusted: true,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          DayDetailSheet(
            portion: portion,
            portionDate: DateTime(2026, 10, 8),
            currentDayNumber: 4,
            onToggleCompletion: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Completed On" row must NOT be visible when isCompleted is false
      expect(find.text('Completed On'), findsNothing);
      expect(find.text('Mark as Completed'), findsOneWidget);
    });
  });
}
