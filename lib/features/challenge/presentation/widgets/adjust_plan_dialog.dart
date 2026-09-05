import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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

  @override
  void initState() {
    super.initState();
    _calculateAdjustedPlan();
  }

  void _calculateAdjustedPlan() {
    final currentDay = widget.challenge.currentDayNumber;
    final portions = widget.challenge.portions;

    // Days from currentDay up to 7
    final remainingDays = <int>[];
    for (int d = currentDay; d <= 7; d++) {
      remainingDays.add(d);
    }

    // Incomplete portions
    final incompletePortions = portions.where((p) => !p.isCompleted).toList();

    if (remainingDays.isEmpty || incompletePortions.isEmpty) {
      _proposedPortions = List.from(portions);
      return;
    }

    // Retain completed portions untouched
    final result = <DayPortion>[];
    for (final p in portions) {
      if (p.isCompleted || p.dayNumber < currentDay) {
        result.add(p);
      }
    }

    // Redistribute incomplete portions across remaining days
    // If we have more incomplete portions than remaining days, combine the backlog
    // into the remaining schedule smoothly
    final totalIncomplete = incompletePortions.length;
    final totalRemainingDays = remainingDays.length;

    int incompleteIndex = 0;
    for (int i = 0; i < totalRemainingDays; i++) {
      final dayNumber = remainingDays[i];
      // Calculate how many portions to assign to this day
      final portionsForThisDay =
          ((totalIncomplete - incompleteIndex) / (totalRemainingDays - i))
              .ceil();
      final endIdx =
          (incompleteIndex + portionsForThisDay).clamp(0, totalIncomplete);

      final assigned = incompletePortions.sublist(incompleteIndex, endIdx);
      incompleteIndex = endIdx;

      if (assigned.isNotEmpty) {
        final startSurah = assigned.first.startSurah;
        final endSurah = assigned.last.endSurah;
        final startSurahAr = assigned.first.startSurahAr;
        final endSurahAr = assigned.last.endSurahAr;
        final surahCount = assigned.fold(0, (sum, p) => sum + p.surahCount);

        result.add(
          DayPortion(
            dayNumber: dayNumber,
            startSurah: startSurah,
            endSurah: endSurah,
            startSurahAr: startSurahAr,
            endSurahAr: endSurahAr,
            surahCount: surahCount,
            isCompleted: false,
            isAdjusted: true,
          ),
        );
      }
    }

    // Sort by day number
    result.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    _proposedPortions = result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDay = widget.challenge.currentDayNumber;

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
                'We redistributed your unfinished portions evenly across the remaining days of your 7-day khatmah. Your completed days are not changed.',
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
