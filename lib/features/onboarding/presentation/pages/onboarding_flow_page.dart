import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../challenge/presentation/notifiers/challenge_providers.dart';

class OnboardingFlowPage extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingFlowPage({super.key, required this.onCompleted});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  DateTime _selectedStartDate = AppDateUtils.dateOnly(DateTime.now());
  TimeOfDay _selectedReminderTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickStartDate() async {
    final now = AppDateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
      setState(() {
        _selectedStartDate = AppDateUtils.dateOnly(picked);
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime,
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
      setState(() {
        _selectedReminderTime = picked;
      });
    }
  }

  Future<void> _finishAndStart() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.requestPermissions();

    // Trigger completion callback first to pop the dialog gracefully
    // before the global loading state unmounts the navigation shell.
    widget.onCompleted();

    final challengeState = ref.read(challengeStateProvider);
    final notifier = ref.read(challengeStateProvider.notifier);

    if (challengeState.challenge != null) {
      await notifier.startNewChallenge(
        startDate: _selectedStartDate,
        reminderTime: _selectedReminderTime,
      );
    } else {
      await notifier.startChallenge(
        startDate: _selectedStartDate,
        reminderTime: _selectedReminderTime,
      );
    }
  }

  void _toggleLanguage() async {
    final newLocale = AppLanguage.isArabic(context)
        ? const Locale('en')
        : const Locale('ar');
    await AppLanguage.switchLanguage(context, newLocale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = AppLanguage.isArabic(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Step Indicator & Language Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                      onPressed: _prevPage,
                      color: AppColors.ink,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const SizedBox(width: 18),
                  const Spacer(),
                  // Step Indicator Bars
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index == _currentPage;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 6,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.ink
                              : AppColors.secondaryNeutral,
                          borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Language quick toggle
                  InkWell(
                    onTap: _toggleLanguage,
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.controlSurface,
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        border: Border.all(color: AppColors.secondaryBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.translate_rounded,
                            size: 14,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'English' : 'العربية',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomeStep(theme),
                  _buildStartDateStep(theme),
                  _buildReminderStep(theme),
                  _buildConfirmStep(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Welcome ---
  Widget _buildWelcomeStep(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Scholarly app logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppColors.standardRadius),
                          color: AppColors.controlSurface,
                          border: Border.all(
                            color: AppColors.mistGray,
                            width: 1.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 38,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    LocaleKeys.onboarding.step1_title.tr(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.signalBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  Text(
                    LocaleKeys.onboarding.step1_tagline.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Hadith reference banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.controlSurface,
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      border: Border.all(color: AppColors.mistGray),
                    ),
                    child: Column(
                      children: [
                        Text(
                          LocaleKeys.onboarding.hadith_quote.tr(),
                          style: AppTypography.scholarlyQuote(
                            AppColors.ink,
                            true,
                          ).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LocaleKeys.onboarding.hadith_ref.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(LocaleKeys.onboarding.step1_cta.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Step 2: Choose Start Date ---
  Widget _buildStartDateStep(ThemeData theme) {
    final isToday = _selectedStartDate.day == DateTime.now().day &&
        _selectedStartDate.month == DateTime.now().month &&
        _selectedStartDate.year == DateTime.now().year;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    LocaleKeys.onboarding.step2_title.tr(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.signalBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    LocaleKeys.onboarding.step2_desc.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Option: Today
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStartDate = AppDateUtils.dateOnly(DateTime.now());
                      });
                    },
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.paper
                            : AppColors.controlSurface,
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        border: Border.all(
                          color: isToday
                              ? AppColors.ink
                              : AppColors.mistGray,
                          width: isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isToday
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isToday
                                ? AppColors.ink
                                : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocaleKeys.onboarding.option_today.tr(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  AppDateUtils.formatDate(DateTime.now(), context.locale.languageCode),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option: Pick Future Date
                  InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: !isToday
                            ? AppColors.paper
                            : AppColors.controlSurface,
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        border: Border.all(
                          color: !isToday
                              ? AppColors.ink
                              : AppColors.mistGray,
                          width: !isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !isToday
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: !isToday
                                ? AppColors.ink
                                : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocaleKeys.onboarding.option_future.tr(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  !isToday
                                      ? AppDateUtils.formatDate(_selectedStartDate, context.locale.languageCode)
                                      : LocaleKeys.onboarding.select_future_date.tr(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: !isToday
                                        ? AppColors.ink
                                        : AppColors.secondaryText,
                                    fontWeight: !isToday
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.ink,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(LocaleKeys.onboarding.continue_button.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Step 3: Daily Reminder ---
  Widget _buildReminderStep(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    LocaleKeys.onboarding.step3_title.tr(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.signalBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    LocaleKeys.onboarding.step3_desc.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Time selector tile
                  InkWell(
                    onTap: _pickReminderTime,
                    borderRadius: BorderRadius.circular(AppColors.standardRadius),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.controlSurface,
                        borderRadius: BorderRadius.circular(AppColors.standardRadius),
                        border: Border.all(
                          color: AppColors.mistGray,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.ink,
                                  size: 24,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    LocaleKeys.onboarding.reminder_at.tr(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(AppColors.standardRadius),
                              border: Border.all(color: AppColors.secondaryBorder),
                            ),
                            child: Text(
                              AppDateUtils.formatTimeOfDay(_selectedReminderTime, context.locale.languageCode),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Explanation note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.controlSurface,
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      border: Border.all(color: AppColors.mistGray),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.ink,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            LocaleKeys.onboarding.reminder_note.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(LocaleKeys.onboarding.review_plan.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Step 4: Confirm Summary ---
  Widget _buildConfirmStep(ThemeData theme) {
    final endDate = _selectedStartDate.add(const Duration(days: 6));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    LocaleKeys.onboarding.step4_title.tr(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.signalBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    LocaleKeys.onboarding.step4_desc.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppColors.standardRadius),
                      border: Border.all(color: AppColors.mistGray),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                           LocaleKeys.onboarding.start_date.tr(),
                          AppDateUtils.formatDateWithYear(_selectedStartDate, context.locale.languageCode),
                          theme,
                        ),
                        const Divider(height: 22, color: AppColors.secondaryNeutral),
                        _buildSummaryRow(
                          LocaleKeys.onboarding.end_date.tr(),
                          AppDateUtils.formatDateWithYear(endDate, context.locale.languageCode),
                          theme,
                        ),
                        const Divider(height: 22, color: AppColors.secondaryNeutral),
                        _buildSummaryRow(
                          LocaleKeys.onboarding.day1_portion.tr(),
                          LocaleKeys.onboarding.day1_portion_value.tr(),
                          theme,
                        ),
                        const Divider(height: 22, color: AppColors.secondaryNeutral),
                        _buildSummaryRow(
                          LocaleKeys.onboarding.daily_reminder.tr(),
                          AppDateUtils.formatTimeOfDay(_selectedReminderTime, context.locale.languageCode),
                          theme,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishAndStart,
                      child: Text(LocaleKeys.onboarding.start_khatmah.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
