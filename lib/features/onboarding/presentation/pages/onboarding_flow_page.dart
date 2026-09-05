import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              primary: AppColors.brassGold,
              onPrimary: AppColors.textLight,
              surface: AppColors.parchmentLight,
              onSurface: AppColors.deepBrown,
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
              primary: AppColors.brassGold,
              onPrimary: AppColors.textLight,
              surface: AppColors.parchmentLight,
              onSurface: AppColors.deepBrown,
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

    final notifier = ref.read(challengeStateProvider.notifier);
    await notifier.startChallenge(
      startDate: _selectedStartDate,
      reminderTime: _selectedReminderTime,
    );

    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: _prevPage,
                      color: AppColors.deepBrown,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const SizedBox(width: 18),
                  const Spacer(),
                  // Dots
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index == _currentPage;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.brassGold
                              : AppColors.softSand,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  const SizedBox(width: 18),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          // Scholarly app logo
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/app_logo.jpg',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.parchmentLight,
                  border: Border.all(color: AppColors.brassGold, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 38,
                    color: AppColors.brassGold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            "30 Juz' in 7 Days",
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.deepBrown,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          Text(
            'Complete the Qur\'an in seven days with a simple daily reminder and progress tracker.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.deepBrown,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Hadith reference banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.parchmentLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.softSand),
            ),
            child: Column(
              children: [
                Text(
                  'اقرأ القرآن في سبع ولا تزد على ذلك',
                  style: AppTypography.scholarlyQuote(AppColors.brassGold).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sahih al-Bukhari 5052',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Start My 7-Day Khatmah'),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Choose Start Date ---
  Widget _buildStartDateStep(ThemeData theme) {
    final isToday = _selectedStartDate.day == DateTime.now().day &&
        _selectedStartDate.month == DateTime.now().month &&
        _selectedStartDate.year == DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'When would you like to begin?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.deepBrown,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your 7-day khatmah will run for 7 consecutive days starting from your chosen date.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isToday ? AppColors.parchmentLight : AppColors.parchment,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday ? AppColors.brassGold : AppColors.softSand,
                  width: isToday ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isToday
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isToday ? AppColors.brassGold : AppColors.textMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepBrown,
                          ),
                        ),
                        Text(
                          AppDateUtils.formatDate(DateTime.now()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: !isToday ? AppColors.parchmentLight : AppColors.parchment,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isToday ? AppColors.brassGold : AppColors.softSand,
                  width: !isToday ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !isToday
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: !isToday ? AppColors.brassGold : AppColors.textMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose another date',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepBrown,
                          ),
                        ),
                        Text(
                          !isToday
                              ? AppDateUtils.formatDate(_selectedStartDate)
                              : 'Select a future start date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: !isToday
                                ? AppColors.brassGold
                                : AppColors.textMuted,
                            fontWeight:
                                !isToday ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.brassGold,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Daily Reminder ---
  Widget _buildReminderStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'When should we remind you?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.deepBrown,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We will send one gentle daily reminder with today\'s assigned reading portion.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),

          // Time selector tile
          InkWell(
            onTap: _pickReminderTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.parchmentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brassGold, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.brassGold,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Daily reminder at:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBrown,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.softSand),
                    ),
                    child: Text(
                      AppDateUtils.formatTimeOfDay(_selectedReminderTime),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.brassGoldDark,
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
              color: AppColors.parchmentLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.softSand),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.brassGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No spam or aggressive messaging. If you complete your portion early, we will not send that day\'s reminder.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.deepBrown,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 4: Confirm Summary ---
  Widget _buildConfirmStep(ThemeData theme) {
    final endDate = _selectedStartDate.add(const Duration(days: 6));

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Your 7-Day Khatmah',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.deepBrown,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please review your challenge plan before beginning.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.parchmentLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.softSand),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Start Date',
                  AppDateUtils.formatDateWithYear(_selectedStartDate),
                  theme,
                ),
                const Divider(height: 22),
                _buildSummaryRow(
                  'End Date',
                  AppDateUtils.formatDateWithYear(endDate),
                  theme,
                ),
                const Divider(height: 22),
                _buildSummaryRow(
                  'Day 1 Portion',
                  'Al-Baqarah → An-Nisa (3 surahs)',
                  theme,
                ),
                const Divider(height: 22),
                _buildSummaryRow(
                  'Daily Reminder',
                  AppDateUtils.formatTimeOfDay(_selectedReminderTime),
                  theme,
                ),
              ],
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finishAndStart,
              child: const Text('Start Khatmah'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.deepBrown,
          ),
        ),
      ],
    );
  }
}
