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
    final logsAsync = ref.watch(activityLogsProvider);

    // Use real "IN_BOX" count as pending workload; fallback to 0 while loading
    final int pendingTasksCount = statsAsync.maybeWhen(
      data: (stats) => stats?.inBox ?? 0,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(activityLogsProvider);
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
                      logsAsync.when(
                        data: (logs) {
                          if (logs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'No recent activity',
                                  style: TextStyle(color: AppColors.textBody),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: logs.map((log) {
                              final action = log['action'] as String? ?? '';
                              final passport = log['passport'] as Map<String, dynamic>?;
                              final box = log['box'] as Map<String, dynamic>?;
                              final String title = _actionLabel(action);
                              final String subtitle = _buildSubtitle(action, passport, box);
                              final String timestamp = _formatTimestamp(log['createdAt']);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ActivityCard(
                                  title: title,
                                  subtitle: subtitle,
                                  timestamp: timestamp,
                                  actionType: action,
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Could not load activity logs',
                              style: TextStyle(color: AppColors.textBody),
                            ),
                          ),
                        ),
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

  String _actionLabel(String action) {
    switch (action) {
      case 'PASSPORT_ASSIGNED': return 'Batch Assignment';
      case 'PASSPORT_RETURNED': return 'Custody Returned';
      case 'PASSPORT_ISSUED':   return 'Passport Issued';
      case 'BOX_MOVED':         return 'Box Relocated';
      default: return action;
    }
  }

  String _buildSubtitle(String action, Map<String, dynamic>? passport, Map<String, dynamic>? box) {
    final passportName = passport?['holderName'] as String?;
    final passportQr   = passport?['qrCode'] as String?;
    final boxLabel     = box?['label'] as String?;

    if (passportName != null && passportQr != null) {
      return '$passportName • $passportQr';
    }
    if (boxLabel != null) {
      return 'Box: $boxLabel';
    }
    return '';
  }

  String _formatTimestamp(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
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
