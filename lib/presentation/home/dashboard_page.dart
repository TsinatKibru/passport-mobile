import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/dashboard_stats.dart';
import 'widgets/fingerprint_background.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/activity_card.dart';
import 'widgets/charts/donut_chart.dart';
import 'widgets/charts/activity_trend_chart.dart';
import 'widgets/charts/room_occupancy_bars.dart';

/// Redesigned custody dashboard: a storage-overview hero (occupancy ring),
/// quick actions, an activity trend chart, a passport-status donut and a
/// per-room storage breakdown — all backed by live analytics endpoints.
class DashboardPage extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;

  /// Opens the Scan tab preselected to [mode] (keeps the bottom nav visible).
  final void Function(String mode)? onOpenScan;

  const DashboardPage({super.key, this.onNavigateToTab, this.onOpenScan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final int pendingCount =
        statsAsync.maybeWhen(data: (s) => s?.inBox ?? 0, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(activityLogsProvider);
            ref.invalidate(activityTrendProvider);
            ref.invalidate(roomOccupancyProvider);
            await Future.wait([
              ref.read(dashboardStatsProvider.future),
              ref.read(activityLogsProvider.future),
              ref.read(activityTrendProvider.future),
              ref.read(roomOccupancyProvider.future),
            ]);
          },
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
                    // Storage overview hero
                    statsAsync.when(
                      data: (stats) => stats == null
                          ? const _InfoCard('Overview unavailable')
                          : _HeroCard(stats: stats),
                      loading: () => const _HeroSkeleton(),
                      error: (_, __) =>
                          const _InfoCard('Failed to load overview'),
                    ),
                    const SizedBox(height: 22),

                    // Quick actions (single, de-duplicated action surface)
                    _QuickActions(
                      onIssue: () => context.push('/scan?mode=issue'),
                      onReturn: () => context.push('/scan?mode=return'),
                      onAssign: () => onOpenScan?.call('assign'),
                      onVerify: () => onOpenScan?.call('verify'),
                    ),
                    const SizedBox(height: 26),

                    // Activity trend chart
                    const _TrendCard(),
                    const SizedBox(height: 18),

                    // Passport status donut
                    statsAsync.maybeWhen(
                      data: (stats) => stats == null
                          ? const SizedBox.shrink()
                          : _StatusCard(stats: stats),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 18),

                    // Storage by room
                    const _RoomCard(),
                    const SizedBox(height: 26),

                    // Recent activity
                    const _RecentActivity(),

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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Notifications',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.primaryDark)),
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
// Hero — storage overview with occupancy ring
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final DashboardStats stats;
  const _HeroCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final occ = stats.totalCapacity > 0
        ? (stats.totalOccupied / stats.totalCapacity * 100)
        : 0.0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fingerprint watermark (same glyph as the profile page), bleeding
          // off the corner and clipped to the card.
          Positioned(
            right: -20,
            bottom: -32,
            child: Icon(
              Icons.fingerprint_rounded,
              size: 176,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORGANISED STORAGE',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${stats.totalPassports}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'passports in custody',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DonutChart(
                size: 82,
                thickness: 10,
                segments: [
                  DonutSegment(stats.totalOccupied.toDouble(), Colors.white),
                  DonutSegment(stats.totalVacant.toDouble(),
                      Colors.white.withValues(alpha: 0.28)),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${occ.round()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'in use',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 10),
          Row(
            children: [
              _HeroStat(value: '${stats.inBox}', label: 'In vault'),
              const _HeroDivider(),
              _HeroStat(value: '${stats.issued}', label: 'Issued'),
              const _HeroDivider(),
              _HeroStat(value: '${stats.totalBoxes}', label: 'Boxes'),
            ],
          ),
        ],
      ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.15),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.primary)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback onIssue;
  final VoidCallback onReturn;
  final VoidCallback onAssign;
  final VoidCallback onVerify;

  const _QuickActions({
    required this.onIssue,
    required this.onReturn,
    required this.onAssign,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
              icon: Icons.upload_rounded,
              label: 'Issue',
              color: AppColors.danger,
              onTap: onIssue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
              icon: Icons.download_rounded,
              label: 'Return',
              color: AppColors.warning,
              onTap: onReturn),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
              icon: Icons.archive_rounded,
              label: 'Assign',
              color: AppColors.primary,
              onTap: onAssign),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
              icon: Icons.verified_user_rounded,
              label: 'Verify',
              color: AppColors.success,
              onTap: onVerify),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.primaryDark, fontSize: 15),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textBody),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity trend
// ─────────────────────────────────────────────────────────────────────────────

class _TrendCard extends ConsumerWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityTrendProvider);
    return _SectionCard(
      title: 'Activity',
      trailing: 'last 7 days',
      child: async.when(
        data: (points) {
          final total = points.fold<int>(0, (s, p) => s + p.total);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'movements',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textBody),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ActivityTrendChart(points: points),
            ],
          );
        },
        loading: () => const _CardLoader(),
        error: (_, __) => const _CardError('Could not load activity'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Passport status donut
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final DashboardStats stats;
  const _StatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Passport status',
      trailing: '${stats.totalPassports} total',
      child: Row(
        children: [
          DonutChart(
            size: 96,
            thickness: 12,
            segments: [
              DonutSegment(stats.inBox.toDouble(), AppColors.primary),
              DonutSegment(stats.issued.toDouble(), AppColors.success),
            ],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${stats.totalPassports}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    height: 1,
                  ),
                ),
                Text('total', style: AppTextStyles.caption.copyWith(fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _LegendRow(
                    color: AppColors.primary, label: 'In vault', value: stats.inBox),
                const SizedBox(height: 12),
                _LegendRow(
                    color: AppColors.success, label: 'Issued', value: stats.issued),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _LegendRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody)),
        ),
        Text(
          '$value',
          style: AppTextStyles.titleMedium
              .copyWith(color: AppColors.primaryDark, fontSize: 15),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Storage by room
// ─────────────────────────────────────────────────────────────────────────────

class _RoomCard extends ConsumerWidget {
  const _RoomCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(roomOccupancyProvider);
    return _SectionCard(
      title: 'Storage by room',
      trailing: async.maybeWhen(
        data: (r) => '${r.length} ${r.length == 1 ? 'room' : 'rooms'}',
        orElse: () => null,
      ),
      child: async.when(
        data: (rooms) => RoomOccupancyBars(rooms: rooms),
        loading: () => const _CardLoader(),
        error: (_, __) => const _CardError('Could not load rooms'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent activity
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);
    return _SectionCard(
      title: 'Recent activity',
      child: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No recent activity',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody)),
            );
          }
          return Column(
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
          );
        },
        loading: () => const _CardLoader(),
        error: (_, __) => const _CardError('Could not load activity'),
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'PASSPORT_ASSIGNED':
        return 'Batch Assignment';
      case 'PASSPORT_RETURNED':
        return 'Custody Returned';
      case 'PASSPORT_ISSUED':
        return 'Passport Issued';
      case 'BOX_MOVED':
        return 'Box Relocated';
      default:
        return action;
    }
  }

  String _buildSubtitle(
      String action, Map<String, dynamic>? passport, Map<String, dynamic>? box) {
    final name = passport?['holderName'] as String?;
    final qr = passport?['qrCode'] as String?;
    final lbl = box?['label'] as String?;
    if (name != null && qr != null) return '$name · $qr';
    if (lbl != null) return 'Box $lbl';
    return '';
  }

  String _formatTimestamp(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CardLoader extends StatelessWidget {
  const _CardLoader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary)),
          ),
        ),
      );
}

class _CardError extends StatelessWidget {
  final String text;
  const _CardError(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(text,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody)),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard(this.text);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(text,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody)),
        ),
      );
}

class _NotifRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _NotifRow(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 3),
              Text(body,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textBody,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
