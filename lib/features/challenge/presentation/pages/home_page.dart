import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_providers.dart';
import '../widgets/adjust_plan_dialog.dart';
import '../widgets/behind_schedule_banner.dart';
import '../widgets/challenge_completed_dialog.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/portion_card.dart';
import '../widgets/schedule_preview_strip.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToProgress;
  final VoidCallback onStartNewKhatmah;

  const HomePage({
    super.key,
    required this.onNavigateToProgress,
    required this.onStartNewKhatmah,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isBehindScheduleBannerDismissed = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            widget.onStartNewKhatmah();
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
                onPressed: widget.onStartNewKhatmah,
                child: const Text('Start 7-Day Khatmah'),
              ),
            ],
          ),
        ),
      );
    }

    final isAllCompleted = challenge.isAllPortionsCompleted;
    final isExpired = challenge.isExpired;
    final isActive = challenge.isActive;

    // Header title and subtitle based on lifecycle state
    String subtitleText;
    if (isAllCompleted) {
      subtitleText = 'Khatmah Complete • Alhamdulillah! 🎉';
    } else if (isExpired) {
      subtitleText = 'Khatmah Concluded • ${challenge.completedPortionsCount} of 7 portions';
    } else {
      final currentDay = challenge.currentDayNumber;
      final daysRemaining = challenge.daysRemaining;
      subtitleText =
          'Day $currentDay of 7 • $daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining';
    }

    // Determine today's portion during an active challenge
    final displayDay = challenge.displayDayNumber;
    DayPortion todayPortion = challenge.portions.first;
    for (final p in challenge.portions) {
      if (p.dayNumber == displayDay) {
        todayPortion = p;
        break;
      }
    }

    final isTodayCompleted = todayPortion.isCompleted;
    final isBehindSchedule = challenge.isBehindSchedule &&
        challenge.daysRemaining > 0 &&
        !_isBehindScheduleBannerDismissed;

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
              subtitleText,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isAllCompleted
                    ? AppColors.brassGoldDark
                    : (isExpired ? AppColors.textMuted : AppColors.brassGold),
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
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. If challenge ended with ALL portions completed
              if (isAllCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.brassGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.brassGold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: AppColors.brassGold,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Alhamdulillah! Khatmah Complete',
                        style: AppTypography.appBarTitle(AppColors.brassGoldDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You successfully completed all 7 daily portions of the Holy Qur\'an.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.deepBrown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Started ${AppDateUtils.formatDate(challenge.startDate)} • Completed ${AppDateUtils.formatDate(challenge.endDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: widget.onStartNewKhatmah,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Start Another 7-Day Khatmah'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ]
              // 2. If challenge period ended (expired) without completing all portions
              else if (isExpired) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.parchmentLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.softSand,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.history_edu_rounded,
                        color: AppColors.brassGold,
                        size: 38,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '7-Day Khatmah Concluded',
                        style: AppTypography.appBarTitle(AppColors.deepBrown),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your 7-day challenge period ended on ${AppDateUtils.formatDate(challenge.endDate)}. You completed ${challenge.completedPortionsCount} of 7 daily portions.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.deepBrown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'May Allah reward your recitation and sincere intention. Start fresh anytime with a new 7-day khatmah.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: widget.onStartNewKhatmah,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Start a New 7-Day Khatmah'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ]
              // 3. Active challenge tracking
              else if (isActive) ...[
                // Gentle behind-schedule banner if overdue portions exist
                if (isBehindSchedule) ...[
                  BehindScheduleBanner(
                    missedCount: challenge.missedPortionsCount,
                    daysRemaining: challenge.daysRemaining,
                    onContinueToday: () {
                      setState(() {
                        _isBehindScheduleBannerDismissed = true;
                      });
                      _scrollController.animateTo(
                        100.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      );
                    },
                    onAdjustPlan: () {
                      AdjustPlanDialog.show(
                        context,
                        challenge: challenge,
                        onConfirm: (newPortions) {
                          notifier.adjustRemainingPlan(newPortions);
                        },
                        onResetToTraditional: () {
                          notifier.resetToTraditionalSchedule();
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Alhamdulillah! Day ${todayPortion.dayNumber} marked complete.',
                        ),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
                currentDayNumber: isActive ? displayDay : (isAllCompleted ? 8 : 8),
                onSelectPortion: (portion) {
                  final portionDate = challenge.startDate.add(
                    Duration(days: portion.dayNumber - 1),
                  );
                  DayDetailSheet.show(
                    context,
                    portion: portion,
                    portionDate: portionDate,
                    currentDayNumber: isActive ? displayDay : 99,
                    onToggleCompletion: () {
                      if (portion.isCompleted) {
                        notifier.undoDayCompletion(portion.dayNumber);
                      } else {
                        notifier.markDayCompleted(portion.dayNumber);
                      }
                    },
                  );
                },
                onViewAll: widget.onNavigateToProgress,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
