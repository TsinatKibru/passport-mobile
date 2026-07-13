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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const TasksPage(),
      const ScanPage(),
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
