import 'package:easy_localization/easy_localization.dart';
import '../localization/locale_keys.g.dart';

/// Localized formatting for reading sizes and durations.
class ReadingFormat {
  ReadingFormat._();

  /// "~2h 35m" / "~45 min" (localized).
  static String duration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return LocaleKeys.common.duration_hm
          .tr(args: [h.toString(), m.toString().padLeft(2, '0')]);
    }
    return LocaleKeys.common.duration_m.tr(args: [minutes.toString()]);
  }

  /// "104 pages" (localized).
  static String pages(int count) =>
      LocaleKeys.common.pages_count.tr(args: [count.toString()]);

  /// "104 pages • ~2h 36m"
  static String pagesAndTime(int pageCount, int minutes) =>
      LocaleKeys.progress.reading_time_pages
          .tr(args: [pageCount.toString(), duration(minutes)]);
}
