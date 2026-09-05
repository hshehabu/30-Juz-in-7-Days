import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ChallengeCompletedDialog extends StatelessWidget {
  final VoidCallback onStartAnother;
  final VoidCallback onDismiss;

  const ChallengeCompletedDialog({
    super.key,
    required this.onStartAnother,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onStartAnother,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChallengeCompletedDialog(
        onStartAnother: onStartAnother,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      title: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.brassGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brassGold, width: 1.5),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.brassGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Alhamdulillah 🤍',
            style: AppTypography.appBarTitle(AppColors.brassGold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You completed your 7-day khatmah.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.deepBrown,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.softSand),
            ),
            child: Text(
              '30 Juz\' Completed ✓',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.brassGoldDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'May Allah accept your recitation and make it a light in your heart.',
            style: AppTypography.scholarlyQuote(AppColors.deepBrown).copyWith(
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onStartAnother();
              },
              child: const Text('Start Another Khatmah'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              child: const Text('View Journey Summary'),
            ),
          ],
        ),
      ],
    );
  }
}
