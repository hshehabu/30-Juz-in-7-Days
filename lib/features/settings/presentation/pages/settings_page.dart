import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_planner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_confirmation_sheet.dart';
import '../../../challenge/domain/entities/challenge.dart';
import '../../../backup/backup_actions.dart';
import '../../../challenge/presentation/notifiers/challenge_providers.dart';
import '../../../challenge/presentation/widgets/reading_plan_picker.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final VoidCallback onStartNewKhatmah;

  /// Whether this tab is visible; the live countdown only ticks while it is.
  final bool isCurrentTab;

  const SettingsPage({
    super.key,
    required this.onStartNewKhatmah,
    this.isCurrentTab = true,
  });

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  ReminderPermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      _checkPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final previous = _permissionStatus;
      final status = await ref
          .read(notificationServiceProvider)
          .getPermissionStatus();
      if (!mounted) return;
      setState(() => _permissionStatus = status);
      // Exact alarms just became available: re-plan with precise timing.
      if (previous != null &&
          !previous.exactAlarmsAllowed &&
          status.exactAlarmsAllowed) {
        ref.read(challengeStateProvider.notifier).refreshReminders();
      }
    } catch (_) {}
  }

  Future<void> _fixPermissions() async {
    final notifService = ref.read(notificationServiceProvider);
    final status = _permissionStatus;
    if (status != null && !status.notificationsEnabled) {
      await notifService.requestPermissions();
    } else {
      await notifService.requestExactAlarmsPermission();
    }
    await _checkPermissionStatus();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
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
  }

  static int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

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
                  final name =
                      AppLanguage.languageNames[locale.languageCode] ??
                      locale.languageCode;
                  return Semantics(
                    selected: isSelected,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppColors.standardRadius,
                      ),
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
                          borderRadius: BorderRadius.circular(
                            AppColors.standardRadius,
                          ),
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
                                style: Theme.of(context).textTheme.titleSmall
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
    final locale = context.locale.languageCode;

    final isReminderOn = storage.isReminderEnabled;
    final currentReminderTime = storage.reminderTime;
    final isFollowUpOn = storage.isFollowUpEnabled;
    final followUpTime = storage.followUpTime;
    final isAutoContinue = storage.isAutoContinueEnabled;
    final currentLangName =
        AppLanguage.languageNames[context.locale.languageCode] ?? 'English';
    final status = _permissionStatus;

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
            _sectionLabel(
              context,
              LocaleKeys.settings.notifications_section.tr(),
            ),
            const SizedBox(height: 8),
            if (isReminderOn && status != null && !status.isHealthy) ...[
              _buildHealthWarning(context, status),
              const SizedBox(height: 10),
            ],
            _card(
              Column(
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
                        await ref
                            .read(notificationServiceProvider)
                            .requestPermissions();
                      }
                      await ref
                          .read(challengeStateProvider.notifier)
                          .updateReminderSettings(
                            enabled: val,
                            reminderTime: currentReminderTime,
                          );
                      await _checkPermissionStatus();
                    },
                  ),
                  if (isReminderOn) ...[
                    const Divider(height: 1),
                    _timeTile(
                      context,
                      icon: Icons.access_time_rounded,
                      title: LocaleKeys.settings.reminder_time.tr(),
                      time: currentReminderTime,
                      locale: locale,
                      onTap: () async {
                        final picked = await _pickTime(currentReminderTime);
                        if (picked == null) return;
                        await ref
                            .read(challengeStateProvider.notifier)
                            .updateReminderSettings(
                              enabled: true,
                              reminderTime: picked,
                            );
                        // Keep the follow-up after the main reminder.
                        if (isFollowUpOn &&
                            _minutesOf(followUpTime) <= _minutesOf(picked)) {
                          await ref
                              .read(challengeStateProvider.notifier)
                              .updateFollowUpSettings(
                                enabled: false,
                                followUpTime: followUpTime,
                              );
                          if (mounted) {
                            _showSnack(
                              LocaleKeys.settings.follow_up_must_be_later.tr(),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _NextReminderRow(
                      challenge: challenge,
                      reminderTime: currentReminderTime,
                      followUpTime: isFollowUpOn ? followUpTime : null,
                      active: widget.isCurrentTab,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: isFollowUpOn,
                      activeThumbColor: AppColors.buttonText,
                      activeTrackColor: AppColors.ink,
                      title: Text(
                        LocaleKeys.settings.follow_up.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        LocaleKeys.settings.follow_up_desc.tr(),
                        style: theme.textTheme.bodySmall,
                      ),
                      onChanged: (val) async {
                        var time = followUpTime;
                        if (val &&
                            _minutesOf(time) <=
                                _minutesOf(currentReminderTime)) {
                          // Default to two hours after the daily reminder.
                          final m = (_minutesOf(currentReminderTime) + 120)
                              .clamp(0, 23 * 60 + 59);
                          time = TimeOfDay(hour: m ~/ 60, minute: m % 60);
                        }
                        await ref
                            .read(challengeStateProvider.notifier)
                            .updateFollowUpSettings(
                              enabled: val,
                              followUpTime: time,
                            );
                      },
                    ),
                    if (isFollowUpOn) ...[
                      const Divider(height: 1),
                      _timeTile(
                        context,
                        icon: Icons.nightlight_round,
                        title: LocaleKeys.settings.follow_up_time.tr(),
                        time: followUpTime,
                        locale: locale,
                        onTap: () async {
                          final picked = await _pickTime(followUpTime);
                          if (picked == null) return;
                          if (_minutesOf(picked) <=
                              _minutesOf(currentReminderTime)) {
                            if (mounted) {
                              _showSnack(
                                LocaleKeys.settings.follow_up_must_be_later
                                    .tr(),
                              );
                            }
                            return;
                          }
                          await ref
                              .read(challengeStateProvider.notifier)
                              .updateFollowUpSettings(
                                enabled: true,
                                followUpTime: picked,
                              );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Language Selector
            _sectionLabel(context, LocaleKeys.settings.language_section.tr()),
            const SizedBox(height: 8),
            _card(
              ListTile(
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
            _sectionLabel(context, LocaleKeys.settings.management_section.tr()),
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
                          AppDateUtils.formatDateWithYear(
                            challenge.startDate,
                            locale,
                          ),
                          theme,
                        ),
                        const Divider(height: 18),
                        _buildInfoItem(
                          LocaleKeys.settings.ends.tr(),
                          AppDateUtils.formatDateWithYear(
                            challenge.endDate,
                            locale,
                          ),
                          theme,
                        ),
                        const Divider(height: 18),
                        _buildInfoItem(
                          LocaleKeys.settings.progress_label.tr(),
                          challenge.isExpired
                              ? LocaleKeys.settings.ended_progress.tr(
                                  args: [
                                    challenge.completedPortionsCount.toString(),
                                  ],
                                )
                              : (challenge.isUpcoming
                                    ? (challenge.daysUntilStart <= 1
                                          ? LocaleKeys.home.starts_tomorrow.tr()
                                          : LocaleKeys.home.starts_in_days.tr(
                                              args: [
                                                challenge.daysUntilStart
                                                    .toString(),
                                              ],
                                            ))
                                    : LocaleKeys.settings.active_progress.tr(
                                        args: [
                                          challenge.displayDayNumber.toString(),
                                          challenge.completedPortionsCount
                                              .toString(),
                                        ],
                                      )),
                          theme,
                        ),
                        const Divider(height: 18),
                        _buildInfoItem(
                          LocaleKeys.progress.stat_khatmahs.tr(),
                          state.completedKhatmahCount.toString(),
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
                    onPressed: challenge == null
                        ? null
                        : () => _confirmRestart(context),
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
            const SizedBox(height: 20),

            // Section 4: Khatmah preferences
            _sectionLabel(context, LocaleKeys.settings.khatmah_section.tr()),
            const SizedBox(height: 8),
            _card(
              Column(
                children: [
                  ListTile(
                    key: const Key('settings_reading_plan'),
                    leading: const Icon(
                      Icons.view_agenda_outlined,
                      color: AppColors.ink,
                      size: 20,
                    ),
                    title: Text(
                      LocaleKeys.reading.picker_title.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      ReadingPlanPicker.label(state.readingPlanParts),
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    onTap: () => ReadingPlanPicker.show(context, ref),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: isAutoContinue,
                    activeThumbColor: AppColors.buttonText,
                    activeTrackColor: AppColors.ink,
                    title: Text(
                      LocaleKeys.settings.auto_continue.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      LocaleKeys.settings.auto_continue_desc.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                    onChanged: (val) => ref
                        .read(challengeStateProvider.notifier)
                        .setAutoContinue(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 5: Backup
            _sectionLabel(context, LocaleKeys.settings.backup_section.tr()),
            const SizedBox(height: 8),
            _card(
              Column(
                children: [
                  Builder(
                    builder: (tileContext) => ListTile(
                      key: const Key('settings_save_backup_file'),
                      leading: const Icon(
                        Icons.save_alt_rounded,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      title: Text(
                        LocaleKeys.settings.save_backup_file.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        state.lastBackupAt != null
                            ? LocaleKeys.settings.last_backup.tr(args: [
                                AppDateUtils.formatDateWithYear(
                                    state.lastBackupAt!, locale),
                              ])
                            : LocaleKeys.settings.save_backup_file_desc.tr(),
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () => BackupActions.saveBackupFile(tileContext, ref),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.restore_rounded,
                      color: AppColors.ink,
                      size: 20,
                    ),
                    title: Text(
                      LocaleKeys.settings.import_backup.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      LocaleKeys.settings.import_backup_desc.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () => BackupActions.showRestoreOptions(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              LocaleKeys.settings.backup_auto_note.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 24),

            // Section 6: About & Religious Basis
            _sectionLabel(context, LocaleKeys.settings.about_section.tr()),
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
                      borderRadius: BorderRadius.circular(
                        AppColors.standardRadius,
                      ),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        semanticLabel: LocaleKeys.common.app_name.tr(),
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
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
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
                    style: AppTypography.scholarlyQuote(
                      AppColors.signalBlack,
                      isAr,
                    ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    LocaleKeys.settings.hadith_text.tr(context: context),
                    style: isAr
                        ? AppTypography.scholarlyQuote(
                            AppColors.bodyGray,
                            true,
                          ).copyWith(fontSize: 14, height: 1.6)
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

  Widget _sectionLabel(BuildContext context, String text) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        side: const BorderSide(color: AppColors.mistGray),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _timeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required TimeOfDay time,
    required String locale,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.ink),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        AppDateUtils.formatTimeOfDay(time, locale),
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.mistGray,
      ),
      onTap: onTap,
    );
  }

  Widget _buildHealthWarning(
    BuildContext context,
    ReminderPermissionStatus status,
  ) {
    final theme = Theme.of(context);
    final blocked = !status.notificationsEnabled;
    return Container(
      key: const Key('reminder_health_warning'),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1EC),
        borderRadius: BorderRadius.circular(AppColors.standardRadius),
        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            blocked ? Icons.notifications_off_rounded : Icons.alarm_off_rounded,
            color: AppColors.terracotta,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blocked
                      ? LocaleKeys.settings.health_blocked.tr()
                      : LocaleKeys.settings.health_inexact.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.signalBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  blocked
                      ? LocaleKeys.settings.health_blocked_desc.tr()
                      : LocaleKeys.settings.health_inexact_desc.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.bodyGray,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _fixPermissions,
            child: Text(LocaleKeys.settings.fix.tr()),
          ),
        ],
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

/// Live countdown to the next reminder that is actually scheduled (computed
/// with the same [ReminderPlanner] rules as the scheduler). Only this row
/// rebuilds each second, and only while the Settings tab is visible.
class _NextReminderRow extends StatefulWidget {
  final Challenge? challenge;
  final TimeOfDay reminderTime;
  final TimeOfDay? followUpTime;
  final bool active;

  const _NextReminderRow({
    required this.challenge,
    required this.reminderTime,
    required this.followUpTime,
    required this.active,
  });

  @override
  State<_NextReminderRow> createState() => _NextReminderRowState();
}

class _NextReminderRowState extends State<_NextReminderRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _NextReminderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.active) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(DateTime? next, DateTime now) {
    if (next == null) return LocaleKeys.settings.next_reminder_none.tr();
    final diff = next.difference(now);
    if (diff.inSeconds < 60 &&
        diff.inSeconds >= -1 &&
        next.minute == now.minute) {
      return LocaleKeys.settings.due_now.tr();
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return LocaleKeys.settings.countdown_hms.tr(
        args: [hours.toString(), minutes, seconds],
      );
    }
    if (diff.inMinutes > 0) {
      return LocaleKeys.settings.countdown_ms.tr(
        args: [diff.inMinutes.toString(), seconds],
      );
    }
    return LocaleKeys.settings.countdown_s.tr(
      args: [diff.inSeconds.clamp(0, 59).toString()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final challenge = widget.challenge;
    DateTime? next;
    if (challenge != null) {
      final plan = ReminderPlanner.plan(
        now: now,
        startDate: challenge.startDate,
        reminderTime: widget.reminderTime,
        totalDays: challenge.portions.length,
        completedDays: challenge.portions
            .where((p) => p.isCompleted)
            .map((p) => p.dayNumber)
            .toSet(),
        followUpTime: widget.followUpTime,
      );
      if (plan.isNotEmpty) next = plan.first.when;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.controlSurface,
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              border: Border.all(color: AppColors.mistGray),
            ),
            child: Text(
              _format(next, now),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
