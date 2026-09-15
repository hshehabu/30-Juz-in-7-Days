import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/khatmah_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../challenge/presentation/notifiers/challenge_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final VoidCallback onStartNewKhatmah;

  const SettingsPage({super.key, required this.onStartNewKhatmah});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  Timer? _tickerTimer;
  bool _canScheduleExact = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExactAlarmPermission();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExactAlarmPermission() async {
    final notifService = ref.read(notificationServiceProvider);
    final canExact = await notifService.canScheduleExact();
    if (mounted && canExact != _canScheduleExact) {
      final wasFalse = !_canScheduleExact && canExact;
      setState(() {
        _canScheduleExact = canExact;
      });
      // Only reschedule if the permission was freshly granted from settings
      if (wasFalse) {
        ref.read(challengeStateProvider.notifier).rescheduleReminders();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExactAlarmPermission();
    }
  }

  void _onTick() {
    if (!mounted) return;
    // Pure UI tick to refresh the countdown display
    setState(() {});
  }

  /// Returns the countdown to the next drop time from [6:00, 12:00, 18:00].
  String _formatCountdown() {
    final now = DateTime.now();
    DateTime? nextDrop;
    for (final dropHour in NotificationService.dropHours) {
      final candidate = DateTime(
          now.year, now.month, now.day, dropHour, 0, 0);
      if (candidate.isAfter(now)) {
        nextDrop = candidate;
        break;
      }
    }
    // All drops passed today — next is 6 AM tomorrow
    nextDrop ??= DateTime(
        now.year, now.month, now.day + 1, NotificationService.dropHours[0], 0, 0);

    final isNow = now.hour == nextDrop.hour && now.minute == nextDrop.minute;
    if (isNow) return 'Due now \u{1F514}';

    final diff = nextDrop.difference(now);
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

  void _confirmRestart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Restart your khatmah?',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
        content: const Text(
          'Your current progress will be reset back to Day 1. This action cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(challengeStateProvider.notifier)
                  .restartCurrentChallenge();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _confirmStartNew(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Start a new khatmah?',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
        content: const Text(
          'Your current challenge is still in progress. Starting a new one will archive your current progress.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onStartNewKhatmah();
            },
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }

  void _confirmResetSchedule(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset Schedule?',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
        content: const Text(
          'This will restore the authentic 7-day traditional schedule (3, 5, 7, 9, 11, 13, Mufassal) while preserving your completed days.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(challengeStateProvider.notifier).resetToTraditionalSchedule();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Schedule restored to authentic traditional portions.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset Schedule'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeStateProvider);
    final storage = ref.watch(storageServiceProvider);
    final challenge = state.challenge;
    final theme = Theme.of(context);

    final isReminderOn = storage.isReminderEnabled;
    final currentReminderTime = storage.reminderTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.appBarTitle(AppColors.deepBrown),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Daily Reminder
            Text(
              'DAILY REMINDER',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.brassGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: AppColors.parchmentLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.softSand),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    value: isReminderOn,
                    activeThumbColor: AppColors.brassGold,
                    title: Text(
                      'Daily Reminder Notification',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Receive gentle daily notice for your assigned portion',
                      style: theme.textTheme.bodySmall,
                    ),
                    onChanged: (val) {
                      ref
                          .read(challengeStateProvider.notifier)
                          .updateReminderSettings(
                            enabled: val,
                            reminderTime: currentReminderTime,
                          );
                    },
                  ),
                  if (isReminderOn) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            size: 18,
                            color: AppColors.brassGold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Next reminder in',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.deepBrown,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.parchment,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.softSand),
                            ),
                            child: Text(
                              _formatCountdown(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.brassGoldDark,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Current Khatmah Info
            Text(
              'CURRENT KHATMAH',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.brassGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.parchmentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.softSand),
              ),
              child: challenge != null
                  ? Column(
                      children: [
                        _buildInfoItem(
                          'Started',
                          AppDateUtils.formatDateWithYear(challenge.startDate),
                          theme,
                        ),
                        const Divider(height: 20),
                        _buildInfoItem(
                          'Ends',
                          AppDateUtils.formatDateWithYear(challenge.endDate),
                          theme,
                        ),
                        const Divider(height: 20),
                        _buildInfoItem(
                          'Progress',
                          challenge.isExpired
                              ? 'Ended • ${challenge.completedPortionsCount}/7 completed'
                              : 'Day ${challenge.displayDayNumber} of 7 • ${challenge.completedPortionsCount}/7 completed',
                          theme,
                        ),
                      ],
                    )
                  : Text(
                      'No active khatmah in progress',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Challenge actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmRestart(context),
                    child: const Text('Restart Khatmah'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmStartNew(context),
                    child: const Text('New Khatmah'),
                  ),
                ),
              ],
            ),
            if (challenge != null &&
                challenge.portions.any((p) => p.isAdjusted)) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmResetSchedule(context),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Reset Schedule to Traditional (Fami bi Shawq)'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brassGoldDark,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Section 3: About & Religious Basis
            Text(
              'ABOUT & FOUNDATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.brassGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.parchmentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.softSand),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/app_logo.jpg',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      KhatmahConstants.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepBrown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A companion for completing the Qur\'an in seven days. This app helps you stay committed to your daily recitation.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Religious Foundation',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brassGoldDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    KhatmahConstants.hadithText,
                    style: AppTypography.scholarlyQuote(AppColors.deepBrown).copyWith(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
              color: AppColors.deepBrown,
            ),
          ),
        ),
      ],
    );
  }
}
