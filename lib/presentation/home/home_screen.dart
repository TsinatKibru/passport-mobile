import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_page.dart';
import 'pages/tasks_page.dart';
import 'pages/scan_page.dart';
import 'pages/boxes_page.dart';
import 'pages/profile_page.dart';
import 'widgets/floating_bottom_nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  String _scanMode = 'assign';
  DateTime? _lastBackPressTime;

  void _selectTab(int index) {
    setState(() {
      if (index == 2) _scanMode = 'assign';
      _selectedIndex = index;
    });
  }

  void _openScan(String mode) {
    setState(() {
      _scanMode = mode;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(
        onNavigateToTab: _selectTab,
        onOpenScan: _openScan,
      ),
      const TasksPage(),
      ScanPage(key: ValueKey(_scanMode), initialMode: _scanMode, isActive: _selectedIndex == 2),
      const BoxesPage(),
      const ProfilePage(),
    ];

    final l = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If not on the first tab, pressing back returns to the dashboard
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        // On the first tab, prompt user to press back again to exit the app
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.pressBackAgainToExit),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: FloatingBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
