import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'features/challenge/presentation/notifiers/challenge_providers.dart';
import 'features/navigation/main_navigation_shell.dart';
import 'features/onboarding/presentation/pages/onboarding_flow_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage initialization
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  // Notification service initialization
  final notificationService = NotificationService();

  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
  );

  await notificationService.initialize(
    onMarkCompleted: (dayNumber) {
      container
          .read(challengeStateProvider.notifier)
          .markDayCompleted(dayNumber);
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ThirtyJuzApp(),
    ),
  );
}

class ThirtyJuzApp extends ConsumerStatefulWidget {
  const ThirtyJuzApp({super.key});

  @override
  ConsumerState<ThirtyJuzApp> createState() => _ThirtyJuzAppState();
}

class _ThirtyJuzAppState extends ConsumerState<ThirtyJuzApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload challenge data in case modified in background from notification action
      ref.read(challengeStateProvider.notifier).loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeStateProvider);

    return MaterialApp(
      title: "30 Juz' in 7 Days",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHomeWidget(state),
    );
  }

  Widget _buildHomeWidget(dynamic state) {
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.parchment,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/app_logo.jpg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.parchmentLight,
                      border: Border.all(color: AppColors.brassGold, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: AppColors.brassGold,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "30 Juz' in 7 Days",
                style: AppTypography.appBarTitle(AppColors.deepBrown),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.brassGold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If an active challenge exists, launch the main navigation shell
    if (state.challenge != null) {
      return const MainNavigationShell();
    }

    // Otherwise launch the onboarding setup flow
    return OnboardingFlowPage(
      onCompleted: () {
        // Will trigger rebuild via Riverpod state change
      },
    );
  }
}
