import 'package:flutter/material.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';

class AdjustPlanDialog extends StatefulWidget {
  final Challenge challenge;
  final Function(List<DayPortion> updatedPortions) onConfirm;
  final VoidCallback? onResetToTraditional;

  const AdjustPlanDialog({
    super.key,
    required this.challenge,
    required this.onConfirm,
    this.onResetToTraditional,
  });

  static Future<void> show(
    BuildContext context, {
    required Challenge challenge,
    required Function(List<DayPortion> updatedPortions) onConfirm,
    VoidCallback? onResetToTraditional,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AdjustPlanDialog(
        challenge: challenge,
        onConfirm: onConfirm,
        onResetToTraditional: onResetToTraditional,
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
    // in past days (days < currentDay)
    final completedPastCount =
        portions.where((p) => p.dayNumber < currentDay && p.isCompleted).length;

    // Remaining traditional blocks to distribute
    final unreadBlocks =
        KhatmahConstants.traditionalSchedule.sublist(completedPastCount);

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

    result.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    _proposedPortions = result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = widget.challenge.currentDayNumber;

    if (!_canAdjust) {
      return AlertDialog(
        title: Text(
          'Khatmah Concluded',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
        content: Text(
          'Your 7-day challenge period has ended. The plan cannot be adjusted because there are no active days remaining.\n\nYou can start a new 7-day khatmah from the home or progress screen anytime.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.deepBrown,
            height: 1.4,
          ),
        ),
        actions: [
          if (widget.onResetToTraditional != null)
            TextButton(
              onPressed: () {
                widget.onResetToTraditional?.call();
                Navigator.of(context).pop();
              },
              child: const Text('Reset Schedule'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(
        'Adjust Remaining Plan',
        style: AppTypography.appBarTitle(AppColors.deepBrown),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We redistributed your unread portions consecutively across the remaining days of your khatmah. Completed portions are preserved.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepBrown,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'NEW SCHEDULE PREVIEW',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.brassGold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ..._proposedPortions.map((p) {
                final isCompleted = p.isCompleted;
                final isUpcoming = p.dayNumber >= currentDay;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.parchment
                        : (p.isAdjusted
                            ? AppColors.brassGold.withValues(alpha: 0.06)
                            : AppColors.parchmentLight),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: p.isAdjusted
                          ? AppColors.brassGold.withValues(alpha: 0.4)
                          : AppColors.softSand,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Day ${p.dayNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isCompleted
                              ? AppColors.textMuted
                              : AppColors.deepBrown,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.rangeDisplay,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted
                                ? AppColors.textMuted
                                : AppColors.deepBrown,
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
                          color: AppColors.brassGold,
                        )
                      else if (p.isAdjusted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brassGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Adjusted',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: AppColors.brassGoldDark,
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
        if (widget.onResetToTraditional != null)
          TextButton(
            onPressed: () {
              widget.onResetToTraditional!.call();
              Navigator.of(context).pop();
            },
            child: const Text('Reset to Traditional'),
          ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_proposedPortions);
            Navigator.of(context).pop();
          },
          child: const Text('Apply Plan'),
        ),
      ],
    );
  }
}
