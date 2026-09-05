import 'package:flutter/material.dart';
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
      builder: (_) => DayDetailSheet(
        portion: portion,
        portionDate: portionDate,
        currentDayNumber: currentDayNumber,
        onToggleCompletion: onToggleCompletion,
      ),
    );
  }

  void _confirmUpcomingCompletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Mark ahead of schedule?',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
        content: Text(
          'Day ${portion.dayNumber} is scheduled for ${AppDateUtils.formatDate(portionDate)}. Would you like to record this portion as completed now ahead of schedule?',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Upcoming'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              onToggleCompletion();
            },
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );
  }

  void _confirmMissedCompletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Catch up on Day ${portion.dayNumber}?',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
        content: Text(
          'Record Day ${portion.dayNumber} (${portion.rangeDisplay}) as finished. Alhamdulillah for continuing your recitation!',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              onToggleCompletion();
            },
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = portion.isCompleted;
    final isToday = portion.dayNumber == currentDayNumber;
    final isUpcoming = portion.dayNumber > currentDayNumber;
    final isMissed = portion.dayNumber < currentDayNumber && !isCompleted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.softSand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${portion.dayNumber} of 7',
                style: AppTypography.appBarTitle(AppColors.deepBrown),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.brassGold.withValues(alpha: 0.15)
                      : (isToday
                          ? AppColors.brassGold
                          : (isMissed
                              ? AppColors.statusMissed.withValues(alpha: 0.1)
                              : AppColors.parchment)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted || isToday
                        ? AppColors.brassGold
                        : (isMissed
                            ? AppColors.statusMissed.withValues(alpha: 0.4)
                            : AppColors.softSand),
                  ),
                ),
                child: Text(
                  isCompleted
                      ? 'Completed ✓'
                      : (isToday
                          ? 'Today'
                          : (isMissed
                              ? 'Missed Portion'
                              : AppDateUtils.formatShortDate(portionDate))),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday && !isCompleted
                        ? AppColors.textLight
                        : (isMissed && !isCompleted
                            ? AppColors.statusMissed
                            : AppColors.brassGoldDark),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Portions display
          Text(
            portion.rangeDisplay,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.deepBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (portion.startSurahAr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              portion.rangeDisplayAr,
              style: AppTypography.scholarlyQuote(AppColors.brassGold).copyWith(
                fontSize: 16,
                fontStyle: FontStyle.normal,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Info rows
          _buildInfoRow(
            context,
            label: 'Surahs Included',
            value: '${portion.surahCount} surahs',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            context,
            label: 'Scheduled Date',
            value: AppDateUtils.formatDate(portionDate),
          ),
          if (portion.completedAt != null) ...[
            const Divider(height: 20),
            _buildInfoRow(
              context,
              label: 'Completed On',
              value: AppDateUtils.formatDate(portion.completedAt!),
            ),
          ],
          if (portion.isAdjusted) ...[
            const Divider(height: 20),
            _buildInfoRow(
              context,
              label: 'Schedule Status',
              value: 'Adjusted to fit remaining window',
            ),
          ],
          const SizedBox(height: 28),

          // Action button
          SizedBox(
            width: double.infinity,
            child: isCompleted
                ? OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onToggleCompletion();
                    },
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: const Text('Undo completion'),
                  )
                : (isUpcoming
                    ? OutlinedButton.icon(
                        onPressed: () => _confirmUpcomingCompletion(context),
                        icon: const Icon(Icons.fast_forward_rounded, size: 18),
                        label: Text('Mark Day ${portion.dayNumber} ahead of schedule'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brassGoldDark,
                          side: const BorderSide(color: AppColors.brassGold),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    : (isMissed
                        ? ElevatedButton.icon(
                            onPressed: () => _confirmMissedCompletion(context),
                            icon: const Icon(Icons.task_alt_rounded, size: 18),
                            label: Text('Catch up: Mark Day ${portion.dayNumber} completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brassGold,
                              foregroundColor: AppColors.textLight,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onToggleCompletion();
                            },
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('Mark as completed'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ))),
          ),
        ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.deepBrown,
          ),
        ),
      ],
    );
  }
}
