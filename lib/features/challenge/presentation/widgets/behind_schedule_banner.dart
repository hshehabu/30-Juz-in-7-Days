import 'package:flutter/material.dart';
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
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softSand,
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
                color: AppColors.brassGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'A gentle note on your progress',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have $missedCount unfinished previous portion${missedCount > 1 ? 's' : ''}, with $daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining in your khatmah.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.deepBrown,
              height: 1.4,
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
                ),
                child: const Text('Continue today\'s portion'),
              ),
              ElevatedButton(
                onPressed: onAdjustPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Adjust my remaining plan'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Adjusting will spread your remaining Surahs evenly across the days you have left.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
