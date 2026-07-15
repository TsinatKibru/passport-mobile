import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/fingerprint_background.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/today_summary.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/statistics_grid.dart';
import 'widgets/activity_card.dart';

class DashboardPage extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;
  /// Opens the Scan tab preselected to [mode] (keeps the bottom nav visible).
  final void Function(String mode)? onOpenScan;
  const DashboardPage({super.key, this.onNavigateToTab, this.onOpenScan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final logsAsync = ref.watch(activityLogsProvider);

    final int pendingCount = statsAsync.maybeWhen(
      data: (stats) => stats?.inBox ?? 0,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: FingerprintBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(activityLogsProvider);
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DashboardHeader(
                  pendingTasksCount: pendingCount,
                  onNotificationTap: () => _showNotificationsSheet(context),
                  onProfileTap: () => onNavigateToTab?.call(4),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Hero card
                    TodaySummary(
                      pendingTasks: pendingCount,
                      onIssueTap: () => context.push('/scan?mode=issue'),
                      onReturnTap: () => context.push('/scan?mode=return'),
                      onAssignTap: () => context.push('/scan?mode=assign'),
                    ),
                    const SizedBox(height: 28),

                    // ── Operations ─────────────────────────────────────────
                    _Label('Operations'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.upload_rounded,
                            color: const Color(0xFFE74C3C),
                            title: 'Issue Passport',
                            subtitle: 'Hand over passport to its owner',
                            onTap: () => context.push('/scan?mode=issue'),
                            showDivider: true,
                          ),
                          _ActionTile(
                            icon: Icons.download_rounded,
                            color: AppColors.warning,
                            title: 'Return Custody',
                            subtitle: 'Return passports back to vault',
                            onTap: () => context.push('/scan?mode=return'),
                            showDivider: true,
                          ),
                          _ActionTile(
                            icon: Icons.qr_code_scanner_rounded,
                            color: AppColors.success,
                            title: 'Scan & Verify',
                            subtitle: 'Query passport location or box status',
                            onTap: () => onOpenScan?.call('verify'),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Vault Status ───────────────────────────────────────
                    _Label('Vault Status'),
                    const SizedBox(height: 10),
                    statsAsync.when(
                      data: (stats) => stats == null
                          ? const _InfoText('Statistics unavailable')
                          : StatisticsGrid(stats: stats),
                      loading: () => const _Loader(),
                      error: (_, __) => const _InfoText('Failed to load statistics'),
                    ),
                    const SizedBox(height: 28),

                    // ── Recent Activity ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Label('Recent Activity'),
                        GestureDetector(
                          onTap: () => onNavigateToTab?.call(1),
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    logsAsync.when(
                      data: (logs) {
                        if (logs.isEmpty) {
                          return const _InfoText('No recent activity');
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: List.generate(logs.length, (i) {
                              final log = logs[i];
                              final action = log['action'] as String? ?? '';
                              final passport = log['passport'] as Map<String, dynamic>?;
                              final box = log['box'] as Map<String, dynamic>?;
                              return Column(
                                children: [
                                  ActivityCard(
                                    title: _actionLabel(action),
                                    subtitle: _buildSubtitle(action, passport, box),
                                    timestamp: _formatTimestamp(log['createdAt']),
                                    actionType: action,
                                  ),
                                  if (i < logs.length - 1)
                                    const Divider(height: 1, indent: 52),
                                ],
                              );
                            }),
                          ),
                        );
                      },
                      loading: () => const _Loader(),
                      error: (_, __) => const _InfoText('Could not load activity'),
                    ),

                    const SizedBox(height: 110),
                  ]),
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
    final name = passport?['holderName'] as String?;
    final qr   = passport?['qrCode']     as String?;
    final lbl  = box?['label']           as String?;
    if (name != null && qr != null) return '$name · $qr';
    if (lbl != null) return 'Box $lbl';
    return '';
  }

  String _formatTimestamp(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt   = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m';
      if (diff.inHours   < 24)  return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) { return ''; }
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Notifications',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700,
                    fontSize: 17, color: AppColors.primaryDark)),
            const SizedBox(height: 16),
            _NotifRow(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              title: 'Box Capacity Alert',
              body: 'Box MB-002 is at 100% capacity. Assign a new target.',
            ),
            const Divider(height: 20),
            _NotifRow(
              icon: Icons.inbox_rounded,
              color: AppColors.primary,
              title: 'New Batch Pending',
              body: '12 ePassports scanned at Reception A awaiting assignment.',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textBody,
      letterSpacing: 0.3,
    ),
  );
}

/// Unified action tile for the operations grouped card.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                              fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                      const SizedBox(height: 1),
                      Text(subtitle,
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 11, color: AppColors.textBody)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textBody, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 68, endIndent: 0),
      ],
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator(
        strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary))),
  );
}

class _InfoText extends StatelessWidget {
  final String text;
  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(text,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textBody))),
  );
}

class _NotifRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _NotifRow({required this.icon, required this.color,
      required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Inter',
                fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryDark)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(fontFamily: 'Inter',
                fontSize: 12, color: AppColors.textBody, height: 1.4)),
          ],
        )),
      ],
    );
  }
}
