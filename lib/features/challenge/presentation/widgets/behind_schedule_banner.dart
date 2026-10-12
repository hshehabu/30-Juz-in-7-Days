import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';

class BehindScheduleBanner extends StatelessWidget {
  final int missedCount;
  final int daysRemaining;
  final VoidCallback onContinueToday;
  final VoidCallback onAdjustPlan;

  const BehindScheduleBanner({
    super.key,
    required this.missedCount,
    required this.daysRemaining,
    required this.onContinueToday,
    required this.onAdjustPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.controlSurface,
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(
          color: AppColors.mistGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: AppColors.ink,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.home.behind_schedule_title.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.signalBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.home.behind_schedule_desc.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.bodyGray,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onContinueToday,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  ),
                ),
                child: Text(LocaleKeys.home.catch_up.tr()),
              ),
              ElevatedButton(
                onPressed: onAdjustPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                  ),
                ),
                child: Text(LocaleKeys.home.adjust_plan.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
