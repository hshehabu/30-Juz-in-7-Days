import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_confirmation_sheet.dart';
import '../../../../core/widgets/countdown_undo_toast.dart';
import '../../../backup/backup_actions.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_providers.dart';
import '../notifiers/challenge_state.dart';
import '../widgets/adjust_plan_dialog.dart';
import '../widgets/behind_schedule_banner.dart';
import '../widgets/challenge_completed_dialog.dart';
import '../widgets/portion_actions.dart';
import '../widgets/portion_card.dart';
import '../widgets/reading_plan_picker.dart';
import '../widgets/schedule_preview_strip.dart';
import '../widgets/share_actions.dart';

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
  bool _celebrationOpen = false;

  @override
  void initState() {
    super.initState();
    // The final portion may have been completed from a notification before
    // this page existed (e.g. the action launched the app). Show the
    // celebration that would otherwise be missed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(challengeStateProvider).showCelebration) {
        _showCelebration();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCelebration() {
    if (_celebrationOpen) return;
    _celebrationOpen = true;
    final notifier = ref.read(challengeStateProvider.notifier);
    ChallengeCompletedDialog.show(
      context,
      onStartAnother: () {
        notifier.dismissCelebration();
        widget.onStartNewKhatmah();
      },
      onDismiss: () {
        notifier.dismissCelebration();
      },
      onShare: () {
        final challenge = ref.read(challengeStateProvider).challenge;
        if (challenge != null) ShareActions.shareCompletion(context, challenge);
      },
    ).whenComplete(() => _celebrationOpen = false);
  }

  void _openAdjustPlan(Challenge challenge) {
    final notifier = ref.read(challengeStateProvider.notifier);
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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeStateProvider);
    final notifier = ref.read(challengeStateProvider.notifier);
    final challenge = state.challenge;
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);
    final locale = context.locale.languageCode;

    // Listen for completion celebration trigger
    ref.listen<ChallengeState>(challengeStateProvider, (prev, next) {
      if (next.showCelebration && !(prev?.showCelebration ?? false)) {
        _showCelebration();
      }
    });

    if (challenge == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
        ),
      );
    }

    final isAllCompleted = challenge.isAllPortionsCompleted;
    final isExpired = challenge.isExpired;
    final isActive = challenge.isActive;
    final isUpcoming = challenge.isUpcoming;

    // Header subtitle based on lifecycle state
    String subtitleText;
    if (isAllCompleted) {
      subtitleText = '${LocaleKeys.completion_dialog.title.tr()} 🎉';
    } else if (isExpired) {
      subtitleText =
          '${LocaleKeys.home.concluded_title.tr()} • ${challenge.completedPortionsCount}/7';
    } else if (isUpcoming) {
      subtitleText = _startsInText(challenge.daysUntilStart);
    } else {
      final currentDay = challenge.currentDayNumber;
      final daysRemaining = challenge.daysRemaining;
      subtitleText =
          '${LocaleKeys.common.day_x_of_7.tr(args: [currentDay.toString()])} • ${LocaleKeys.progress.days_left.tr(args: [daysRemaining.toString()])}';
    }

    // Today's portion during an active challenge (Day 1 before the start)
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
    final readingPlanOn = state.isReadingPlanOn;

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
        onRefresh: notifier.refreshFromDisk,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. All portions completed
              if (isAllCompleted) ...[
                _buildCompletedCard(context, challenge, isAr, locale),
                const SizedBox(height: 20),
              ]
              // 2. Period ended without completing all portions
              else if (isExpired) ...[
                _buildExpiredCard(context, isAr),
                const SizedBox(height: 20),
              ]
              // 3. Scheduled to start on a future date
              else if (isUpcoming) ...[
                _buildUpcomingCard(context, challenge, isAr, locale),
                const SizedBox(height: 16),
                PortionCard(
                  portion: todayPortion,
                  currentDayNumber: 0,
                  eyebrow: LocaleKeys.home.first_portion.tr(),
                  showCompletionAction: false,
                  onMarkCompleted: () {},
                  onUndoCompleted: () {},
                ),
                const SizedBox(height: 20),
              ]
              // 4. Active challenge tracking
              else if (isActive) ...[
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
                    onAdjustPlan: () => _openAdjustPlan(challenge),
                  ),
                  const SizedBox(height: 20),
                ] else if (challenge.isBehindSchedule &&
                    _isBehindScheduleBannerDismissed) ...[
                  // Collapsed bar: user never loses access to adjust plan
                  _buildCollapsedBehindBar(context, challenge),
                  const SizedBox(height: 20),
                ],

                // Today's Portion Main Card
                PortionCard(
                  portion: todayPortion,
                  currentDayNumber: displayDay,
                  onTogglePart: readingPlanOn
                      ? (index) => PortionActions.toggleReadingPart(
                          context, ref, todayPortion.dayNumber, index)
                      : null,
                  onCustomizePlan: () => ReadingPlanPicker.showForDay(
                      context, ref, todayPortion),
                  onMarkCompleted: () => PortionActions.markCompleted(
                      context, ref, todayPortion.dayNumber),
                  onUndoCompleted: () => PortionActions.confirmUndo(
                      context, ref, todayPortion.dayNumber),
                ),
                const SizedBox(height: 20),
              ],

              // Unified 7-Day Khatmah Progress Card
              SchedulePreviewStrip(
                portions: challenge.portions,
                currentDayNumber:
                    isActive ? displayDay : (isUpcoming ? 0 : 8),
                completedCount: challenge.completedPortionsCount,
                percentage: challenge.completionPercentage,
                onSelectPortion: (portion) => PortionActions.showDetail(
                  context,
                  ref,
                  challenge: challenge,
                  portion: portion,
                ),
                onViewAll: widget.onNavigateToProgress,
              ),
              const SizedBox(height: 20),

              _buildHadithCard(context, isAr),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  /// Offer a backup after a finished khatmah unless one was saved since.
  bool _needsBackupPrompt(Challenge challenge) {
    DateTime? finished;
    for (final p in challenge.portions) {
      final at = p.completedAt;
      if (at != null && (finished == null || at.isAfter(finished))) {
        finished = at;
      }
    }
    if (finished == null) return false;
    final last = ref.read(challengeStateProvider).lastBackupAt;
    return last == null || last.isBefore(finished);
  }

  String _startsInText(int days) {
    if (days <= 1) return LocaleKeys.home.starts_tomorrow.tr();
    return LocaleKeys.home.starts_in_days.tr(args: [days.toString()]);
  }

  Widget _buildUpcomingCard(
    BuildContext context,
    Challenge challenge,
    bool isAr,
    String locale,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.controlSurface,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.mistGray),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded,
              color: AppColors.ink, size: 36),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.home.upcoming_title.tr(),
            style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _startsInText(challenge.daysUntilStart),
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.dustyGreenDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.home.upcoming_desc.tr(args: [
              AppDateUtils.formatDateWithYear(challenge.startDate, locale),
            ]),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.bodyGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                ref.read(challengeStateProvider.notifier).restartCurrentChallenge(),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(LocaleKeys.home.start_today_instead.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(
    BuildContext context,
    Challenge challenge,
    bool isAr,
    String locale,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.controlSurface,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.ink, size: 38),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.completion_dialog.title.tr(),
            style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.completion_dialog.subtitle.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.bodyGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${AppDateUtils.formatDate(challenge.startDate, locale)} • ${AppDateUtils.formatDate(challenge.endDate, locale)}',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: widget.onStartNewKhatmah,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(LocaleKeys.completion_dialog.start_another.tr()),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (buttonContext) => TextButton.icon(
              onPressed: () =>
                  ShareActions.shareCompletion(buttonContext, challenge),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(LocaleKeys.share.button.tr()),
            ),
          ),
          if (_needsBackupPrompt(challenge)) ...[
            const Divider(height: 24),
            Text(
              LocaleKeys.home.backup_prompt.tr(),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            Builder(
              builder: (buttonContext) => TextButton.icon(
                key: const Key('home_backup_prompt'),
                onPressed: () =>
                    BackupActions.saveBackupFile(buttonContext, ref),
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: Text(LocaleKeys.settings.save_backup_file.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpiredCard(BuildContext context, bool isAr) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.controlSurface,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.mistGray, width: 1.0),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_edu_rounded, color: AppColors.ink, size: 36),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.home.concluded_title.tr(),
            style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.home.concluded_desc.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.bodyGray),
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
    );
  }

  Widget _buildCollapsedBehindBar(BuildContext context, Challenge challenge) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 14, right: 4, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.controlSurface,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.mistGray),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.dustyGreen, size: 16),
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
            onPressed: () => _openAdjustPlan(challenge),
            child: Text(
              LocaleKeys.home.adjust_plan.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_more_rounded, size: 18),
            tooltip: LocaleKeys.confirmation.show_banner.tr(),
            color: AppColors.bodyGray,
            onPressed: () {
              setState(() {
                _isBehindScheduleBannerDismissed = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHadithCard(BuildContext context, bool isAr) {
    final theme = Theme.of(context);
    return Container(
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
              const Icon(Icons.menu_book_rounded,
                  size: 16, color: AppColors.dustyGreenDark),
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
    );
  }
}
