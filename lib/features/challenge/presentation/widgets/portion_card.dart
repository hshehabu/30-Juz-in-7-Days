import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/reading_format.dart';
import '../../domain/entities/day_portion.dart';
import 'reading_plan.dart';

class PortionCard extends StatelessWidget {
  final DayPortion portion;
  final int currentDayNumber;
  final VoidCallback onMarkCompleted;
  final VoidCallback onUndoCompleted;

  /// Ticks a part (0..4) of the day's reading plan. The plan is shown inline
  /// only when this is provided.
  final ValueChanged<int>? onTogglePart;

  /// Opens the reading plan picker from the plan header.
  final VoidCallback? onCustomizePlan;

  /// Overrides the eyebrow label (e.g. "FIRST PORTION" before the start).
  final String? eyebrow;

  /// Whether the complete / undo button is shown.
  final bool showCompletionAction;

  const PortionCard({
    super.key,
    required this.portion,
    required this.currentDayNumber,
    required this.onMarkCompleted,
    required this.onUndoCompleted,
    this.onTogglePart,
    this.onCustomizePlan,
    this.eyebrow,
    this.showCompletionAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = portion.isCompleted;
    final isAr = AppLanguage.isArabic(context);

    final primaryRange = isAr ? portion.rangeDisplayAr : portion.rangeDisplay;
    final secondaryRange = isAr ? portion.rangeDisplay : portion.rangeDisplayAr;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(
          color: isCompleted ? AppColors.dustyGreen : AppColors.mistGray,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "${eyebrow ?? LocaleKeys.home.today_portion.tr()} • ${LocaleKeys.common.day_number.tr(args: [portion.dayNumber.toString()])}",
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.controlSurface,
                  borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  border: Border.all(color: AppColors.mistGray, width: 0.8),
                ),
                child: Text(
                  LocaleKeys.common.surah_count.tr(args: [portion.surahCount.toString()]),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.bodyGray,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main portion display
          Text(
            primaryRange,
            style: isAr
                ? AppTypography.arabicSurahTitle(AppColors.ink, 26)
                : theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.signalBlack,
                    fontWeight: FontWeight.w700,
                  ),
          ),
          const SizedBox(height: 4),

          // Secondary translation / transliteration
          if (secondaryRange.isNotEmpty)
            Text(
              secondaryRange,
              style: isAr
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    )
                  : AppTypography.scholarlyQuote(AppColors.textMuted, false).copyWith(
                      fontSize: 15,
                      fontStyle: FontStyle.normal,
                    ),
            ),
          const SizedBox(height: 10),

          // Size of the day's reading: pages and realistic time
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined,
                  size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ReadingFormat.pagesAndTime(
                      portion.pageCount, portion.estimatedMinutes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Reading plan: five parts that double as the progress tracker
          if (onTogglePart != null && !isCompleted) ...[
            ReadingPlan(
              portion: portion,
              onToggle: onTogglePart,
              onCustomize: onCustomizePlan,
              boxed: false,
            ),
            const SizedBox(height: 16),
          ],

          // Action button changes content and color in place without layout shift
          if (showCompletionAction)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isCompleted
                ? OutlinedButton.icon(
                    onPressed: onUndoCompleted,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.dustyGreen,
                      size: 20,
                    ),
                    label: Text(
                      LocaleKeys.home.completed_status.tr(),
                      style: const TextStyle(
                        color: AppColors.dustyGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.controlSurface,
                      side: const BorderSide(color: AppColors.dustyGreen, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onMarkCompleted,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(LocaleKeys.home.mark_as_completed.tr()),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
