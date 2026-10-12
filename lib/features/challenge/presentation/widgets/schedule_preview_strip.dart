import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_portion.dart';

/// A unified, elegant progress card for the active 7-day Khatmah.
/// Combines the overall completion metrics, progress bar, and the 7 interactive
/// day preview tiles into a single, cohesive view.
class SchedulePreviewStrip extends StatelessWidget {
  final List<DayPortion> portions;
  final int currentDayNumber;
  final int? completedCount;
  final double? percentage;
  final Function(DayPortion portion) onSelectPortion;
  final VoidCallback onViewAll;

  const SchedulePreviewStrip({
    super.key,
    required this.portions,
    required this.currentDayNumber,
    this.completedCount,
    this.percentage,
    required this.onSelectPortion,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final completed =
        completedCount ?? portions.where((p) => p.isCompleted).length;
    final total = portions.isEmpty ? 7 : portions.length;
    final pct = (percentage ?? (completed / total)).clamp(0.0, 1.0);
    final percentInt = (pct * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.mistGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Section Title and Journey navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.progress.title.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.signalBlack,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LocaleKeys.home.view_journey.tr(context: context),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.dustyGreenDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.dustyGreenDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Completion stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.home.portions_completed_count.tr(
                  context: context,
                  args: [completed.toString(), total.toString()],
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentInt%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.dustyGreenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Flat clean progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.secondaryNeutral,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
          const SizedBox(height: 16),

          // 7 Day compact interactive tiles in a balanced row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: portions.map((p) {
              final isToday = p.dayNumber == currentDayNumber;
              final isPast = p.dayNumber < currentDayNumber;
              final isCompleted = p.isCompleted;

              Color borderColor = AppColors.mistGray;
              Color bgColor = AppColors.paper;
              Widget iconOrNum;

              if (isCompleted) {
                bgColor = AppColors.secondaryNeutral;
                borderColor = AppColors.ink;
                iconOrNum = const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.ink,
                );
              } else if (isToday) {
                bgColor = AppColors.ink;
                borderColor = AppColors.ink;
                iconOrNum = Text(
                  '${p.dayNumber}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.buttonText,
                  ),
                );
              } else if (isPast && !isCompleted) {
                bgColor = AppColors.controlSurface;
                borderColor = AppColors.mistGray;
                iconOrNum = Text(
                  '${p.dayNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                );
              } else {
                iconOrNum = Text(
                  '${p.dayNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                );
              }

              return InkWell(
                onTap: () => onSelectPortion(p),
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius:
                            BorderRadius.circular(AppColors.standardRadius),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: iconOrNum,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocaleKeys.common.day_number
                          .tr(args: [p.dayNumber.toString()]),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? AppColors.signalBlack
                            : AppColors.textMuted,
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
