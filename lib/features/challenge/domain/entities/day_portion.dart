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
  });

  String get rangeDisplay => '$startSurah → $endSurah';
  String get rangeDisplayAr => '$startSurahAr ← $endSurahAr';

  DayPortion copyWith({
    int? dayNumber,
    String? startSurah,
    String? endSurah,
    String? startSurahAr,
    String? endSurahAr,
    int? surahCount,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isAdjusted,
  }) {
    return DayPortion(
      dayNumber: dayNumber ?? this.dayNumber,
      startSurah: startSurah ?? this.startSurah,
      endSurah: endSurah ?? this.endSurah,
      startSurahAr: startSurahAr ?? this.startSurahAr,
      endSurahAr: endSurahAr ?? this.endSurahAr,
      surahCount: surahCount ?? this.surahCount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isAdjusted: isAdjusted ?? this.isAdjusted,
    );
  }
}
