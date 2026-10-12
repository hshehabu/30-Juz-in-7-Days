import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_confirmation_sheet.dart';
import '../../../../core/widgets/countdown_undo_toast.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_providers.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../widgets/adjust_plan_dialog.dart';
import '../widgets/behind_schedule_banner.dart';
import '../widgets/challenge_completed_dialog.dart';
import '../widgets/day_detail_sheet.dart';
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
    final isAr = AppLanguage.isArabic(context);

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
                LocaleKeys.home.concluded_desc.tr(),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onStartNewKhatmah,
                child: Text(LocaleKeys.onboarding.step1_cta.tr()),
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
      subtitleText = '${LocaleKeys.completion_dialog.title.tr()} 🎉';
    } else if (isExpired) {
      subtitleText =
          '${LocaleKeys.home.concluded_title.tr()} • ${challenge.completedPortionsCount}/7';
    } else {
      final currentDay = challenge.currentDayNumber;
      final daysRemaining = challenge.daysRemaining;
      subtitleText =
          '${LocaleKeys.common.day_x_of_7.tr(args: [currentDay.toString()])} • ${LocaleKeys.progress.days_left.tr(args: [daysRemaining.toString()])}';
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

    final isBehindSchedule =
        challenge.isBehindSchedule && !_isBehindScheduleBannerDismissed;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              LocaleKeys.common.app_name.tr(),
              style: AppTypography.appBarTitle(AppColors.deepBrown, isAr),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.controlSurface,
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    border: Border.all(
                      color: AppColors.ink,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: AppColors.ink,
                        size: 38,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LocaleKeys.completion_dialog.title.tr(),
                        style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocaleKeys.completion_dialog.subtitle.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.bodyGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${AppDateUtils.formatDate(challenge.startDate, context.locale.languageCode)} • ${AppDateUtils.formatDate(challenge.endDate, context.locale.languageCode)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: widget.onStartNewKhatmah,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(LocaleKeys.completion_dialog.start_another.tr()),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.controlSurface,
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    border: Border.all(
                      color: AppColors.mistGray,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.history_edu_rounded,
                        color: AppColors.ink,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LocaleKeys.home.concluded_title.tr(),
                        style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocaleKeys.home.concluded_desc.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.bodyGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocaleKeys.completion_dialog.dua.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: widget.onStartNewKhatmah,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(LocaleKeys.home.start_new.tr()),
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
                    onContinueToday: () async {
                      final confirmed = await AppConfirmationSheet.show(
                        context,
                        title: LocaleKeys.confirmation.continue_today_title.tr(),
                        message: LocaleKeys.confirmation.continue_today_desc.tr(),
                        confirmLabel: LocaleKeys.home.catch_up.tr(),
                        cancelLabel: LocaleKeys.common.cancel.tr(),
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.dustyGreen,
                      );
                      if (!confirmed || !context.mounted) return;

                      setState(() {
                        _isBehindScheduleBannerDismissed = true;
                      });
                      _scrollController.animateTo(
                        100.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      );
                      CountdownUndoToast.show(
                        context,
                        message: LocaleKeys.confirmation.continue_today_toast.tr(),
                        undoLabel: LocaleKeys.confirmation.undo_action.tr(),
                        onUndo: () {
                          setState(() {
                            _isBehindScheduleBannerDismissed = false;
                          });
                        },
                      );
                    },
                    onAdjustPlan: () {
                      AdjustPlanDialog.show(
                        context,
                        challenge: challenge,
                        onConfirm: (newPortions) {
                          notifier.adjustRemainingPlan(newPortions);
                          if (mounted) {
                            setState(() {
                              _isBehindScheduleBannerDismissed = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LocaleKeys.confirmation.apply_plan_toast.tr()),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ] else if (challenge.isBehindSchedule &&
                    _isBehindScheduleBannerDismissed) ...[
                  // Collapsed sleek bar: user never loses access to adjust plan banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.controlSurface,
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      border: Border.all(color: AppColors.mistGray),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.dustyGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleKeys.home.behind_schedule_title.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.signalBlack,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            AdjustPlanDialog.show(
                              context,
                              challenge: challenge,
                              onConfirm: (newPortions) {
                                notifier.adjustRemainingPlan(newPortions);
                                if (mounted) {
                                  setState(() {
                                    _isBehindScheduleBannerDismissed = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocaleKeys.confirmation.apply_plan_toast.tr()),
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            LocaleKeys.home.adjust_plan.tr(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.unfold_more_rounded, size: 18),
                          tooltip: LocaleKeys.confirmation.show_banner.tr(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppColors.bodyGray,
                          onPressed: () {
                            setState(() {
                              _isBehindScheduleBannerDismissed = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Today's Portion Main Card
                PortionCard(
                  portion: todayPortion,
                  currentDayNumber: displayDay,
                  onMarkCompleted: () async {
                    final confirmed = await AppConfirmationSheet.show(
                      context,
                      title: LocaleKeys.confirmation.mark_completed_title.tr(),
                      message: LocaleKeys.confirmation.mark_completed_desc.tr(
                        args: [todayPortion.dayNumber.toString()],
                      ),
                      confirmLabel: LocaleKeys.confirmation.mark_completed_confirm.tr(),
                      cancelLabel: LocaleKeys.common.cancel.tr(),
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.dustyGreen,
                    );
                    if (!confirmed || !context.mounted) return;

                    await notifier.markDayCompleted(todayPortion.dayNumber);

                    if (!context.mounted) return;
                    CountdownUndoToast.show(
                      context,
                      message:
                          '${LocaleKeys.common.alhamdulillah.tr()} • ${LocaleKeys.common.day_number.tr(args: [todayPortion.dayNumber.toString()])} ${LocaleKeys.common.completed.tr()}',
                      undoLabel: LocaleKeys.confirmation.undo_action.tr(),
                      onUndo: () {
                        notifier.undoDayCompletion(todayPortion.dayNumber);
                      },
                    );
                  },
                  onUndoCompleted: () async {
                    final confirmed = await AppConfirmationSheet.show(
                      context,
                      title: LocaleKeys.confirmation.undo_title.tr(),
                      message: LocaleKeys.confirmation.undo_desc.tr(),
                      confirmLabel: LocaleKeys.confirmation.undo_confirm.tr(),
                      cancelLabel: LocaleKeys.common.cancel.tr(),
                      isDestructive: true,
                      icon: Icons.undo_rounded,
                    );
                    if (!confirmed || !context.mounted) return;

                    notifier.undoDayCompletion(todayPortion.dayNumber);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Unified 7-Day Khatmah Progress Card
              SchedulePreviewStrip(
                portions: challenge.portions,
                currentDayNumber: isActive ? displayDay : (isAllCompleted ? 8 : 8),
                completedCount: challenge.completedPortionsCount,
                percentage: challenge.completionPercentage,
                onSelectPortion: (portion) {
                  final portionDate = challenge.startDate.add(
                    Duration(days: portion.dayNumber - 1),
                  );
                  DayDetailSheet.show(
                    context,
                    portion: portion,
                    portionDate: portionDate,
                    currentDayNumber: isActive ? displayDay : 99,
                    onToggleCompletion: () async {
                      if (portion.isCompleted) {
                        final confirmed = await AppConfirmationSheet.show(
                          context,
                          title: LocaleKeys.confirmation.undo_title.tr(),
                          message: LocaleKeys.confirmation.undo_desc.tr(),
                          confirmLabel: LocaleKeys.confirmation.undo_confirm.tr(),
                          cancelLabel: LocaleKeys.common.cancel.tr(),
                          isDestructive: true,
                          icon: Icons.undo_rounded,
                        );
                        if (confirmed && context.mounted) {
                          notifier.undoDayCompletion(portion.dayNumber);
                        }
                      } else {
                        final confirmed = await AppConfirmationSheet.show(
                          context,
                          title: LocaleKeys.confirmation.mark_completed_title.tr(),
                          message: LocaleKeys.confirmation.mark_completed_desc.tr(
                            args: [portion.dayNumber.toString()],
                          ),
                          confirmLabel: LocaleKeys.confirmation.mark_completed_confirm.tr(),
                          cancelLabel: LocaleKeys.common.cancel.tr(),
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.dustyGreen,
                        );
                        if (confirmed && context.mounted) {
                          await notifier.markDayCompleted(portion.dayNumber);
                          if (!context.mounted) return;
                          CountdownUndoToast.show(
                            context,
                            message:
                                '${LocaleKeys.common.alhamdulillah.tr()} • ${LocaleKeys.common.day_number.tr(args: [portion.dayNumber.toString()])} ${LocaleKeys.common.completed.tr()}',
                            undoLabel: LocaleKeys.confirmation.undo_action.tr(),
                            onUndo: () {
                              notifier.undoDayCompletion(portion.dayNumber);
                            },
                          );
                        }
                      }
                    },
                  );
                },
                onViewAll: widget.onNavigateToProgress,
              ),
              const SizedBox(height: 20),

              // Spiritual Foundation / Sunnah Hadith Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.controlSurface,
                  borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  border: Border.all(color: AppColors.mistGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: AppColors.dustyGreenDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.settings.religious_foundation.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.dustyGreenDark,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      KhatmahConstants.getHadithQuote(isAr),
                      style: AppTypography.scholarlyQuote(AppColors.signalBlack, isAr).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocaleKeys.settings.hadith_text.tr(context: context),
                      style: isAr
                          ? AppTypography.scholarlyQuote(AppColors.bodyGray, true).copyWith(
                              fontSize: 14.5,
                              height: 1.6,
                            )
                          : theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.bodyGray,
                              height: 1.45,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LocaleKeys.settings.hadith_source.tr(context: context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
