import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/day_portion.dart';

class PortionCard extends StatelessWidget {
  final DayPortion portion;
  final int currentDayNumber;
  final VoidCallback onMarkCompleted;
  final VoidCallback onUndoCompleted;

  const PortionCard({
    super.key,
    required this.portion,
    required this.currentDayNumber,
    required this.onMarkCompleted,
    required this.onUndoCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = portion.isCompleted;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.parchmentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppColors.brassGold : AppColors.softSand,
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S PORTION • DAY ${portion.dayNumber}",
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.brassGold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.softSand, width: 0.8),
                ),
                child: Text(
                  '${portion.surahCount} surahs',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main portion display in Cormorant Garamond
          Text(
            portion.rangeDisplay,
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.deepBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          // Arabic translation / calligraphy label
          if (portion.startSurahAr.isNotEmpty)
            Text(
              portion.rangeDisplayAr,
              style: AppTypography.scholarlyQuote(AppColors.brassGold).copyWith(
                fontSize: 18,
                fontStyle: FontStyle.normal,
              ),
            ),
          const SizedBox(height: 24),

          // Action area
          if (!isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkCompleted,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Mark as completed'),
              ),
            ),
          ] else ...[
            // Completed state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.brassGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.brassGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.brassGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Completed — Alhamdulillah 🤍',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.brassGoldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: onUndoCompleted,
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Undo completion'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
