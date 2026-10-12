import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../localization/app_language.dart';
import '../localization/locale_keys.g.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable minimal, sleek bottom sheet for confirming user actions across the app.
class AppConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool isDestructive;
  final Widget? customContent;

  const AppConfirmationSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.isDestructive = false,
    this.customContent,
  });

  /// Displays the confirmation sheet and returns `true` if confirmed, `false` otherwise.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    bool isDestructive = false,
    Widget? customContent,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppConfirmationSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        isDestructive: isDestructive,
        customContent: customContent,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);

    final effectiveConfirmLabel = confirmLabel ?? LocaleKeys.common.confirm.tr();
    final effectiveCancelLabel = cancelLabel ?? LocaleKeys.common.cancel.tr();

    final effectiveIcon = icon ??
        (isDestructive
            ? Icons.warning_amber_rounded
            : Icons.help_outline_rounded);
    final effectiveIconColor = iconColor ??
        (isDestructive ? AppColors.terracotta : AppColors.ink);
    final effectiveIconBg = iconBackgroundColor ??
        (isDestructive
            ? AppColors.terracotta.withValues(alpha: 0.1)
            : AppColors.controlSurface);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppColors.mistGray, width: 1),
          left: BorderSide(color: AppColors.mistGray, width: 1),
          right: BorderSide(color: AppColors.mistGray, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sleek Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mistGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Icon badge + Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      border: Border.all(
                        color: effectiveIconColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      effectiveIcon,
                      color: effectiveIconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: isAr
                          ? AppTypography.arabicSurahTitle(AppColors.signalBlack, 19)
                          : theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.signalBlack,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description Message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.bodyGray,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),

              // Dynamic custom content slot
              if (customContent != null) ...[
                const SizedBox(height: 14),
                customContent!,
              ],

              const SizedBox(height: 22),

              // Action Buttons: Cancel & Confirm
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.mistGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        ),
                      ),
                      child: Text(
                        effectiveCancelLabel,
                        style: const TextStyle(
                          color: AppColors.bodyGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive
                            ? AppColors.terracotta
                            : AppColors.ink,
                        foregroundColor: AppColors.buttonText,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        ),
                      ),
                      child: Text(
                        effectiveConfirmLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
