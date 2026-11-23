import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/constants/quran_data.dart';

class DayPortion {
  final int dayNumber;
  final String startSurah;
  final String endSurah;
  final String startSurahAr;
  final String endSurahAr;
  final int surahCount;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isAdjusted;

  /// Default split: one part after each of the five daily prayers.
  static const int defaultPartsCount = 5;

  /// Split choices offered to the user (0 = reading plan turned off).
  static const List<int> partsCountOptions = [5, 3, 2];

  /// Number of equal page-based parts this day is split into.
  final int partsCount;

  /// True when this day's split was chosen for this day only, so changes to
  /// the default (Settings) leave it alone.
  final bool partsCustom;

  /// Indexes (0..partsCount-1) of the day's parts already read. Enables
  /// "where did I stop" tracking for long daily portions.
  final List<int> readParts;

  const DayPortion({
    required this.dayNumber,
    required this.startSurah,
    required this.endSurah,
    required this.startSurahAr,
    required this.endSurahAr,
    required this.surahCount,
    this.isCompleted = false,
    this.completedAt,
    this.isAdjusted = false,
    this.readParts = const [],
    this.partsCount = defaultPartsCount,
    this.partsCustom = false,
  });

  String get rangeDisplay => '$startSurah → $endSurah';
  String get rangeDisplayAr => '$startSurahAr ← $endSurahAr';

  /// First surah number (1..114) of this portion.
  int get startSurahNumber {
    final idx = KhatmahConstants.getBlockIndexByStartSurah(startSurah);
    if (idx != -1) return KhatmahConstants.traditionalSchedule[idx].startSurahIndex;
    return KhatmahConstants
        .traditionalSchedule[(dayNumber - 1).clamp(0, KhatmahConstants.totalDays - 1)]
        .startSurahIndex;
  }

  /// Last surah number (1..114) of this portion.
  int get endSurahNumber {
    final idx = KhatmahConstants.getBlockIndexByEndSurah(endSurah);
    if (idx != -1) return KhatmahConstants.traditionalSchedule[idx].endSurahIndex;
    return KhatmahConstants
        .traditionalSchedule[(dayNumber - 1).clamp(0, KhatmahConstants.totalDays - 1)]
        .endSurahIndex;
  }

  /// All surah numbers in reading order.
  List<int> get surahNumbers {
    final start = startSurahNumber;
    final end = endSurahNumber;
    if (end < start) return const [];
    return [for (var s = start; s <= end; s++) s];
  }

  /// Number of pages in the 604-page Madani mushaf.
  int get pageCount => QuranData.pageCount(startSurahNumber, endSurahNumber);

  int get startPage => QuranData.startPageOf(startSurahNumber);
  int get endPage => QuranData.endPageOf(endSurahNumber);

  int get estimatedMinutes => QuranData.estimatedMinutes(pageCount);

  /// The day split into [partsCount] roughly equal page ranges.
  List<ReadingSitting> get parts => QuranData.splitIntoSittings(
        startSurahNumber,
        endSurahNumber,
        count: partsCount < 1 ? defaultPartsCount : partsCount,
      );

  /// Re-splits the day into [count] parts, keeping progress: a new part is
  /// ticked when every one of its pages was already covered by ticked parts.
  DayPortion withPartsCount(int count) {
    if (count < 1 || count == partsCount) return this;
    final oldParts = parts;
    final covered = <int>{};
    for (final i in _validReadParts) {
      for (var page = oldParts[i].startPage; page <= oldParts[i].endPage; page++) {
        covered.add(page);
      }
    }
    final resized = copyWith(partsCount: count, readParts: const []);
    final carried = [
      for (final part in resized.parts)
        if (covered.isNotEmpty &&
            [for (var p = part.startPage; p <= part.endPage; p++) p]
                .every(covered.contains))
          part.index,
    ];
    return resized.copyWith(readParts: carried);
  }

  Set<int> get _validReadParts {
    final count = parts.length;
    return readParts.where((i) => i >= 0 && i < count).toSet();
  }

  /// Number of parts marked as read.
  int get readPartCount => _validReadParts.length;

  /// Page-weighted reading progress (0.0..1.0) within the portion.
  double get readingProgress {
    if (isCompleted) return 1.0;
    final all = parts;
    final read = _validReadParts;
    if (all.isEmpty || read.isEmpty) return 0.0;
    final total = all.fold<int>(0, (s, p) => s + p.pageCount);
    final done = read.fold<int>(0, (s, i) => s + all[i].pageCount);
    return total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
  }

  /// First page of the first unread part, i.e. where to continue. Null when
  /// nothing has been started yet or everything is read.
  int? get continueFromPage {
    if (isCompleted) return null;
    final read = _validReadParts;
    if (read.isEmpty) return null;
    for (final part in parts) {
      if (!read.contains(part.index)) return part.startPage;
    }
    return null;
  }

  DayPortion copyWith({
    int? dayNumber,
    String? startSurah,
    String? endSurah,
    String? startSurahAr,
    String? endSurahAr,
    int? surahCount,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isAdjusted,
    List<int>? readParts,
    int? partsCount,
    bool? partsCustom,
  }) {
    final nextIsCompleted = isCompleted ?? this.isCompleted;
    final DateTime? nextCompletedAt;
    if (clearCompletedAt || (!nextIsCompleted && completedAt == null)) {
      nextCompletedAt = null;
    } else {
      nextCompletedAt = completedAt ?? this.completedAt;
    }

    return DayPortion(
      dayNumber: dayNumber ?? this.dayNumber,
      startSurah: startSurah ?? this.startSurah,
      endSurah: endSurah ?? this.endSurah,
      startSurahAr: startSurahAr ?? this.startSurahAr,
      endSurahAr: endSurahAr ?? this.endSurahAr,
      surahCount: surahCount ?? this.surahCount,
      isCompleted: nextIsCompleted,
      completedAt: nextCompletedAt,
      isAdjusted: isAdjusted ?? this.isAdjusted,
      readParts: readParts ?? this.readParts,
      partsCount: partsCount ?? this.partsCount,
      partsCustom: partsCustom ?? this.partsCustom,
    );
  }
}
