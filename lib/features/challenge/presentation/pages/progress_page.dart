import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_providers.dart';
import '../widgets/day_detail_sheet.dart';

enum DayStatus { completed, today, upcoming, missed }

class ProgressPage extends ConsumerWidget {
  final VoidCallback onStartNewKhatmah;

  const ProgressPage({
    super.key,
    required this.onStartNewKhatmah,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeStateProvider);
    final notifier = ref.read(challengeStateProvider.notifier);
    final challenge = state.challenge;
    final theme = Theme.of(context);

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your 7-Day Journey')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No active khatmah in progress',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onStartNewKhatmah,
                child: const Text('Start 7-Day Khatmah'),
              ),
            ],
          ),
        ),
      );
    }

    final currentDay = challenge.currentDayNumber;
    final completedCount = challenge.completedPortionsCount;
    final isFinished = challenge.isAllPortionsCompleted || challenge.isExpired;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your 7-Day Journey',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
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
                        '$completedCount / 7 portions completed',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepBrown,
                        ),
                      ),
                      Text(
                        '${challenge.completionPercentInt}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.brassGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: challenge.completionPercentage.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppColors.softSand.withValues(alpha: 0.35),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brassGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Started ${AppDateUtils.formatDate(challenge.startDate)} • Ends ${AppDateUtils.formatDate(challenge.endDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Finished Celebration / Conclusion Banner
            if (isFinished) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: challenge.isAllPortionsCompleted
                      ? AppColors.brassGold.withValues(alpha: 0.09)
                      : AppColors.parchmentLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: challenge.isAllPortionsCompleted
                        ? AppColors.brassGold.withValues(alpha: 0.4)
                        : AppColors.softSand,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      challenge.isAllPortionsCompleted
                          ? 'Alhamdulillah Khatmah Complete'
                          : '7-Day Khatmah Period Ended',
                      style: AppTypography.appBarTitle(
                        challenge.isAllPortionsCompleted
                            ? AppColors.brassGoldDark
                            : AppColors.deepBrown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.isAllPortionsCompleted
                          ? 'You successfully recited all seven portions of the Qur\'an.'
                          : 'The 7-day challenge period ended. You completed $completedCount of 7 daily portions.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.deepBrown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: onStartNewKhatmah,
                      child: Text(
                        challenge.isAllPortionsCompleted
                            ? 'Start Another 7-Day Khatmah'
                            : 'Start a New 7-Day Khatmah',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              'SEVEN-DAY TIMELINE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.brassGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // 7 Days Timeline List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: challenge.portions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final portion = challenge.portions[index];
                final portionDate = challenge.startDate.add(Duration(days: index));

                DayStatus status;
                if (portion.isCompleted) {
                  status = DayStatus.completed;
                } else if (portion.dayNumber == currentDay) {
                  status = DayStatus.today;
                } else if (portion.dayNumber < currentDay) {
                  status = DayStatus.missed;
                } else {
                  status = DayStatus.upcoming;
                }

                return _buildTimelineCard(
                  context,
                  portion: portion,
                  portionDate: portionDate,
                  status: status,
                  onTap: () {
                    DayDetailSheet.show(
                      context,
                      portion: portion,
                      portionDate: portionDate,
                      currentDayNumber: currentDay,
                      onToggleCompletion: () {
                        if (portion.isCompleted) {
                          notifier.undoDayCompletion(portion.dayNumber);
                        } else {
                          notifier.markDayCompleted(portion.dayNumber);
                        }
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context, {
    required DayPortion portion,
    required DateTime portionDate,
    required DayStatus status,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    Color borderColor = AppColors.softSand;
    Color bgColor = AppColors.parchmentLight;
    Widget statusBadge;

    switch (status) {
      case DayStatus.completed:
        borderColor = AppColors.brassGold;
        bgColor = AppColors.cardSurface;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brassGold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.brassGold.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 13, color: AppColors.brassGoldDark),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.brassGoldDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
        break;

      case DayStatus.today:
        borderColor = AppColors.brassGold;
        bgColor = AppColors.cardSurface;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brassGold,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '● Today',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        break;

      case DayStatus.missed:
        borderColor = AppColors.statusMissed.withValues(alpha: 0.4);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.statusMissed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Missed',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.statusMissed,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        break;

      case DayStatus.upcoming:
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.softSand),
          ),
          child: Text(
            '○ Upcoming',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: (status == DayStatus.today || status == DayStatus.completed) ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Day circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: status == DayStatus.today
                    ? AppColors.brassGold
                    : (status == DayStatus.completed
                        ? AppColors.brassGold.withValues(alpha: 0.15)
                        : AppColors.parchment),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (status == DayStatus.today || status == DayStatus.completed)
                      ? AppColors.brassGold
                      : AppColors.softSand,
                  width: status == DayStatus.completed ? 1.5 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: status == DayStatus.completed
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.brassGoldDark,
                      size: 20,
                    )
                  : Text(
                      '${portion.dayNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: status == DayStatus.today
                            ? AppColors.textLight
                            : AppColors.deepBrown,
                      ),
                    ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppDateUtils.formatDate(portionDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      statusBadge,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    portion.rangeDisplay,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${portion.surahCount} surahs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: status == DayStatus.completed
                  ? AppColors.brassGold
                  : AppColors.softSand,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
