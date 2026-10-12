import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_confirmation_sheet.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';

class AdjustPlanDialog extends StatefulWidget {
  final Challenge challenge;
  final Function(List<DayPortion> updatedPortions) onConfirm;

  const AdjustPlanDialog({
    super.key,
    required this.challenge,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required Challenge challenge,
    required Function(List<DayPortion> updatedPortions) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AdjustPlanDialog(
        challenge: challenge,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AdjustPlanDialog> createState() => _AdjustPlanDialogState();
}

class _AdjustPlanDialogState extends State<AdjustPlanDialog> {
  late List<DayPortion> _proposedPortions;
  bool _canAdjust = true;

  @override
  void initState() {
    super.initState();
    _calculateAdjustedPlan();
  }

  void _calculateAdjustedPlan() {
    final currentDay = widget.challenge.currentDayNumber;
    final portions = widget.challenge.portions;

    // If challenge expired or not active, adjustment cannot be performed
    if (widget.challenge.isExpired || currentDay > 7 || currentDay < 1) {
      _canAdjust = false;
      _proposedPortions = List.from(portions);
      return;
    }

    final remainingDays = <int>[];
    for (int d = currentDay; d <= 7; d++) {
      remainingDays.add(d);
    }

    if (remainingDays.isEmpty) {
      _canAdjust = false;
      _proposedPortions = List.from(portions);
      return;
    }

    // Historical record: retain past days (< currentDay) as-is
    final result = <DayPortion>[];
    for (final p in portions) {
      if (p.dayNumber < currentDay) {
        result.add(p);
      }
    }

    // Determine which traditional blocks have already been completed
    final completedBlocks = widget.challenge.completedBlockIndices;

    // Remaining traditional blocks to distribute
    final unreadBlocks = <DefaultPortionData>[];
    for (int i = 0; i < KhatmahConstants.traditionalSchedule.length; i++) {
      if (!completedBlocks.contains(i)) {
        unreadBlocks.add(KhatmahConstants.traditionalSchedule[i]);
      }
    }

    final totalUnread = unreadBlocks.length;
    final totalRemainingDays = remainingDays.length;

    int blockIndex = 0;
    for (int i = 0; i < totalRemainingDays; i++) {
      final dayNumber = remainingDays[i];
      final blocksForThisDay =
          ((totalUnread - blockIndex) / (totalRemainingDays - i)).ceil();
      final endIdx = (blockIndex + blocksForThisDay).clamp(0, totalUnread);

      final assigned = unreadBlocks.sublist(blockIndex, endIdx);
      blockIndex = endIdx;

      if (assigned.isNotEmpty) {
        final startSurah = assigned.first.startSurah;
        final endSurah = assigned.last.endSurah;
        final startSurahAr = assigned.first.startSurahAr;
        final endSurahAr = assigned.last.endSurahAr;
        final surahCount = assigned.fold(0, (sum, p) => sum + p.surahCount);

        // Check if portion differs from default traditional schedule
        final originalDefault = KhatmahConstants.traditionalSchedule[dayNumber - 1];
        final isDifferent = startSurah != originalDefault.startSurah ||
            endSurah != originalDefault.endSurah;

        result.add(
          DayPortion(
            dayNumber: dayNumber,
            startSurah: startSurah,
            endSurah: endSurah,
            startSurahAr: startSurahAr,
            endSurahAr: endSurahAr,
            surahCount: surahCount,
            isCompleted: false,
            isAdjusted: isDifferent,
          ),
        );
      }
    }

    _canAdjust = true;
    _proposedPortions = result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = widget.challenge.currentDayNumber;

    if (!_canAdjust) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          side: const BorderSide(color: AppColors.mistGray),
        ),
        title: Text(
          LocaleKeys.adjust_plan.concluded_title.tr(),
          style: AppTypography.appBarTitle(
            AppColors.signalBlack,
            AppLanguage.isArabic(context),
          ),
        ),
        content: Text(
          LocaleKeys.adjust_plan.concluded_desc.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.bodyGray,
            height: 1.45,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.adjust_plan.close.tr()),
          ),
        ],
      );
    }

    final isAr = AppLanguage.isArabic(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        side: const BorderSide(color: AppColors.mistGray),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      title: Text(
        LocaleKeys.adjust_plan.title.tr(),
        style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.adjust_plan.description.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.bodyGray,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.adjust_plan.preview_title.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._proposedPortions.map((p) {
                final isCompleted = p.isCompleted;
                final isUpcoming = p.dayNumber >= currentDay;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.controlSurface
                        : (p.isAdjusted
                            ? AppColors.secondaryNeutral
                            : AppColors.paper),
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    border: Border.all(
                      color: p.isAdjusted
                          ? AppColors.secondaryBorder
                          : AppColors.mistGray,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        LocaleKeys.common.day_number.tr(args: [p.dayNumber.toString()]),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isCompleted
                              ? AppColors.textMuted
                              : AppColors.signalBlack,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAr ? p.rangeDisplayAr : p.rangeDisplay,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted
                                ? AppColors.textMuted
                                : AppColors.bodyGray,
                            fontWeight: isUpcoming
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.ink,
                        )
                      else if (p.isAdjusted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.controlSurface,
                            borderRadius: BorderRadius.circular(AppColors.standardRadius),
                            border: Border.all(color: AppColors.mistGray),
                          ),
                          child: Text(
                            LocaleKeys.common.adjusted.tr(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  ),
                ),
                child: Text(LocaleKeys.adjust_plan.cancel.tr()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await AppConfirmationSheet.show(
                    context,
                    title: LocaleKeys.confirmation.apply_plan_title.tr(),
                    message: LocaleKeys.confirmation.apply_plan_desc.tr(),
                    confirmLabel: LocaleKeys.adjust_plan.apply_plan.tr(),
                    cancelLabel: LocaleKeys.common.cancel.tr(),
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.dustyGreen,
                  );
                  if (confirmed && context.mounted) {
                    widget.onConfirm(_proposedPortions);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  ),
                ),
                child: Text(LocaleKeys.adjust_plan.apply_plan.tr()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
