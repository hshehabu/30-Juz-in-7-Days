import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';
import 'day_portion_model.dart';

class ChallengeModel extends Challenge {
  const ChallengeModel({
    required super.id,
    required super.startDate,
    required super.endDate,
    required super.portions,
    required super.reminderHour,
    required super.reminderMinute,
    super.isCompleted = false,
    required super.createdAt,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    final List<DayPortion> portionsList = (json['portions'] as List<dynamic>)
        .map<DayPortion>((e) => DayPortionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ChallengeModel(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      portions: portionsList,
      reminderHour: json['reminderHour'] as int? ?? 19,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'portions': portions
          .map((p) => DayPortionModel.fromEntity(p).toJson())
          .toList(),
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChallengeModel.fromEntity(Challenge entity) {
    return ChallengeModel(
      id: entity.id,
      startDate: entity.startDate,
      endDate: entity.endDate,
      portions: entity.portions,
      reminderHour: entity.reminderHour,
      reminderMinute: entity.reminderMinute,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
    );
  }

  ChallengeModel copyWithModel({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    List<DayPortion>? portions,
    int? reminderHour,
    int? reminderMinute,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      portions: portions ?? this.portions,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
