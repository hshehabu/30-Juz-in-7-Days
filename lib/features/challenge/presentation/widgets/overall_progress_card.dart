import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OverallProgressCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double percentage;

  const OverallProgressCard({
    super.key,
    required this.completedCount,
    this.totalCount = 7,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentInt = (percentage * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.parchmentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softSand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBrown,
                ),
              ),
              Text(
                '$percentInt% complete',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brassGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Custom smooth segmented progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.softSand.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brassGold),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            '$completedCount / $totalCount portions completed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
