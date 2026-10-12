import 'dart:convert';
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
import '../../data/models/challenge_model.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_notifier.dart';
import '../notifiers/challenge_providers.dart';
import '../widgets/circular_progress_badge.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/mosque_silhouette_painter.dart';

enum DayStatus { completed, today, upcoming, missed }

enum JourneyStep {
  whatDoIDoNow, // Step 1: Your Journey
  whereAmIInThePlan, // Step 2: Journey Detail
}

class ProgressPage extends ConsumerStatefulWidget {
  final VoidCallback onStartNewKhatmah;
  final VoidCallback? onBackToHome;
  final JourneyStep initialStep;

  const ProgressPage({
    super.key,
    required this.onStartNewKhatmah,
    this.onBackToHome,
    this.initialStep = JourneyStep.whatDoIDoNow,
  });

  @override
  ConsumerState<ProgressPage> createState() => ProgressPageState();
}

class ProgressPageState extends ConsumerState<ProgressPage> {
  late JourneyStep _currentStep;
  bool _openedFromHome = false;
  late DateTime _selectedMonth;
  final Set<String> _expandedCycleIds = <String>{};

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void resetToStep1() {
    if (_currentStep != JourneyStep.whatDoIDoNow || _openedFromHome) {
      if (mounted) {
        setState(() {
          _currentStep = JourneyStep.whatDoIDoNow;
          _openedFromHome = false;
        });
      }
    }
  }

  void openStep2FromHome() {
    if (mounted) {
      setState(() {
        _currentStep = JourneyStep.whereAmIInThePlan;
        _openedFromHome = true;
      });
    }
  }

  void _toggleCycleExpansion(String cycleId) {
    setState(() {
      if (_expandedCycleIds.contains(cycleId)) {
        _expandedCycleIds.remove(cycleId);
      } else {
        _expandedCycleIds.add(cycleId);
      }
    });
  }

  int _getEstimatedMinutes(int dayNumber) {
    switch (dayNumber) {
      case 1:
        return 15;
      case 2:
        return 25;
      case 3:
        return 35;
      case 4:
        return 40;
      case 5:
        return 30;
      case 6:
        return 30;
      case 7:
        return 25;
      default:
        return 25;
    }
  }

  void _openPortionDetail(
    BuildContext context,
    DayPortion portion,
    DateTime portionDate,
    Challenge targetChallenge,
    ChallengeNotifier notifier,
  ) {
    final currentDay = targetChallenge.currentDayNumber;
    DayDetailSheet.show(
      context,
      portion: portion,
      portionDate: portionDate,
      currentDayNumber: targetChallenge.isActive ? currentDay : 8,
      onToggleCompletion: () async {
        if (!targetChallenge.isActive) return;
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
          if (confirmed) {
            await notifier.undoDayCompletion(portion.dayNumber);
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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeStateProvider);
    final notifier = ref.read(challengeStateProvider.notifier);
    final challenge = state.challenge;
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);
    final locale = context.locale.languageCode;

    // Retrieve historical challenges from storage safely
    final historyChallenges = <Challenge>[];
    try {
      final storageService = ref.watch(storageServiceProvider);
      final historyJsons = storageService.getHistoryJsonList();
      for (final j in historyJsons) {
        try {
          final map = jsonDecode(j) as Map<String, dynamic>;
          historyChallenges.add(ChallengeModel.fromJson(map));
        } catch (_) {}
      }
    } catch (_) {}

    final challengeMap = <String, Challenge>{};
    if (challenge != null) {
      challengeMap[challenge.id] = challenge;
    }
    for (final c in historyChallenges) {
      challengeMap.putIfAbsent(c.id, () => c);
    }
    final allChallenges = challengeMap.values.toList();

    if (challenge == null && allChallenges.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.progress.title.tr(),
            style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
          ),
        ),
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

    final activeCycle = challenge ?? allChallenges.first;
    final currentDay = activeCycle.currentDayNumber;
    final completedCount = activeCycle.completedPortionsCount;
    final isFinished = challenge != null &&
        (challenge.isAllPortionsCompleted || challenge.isExpired);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentStep == JourneyStep.whereAmIInThePlan) {
          if (_openedFromHome && widget.onBackToHome != null) {
            widget.onBackToHome!();
          } else {
            setState(() {
              _currentStep = JourneyStep.whatDoIDoNow;
            });
          }
        } else {
          if (widget.onBackToHome != null) {
            widget.onBackToHome!();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: _buildAppBar(context, isAr),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Concluded / Expired Banner (Preserved for tests & state clarity)
              if (isFinished) ...[
                _buildConcludedBanner(context, challenge, completedCount, isAr),
                const SizedBox(height: 18),
              ],

              // 2-Step Conditional Rendering
              if (_currentStep == JourneyStep.whatDoIDoNow)
                _buildStep1WhatDoIDoNow(
                  context: context,
                  challenge: activeCycle,
                  currentDay: currentDay,
                  completedCount: completedCount,
                  notifier: notifier,
                  isAr: isAr,
                  locale: locale,
                )
              else
                _buildStep2WhereAmIInThePlan(
                  context: context,
                  challenge: activeCycle,
                  allChallenges: allChallenges,
                  currentDay: currentDay,
                  completedCount: completedCount,
                  notifier: notifier,
                  isAr: isAr,
                  locale: locale,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // APP BARS
  // ───────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isAr) {
    if (_currentStep == JourneyStep.whatDoIDoNow) {
      return AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            // App Logo Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.dustyGreenDark,
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocaleKeys.progress.title.tr(),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.signalBlack,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleKeys.progress.journey_subtitle.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryText,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 18),
            child: InkWell(
              onTap: () {
                setState(() {
                  _currentStep = JourneyStep.whereAmIInThePlan;
                });
              },
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  border: Border.all(color: AppColors.mistGray),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.signalBlack,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Step 2 AppBar: Centered Title with Back Arrow on Left and Calendar on Right
      return AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('journey_step2_back_button'),
          icon: Icon(
            isAr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.signalBlack,
          ),
          onPressed: () {
            if (_openedFromHome && widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else {
              setState(() {
                _currentStep = JourneyStep.whatDoIDoNow;
              });
            }
          },
        ),
        centerTitle: true,
        title: Text(
          LocaleKeys.progress.journey_title_step2.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.signalBlack,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: InkWell(
              onTap: () {
                final now = DateTime.now();
                setState(() {
                  _selectedMonth = DateTime(now.year, now.month, 1);
                });
              },
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  border: Border.all(color: AppColors.mistGray),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.dustyGreenDark,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1: "WHAT DO I DO NOW?"
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStep1WhatDoIDoNow({
    required BuildContext context,
    required Challenge challenge,
    required int currentDay,
    required int completedCount,
    required ChallengeNotifier notifier,
    required bool isAr,
    required String locale,
  }) {
    final daysRemaining = (7 - currentDay + 1).clamp(0, 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Warm Hero Greeting Card with Mosque Silhouette & Tappable Current Cycle Card
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFAF7EE),
                Color(0xFFF4EFE3),
                Color(0xFFEFF5F1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            border: Border.all(color: const Color(0xFFE4DDD0)),
          ),
          child: Stack(
            children: [
              // Mosque Skyline Silhouette Graphic
              Positioned(
                right: isAr ? null : 0,
                left: isAr ? 0 : null,
                bottom: 0,
                top: 0,
                child: IgnorePointer(
                  child: Transform.flip(
                    flipX: isAr,
                    child: SizedBox(
                      width: 275,
                      child: CustomPaint(
                        painter: MosqueSilhouettePainter(
                          color: const Color(0xFFD6C8AF),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.progress.greeting_assalamu_alaikum.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.signalBlack,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                LocaleKeys.progress.greeting_keep_going.tr(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Intuitive top-right navigation indicator chip
                        InkWell(
                          onTap: () {
                            setState(() {
                              _currentStep = JourneyStep.whereAmIInThePlan;
                            });
                          },
                          borderRadius: BorderRadius.circular(AppColors.standardRadius),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(AppColors.standardRadius),
                              border: Border.all(
                                color: const Color(0xFFC3D8CE),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  LocaleKeys.progress.plan_details.tr(),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dustyGreenDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isAr
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: AppColors.dustyGreenDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tappable Current Cycle Card (Answers "Where am I in the plan?" when clicked)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _currentStep = JourneyStep.whereAmIInThePlan;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius:
                              BorderRadius.circular(AppColors.standardRadius),
                          border: Border.all(color: AppColors.mistGray),
                        ),
                        child: Row(
                          children: [
                            // Circular Progress Ring (e.g. 5/7 Today)
                            CircularProgressBadge(
                              completed: completedCount,
                              total: 7,
                              sublabel: LocaleKeys.common.today.tr(),
                              size: 70,
                              strokeWidth: 6.0,
                              progressColor: AppColors.dustyGreenDark,
                              trackColor: AppColors.secondaryNeutral,
                            ),
                            const SizedBox(width: 16),

                            // Right Details Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        LocaleKeys.progress.current_cycle.tr(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.signalBlack,
                                        ),
                                      ),
                                      // Status Pill Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF2EE),
                                          borderRadius: BorderRadius.circular(
                                            AppColors.standardRadius,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFC3D8CE),
                                          ),
                                        ),
                                        child: Text(
                                          challenge.isAllPortionsCompleted
                                              ? LocaleKeys.common.completed.tr()
                                              : LocaleKeys.progress.in_progress.tr(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.dustyGreenDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppDateUtils.formatShortDate(challenge.startDate, locale)} – ${AppDateUtils.formatShortDate(challenge.endDate, locale)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Linear progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppColors.standardRadius,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: challenge.completionPercentage
                                          .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor:
                                          AppColors.secondaryNeutral,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.dustyGreenDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Days remaining label
                                  Text(
                                    daysRemaining > 1
                                        ? LocaleKeys.progress.days_remaining_count.tr(
                                            args: [daysRemaining.toString()],
                                          )
                                        : (daysRemaining == 1
                                            ? LocaleKeys.progress.day_remaining_single.tr()
                                            : LocaleKeys.progress.ends_today.tr()),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Horizontal 7-Day Week / Cycle Strip
        _buildHorizontalWeekStrip(challenge, currentDay, isAr, locale),
        const SizedBox(height: 26),

        // 3. "Today's Journey" Section Header
        Text(
          LocaleKeys.progress.todays_journey.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.signalBlack,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          LocaleKeys.progress.todays_journey_sub.tr(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 14),

        // 4. Portions List (Days 1 to 7) with prominent Today card
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
            } else if (portion.dayNumber == currentDay && challenge.isActive) {
              status = DayStatus.today;
            } else if (portion.dayNumber < currentDay) {
              status = DayStatus.missed;
            } else {
              status = DayStatus.upcoming;
            }

            return _buildStep1PortionCard(
              context,
              portion: portion,
              portionDate: portionDate,
              status: status,
              isAr: isAr,
              locale: locale,
              onTap: () {
                _openPortionDetail(context, portion, portionDate, challenge, notifier);
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Horizontal 7-Day Cycle Strip (Sun Oct 5 .. Sat Oct 11)
  Widget _buildHorizontalWeekStrip(
    Challenge challenge,
    int currentDay,
    bool isAr,
    String locale,
  ) {
    return Row(
      children: List.generate(challenge.portions.length, (index) {
        final portion = challenge.portions[index];
        final portionDate = challenge.startDate.add(Duration(days: index));
        final isToday = challenge.isActive && portion.dayNumber == currentDay;
        final isCompleted = portion.isCompleted;

        final weekday = AppDateUtils.formatWeekday(portionDate, locale);
        final shortDate = AppDateUtils.formatShortDate(portionDate, locale);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            padding: EdgeInsets.symmetric(
              vertical: isToday ? 8 : 6,
              horizontal: 2,
            ),
            decoration: BoxDecoration(
              color: isToday ? AppColors.dustyGreenDark : AppColors.paper,
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              border: Border.all(
                color: isToday ? AppColors.dustyGreenDark : AppColors.mistGray,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekday,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? Colors.white : AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  shortDate,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF8A9C94),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Icon / Status indicator
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      LocaleKeys.common.today.tr(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dustyGreenDark,
                      ),
                    ),
                  )
                else if (isCompleted)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.dustyGreenDark,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  )
                else
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.mistGray,
                        width: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Step 1 Portion Card (with numbered circle on left and prominent Today focus)
  Widget _buildStep1PortionCard(
    BuildContext context, {
    required DayPortion portion,
    required DateTime portionDate,
    required DayStatus status,
    required bool isAr,
    required String locale,
    required VoidCallback onTap,
  }) {
    final isToday = status == DayStatus.today;
    final isCompleted = status == DayStatus.completed;

    // Card background & border
    final bgColor = isToday ? const Color(0xFFF1F6F3) : AppColors.paper;
    final borderColor = isToday ? AppColors.dustyGreenDark : AppColors.mistGray;
    final borderWidth = isToday ? 1.5 : 1.0;

    // Status Badge on the right
    Widget statusBadge;
    if (isCompleted) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2EE),
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          border: Border.all(color: const Color(0xFFC3D8CE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 12, color: AppColors.dustyGreenDark),
            const SizedBox(width: 4),
            Text(
              LocaleKeys.common.completed.tr(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.dustyGreenDark,
              ),
            ),
          ],
        ),
      );
    } else if (isToday) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.dustyGreenDark,
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
        ),
        child: Text(
          LocaleKeys.common.today.tr(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    } else if (status == DayStatus.missed) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.controlSurface,
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          border: Border.all(color: AppColors.mistGray),
        ),
        child: Text(
          LocaleKeys.common.missed.tr(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
        ),
      );
    } else {
      // Upcoming
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          border: Border.all(color: AppColors.mistGray),
        ),
        child: Text(
          LocaleKeys.common.upcoming.tr(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    final estimatedMinutes = _getEstimatedMinutes(portion.dayNumber);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.standardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Row(
          children: [
            // Left Numbered Circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday
                    ? AppColors.dustyGreenDark
                    : (isCompleted
                        ? const Color(0xFFEAF2EE)
                        : const Color(0xFFF5F8F6)),
                border: Border.all(
                  color: isToday
                      ? AppColors.dustyGreenDark
                      : (isCompleted
                          ? const Color(0xFFBCCDC5)
                          : AppColors.mistGray),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${portion.dayNumber}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? Colors.white
                      : (isCompleted
                          ? AppColors.dustyGreenDark
                          : AppColors.signalBlack),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle: Date, Surah Range & Sub-details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDateUtils.formatDate(portionDate, locale),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8A9C94),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr ? portion.rangeDisplayAr : portion.rangeDisplay,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.signalBlack,
                      fontFamily: isAr ? 'Tajawal' : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${portion.surahCount} ${LocaleKeys.common.surahs.tr()} • ~ $estimatedMinutes ${isAr ? 'د' : 'min'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: Status badge & Chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                statusBadge,
                const SizedBox(width: 6),
                Icon(
                  isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: isToday
                      ? AppColors.dustyGreenDark
                      : const Color(0xFFB0BFB8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2: "WHERE AM I IN THE PLAN?"
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStep2WhereAmIInThePlan({
    required BuildContext context,
    required Challenge challenge,
    required List<Challenge> allChallenges,
    required int currentDay,
    required int completedCount,
    required ChallengeNotifier notifier,
    required bool isAr,
    required String locale,
  }) {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    // Filter all challenges/cycles that intersect or start in _selectedMonth
    final monthChallenges = allChallenges.where((c) {
      final start = c.startDate;
      final end = c.endDate;
      final isStartInMonth =
          start.year == _selectedMonth.year && start.month == _selectedMonth.month;
      final isEndInMonth =
          end.year == _selectedMonth.year && end.month == _selectedMonth.month;
      return isStartInMonth || isEndInMonth;
    }).toList();

    monthChallenges.sort((a, b) => a.startDate.compareTo(b.startDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── MONTH SELECTOR ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            border: Border.all(color: AppColors.mistGray),
          ),
          child: Row(
            children: [
              // Previous month
              IconButton(
                key: const Key('journey_prev_month_button'),
                icon: Icon(
                  isAr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  size: 22,
                ),
                color: AppColors.signalBlack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                      1,
                    );
                    _expandedCycleIds.clear();
                  });
                },
              ),
              // Month label
              Expanded(
                child: GestureDetector(
                  onTap: isCurrentMonth
                      ? null
                      : () {
                          final nowTime = DateTime.now();
                          setState(() {
                            _selectedMonth = DateTime(nowTime.year, nowTime.month, 1);
                            _expandedCycleIds.clear();
                          });
                        },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppDateUtils.formatMonthYear(_selectedMonth, locale),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.signalBlack,
                        ),
                      ),
                      if (!isCurrentMonth) ...[                      
                        const SizedBox(height: 2),
                        Text(
                          LocaleKeys.progress.today_jump.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dustyGreenDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Next month
              IconButton(
                key: const Key('journey_next_month_button'),
                icon: Icon(
                  isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 22,
                ),
                color: AppColors.signalBlack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      1,
                    );
                    _expandedCycleIds.clear();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── CYCLES LIST or EMPTY STATE ───────────────────────────────────────
        if (monthChallenges.isEmpty) ...[          
          // Clean Empty State
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.controlSurface,
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              border: Border.all(color: AppColors.mistGray),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  LocaleKeys.progress.no_cycles_month.tr(
                    args: [AppDateUtils.formatMonthYear(_selectedMonth, locale)],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.signalBlack,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  LocaleKeys.progress.no_cycles_sub.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('journey_today_jump_button'),
                  onPressed: () {
                    final nowTime = DateTime.now();
                    setState(() {
                      _selectedMonth = DateTime(nowTime.year, nowTime.month, 1);
                      _expandedCycleIds.clear();
                    });
                  },
                  child: Text(LocaleKeys.progress.today_jump.tr()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[          
          // Expandable Cycle Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: monthChallenges.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cycle = monthChallenges[index];
              final isExpanded = _expandedCycleIds.contains(cycle.id);
              final cycleNumber = index + 1;
              return _buildExpandableCycleCard(
                context: context,
                cycle: cycle,
                cycleNumber: cycleNumber,
                isExpanded: isExpanded,
                onToggle: () => _toggleCycleExpansion(cycle.id),
                notifier: notifier,
                isAr: isAr,
                locale: locale,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  /// Expandable Cycle Card — clean minimal accordion
  Widget _buildExpandableCycleCard({
    required BuildContext context,
    required Challenge cycle,
    required int cycleNumber,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ChallengeNotifier notifier,
    required bool isAr,
    required String locale,
  }) {
    final int cycleCompletedCount = cycle.completedPortionsCount;
    final int cycleCurrentDay = cycle.currentDayNumber;

    // Human-readable completion fraction
    final String completionText = cycle.isAllPortionsCompleted
        ? LocaleKeys.common.completed.tr()
        : cycle.isActive
            ? LocaleKeys.progress.in_progress.tr()
            : '$cycleCompletedCount / 7 ${LocaleKeys.common.completed.tr()}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(
          color: isExpanded ? AppColors.dustyGreen : AppColors.mistGray,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header (always visible) ─────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cycle number badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.dustyGreen
                          : AppColors.controlSurface,
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$cycleNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isExpanded ? Colors.white : AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cycle title & date range
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.progress.cycle_label.tr(args: [cycleNumber.toString()]),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.signalBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppDateUtils.formatShortDate(cycle.startDate, locale)} – ${AppDateUtils.formatShortDate(cycle.endDate, locale)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Completion summary text
                  Text(
                    completionText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: cycle.isAllPortionsCompleted
                          ? AppColors.dustyGreen
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Rotating chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Smooth Expandable Body ────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, thickness: 1, color: AppColors.secondaryNeutral),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cycle.portions.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: AppColors.secondaryNeutral),
                          itemBuilder: (context, idx) {
                            final portion = cycle.portions[idx];
                            final portionDate = cycle.startDate.add(
                              Duration(days: portion.dayNumber - 1),
                            );

                            DayStatus status;
                            if (portion.isCompleted) {
                              status = DayStatus.completed;
                            } else if (portion.dayNumber == cycleCurrentDay &&
                                cycle.isActive) {
                              status = DayStatus.today;
                            } else if (portion.dayNumber < cycleCurrentDay) {
                              status = DayStatus.missed;
                            } else {
                              status = DayStatus.upcoming;
                            }

                            return _buildStep2PortionRow(
                              context,
                              portion: portion,
                              portionDate: portionDate,
                              status: status,
                              isAr: isAr,
                              locale: locale,
                              onTap: () {
                                _openPortionDetail(
                                  context,
                                  portion,
                                  portionDate,
                                  cycle,
                                  notifier,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Step 2 Portion Row — clean list tile inside an expanded cycle card.
  Widget _buildStep2PortionRow(
    BuildContext context, {
    required DayPortion portion,
    required DateTime portionDate,
    required DayStatus status,
    required bool isAr,
    required String locale,
    required VoidCallback onTap,
  }) {
    final isToday = status == DayStatus.today;
    final isCompleted = status == DayStatus.completed;
    final isMissed = status == DayStatus.missed;

    // Status indicator dot / check
    Widget indicator;
    if (isCompleted) {
      indicator = Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.dustyGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 11, color: Colors.white),
      );
    } else if (isToday) {
      indicator = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dustyGreen, width: 2),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.dustyGreen,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      indicator = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isMissed ? AppColors.secondaryText.withValues(alpha: 0.4) : AppColors.mistGray,
            width: 1.5,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Status indicator
            indicator,
            const SizedBox(width: 12),
            // Day number
            Text(
              'Day ${portion.dayNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMissed
                    ? AppColors.secondaryText
                    : (isToday ? AppColors.dustyGreen : AppColors.signalBlack),
              ),
            ),
            const SizedBox(width: 10),
            // Juz range (primary info)
            Expanded(
              child: Text(
                isAr ? portion.rangeDisplayAr : portion.rangeDisplay,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isMissed ? AppColors.secondaryText : AppColors.signalBlack,
                  fontFamily: isAr ? 'Tajawal' : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Today tag or chevron
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.dustyGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  LocaleKeys.common.today.tr(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dustyGreen,
                  ),
                ),
              )
            else
              Icon(
                isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.mistGray,
              ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CONCLUDED BANNER
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildConcludedBanner(
    BuildContext context,
    Challenge challenge,
    int completedCount,
    bool isAr,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.controlSurface,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(
          color: challenge.isAllPortionsCompleted
              ? AppColors.ink
              : AppColors.mistGray,
          width: challenge.isAllPortionsCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            challenge.isAllPortionsCompleted
                ? LocaleKeys.completion_dialog.title.tr()
                : LocaleKeys.progress.concluded_banner_title.tr(),
            style: AppTypography.appBarTitle(
              AppColors.signalBlack,
              isAr,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            challenge.isAllPortionsCompleted
                ? LocaleKeys.completion_dialog.subtitle.tr()
                : LocaleKeys.progress.concluded_banner_desc.tr(
                    args: [completedCount.toString()],
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.bodyGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onStartNewKhatmah,
            child: Text(
              challenge.isAllPortionsCompleted
                  ? LocaleKeys.completion_dialog.start_another.tr()
                  : LocaleKeys.home.start_new.tr(),
            ),
          ),
        ],
      ),
    );
  }
}
