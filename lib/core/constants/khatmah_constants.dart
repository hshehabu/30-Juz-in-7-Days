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
  static const String hadithText =
      'The Prophet ﷺ instructed ʿAbdullah ibn ʿAmr to recite the Qur\'an in seven days: "Read it in seven days, and do not exceed that."';
  static const String hadithExplanation =
      'Distinction: The seven-day completion is established in the prophetic Sunnah (Bukhari 5052). The particular 3-5-7-9-11-13-Mufassal division is a venerable traditional arrangement used by the early generations.';
}
