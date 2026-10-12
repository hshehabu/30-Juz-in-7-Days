import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/utils/date_utils.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/widgets/schedule_preview_strip.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en', null);
  });

  group('Date and Time Localization Tests', () {
    test('formatDate localizes correctly for Arabic and English', () {
      final dt = DateTime(2026, 10, 12);
      expect(AppDateUtils.formatDate(dt, 'ar'), '12 أكتوبر');
      expect(AppDateUtils.formatDate(dt, 'en'), 'October 12');
    });

    test('formatDateWithYear localizes correctly for Arabic and English', () {
      final dt = DateTime(2026, 10, 12);
      expect(AppDateUtils.formatDateWithYear(dt, 'ar'), '12 أكتوبر 2026');
      expect(AppDateUtils.formatDateWithYear(dt, 'en'), 'October 12, 2026');
    });

    test('formatTimeOfDay localizes PM/AM marker for Arabic and English', () {
      const pmTime = TimeOfDay(hour: 19, minute: 0); // 7:00 PM
      const amTime = TimeOfDay(hour: 7, minute: 30); // 7:30 AM
      expect(AppDateUtils.formatTimeOfDay(pmTime, 'ar'), contains('م'));
      expect(AppDateUtils.formatTimeOfDay(amTime, 'ar'), contains('ص'));
      expect(AppDateUtils.formatTimeOfDay(pmTime, 'en'), contains('PM'));
      expect(AppDateUtils.formatTimeOfDay(amTime, 'en'), contains('AM'));
    });
  });

  group('Icon Direction & Layout Verification', () {
    testWidgets('SchedulePreviewStrip arrow forward is rendered', (tester) async {
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

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: SchedulePreviewStrip(
              portions: portions,
              currentDayNumber: 1,
              completedCount: 0,
              percentage: 0.0,
              onSelectPortion: (_) {},
              onViewAll: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });
  });
}
