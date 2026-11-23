import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/challenge.dart';

/// Aggregated, non-gamified stats across every recorded khatmah.
class LifetimeStats {
  final int khatmahsCompleted;

  /// Share (0..1) of completed portions read on their scheduled day or
  /// earlier; null when nothing has been completed yet.
  final double? onTimeRate;

  /// Average calendar days from start to final completion for finished
  /// khatmahs; null when none are finished.
  final double? averageDaysToFinish;

  const LifetimeStats({
    required this.khatmahsCompleted,
    this.onTimeRate,
    this.averageDaysToFinish,
  });

  factory LifetimeStats.from(Iterable<Challenge> challenges) {
    var finished = 0;
    var completedPortions = 0;
    var onTime = 0;
    final finishDurations = <int>[];

    for (final c in challenges) {
      DateTime? lastCompletion;
      for (final p in c.portions) {
        final at = p.completedAt;
        if (!p.isCompleted || at == null) continue;
        completedPortions++;
        final scheduled = AppDateUtils.dateOnly(c.dateForDay(p.dayNumber));
        if (!AppDateUtils.dateOnly(at).isAfter(scheduled)) onTime++;
        if (lastCompletion == null || at.isAfter(lastCompletion)) {
          lastCompletion = at;
        }
      }
      if (c.isAllPortionsCompleted) {
        finished++;
        if (lastCompletion != null) {
          final days = AppDateUtils.dateOnly(lastCompletion)
                  .difference(AppDateUtils.dateOnly(c.startDate))
                  .inDays +
              1;
          finishDurations.add(days.clamp(1, 365));
        }
      }
    }

    return LifetimeStats(
      khatmahsCompleted: finished,
      onTimeRate: completedPortions == 0 ? null : onTime / completedPortions,
      averageDaysToFinish: finishDurations.isEmpty
          ? null
          : finishDurations.reduce((a, b) => a + b) / finishDurations.length,
    );
  }
}

class LifetimeStatsCard extends StatelessWidget {
  final List<Challenge> challenges;

  const LifetimeStatsCard({super.key, required this.challenges});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = LifetimeStats.from(challenges);
    final onTime = stats.onTimeRate == null
        ? '—'
        : '${(stats.onTimeRate! * 100).round()}%';
    final avgDays = stats.averageDaysToFinish == null
        ? '—'
        : stats.averageDaysToFinish!.toStringAsFixed(
            stats.averageDaysToFinish! % 1 == 0 ? 0 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.progress.lifetime_title.tr(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.controlSurface,
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            border: Border.all(color: AppColors.mistGray),
          ),
          child: Row(
            children: [
              _stat(context, stats.khatmahsCompleted.toString(),
                  LocaleKeys.progress.stat_khatmahs.tr()),
              _divider(),
              _stat(context, onTime, LocaleKeys.progress.stat_on_time.tr()),
              _divider(),
              _stat(context, avgDays, LocaleKeys.progress.stat_avg_days.tr()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.mistGray,
      );

  Widget _stat(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.dustyGreenDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
