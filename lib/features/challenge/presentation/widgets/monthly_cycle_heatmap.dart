import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/day_portion.dart';

enum CycleFilter { all, completed, active }

class MonthlyCycleHeatmap extends StatefulWidget {
  final List<Challenge> challenges;
  final void Function(DayPortion portion, DateTime portionDate, Challenge challenge) onTapPortion;
  final VoidCallback? onStartNewKhatmah;

  const MonthlyCycleHeatmap({
    super.key,
    required this.challenges,
    required this.onTapPortion,
    this.onStartNewKhatmah,
  });

  @override
  State<MonthlyCycleHeatmap> createState() => _MonthlyCycleHeatmapState();
}

class _MonthlyCycleHeatmapState extends State<MonthlyCycleHeatmap> {
  late DateTime _selectedMonth;
  CycleFilter _filter = CycleFilter.all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _jumpToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  List<Challenge> _getCyclesForMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final monthEnd = nextMonth.subtract(const Duration(seconds: 1));

    final filtered = widget.challenges.where((c) {
      return !c.startDate.isAfter(monthEnd) && !c.endDate.isBefore(monthStart);
    }).toList();

    filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
    return filtered;
  }

  List<Challenge> _applyFilter(List<Challenge> cycles) {
    switch (_filter) {
      case CycleFilter.completed:
        return cycles.where((c) => c.isAllPortionsCompleted).toList();
      case CycleFilter.active:
        return cycles.where((c) => c.isActive).toList();
      case CycleFilter.all:
        return cycles;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);
    final langCode = context.locale.languageCode;

    final cyclesInMonth = _getCyclesForMonth(_selectedMonth);
    final filteredCycles = _applyFilter(cyclesInMonth);

    // Compute monthly consistency metrics
    final totalCycles = cyclesInMonth.length;
    int completedPortionsInMonth = 0;
    for (final c in cyclesInMonth) {
      completedPortionsInMonth += c.completedPortionsCount;
    }
    final targetPortionsInMonth = totalCycles * 7;
    final consistencyPercent = targetPortionsInMonth > 0
        ? ((completedPortionsInMonth / targetPortionsInMonth) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with optional "Current Month" jump button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleKeys.progress.monthly_stream_title.tr(context: context),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!_isCurrentMonth())
              InkWell(
                onTap: _jumpToCurrentMonth,
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.controlSurface,
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    border: Border.all(color: AppColors.mistGray),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.today_rounded, size: 12, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        LocaleKeys.progress.today_jump.tr(context: context),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Month Stepper Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            border: Border.all(color: AppColors.mistGray),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepButton(
                icon: Icons.chevron_left_rounded,
                onTap: _previousMonth,
                tooltip: 'Previous Month',
              ),
              Text(
                AppDateUtils.formatMonthYear(_selectedMonth, langCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.signalBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              _buildStepButton(
                icon: Icons.chevron_right_rounded,
                onTap: _nextMonth,
                tooltip: 'Next Month',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Monthly Stats Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.controlSurface,
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            border: Border.all(color: AppColors.mistGray),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: LocaleKeys.progress.stat_cycles.tr(context: context),
                value: '$totalCycles',
              ),
              Container(width: 1, height: 20, color: AppColors.mistGray),
              _buildMetricItem(
                label: LocaleKeys.progress.stat_portions.tr(context: context),
                value: '$completedPortionsInMonth / $targetPortionsInMonth',
              ),
              Container(width: 1, height: 20, color: AppColors.mistGray),
              _buildMetricItem(
                label: LocaleKeys.progress.stat_consistency.tr(context: context),
                value: '$consistencyPercent%',
                valueColor: consistencyPercent > 0 ? AppColors.ink : AppColors.textMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filter Pills
        Row(
          children: [
            _buildFilterPill(
              label: LocaleKeys.progress.filter_all.tr(context: context),
              filter: CycleFilter.all,
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: LocaleKeys.progress.filter_completed.tr(context: context),
              filter: CycleFilter.completed,
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: LocaleKeys.progress.filter_active.tr(context: context),
              filter: CycleFilter.active,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Cycles List or Empty State
        if (filteredCycles.isEmpty)
          _buildEmptyState(context, isAr)
        else
          ...filteredCycles.map((cycle) {
            final originalIndex = cyclesInMonth.indexOf(cycle);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCycleCard(
                context,
                cycle: cycle,
                cycleNumber: originalIndex >= 0 ? originalIndex + 1 : 1,
                isAr: isAr,
              ),
            );
          }),

        // Heatmap Legend
        const SizedBox(height: 4),
        _buildLegendRow(context),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.standardRadius),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.controlSurface,
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          border: Border.all(color: AppColors.mistGray),
        ),
        child: Icon(icon, size: 20, color: AppColors.bodyGray),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.signalBlack,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String label,
    required CycleFilter filter,
  }) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _filter = filter;
        });
      },
      borderRadius: BorderRadius.circular(AppColors.standardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryNeutral : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          border: Border.all(
            color: isSelected ? AppColors.secondaryBorder : AppColors.mistGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.ink : AppColors.bodyGray,
          ),
        ),
      ),
    );
  }

  Widget _buildCycleCard(
    BuildContext context, {
    required Challenge cycle,
    required int cycleNumber,
    required bool isAr,
  }) {
    final theme = Theme.of(context);
    final currentDay = cycle.currentDayNumber;

    // Status pill text and colors
    final String statusText;
    final Color badgeBg;
    final Color badgeBorder;
    final Color badgeTextColor;

    if (cycle.isAllPortionsCompleted) {
      statusText = LocaleKeys.progress.cycle_completed.tr(context: context);
      badgeBg = AppColors.secondaryNeutral;
      badgeBorder = AppColors.secondaryBorder;
      badgeTextColor = AppColors.ink;
    } else if (cycle.isActive) {
      statusText = LocaleKeys.progress.cycle_in_progress.tr(
        context: context,
        args: [cycle.completedPortionsCount.toString()],
      );
      badgeBg = AppColors.ink;
      badgeBorder = AppColors.ink;
      badgeTextColor = AppColors.buttonText;
    } else {
      statusText = LocaleKeys.progress.cycle_concluded.tr(
        context: context,
        args: [cycle.completedPortionsCount.toString()],
      );
      badgeBg = AppColors.controlSurface;
      badgeBorder = AppColors.mistGray;
      badgeTextColor = AppColors.textMuted;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.mistGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cycle Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.progress.cycle_label.tr(
                      context: context,
                      args: [cycleNumber.toString()],
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.signalBlack,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppDateUtils.formatShortDate(cycle.startDate, context.locale.languageCode)} – ${AppDateUtils.formatShortDate(cycle.endDate, context.locale.languageCode)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-Day Stream Grid
          Row(
            children: List.generate(cycle.portions.length, (index) {
              final portion = cycle.portions[index];
              final portionDate = cycle.startDate.add(Duration(days: index));

              final bool isToday = cycle.isActive && portion.dayNumber == currentDay;
              final bool isCompleted = portion.isCompleted;
              final bool isMissed = !isCompleted && portion.dayNumber < currentDay && cycle.isActive;
              final bool isConcludedMissed = !cycle.isActive && !isCompleted;

              // Tile appearance
              Color tileBg = AppColors.paper;
              Color tileBorder = AppColors.mistGray;
              Widget iconOrLabel;

              if (isCompleted) {
                tileBg = AppColors.dustyGreen;
                tileBorder = AppColors.dustyGreen;
                iconOrLabel = const Icon(
                  Icons.check_rounded,
                  color: AppColors.buttonText,
                  size: 16,
                );
              } else if (isToday) {
                tileBg = AppColors.dustyGreenDark;
                tileBorder = AppColors.dustyGreenDark;
                iconOrLabel = Text(
                  '${portion.dayNumber}',
                  style: const TextStyle(
                    color: AppColors.buttonText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              } else if (isMissed || isConcludedMissed) {
                tileBg = AppColors.controlSurface;
                tileBorder = AppColors.mistGray;
                iconOrLabel = Text(
                  '${portion.dayNumber}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              } else {
                // Upcoming
                tileBg = AppColors.paper;
                tileBorder = AppColors.mistGray;
                iconOrLabel = Text(
                  '${portion.dayNumber}',
                  style: const TextStyle(
                    color: AppColors.mistGray,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Column(
                    children: [
                      // Day Abbreviation header
                      Text(
                        LocaleKeys.progress.day_abbr.tr(
                          context: context,
                          args: [portion.dayNumber.toString()],
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Square Tile
                      InkWell(
                        onTap: () => widget.onTapPortion(portion, portionDate, cycle),
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: tileBg,
                            borderRadius: BorderRadius.circular(AppColors.standardRadius),
                            border: Border.all(color: tileBorder),
                          ),
                          alignment: Alignment.center,
                          child: iconOrLabel,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Calendar date below tile
                      Text(
                        '${portionDate.day}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Micro Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            child: LinearProgressIndicator(
              value: cycle.completionPercentage.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.secondaryNeutral,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    final theme = Theme.of(context);
    final monthStr = AppDateUtils.formatMonthYear(
      _selectedMonth,
      context.locale.languageCode,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.mistGray),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.controlSurface,
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.progress.no_cycles_month.tr(
              context: context,
              args: [monthStr],
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.signalBlack,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.progress.no_cycles_sub.tr(context: context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_isCurrentMonth()) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _jumpToCurrentMonth,
              icon: const Icon(Icons.today_rounded, size: 16),
              label: Text(LocaleKeys.progress.today_jump.tr(context: context)),
            ),
          ] else if (widget.onStartNewKhatmah != null) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: widget.onStartNewKhatmah,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocaleKeys.home.start_new.tr(context: context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem(
            color: AppColors.dustyGreen,
            label: LocaleKeys.progress.legend_completed.tr(context: context),
            hasCheck: true,
          ),
          const SizedBox(width: 14),
          _buildLegendItem(
            color: AppColors.dustyGreenDark,
            label: LocaleKeys.progress.legend_today.tr(context: context),
          ),
          const SizedBox(width: 14),
          _buildLegendItem(
            color: AppColors.controlSurface,
            borderColor: AppColors.mistGray,
            label: LocaleKeys.progress.legend_missed.tr(context: context),
          ),
          const SizedBox(width: 14),
          _buildLegendItem(
            color: AppColors.paper,
            borderColor: AppColors.mistGray,
            label: LocaleKeys.progress.legend_upcoming.tr(context: context),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    Color? borderColor,
    required String label,
    bool hasCheck = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor ?? color),
          ),
          alignment: Alignment.center,
          child: hasCheck
              ? const Icon(
                  Icons.check,
                  size: 10,
                  color: AppColors.buttonText,
                )
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
