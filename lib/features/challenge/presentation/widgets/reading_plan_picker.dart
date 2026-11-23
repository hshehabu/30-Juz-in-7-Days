import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_portion.dart';
import '../notifiers/challenge_providers.dart';

/// Lets the reader choose how each day is split for tracking:
/// by prayer (5 parts, default), 3 or 2 sittings, or off.
class ReadingPlanPicker {
  ReadingPlanPicker._();

  /// Option values in display order (0 = off).
  static const List<int> options = [5, 3, 2, 0];

  static String label(int parts) => switch (parts) {
        5 => LocaleKeys.reading.option_prayers.tr(),
        3 => LocaleKeys.reading.option_three.tr(),
        2 => LocaleKeys.reading.option_two.tr(),
        _ => LocaleKeys.reading.option_off.tr(),
      };

  static String description(int parts) => switch (parts) {
        5 => LocaleKeys.reading.option_prayers_desc.tr(),
        3 => LocaleKeys.reading.option_three_desc.tr(),
        2 => LocaleKeys.reading.option_two_desc.tr(),
        _ => LocaleKeys.reading.option_off_desc.tr(),
      };

  /// Default plan for all unfinished, non-customized days (Settings).
  static Future<void> show(BuildContext context, WidgetRef ref) {
    final current = ref.read(challengeStateProvider).readingPlanParts;
    return _showSheet(
      context,
      title: LocaleKeys.reading.picker_title.tr(),
      description: LocaleKeys.reading.picker_desc.tr(),
      tiles: [
        for (final option in options)
          _TileData(
            key: 'reading_plan_option_$option',
            title: label(option),
            subtitle: description(option),
            selected: option == current,
            onSelect: option == current
                ? null
                : () => ref
                    .read(challengeStateProvider.notifier)
                    .setReadingPlanParts(option),
          ),
      ],
    );
  }

  /// Plan for one day only (the ⚙ on that day's plan).
  static Future<void> showForDay(
    BuildContext context,
    WidgetRef ref,
    DayPortion portion,
  ) {
    final state = ref.read(challengeStateProvider);
    final notifier = ref.read(challengeStateProvider.notifier);
    final day = portion.dayNumber;
    final defaultParts = state.readingPlanParts;
    return _showSheet(
      context,
      title: LocaleKeys.reading.day_picker_title.tr(args: [day.toString()]),
      description: LocaleKeys.reading.day_picker_desc.tr(),
      tiles: [
        _TileData(
          key: 'reading_plan_day_option_default',
          title: LocaleKeys.reading.use_default.tr(),
          subtitle: LocaleKeys.reading.use_default_desc
              .tr(args: [label(defaultParts)]),
          selected: !portion.partsCustom,
          onSelect: portion.partsCustom
              ? () => notifier.setDayReadingPlan(day, null)
              : null,
        ),
        for (final option in DayPortion.partsCountOptions)
          _TileData(
            key: 'reading_plan_day_option_$option',
            title: label(option),
            subtitle: description(option),
            selected: portion.partsCustom && portion.partsCount == option,
            onSelect: portion.partsCustom && portion.partsCount == option
                ? null
                : () => notifier.setDayReadingPlan(day, option),
          ),
      ],
    );
  }

  static Future<void> _showSheet(
    BuildContext context, {
    required String title,
    required String description,
    required List<_TileData> tiles,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.signalBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                for (final tile in tiles)
                  _OptionTile(
                    key: ValueKey(tile.key),
                    title: tile.title,
                    subtitle: tile.subtitle,
                    selected: tile.selected,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      tile.onSelect?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondaryNeutral : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
            border: Border.all(
              color: selected ? AppColors.secondaryBorder : AppColors.mistGray,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.ink : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.signalBlack,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileData {
  final String key;
  final String title;
  final String subtitle;
  final bool selected;

  /// Null when choosing this option would change nothing.
  final VoidCallback? onSelect;

  const _TileData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
  });
}
