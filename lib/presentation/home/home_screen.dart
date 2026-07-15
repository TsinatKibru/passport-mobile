import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Mode the Scan tab opens in. Dashboard shortcuts can preselect a mode
  // (e.g. 'verify') so the scanner opens on the right tab with the bottom nav
  // still visible — instead of pushing a separate, nav-less route.
  String _scanMode = 'assign';

  void _selectTab(int index) {
    setState(() {
      // Tapping the Scan tab directly opens the general scanner.
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

    return Scaffold(
      // Let body extend behind bottom navbar for smooth floating aesthetic
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: FloatingBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}
