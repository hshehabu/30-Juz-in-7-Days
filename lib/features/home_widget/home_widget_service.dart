import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../challenge/data/models/challenge_model.dart';
import '../challenge/domain/entities/challenge.dart';
import '../challenge/domain/entities/day_portion.dart';

/// Called by the Android home-screen widget's "Mark done" button. Runs in a
/// background isolate, so it only uses storage and static helpers.
@pragma('vm:entry-point')
Future<void> homeWidgetInteractivityCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri?.host == 'markdone') {
    final day = int.tryParse(uri!.queryParameters['day'] ?? '');
    if (day != null) {
      await NotificationService.markDayCompletedInBackground(day);
    }
  }
  await HomeWidgetService.refreshFromStorage();
}

/// Localized widget text. The widget is rendered outside the Flutter UI (and
/// refreshed from a background isolate), so easy_localization is unavailable.
class _WidgetCopy {
  final String dayOfSeven;
  final String readToday;
  final String markDone;
  final String beginsSoon;
  final String startsOn;
  final String completedTitle;
  final String completedBody;
  final String endedTitle;
  final String endedBody;
  final String noKhatmahTitle;
  final String noKhatmahBody;
  final String pagesTime;
  final String hoursMinutes;
  final String minutesOnly;
  final String continueFrom;

  const _WidgetCopy({
    required this.dayOfSeven,
    required this.readToday,
    required this.markDone,
    required this.beginsSoon,
    required this.startsOn,
    required this.completedTitle,
    required this.completedBody,
    required this.endedTitle,
    required this.endedBody,
    required this.noKhatmahTitle,
    required this.noKhatmahBody,
    required this.pagesTime,
    required this.hoursMinutes,
    required this.minutesOnly,
    required this.continueFrom,
  });

  static const en = _WidgetCopy(
    dayOfSeven: 'Day {d} of 7',
    readToday: 'Read today ✓',
    markDone: 'Mark done',
    beginsSoon: 'Your khatmah begins soon',
    startsOn: 'Starts {date}',
    completedTitle: 'Khatmah completed',
    completedBody: 'Alhamdulillah. Open the app to begin the next one.',
    endedTitle: 'Khatmah period ended',
    endedBody: 'Open the app to start a fresh 7-day journey.',
    noKhatmahTitle: '30 Juz\' in 7 Days',
    noKhatmahBody: 'Start your 7-day khatmah',
    pagesTime: '{p} pages • {t}',
    hoursMinutes: '~{h}h {m}m',
    minutesOnly: '~{m} min',
    continueFrom: 'Continue from page {p}',
  );

  static const ar = _WidgetCopy(
    dayOfSeven: 'اليوم {d} من ٧',
    readToday: 'تمت قراءة ورد اليوم ✓',
    markDone: 'تمت القراءة',
    beginsSoon: 'ختمتك تبدأ قريباً',
    startsOn: 'تبدأ في {date}',
    completedTitle: 'اكتملت الختمة',
    completedBody: 'الحمد لله. افتح التطبيق لبدء ختمة جديدة.',
    endedTitle: 'انتهت مدة الختمة',
    endedBody: 'افتح التطبيق لبدء رحلة جديدة في ٧ أيام.',
    noKhatmahTitle: '٣٠ جزءاً في ٧ أيام',
    noKhatmahBody: 'ابدأ ختمتك في ٧ أيام',
    pagesTime: '{p} صفحة • {t}',
    hoursMinutes: '~{h} س {m} د',
    minutesOnly: '~{m} د',
    continueFrom: 'تابع من الصفحة {p}',
  );

  static _WidgetCopy of(String code) => code == 'ar' ? ar : en;

  String duration(int minutes) => minutes >= 60
      ? hoursMinutes
          .replaceAll('{h}', '${minutes ~/ 60}')
          .replaceAll('{m}', (minutes % 60).toString().padLeft(2, '0'))
      : minutesOnly.replaceAll('{m}', '$minutes');
}

class HomeWidgetService {
  HomeWidgetService._();

  static const String dataKey = 'khatmah_widget';
  static const String qualifiedAndroidName =
      'com.hshehabu.thirtyjuz.KhatmahWidgetProvider';

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Registers the background handler for the widget's "Mark done" button.
  static Future<void> registerCallback() async {
    if (!_supported) return;
    try {
      await HomeWidget.registerInteractivityCallback(
          homeWidgetInteractivityCallback);
    } catch (_) {}
  }

  /// Pushes the latest challenge state to the home-screen widget.
  static Future<void> update(Challenge? challenge, String languageCode) async {
    if (!_supported) return;
    try {
      final payload = await buildPayload(challenge, languageCode);
      await HomeWidget.saveWidgetData<String>(dataKey, jsonEncode(payload));
      await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
    } catch (_) {
      // Widget support is optional (e.g. no widget placed, or tests).
    }
  }

  /// Rebuilds the widget from persisted storage (background isolate safe).
  static Future<void> refreshFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      await storage.reloadFromDisk();
      final raw = storage.getActiveChallengeJson();
      Challenge? challenge;
      if (raw != null) {
        challenge =
            ChallengeModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      await update(challenge, storage.languageCode);
    } catch (_) {}
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Widget content for every date of the challenge, plus "before" and
  /// "after" states. The native widget picks the entry for the current date,
  /// so the day rolls over at midnight even when the app is not running.
  @visibleForTesting
  static Future<Map<String, dynamic>> buildPayload(
    Challenge? challenge,
    String languageCode,
  ) async {
    final copy = _WidgetCopy.of(languageCode);
    final isAr = languageCode == 'ar';

    Map<String, dynamic> entry({
      required String header,
      required String range,
      required String detail,
      int progress = 0,
      String progressLabel = '',
      bool canMark = false,
      int day = 0,
    }) =>
        {
          'header': header,
          'range': range,
          'detail': detail,
          'progress': progress,
          'progressLabel': progressLabel,
          'canMark': canMark,
          'day': day,
          'markLabel': copy.markDone,
        };

    if (challenge == null) {
      final empty = entry(
        header: copy.noKhatmahTitle,
        range: copy.noKhatmahBody,
        detail: '',
      );
      return {
        'start': '',
        'end': '',
        'dates': <String, dynamic>{},
        'before': empty,
        'after': empty,
      };
    }

    final percent = (challenge.completionPercentage * 100).round();
    final progressLabel = '${challenge.completedPortionsCount}/7';

    final completedEntry = entry(
      header: copy.completedTitle,
      range: copy.completedBody,
      detail: '',
      progress: 100,
      progressLabel: '7/7',
    );

    String detailFor(DayPortion p) {
      final from = p.continueFromPage;
      if (from != null) {
        return copy.continueFrom.replaceAll('{p}', '$from');
      }
      return copy.pagesTime
          .replaceAll('{p}', '${p.pageCount}')
          .replaceAll('{t}', copy.duration(p.estimatedMinutes));
    }

    final dates = <String, dynamic>{};
    for (final p in challenge.portions) {
      final date = challenge.dateForDay(p.dayNumber);
      if (challenge.isAllPortionsCompleted) {
        dates[_dateKey(date)] = completedEntry;
        continue;
      }
      dates[_dateKey(date)] = entry(
        header: copy.dayOfSeven.replaceAll('{d}', '${p.dayNumber}'),
        range: isAr ? p.rangeDisplayAr : p.rangeDisplay,
        detail: p.isCompleted ? copy.readToday : detailFor(p),
        progress: percent,
        progressLabel: progressLabel,
        canMark: !p.isCompleted,
        day: p.dayNumber,
      );
    }

    String startLabel;
    try {
      await initializeDateFormatting(languageCode);
      startLabel = DateFormat(isAr ? 'd MMMM' : 'MMMM d', languageCode)
          .format(challenge.startDate);
    } catch (_) {
      startLabel = _dateKey(challenge.startDate);
    }
    final first = challenge.portions.first;

    return {
      'start': _dateKey(challenge.startDate),
      'end': _dateKey(challenge.dateForDay(challenge.portions.length)),
      'dates': dates,
      'before': entry(
        header: copy.beginsSoon,
        range: isAr ? first.rangeDisplayAr : first.rangeDisplay,
        detail: copy.startsOn.replaceAll('{date}', startLabel),
      ),
      'after': challenge.isAllPortionsCompleted
          ? completedEntry
          : entry(
              header: copy.endedTitle,
              range: copy.endedBody,
              detail: '',
              progress: percent,
              progressLabel: progressLabel,
            ),
    };
  }
}
