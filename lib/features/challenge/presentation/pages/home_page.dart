import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_providers.dart';
import '../widgets/adjust_plan_dialog.dart';
import '../widgets/behind_schedule_banner.dart';
import '../widgets/challenge_completed_dialog.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/portion_card.dart';
import '../widgets/schedule_preview_strip.dart';

class HomePage extends ConsumerWidget {
  final VoidCallback onNavigateToProgress;
  final VoidCallback onStartNewKhatmah;

  const HomePage({
    super.key,
    required this.onNavigateToProgress,
    required this.onStartNewKhatmah,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeStateProvider);
    final notifier = ref.read(challengeStateProvider.notifier);
    final challenge = state.challenge;
    final theme = Theme.of(context);

    // Listen for completion celebration trigger
    ref.listen(challengeStateProvider, (prev, next) {
      if (next.showCelebration && !(prev?.showCelebration ?? false)) {
        ChallengeCompletedDialog.show(
          context,
          onStartAnother: () {
            notifier.dismissCelebration();
            onStartNewKhatmah();
          },
          onDismiss: () {
            notifier.dismissCelebration();
          },
        );
      }
    });

    if (challenge == null) {
      return Scaffold(
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

    final displayDay = challenge.displayDayNumber;
    final daysRemaining = challenge.daysRemaining;
    DayPortion todayPortion = challenge.portions.first;
    for (final p in challenge.portions) {
      if (p.dayNumber == displayDay) {
        todayPortion = p;
        break;
      }
    }

    final isTodayCompleted = todayPortion.isCompleted;
    final isBehindSchedule = challenge.isBehindSchedule;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              "30 Juz' in 7 Days",
              style: AppTypography.appBarTitle(AppColors.deepBrown),
            ),
            const SizedBox(height: 2),
            Text(
              'Day $displayDay of 7 • $daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.brassGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brassGold,
        backgroundColor: AppColors.parchmentLight,
        onRefresh: () async {
          await notifier.loadInitialData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gentle behind-schedule banner if overdue portions exist
              if (isBehindSchedule) ...[
                BehindScheduleBanner(
                  missedCount: challenge.missedPortionsCount,
                  daysRemaining: daysRemaining,
                  onContinueToday: () {
                    // Scroll to today's portion or no-op
                  },
                  onAdjustPlan: () {
                    AdjustPlanDialog.show(
                      context,
                      challenge: challenge,
                      onConfirm: (newPortions) {
                        notifier.adjustRemainingPlan(newPortions);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Today's Portion Main Card
              PortionCard(
                portion: todayPortion,
                currentDayNumber: displayDay,
                onMarkCompleted: () {
                  notifier.markDayCompleted(todayPortion.dayNumber);
                },
                onUndoCompleted: () {
                  notifier.undoDayCompletion(todayPortion.dayNumber);
                },
              ),
              const SizedBox(height: 16),

              // Completed-today feedback message
              if (isTodayCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.parchmentLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.softSand),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.nights_stay_outlined,
                        color: AppColors.brassGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayDay < 7
                              ? 'Come back tomorrow for Day ${displayDay + 1}'
                              : 'Alhamdulillah, you have reached the final day!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.deepBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 4),
              ],

              // Overall Progress Card
              OverallProgressCard(
                completedCount: challenge.completedPortionsCount,
                percentage: challenge.completionPercentage,
              ),
              const SizedBox(height: 20),

              // Compact 7-Day Strip
              SchedulePreviewStrip(
                portions: challenge.portions,
                currentDayNumber: displayDay,
                onSelectPortion: (portion) {
                  final portionDate = challenge.startDate.add(
                    Duration(days: portion.dayNumber - 1),
                  );
                  DayDetailSheet.show(
                    context,
                    portion: portion,
                    portionDate: portionDate,
                    currentDayNumber: displayDay,
                    onToggleCompletion: () {
                      if (portion.isCompleted) {
                        notifier.undoDayCompletion(portion.dayNumber);
                      } else {
                        notifier.markDayCompleted(portion.dayNumber);
                      }
                    },
                  );
                },
                onViewAll: onNavigateToProgress,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
