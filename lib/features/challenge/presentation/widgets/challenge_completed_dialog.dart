import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
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
    final isAr = AppLanguage.isArabic(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        side: const BorderSide(color: AppColors.mistGray),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      title: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.controlSurface,
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              border: Border.all(color: AppColors.mistGray, width: 1.0),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.ink,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.completion_dialog.title.tr(),
            style: AppTypography.appBarTitle(AppColors.signalBlack, isAr),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.completion_dialog.subtitle.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.signalBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryNeutral,
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              border: Border.all(color: AppColors.secondaryBorder),
            ),
            child: Text(
              LocaleKeys.completion_dialog.badge.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.completion_dialog.dua.tr(),
            style: AppTypography.scholarlyQuote(AppColors.bodyGray, isAr).copyWith(
              fontSize: 14,
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.standardRadius),
                ),
              ),
              child: Text(LocaleKeys.completion_dialog.start_another.tr()),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              child: Text(LocaleKeys.completion_dialog.view_summary.tr()),
            ),
          ],
        ),
      ],
    );
  }
}
