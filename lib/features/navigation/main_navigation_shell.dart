import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/locale_keys.g.dart';
import '../../core/theme/app_colors.dart';
import '../challenge/presentation/pages/home_page.dart';
import '../challenge/presentation/pages/progress_page.dart';
import '../onboarding/presentation/pages/onboarding_flow_page.dart';
import '../settings/presentation/pages/settings_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final GlobalKey<ProgressPageState> _progressPageKey =
      GlobalKey<ProgressPageState>();

  void _navigateToTab(int index) {
    if (index == 1 && _currentIndex != 1) {
      _progressPageKey.currentState?.resetToStep1();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToJourneyFromHome() {
    _progressPageKey.currentState?.openStep2FromHome();
    setState(() {
      _currentIndex = 1;
    });
  }

  void _onBackToHome() {
    setState(() {
      _currentIndex = 0;
    });
    _progressPageKey.currentState?.resetToStep1();
  }

  void _openStartNewKhatmahFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (navContext) => OnboardingFlowPage(
          onCompleted: () {
            Navigator.of(navContext).pop();
            if (mounted) {
              setState(() {
                _currentIndex = 0;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly read context.locale so this stateful shell registers a dependency
    // on the active locale. When the user switches language in Settings, this shell
    // immediately rebuilds its BottomNavigationBar with the new localized labels and direction.
    final currentLocale = context.locale;

    final pages = [
      HomePage(
        onNavigateToProgress: _navigateToJourneyFromHome,
        onStartNewKhatmah: _openStartNewKhatmahFlow,
      ),
      ProgressPage(
        key: _progressPageKey,
        onStartNewKhatmah: _openStartNewKhatmahFlow,
        onBackToHome: _onBackToHome,
      ),
      SettingsPage(
        onStartNewKhatmah: _openStartNewKhatmahFlow,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(
            top: BorderSide(color: AppColors.secondaryNeutral, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          key: ValueKey('bottom_nav_${currentLocale.languageCode}'),
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book_rounded),
              activeIcon: const Icon(Icons.menu_book_rounded),
              label: LocaleKeys.navigation.today.tr(context: context),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.timeline_rounded),
              activeIcon: const Icon(Icons.timeline_rounded),
              label: LocaleKeys.navigation.journey.tr(context: context),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.tune_rounded),
              activeIcon: const Icon(Icons.tune_rounded),
              label: LocaleKeys.navigation.settings.tr(context: context),
            ),
          ],
        ),
      ),
    );
  }
}
