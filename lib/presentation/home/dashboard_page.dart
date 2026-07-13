import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/fingerprint_background.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/today_summary.dart';
import 'widgets/section_title.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/statistics_grid.dart';
import 'widgets/activity_card.dart';

class DashboardPage extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;

  const DashboardPage({
    super.key,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    
    // We will pull the real pending tasks count if available, otherwise default to a mockup representing outstanding assignments
    final int pendingTasksCount = 12; 

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // White styled header replaces blue AppBar
              SliverToBoxAdapter(
                child: DashboardHeader(
                  pendingTasksCount: pendingTasksCount,
                  onNotificationTap: () {
                    _showNotificationsSheet(context);
                  },
                  onProfileTap: () {
                    if (onNavigateToTab != null) {
                      onNavigateToTab!(4); // Navigate to Profile tab
                    }
                  },
                ),
              ),

              // Main body scroll view content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // 1. Hero Section (Today's Summary)
                      TodaySummary(
                        pendingTasks: pendingTasksCount,
                        onIssueTap: () => context.push('/scan?mode=issue'),
                        onReturnTap: () => context.push('/scan?mode=return'),
                        onAssignTap: () => context.push('/scan?mode=assign'),
                      ),
                      const SizedBox(height: 24),

                      // 2. Quick Actions Section
                      const SectionTitle(
                        title: 'Quick Operations',
                        subtitle: 'Primary tools for daily officer workflows',
                      ),
                      const SizedBox(height: 8),
                      QuickActionCard(
                        title: 'Issue Passport',
                        description: 'Scan and hand over passport to its owner',
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: AppColors.danger,
                        iconBgColor: AppColors.danger.withOpacity(0.08),
                        badgeText: 'Actionable',
                        onTap: () => context.push('/scan?mode=issue'),
                      ),
                      const SizedBox(height: 10),
                      QuickActionCard(
                        title: 'Return Custody',
                        description: 'Scan incoming passports back to vault boxes',
                        icon: Icons.swap_horizontal_circle_rounded,
                        iconColor: AppColors.warning,
                        iconBgColor: AppColors.warning.withOpacity(0.08),
                        onTap: () => context.push('/scan?mode=return'),
                      ),
                      const SizedBox(height: 10),
                      QuickActionCard(
                        title: 'Assign Box Slot',
                        description: 'Batch assign passports and allocate box slot locations',
                        icon: Icons.inventory_2_rounded,
                        iconColor: AppColors.primary,
                        iconBgColor: AppColors.primary.withOpacity(0.08),
                        onTap: () => context.push('/scan?mode=assign'),
                      ),
                      const SizedBox(height: 10),
                      QuickActionCard(
                        title: 'Verify Entity',
                        description: 'Quickly query passport location or box capacity',
                        icon: Icons.verified_user_rounded,
                        iconColor: AppColors.success,
                        iconBgColor: AppColors.success.withOpacity(0.08),
                        onTap: () {
                          if (onNavigateToTab != null) {
                            onNavigateToTab!(2); // Navigate to Scanner (tab 2)
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // 3. Statistics Section
                      const SectionTitle(
                        title: 'Operational Status',
                        subtitle: 'Real-time overview of storage capacity',
                      ),
                      const SizedBox(height: 8),
                      statsAsync.when(
                        data: (stats) {
                          if (stats == null) {
                            return const Center(child: Text('Unable to query statistics'));
                          }
                          return StatisticsGrid(stats: stats);
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, stack) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Failed to load statistics: $err',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. Recent Activity Logs Section
                      SectionTitle(
                        title: 'Recent Activity Logs',
                        subtitle: 'Chronological timeline of custody events',
                        trailing: TextButton(
                          onPressed: () {
                            if (onNavigateToTab != null) {
                              onNavigateToTab!(1); // Go to Tasks/Activity
                            }
                          },
                          child: const Text('View Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const ActivityCard(
                        title: 'Passport Issued',
                        subtitle: 'Ahmed Mohamed • PP-938210',
                        timestamp: '12m ago',
                        actionType: 'PASSPORT_ISSUED',
                      ),
                      const SizedBox(height: 8),
                      const ActivityCard(
                        title: 'Box Relocated',
                        subtitle: 'Box 012 -> Room B / Row 2',
                        timestamp: '45m ago',
                        actionType: 'BOX_MOVED',
                      ),
                      const SizedBox(height: 8),
                      const ActivityCard(
                        title: 'Custody Returned',
                        subtitle: 'Fatuma Kebede • PP-194827',
                        timestamp: '2h ago',
                        actionType: 'PASSPORT_RETURNED',
                      ),
                      const SizedBox(height: 8),
                      const ActivityCard(
                        title: 'Batch Assignment',
                        subtitle: '8 passports stored in Box 001',
                        timestamp: '3h ago',
                        actionType: 'PASSPORT_ASSIGNED',
                      ),
                      
                      // Extra space at bottom to prevent bottom nav overlay
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.warning.withOpacity(0.08),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                ),
                title: const Text('Box Capacity Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Box 002 is at 100% capacity. Please assign a new target box.', style: TextStyle(fontSize: 11)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  child: const Icon(Icons.assignment_rounded, color: AppColors.primary),
                ),
                title: const Text('New Batch Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('A batch of 12 new ePassports has been scanned at Reception A.', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }
}
