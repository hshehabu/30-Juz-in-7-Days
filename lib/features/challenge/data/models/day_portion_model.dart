import '../../domain/entities/day_portion.dart';

class DayPortionModel extends DayPortion {
  const DayPortionModel({
    required super.dayNumber,
    required super.startSurah,
    required super.endSurah,
    required super.startSurahAr,
    required super.endSurahAr,
    required super.surahCount,
    super.isCompleted = false,
    super.completedAt,
    super.isAdjusted = false,
    super.readParts = const [],
    super.partsCount = DayPortion.defaultPartsCount,
    super.partsCustom = false,
  });

  factory DayPortionModel.fromJson(Map<String, dynamic> json) {
    return DayPortionModel(
      dayNumber: json['dayNumber'] as int,
      startSurah: json['startSurah'] as String,
      endSurah: json['endSurah'] as String,
      startSurahAr: json['startSurahAr'] as String? ?? '',
      endSurahAr: json['endSurahAr'] as String? ?? '',
      surahCount: json['surahCount'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      isAdjusted: json['isAdjusted'] as bool? ?? false,
      readParts: (json['readParts'] as List<dynamic>?)
              ?.whereType<int>()
              .toList() ??
          const [],
      partsCount: json['partsCount'] as int? ?? DayPortion.defaultPartsCount,
      partsCustom: json['partsCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'startSurah': startSurah,
      'endSurah': endSurah,
      'startSurahAr': startSurahAr,
      'endSurahAr': endSurahAr,
      'surahCount': surahCount,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'isAdjusted': isAdjusted,
      'readParts': readParts,
      'partsCount': partsCount,
      'partsCustom': partsCustom,
    };
  }

  factory DayPortionModel.fromEntity(DayPortion entity) {
    return DayPortionModel(
      dayNumber: entity.dayNumber,
      startSurah: entity.startSurah,
      endSurah: entity.endSurah,
      startSurahAr: entity.startSurahAr,
      endSurahAr: entity.endSurahAr,
      surahCount: entity.surahCount,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      isAdjusted: entity.isAdjusted,
      readParts: entity.readParts,
      partsCount: entity.partsCount,
      partsCustom: entity.partsCustom,
    );
  }
}
