class DefaultPortionData {
  final int dayNumber;
  final String startSurah;
  final String endSurah;
  final String startSurahAr;
  final String endSurahAr;
  final int surahCount;
  final int startSurahIndex;
  final int endSurahIndex;

  const DefaultPortionData({
    required this.dayNumber,
    required this.startSurah,
    required this.endSurah,
    required this.startSurahAr,
    required this.endSurahAr,
    required this.surahCount,
    required this.startSurahIndex,
    required this.endSurahIndex,
  });

  String get rangeDisplay => '$startSurah → $endSurah';
  String get rangeDisplayAr => '$startSurahAr ← $endSurahAr';
}

class KhatmahConstants {
  KhatmahConstants._();

  static const String appName = "30 Juz' in 7 Days";
  static const String appTagline =
      'Complete the Qur\'an in seven days with a simple daily reminder and progress tracker.';

  static const int totalDays = 7;

  /// Traditional 7-part schedule: 3 → 5 → 7 → 9 → 11 → 13 → Al-Mufassal
  static const List<DefaultPortionData> traditionalSchedule = [
    DefaultPortionData(
      dayNumber: 1,
      startSurah: 'Al-Baqarah',
      endSurah: 'An-Nisa',
      startSurahAr: 'البقرة',
      endSurahAr: 'النساء',
      surahCount: 3,
      startSurahIndex: 2,
      endSurahIndex: 4,
    ),
    DefaultPortionData(
      dayNumber: 2,
      startSurah: 'Al-Ma\'idah',
      endSurah: 'At-Tawbah',
      startSurahAr: 'المائدة',
      endSurahAr: 'التوبة',
      surahCount: 5,
      startSurahIndex: 5,
      endSurahIndex: 9,
    ),
    DefaultPortionData(
      dayNumber: 3,
      startSurah: 'Yunus',
      endSurah: 'An-Nahl',
      startSurahAr: 'يونس',
      endSurahAr: 'النحل',
      surahCount: 7,
      startSurahIndex: 10,
      endSurahIndex: 16,
    ),
    DefaultPortionData(
      dayNumber: 4,
      startSurah: 'Al-Isra',
      endSurah: 'Al-Furqan',
      startSurahAr: 'الإسراء',
      endSurahAr: 'الفرقان',
      surahCount: 9,
      startSurahIndex: 17,
      endSurahIndex: 25,
    ),
    DefaultPortionData(
      dayNumber: 5,
      startSurah: 'Ash-Shu\'ara',
      endSurah: 'Ya-Sin',
      startSurahAr: 'الشعراء',
      endSurahAr: 'يس',
      surahCount: 11,
      startSurahIndex: 26,
      endSurahIndex: 36,
    ),
    DefaultPortionData(
      dayNumber: 6,
      startSurah: 'As-Saffat',
      endSurah: 'Al-Hujurat',
      startSurahAr: 'الصافات',
      endSurahAr: 'الحجرات',
      surahCount: 13,
      startSurahIndex: 37,
      endSurahIndex: 49,
    ),
    DefaultPortionData(
      dayNumber: 7,
      startSurah: 'Qaf',
      endSurah: 'An-Nas',
      startSurahAr: 'ق',
      endSurahAr: 'الناس',
      surahCount: 65,
      startSurahIndex: 50,
      endSurahIndex: 114,
    ),
  ];

  static const String hadithSource = 'Sahih al-Bukhari 5052';
  static const String hadithSourceAr = 'صحيح البخاري (٥٠٥٢)';
  static const String hadithText =
      'The Prophet ﷺ instructed ʿAbdullah ibn ʿAmr to recite the Qur\'an in seven days: "Read it in seven days, and do not exceed that."';
  static const String hadithTextAr =
      'عَنْ عَبْدِ اللَّهِ بْنِ عَمْرٍو رَضِيَ اللَّهُ عَنْهُمَا، قَالَ لِي رَسُولُ اللَّهِ ﷺ: «اقْرَأِ الْقُرْآنَ فِي سَبْعٍ، وَلَا تَزِدْ عَلَى ذَلِكَ».';
  static const String hadithQuote = '«اقْرَأِ الْقُرْآنَ فِي كُلِّ سَبْعٍ»';

  static String getHadithText(bool isArabic) =>
      isArabic ? hadithTextAr : hadithText;

  static String getHadithSource(bool isArabic) =>
      isArabic ? hadithSourceAr : hadithSource;

  static String _normalize(String s) {
    return s.replaceAll('’', "'").replaceAll('`', "'").trim().toLowerCase();
  }

  static String _normalizeAr(String s) {
    return s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  /// Returns the traditional block index (0..6) matching the given start surah (English or Arabic).
  /// Returns -1 if not found.
  static int getBlockIndexByStartSurah(String surahName) {
    final norm = _normalize(surahName);
    final normAr = _normalizeAr(surahName);
    for (int i = 0; i < traditionalSchedule.length; i++) {
      final block = traditionalSchedule[i];
      if (_normalize(block.startSurah) == norm ||
          _normalizeAr(block.startSurahAr) == normAr) {
        return i;
      }
    }
    return -1;
  }

  /// Returns the traditional block index (0..6) matching the given end surah (English or Arabic).
  /// Returns -1 if not found.
  static int getBlockIndexByEndSurah(String surahName) {
    final norm = _normalize(surahName);
    final normAr = _normalizeAr(surahName);
    for (int i = 0; i < traditionalSchedule.length; i++) {
      final block = traditionalSchedule[i];
      if (_normalize(block.endSurah) == norm ||
          _normalizeAr(block.endSurahAr) == normAr) {
        return i;
      }
    }
    return -1;
  }

  /// Returns the set of traditional block indices (0..6) covered by a portion range.
  static Set<int> getBlocksCovered(String startSurah, String endSurah) {
    final startIdx = getBlockIndexByStartSurah(startSurah);
    final endIdx = getBlockIndexByEndSurah(endSurah);
    if (startIdx != -1 && endIdx != -1 && startIdx <= endIdx) {
      return {for (int i = startIdx; i <= endIdx; i++) i};
    }
    return {};
  }
}
