import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/day_portion.dart';

class DayDetailSheet extends StatelessWidget {
  final DayPortion portion;
  final DateTime portionDate;
  final int currentDayNumber;
  final VoidCallback onToggleCompletion;

  const DayDetailSheet({
    super.key,
    required this.portion,
    required this.portionDate,
    required this.currentDayNumber,
    required this.onToggleCompletion,
  });

  static Future<void> show(
    BuildContext context, {
    required DayPortion portion,
    required DateTime portionDate,
    required int currentDayNumber,
    required VoidCallback onToggleCompletion,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => DayDetailSheet(
        portion: portion,
        portionDate: portionDate,
        currentDayNumber: currentDayNumber,
        onToggleCompletion: onToggleCompletion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);

    final isCompleted = portion.isCompleted;
    final isToday = portion.dayNumber == currentDayNumber;
    final isMissed = portion.dayNumber < currentDayNumber && !isCompleted;

    final primaryRange = isAr ? portion.rangeDisplayAr : portion.rangeDisplay;
    final secondaryRange = isAr ? portion.rangeDisplay : portion.rangeDisplayAr;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mistGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    LocaleKeys.common.day_x_of_7.tr(args: [portion.dayNumber.toString()]),
                    style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.secondaryNeutral
                        : (isToday
                            ? AppColors.ink
                            : AppColors.controlSurface),
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    border: Border.all(
                      color: isCompleted || isToday
                          ? AppColors.ink
                          : AppColors.mistGray,
                    ),
                  ),
                  child: Text(
                    isCompleted
                        ? LocaleKeys.common.completed_check.tr()
                        : (isToday
                            ? LocaleKeys.common.today.tr()
                            : (isMissed
                                ? LocaleKeys.common.missed.tr()
                                : AppDateUtils.formatShortDate(portionDate))),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isToday && !isCompleted
                          ? AppColors.buttonText
                          : (isMissed && !isCompleted
                              ? AppColors.textMuted
                              : AppColors.ink),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Portions display
            Text(
              primaryRange,
              style: isAr
                  ? AppTypography.arabicSurahTitle(AppColors.ink, 24)
                  : theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.signalBlack,
                      fontWeight: FontWeight.w700,
                    ),
            ),
            if (secondaryRange.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                secondaryRange,
                style: isAr
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      )
                    : AppTypography.scholarlyQuote(AppColors.textMuted, false).copyWith(
                        fontSize: 15,
                        fontStyle: FontStyle.normal,
                      ),
              ),
            ],
            const SizedBox(height: 18),

            // Info rows
            _buildInfoRow(
              context,
              label: LocaleKeys.common.surahs.tr(),
              value: LocaleKeys.common.surah_count.tr(args: [portion.surahCount.toString()]),
            ),
            const Divider(height: 18),
            _buildInfoRow(
              context,
              label: isAr ? 'التاريخ المقرر' : 'Scheduled Date',
              value: AppDateUtils.formatDate(portionDate),
            ),
            if (portion.isCompleted && portion.completedAt != null) ...[
              const Divider(height: 18),
              _buildInfoRow(
                context,
                label: isAr ? 'تاريخ الإكمال' : 'Completed On',
                value: AppDateUtils.formatDate(portion.completedAt!),
              ),
            ],
            if (portion.isAdjusted) ...[
              const Divider(height: 18),
              _buildInfoRow(
                context,
                label: isAr ? 'حالة الحزب' : 'Schedule Status',
                value: isAr ? 'مُعدل ليناسب الأيام المتبقية' : 'Adjusted to fit remaining window',
              ),
            ],
            // Action button (today only, or undo if completed)
            if (isToday) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: isCompleted
                    ? OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onToggleCompletion();
                        },
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text(LocaleKeys.home.undo.tr()),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onToggleCompletion();
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(LocaleKeys.home.mark_as_completed.tr()),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
              ),
            ] else if (isCompleted) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onToggleCompletion();
                  },
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: Text(LocaleKeys.home.undo.tr()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.bodyGray,
            ),
          ),
        ),
      ],
    );
  }
}
