import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/app_language.dart';
import 'core/localization/locale_keys.g.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'features/challenge/presentation/notifiers/challenge_providers.dart';
import 'features/challenge/presentation/notifiers/challenge_state.dart';
import 'features/home_widget/home_widget_service.dart';
import 'features/navigation/main_navigation_shell.dart';
import 'features/onboarding/presentation/pages/onboarding_flow_page.dart';

/// App-wide messenger so errors can be surfaced from any screen.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Offline-first fonts: use pre-bundled asset fonts and prevent network lookup
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

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
    languageCode: storageService.languageCode,
    onMarkCompleted: (dayNumber) {
      container
          .read(challengeStateProvider.notifier)
          .markDayCompleted(dayNumber);
    },
  );

  runApp(
    EasyLocalization(
      supportedLocales: AppLanguage.supportedLocales,
      path: 'assets/translations',
      fallbackLocale: AppLanguage.fallbackLocale,
      child: UncontrolledProviderScope(
        container: container,
        child: const ThirtyJuzApp(),
      ),
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
  Timer? _midnightTimer;
  String? _syncedLanguageCode;
  bool _startupRefreshDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
    HomeWidgetService.registerCallback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  Future<void> _onResumed() async {
    // Pick up travel / DST changes, progress written from a notification
    // action in the background, and the current calendar day.
    await ref.read(notificationServiceProvider).syncTimeZone();
    await ref.read(challengeStateProvider.notifier).refreshFromDisk();
    _scheduleMidnightRefresh();
  }

  /// Refreshes "today" when the date changes while the app stays open.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      ref.read(challengeStateProvider.notifier).loadInitialData();
      _scheduleMidnightRefresh();
    });
  }

  /// Keeps the stored language (used for notifications) in sync with the UI
  /// locale, and re-plans reminders on first launch and language changes.
  void _syncLanguage(String languageCode) {
    if (_syncedLanguageCode == languageCode) return;
    final isFirstSync = _syncedLanguageCode == null;
    _syncedLanguageCode = languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = ref.read(storageServiceProvider);
      final notifications = ref.read(notificationServiceProvider);
      final changed = storage.languageCode != languageCode;
      if (changed) await storage.setLanguageCode(languageCode);
      await notifications.setLanguage(languageCode);
      if (changed) {
        await HomeWidgetService.update(
            ref.read(challengeStateProvider).challenge, languageCode);
      }
      if (changed || (isFirstSync && !_startupRefreshDone)) {
        _startupRefreshDone = true;
        await ref.read(challengeStateProvider.notifier).refreshReminders();
      }
    });
  }

  void _showSnack(String message) {
    appScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeStateProvider);
    _syncLanguage(context.locale.languageCode);

    ref.listen<ChallengeState>(challengeStateProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        _showSnack(LocaleKeys.errors.generic.tr());
      }
      if (next.autoStartedNewCycle && !(prev?.autoStartedNewCycle ?? false)) {
        _showSnack(LocaleKeys.settings.auto_continue_started.tr());
      }
      // Keep the home-screen widget in sync with every progress change.
      if (next.isInitialized && !identical(prev?.challenge, next.challenge)) {
        HomeWidgetService.update(next.challenge, context.locale.languageCode);
      }
    });

    return MaterialApp(
      onGenerateTitle: (context) => LocaleKeys.common.app_name.tr(),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: _buildHomeWidget(state),
    );
  }

  Widget _buildHomeWidget(ChallengeState state) {
    final showSplash =
        !state.isInitialized || (state.isLoading && state.challenge == null);
    if (showSplash) {
      return const _SplashScreen();
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppColors.standardRadius),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppColors.standardRadius),
                    color: AppColors.controlSurface,
                    border: Border.all(color: AppColors.mistGray, width: 1.0),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.ink,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              LocaleKeys.common.app_name.tr(),
              style: AppTypography.appBarTitle(
                AppColors.signalBlack,
                AppLanguage.isArabic(context),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
