import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_portion.dart';

class SchedulePreviewStrip extends StatelessWidget {
  final List<DayPortion> portions;
  final int currentDayNumber;
  final Function(DayPortion portion) onSelectPortion;
  final VoidCallback onViewAll;

  const SchedulePreviewStrip({
    super.key,
    required this.portions,
    required this.currentDayNumber,
    required this.onSelectPortion,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.parchmentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softSand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Journey',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBrown,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'View Timeline →',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.brassGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7 Day circular / pill nodes in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: portions.map((p) {
              final isToday = p.dayNumber == currentDayNumber;
              final isPast = p.dayNumber < currentDayNumber;
              final isCompleted = p.isCompleted;

              Color borderColor = AppColors.softSand;
              Color bgColor = AppColors.parchment;
              Color textColor = AppColors.deepBrown;
              Widget iconOrNum;

              if (isCompleted) {
                bgColor = AppColors.brassGold.withValues(alpha: 0.12);
                borderColor = AppColors.brassGold;
                textColor = AppColors.brassGoldDark;
                iconOrNum = const Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.brassGold,
                );
              } else if (isToday) {
                bgColor = AppColors.brassGold;
                borderColor = AppColors.brassGold;
                textColor = AppColors.textLight;
                iconOrNum = Text(
                  '${p.dayNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                );
              } else if (isPast && !isCompleted) {
                bgColor = AppColors.statusMissed.withValues(alpha: 0.1);
                borderColor = AppColors.statusMissed.withValues(alpha: 0.4);
                textColor = AppColors.statusMissed;
                iconOrNum = Text(
                  '${p.dayNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusMissed,
                  ),
                );
              } else {
                iconOrNum = Text(
                  '${p.dayNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                );
              }

              return InkWell(
                onTap: () => onSelectPortion(p),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: iconOrNum,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Day ${p.dayNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday ? AppColors.brassGold : textColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
