import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_portion.dart';

/// The day's portion split into five roughly equal parts (one per prayer).
///
/// This single list is both the suggested plan and the progress tracker:
/// tapping a part ticks it off, so the reader always knows where to continue.
/// When [onToggle] is null the plan is shown read-only.
class ReadingPlan extends StatelessWidget {
  final DayPortion portion;
  final ValueChanged<int>? onToggle;

  /// Opens the reading plan picker for this day; hidden when null.
  final VoidCallback? onCustomize;

  /// Draws the parts inside their own bordered box. Turn off when the plan
  /// already sits inside a card, so it uses the card's full width.
  final bool boxed;

  const ReadingPlan({
    super.key,
    required this.portion,
    this.onToggle,
    this.onCustomize,
    this.boxed = true,
  });

  /// Prayer names for the five-part plan, numbered sittings otherwise.
  static String _labelFor(int index, int count) {
    if (count == 5) return _prayerLabels[index];
    return LocaleKeys.reading.sitting_label.tr(args: [(index + 1).toString()]);
  }

  static List<String> get _prayerLabels => [
    LocaleKeys.day_detail.sitting_fajr.tr(),
    LocaleKeys.day_detail.sitting_dhuhr.tr(),
    LocaleKeys.day_detail.sitting_asr.tr(),
    LocaleKeys.day_detail.sitting_maghrib.tr(),
    LocaleKeys.day_detail.sitting_isha.tr(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);
    final parts = portion.parts;
    if (parts.isEmpty) return const SizedBox.shrink();

    final interactive = onToggle != null;
    final read = portion.readParts.toSet();
    final doneCount = portion.readPartCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
              header: true,
              child: Text(
                LocaleKeys.reading.plan_title.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (portion.partsCustom) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryNeutral,
                    borderRadius: BorderRadius.circular(
                      AppColors.standardRadius,
                    ),
                  ),
                  child: Text(
                    LocaleKeys.reading.this_day_only.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.dustyGreenDark,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (interactive || doneCount > 0)
              Text(
                LocaleKeys.reading.parts_done.tr(
                  args: [doneCount.toString(), parts.length.toString()],
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.dustyGreenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (onCustomize != null)
              IconButton(
                key: const ValueKey('reading_plan_customize'),
                tooltip: LocaleKeys.reading.customize.tr(),
                onPressed: onCustomize,
                icon: const Icon(Icons.tune_rounded, size: 18),
                color: AppColors.textMuted,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        if (interactive && doneCount == 0) ...[
          const SizedBox(height: 4),
          Text(
            LocaleKeys.reading.plan_hint.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
        SizedBox(height: boxed ? 8 : 4),
        Container(
          decoration: boxed
              ? BoxDecoration(
                  color: AppColors.controlSurface,
                  borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  border: Border.all(color: AppColors.mistGray),
                )
              : null,
          clipBehavior: boxed ? Clip.antiAlias : Clip.none,
          child: Column(
            children: [
              for (final part in parts) ...[
                if (part.index > 0 || !boxed)
                  const Divider(height: 1, color: AppColors.mistGray),
                _PartRow(
                  key: ValueKey('reading_part_${part.index}'),
                  label: _labelFor(part.index, parts.length),
                  pages: LocaleKeys.reading.pages_short.tr(
                    args: [part.startPage.toString(), part.endPage.toString()],
                  ),
                  surah: part.startSurah.name(isAr),
                  isDone: read.contains(part.index),
                  onTap: interactive ? () => onToggle!(part.index) : null,
                  horizontalPadding: boxed ? 12 : 0,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PartRow extends StatelessWidget {
  final String label;
  final String pages;
  final String surah;
  final bool isDone;
  final VoidCallback? onTap;
  final double horizontalPadding;

  const _PartRow({
    super.key,
    required this.label,
    required this.pages,
    required this.surah,
    required this.isDone,
    required this.onTap,
    this.horizontalPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interactive = onTap != null;

    Widget leading;
    if (isDone) {
      leading = const Icon(
        Icons.check_circle_rounded,
        size: 22,
        color: AppColors.dustyGreen,
      );
    } else if (interactive) {
      leading = const Icon(
        Icons.radio_button_unchecked_rounded,
        size: 22,
        color: AppColors.secondaryBorder,
      );
    } else {
      leading = const Icon(
        Icons.schedule_rounded,
        size: 18,
        color: AppColors.textMuted,
      );
    }

    return Semantics(
      button: interactive,
      checked: interactive ? isDone : null,
      label: '$label, $pages, $surah',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: Row(
              children: [
                SizedBox(width: 26, child: Center(child: leading)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? AppColors.textMuted
                              : AppColors.signalBlack,
                        ),
                      ),
                      Text(
                        surah,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pages,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDone ? AppColors.textMuted : AppColors.bodyGray,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
