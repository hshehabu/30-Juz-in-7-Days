import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_confirmation_sheet.dart';
import '../../../challenge/presentation/notifiers/challenge_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final VoidCallback onStartNewKhatmah;

  const SettingsPage({super.key, required this.onStartNewKhatmah});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    // Pure UI tick to refresh the countdown display
    setState(() {});
  }

  /// Returns the countdown to the daily reminder time.
  String _formatCountdown(TimeOfDay reminderTime) {
    final now = DateTime.now();
    var nextReminder = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
      0,
    );
    if (!nextReminder.isAfter(now)) {
      nextReminder = nextReminder.add(const Duration(days: 1));
    }

    final isNow =
        now.hour == nextReminder.hour && now.minute == nextReminder.minute;
    if (isNow) return LocaleKeys.settings.due_now.tr();

    final diff = nextReminder.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }

  void _confirmRestart(BuildContext context) async {
    final confirmed = await AppConfirmationSheet.show(
      context,
      title: LocaleKeys.settings.restart_dialog_title.tr(),
      message: LocaleKeys.settings.restart_dialog_desc.tr(),
      confirmLabel: LocaleKeys.settings.restart_confirm.tr(),
      cancelLabel: LocaleKeys.common.cancel.tr(),
      isDestructive: true,
      icon: Icons.refresh_rounded,
    );
    if (confirmed && mounted) {
      ref.read(challengeStateProvider.notifier).restartCurrentChallenge();
    }
  }

  void _confirmStartNew(BuildContext context) async {
    final confirmed = await AppConfirmationSheet.show(
      context,
      title: LocaleKeys.settings.new_dialog_title.tr(),
      message: LocaleKeys.settings.new_dialog_desc.tr(),
      confirmLabel: LocaleKeys.settings.new_confirm.tr(),
      cancelLabel: LocaleKeys.common.cancel.tr(),
      icon: Icons.add_circle_outline_rounded,
      iconColor: AppColors.dustyGreen,
    );
    if (confirmed && mounted) {
      widget.onStartNewKhatmah();
    }
  }

  void _showLanguagePicker(BuildContext context) {
    final currentCode = context.locale.languageCode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      backgroundColor: AppColors.paper,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.settings.choose_language.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.signalBlack,
                  ),
                ),
                const SizedBox(height: 14),
                ...AppLanguage.supportedLocales.map((locale) {
                  final isSelected = locale.languageCode == currentCode;
                  final name = AppLanguage.languageNames[locale.languageCode] ??
                      locale.languageCode;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      if (!isSelected) {
                        await AppLanguage.switchLanguage(context, locale);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondaryNeutral
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondaryBorder
                              : AppColors.mistGray,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? AppColors.ink
                                : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppColors.signalBlack,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeStateProvider);
    final storage = ref.watch(storageServiceProvider);
    final challenge = state.challenge;
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);

    final isReminderOn = storage.isReminderEnabled;
    final currentReminderTime = storage.reminderTime;
    final currentLangName =
        AppLanguage.languageNames[context.locale.languageCode] ?? 'English';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.settings.title.tr(),
          style: AppTypography.appBarTitle(AppColors.signalBlack),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Daily Reminder
            Text(
              LocaleKeys.settings.notifications_section.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                side: const BorderSide(color: AppColors.mistGray),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    value: isReminderOn,
                    activeThumbColor: AppColors.buttonText,
                    activeTrackColor: AppColors.ink,
                    title: Text(
                      LocaleKeys.settings.daily_reminder.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      LocaleKeys.settings.daily_reminder_desc.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                    onChanged: (val) async {
                      if (val) {
                        final notifService =
                            ref.read(notificationServiceProvider);
                        await notifService.requestPermissions();
                      }
                      await ref
                          .read(challengeStateProvider.notifier)
                          .updateReminderSettings(
                            enabled: val,
                            reminderTime: currentReminderTime,
                          );
                    },
                  ),
                  if (isReminderOn) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: AppColors.ink,
                      ),
                      title: Text(
                        LocaleKeys.settings.reminder_time.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        AppDateUtils.formatTimeOfDay(currentReminderTime, context.locale.languageCode),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.mistGray,
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: currentReminderTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.ink,
                                  onPrimary: AppColors.paper,
                                  surface: AppColors.paper,
                                  onSurface: AppColors.ink,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          final notifService =
                              ref.read(notificationServiceProvider);
                          await notifService.requestPermissions();
                          await ref
                              .read(challengeStateProvider.notifier)
                              .updateReminderSettings(
                                enabled: isReminderOn,
                                reminderTime: picked,
                              );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            size: 16,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              LocaleKeys.settings.next_reminder_in.tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.bodyGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.controlSurface,
                              borderRadius: BorderRadius.circular(AppColors.standardRadius),
                              border: Border.all(color: AppColors.mistGray),
                            ),
                            child: Text(
                              _formatCountdown(currentReminderTime),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              LocaleKeys.settings.test_reminder_title.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              side: const BorderSide(color: AppColors.mistGray),
                            ),
                            onPressed: () async {
                              final notif = ref.read(notificationServiceProvider);
                              await notif.requestPermissions();
                              await notif.showDailyReminderNow(
                                dayNumber: 1,
                                rangeDisplay: 'Al-Baqarah (Test)',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(LocaleKeys.settings.test_sent.tr()),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              LocaleKeys.settings.test_now.tr(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              side: const BorderSide(color: AppColors.ink),
                            ),
                            onPressed: () async {
                              final notif = ref.read(notificationServiceProvider);
                              await notif.requestPermissions();
                              await notif.scheduleTestReminder(seconds: 5);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(LocaleKeys.settings.test_scheduled_5s.tr()),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              LocaleKeys.settings.test_in_5s.tr(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Language Selector
            Text(
              LocaleKeys.settings.language_section.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                side: const BorderSide(color: AppColors.mistGray),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
                title: Text(
                  LocaleKeys.settings.app_language.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  currentLangName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onTap: () => _showLanguagePicker(context),
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Current Khatmah Info & Management
            Text(
              LocaleKeys.settings.management_section.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                border: Border.all(color: AppColors.mistGray),
              ),
              child: challenge != null
                  ? Column(
                      children: [
                        _buildInfoItem(
                          LocaleKeys.settings.started.tr(),
                          AppDateUtils.formatDateWithYear(challenge.startDate, context.locale.languageCode),
                          theme,
                        ),
                        const Divider(height: 18),
                        _buildInfoItem(
                          LocaleKeys.settings.ends.tr(),
                          AppDateUtils.formatDateWithYear(challenge.endDate, context.locale.languageCode),
                          theme,
                        ),
                        const Divider(height: 18),
                        _buildInfoItem(
                          LocaleKeys.settings.progress_label.tr(),
                          challenge.isExpired
                              ? LocaleKeys.settings.ended_progress.tr(
                                  args: [challenge.completedPortionsCount.toString()],
                                )
                              : LocaleKeys.settings.active_progress.tr(
                                  args: [
                                    challenge.displayDayNumber.toString(),
                                    challenge.completedPortionsCount.toString(),
                                  ],
                                ),
                          theme,
                        ),
                      ],
                    )
                  : Text(
                      LocaleKeys.settings.no_active_khatmah.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
            const SizedBox(height: 16),


            // Challenge actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmRestart(context),
                    child: Text(LocaleKeys.settings.restart_button.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmStartNew(context),
                    child: Text(LocaleKeys.settings.new_button.tr()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 4: About & Religious Basis
            Text(
              LocaleKeys.settings.about_section.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppColors.standardRadius),
                border: Border.all(color: AppColors.mistGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      LocaleKeys.common.app_name.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.signalBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    LocaleKeys.settings.app_desc.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
                  ),
                  const Divider(height: 20),
                  Text(
                    LocaleKeys.settings.religious_foundation.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.signalBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    KhatmahConstants.getHadithQuote(isAr),
                    style: AppTypography.scholarlyQuote(AppColors.signalBlack, isAr).copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    LocaleKeys.settings.hadith_text.tr(context: context),
                    style: isAr
                        ? AppTypography.scholarlyQuote(AppColors.bodyGray, true).copyWith(
                            fontSize: 14,
                            height: 1.6,
                          )
                        : theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.bodyGray,
                            height: 1.45,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocaleKeys.settings.hadith_source.tr(context: context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.signalBlack,
            ),
          ),
        ),
      ],
    );
  }
}
