import 'package:flutter_test/flutter_test.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/challenge_completed_dialog.dart';
import 'package:thirty_juz_in_7_days/features/home_widget/home_widget_service.dart';
import 'test_helper.dart';

Challenge _challenge(DateTime start, {int completedDays = 0}) {
  final s = DateTime(start.year, start.month, start.day);
  return Challenge(
    id: 'w',
    startDate: s,
    endDate: s.add(const Duration(days: 6)),
    portions: KhatmahConstants.traditionalSchedule
        .map((d) => DayPortion(
              dayNumber: d.dayNumber,
              startSurah: d.startSurah,
              endSurah: d.endSurah,
              startSurahAr: d.startSurahAr,
              endSurahAr: d.endSurahAr,
              surahCount: d.surahCount,
              isCompleted: d.dayNumber <= completedDays,
            ))
        .toList(),
    reminderHour: 19,
    reminderMinute: 0,
    createdAt: s,
  );
}

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  group('Home widget payload', () {
    test('each date carries a 7-day strip: read, shown day, not yet', () async {
      final start = DateTime.now().subtract(const Duration(days: 2));
      final payload = await HomeWidgetService.buildPayload(
          _challenge(start, completedDays: 1), 'en');
      final dates = payload['dates'] as Map<String, dynamic>;
      final day3 = dates[_key(DateTime.now())] as Map<String, dynamic>;
      expect(day3['days'], 'cutuuuu');
      expect(day3['rtl'], isFalse);
      expect((payload['before'] as Map)['days'], 'cuuuuuu');
    });

    test('completed khatmah fills the whole strip', () async {
      final payload = await HomeWidgetService.buildPayload(
          _challenge(DateTime.now(), completedDays: 7), 'en');
      expect((payload['after'] as Map)['days'], 'ccccccc');
    });

    test('has an entry for every challenge date with a Mark done action', () async {
      final today = DateTime.now();
      final payload = await HomeWidgetService.buildPayload(_challenge(today), 'en');
      final dates = payload['dates'] as Map<String, dynamic>;
      expect(dates, hasLength(7));
      final todayEntry = dates[_key(today)] as Map<String, dynamic>;
      expect(todayEntry['header'], 'Day 1 of 7');
      expect(todayEntry['range'], 'Al-Baqarah → An-Nisa');
      expect(todayEntry['canMark'], isTrue);
      expect(todayEntry['day'], 1);
      expect(todayEntry['detail'], contains('104 pages'));
    });

    test('Arabic payload uses Arabic text and ranges', () async {
      final payload =
          await HomeWidgetService.buildPayload(_challenge(DateTime.now()), 'ar');
      final entry = (payload['dates'] as Map<String, dynamic>)
          .values
          .first as Map<String, dynamic>;
      expect(entry['header'], 'اليوم 1 من ٧');
      expect(entry['range'], 'البقرة ← النساء');
      expect(entry['markLabel'], contains('تمت القراءة'));
      expect(entry['rtl'], isTrue);
    });

    test('completed khatmah shows the completed state, no button', () async {
      final payload = await HomeWidgetService.buildPayload(
          _challenge(DateTime.now(), completedDays: 7), 'en');
      final entries = (payload['dates'] as Map<String, dynamic>).values;
      expect(entries.every((e) => (e as Map)['canMark'] == false), isTrue);
      expect((payload['after'] as Map)['header'], 'Khatmah completed');
    });

    test('future start provides a "before" state', () async {
      final payload = await HomeWidgetService.buildPayload(
          _challenge(DateTime.now().add(const Duration(days: 5))), 'en');
      expect((payload['before'] as Map)['header'], 'Your khatmah begins soon');
      expect(payload['start'], isNotEmpty);
    });

    test('no challenge yields a setup prompt', () async {
      final payload = await HomeWidgetService.buildPayload(null, 'en');
      expect((payload['after'] as Map)['range'], 'Start your 7-day khatmah');
    });
  });

  testWidgets('Completion dialog offers Share when a handler is provided',
      (tester) async {
    var shared = false;
    await tester.pumpWidget(wrapWithLocalization(
      ChallengeCompletedDialog(
        onStartAnother: () {},
        onDismiss: () {},
        onShare: () => shared = true,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    expect(shared, isTrue);
  });
}
