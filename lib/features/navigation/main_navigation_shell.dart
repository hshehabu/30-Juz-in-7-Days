import 'package:flutter/material.dart';
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

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
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
    final pages = [
      HomePage(
        onNavigateToProgress: () => _navigateToTab(1),
        onStartNewKhatmah: _openStartNewKhatmahFlow,
      ),
      ProgressPage(
        onStartNewKhatmah: _openStartNewKhatmahFlow,
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
          color: AppColors.parchment,
          border: Border(
            top: BorderSide(color: AppColors.softSand, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline_rounded),
              activeIcon: Icon(Icons.timeline_rounded),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_rounded),
              activeIcon: Icon(Icons.tune_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
