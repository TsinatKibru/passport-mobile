import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/dashboard_stats.dart';
import '../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.surface,
      body: FingerprintBackground(
        child: RefreshIndicator(
          color: c.primary,
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
                          ? _InfoCard(l.dashOverviewUnavailable)
                          : _HeroCard(stats: stats),
                      loading: () => const _HeroSkeleton(),
                      error: (_, __) => _InfoCard(l.dashOverviewFailed),
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

}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — storage overview with occupancy ring
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final DashboardStats stats;
  const _HeroCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                      l.dashOrganisedStorage,
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
                      l.dashPassportsInCustody,
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
                      l.dashInUse,
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
              _HeroStat(
                  icon: Icons.shield_rounded,
                  value: '${stats.inBox}',
                  label: l.dashInVault),
              const _HeroDivider(),
              _HeroStat(
                  icon: Icons.import_contacts_rounded,
                  value: '${stats.issued}',
                  label: l.dashIssued),
              const _HeroDivider(),
              _HeroStat(
                  icon: Icons.inventory_2_rounded,
                  value: '${stats.totalBoxes}',
                  label: l.dashBoxes),
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
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
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
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
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

class ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent - 0.5) * 2, 0, 0);
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? c.surfaceVariant : c.surfaceVariant.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerEffect(width: 120, height: 12),
                    SizedBox(height: 10),
                    ShimmerEffect(width: 60, height: 32),
                    SizedBox(height: 10),
                    ShimmerEffect(width: 140, height: 14),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ShimmerEffect(width: 72, height: 72, borderRadius: BorderRadius.all(Radius.circular(36))),
            ],
          ),
          const Spacer(),
          Container(height: 1, color: c.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeroStatPlaceholder(),
              _buildDividerPlaceholder(c),
              _buildHeroStatPlaceholder(),
              _buildDividerPlaceholder(c),
              _buildHeroStatPlaceholder(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeroStatPlaceholder() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerEffect(width: 40, height: 16),
        SizedBox(height: 6),
        ShimmerEffect(width: 50, height: 10),
      ],
    );
  }

  Widget _buildDividerPlaceholder(AppPalette c) {
    return Container(width: 1, height: 24, color: c.border);
  }
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
              icon: Icons.import_contacts_rounded,
              label: l.qaIssue,
              subtitle: l.qaIssueSub,
              color: c.danger,
              onTap: onIssue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
              icon: Icons.assignment_return_rounded,
              label: l.qaReturn,
              subtitle: l.qaReturnSub,
              color: c.warning,
              onTap: onReturn),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
              icon: Icons.person_add_alt_1_rounded,
              label: l.qaAssign,
              subtitle: l.qaAssignSub,
              color: c.primary,
              onTap: onAssign),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
              icon: Icons.verified_user_rounded,
              label: l.qaVerify,
              subtitle: l.qaVerifySub,
              color: c.success,
              onTap: onVerify),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
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
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  color: c.textBody.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
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
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
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
                    .copyWith(color: c.primaryDark, fontSize: 15),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: AppTextStyles.caption.copyWith(color: c.textBody),
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

class _GraphSkeleton extends StatelessWidget {
  const _GraphSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            ShimmerEffect(width: 50, height: 24),
            SizedBox(width: 6),
            ShimmerEffect(width: 70, height: 14),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              ShimmerEffect(width: 24, height: 40, borderRadius: BorderRadius.all(Radius.circular(6))),
              ShimmerEffect(width: 24, height: 80, borderRadius: BorderRadius.all(Radius.circular(6))),
              ShimmerEffect(width: 24, height: 50, borderRadius: BorderRadius.all(Radius.circular(6))),
              ShimmerEffect(width: 24, height: 100, borderRadius: BorderRadius.all(Radius.circular(6))),
              ShimmerEffect(width: 24, height: 70, borderRadius: BorderRadius.all(Radius.circular(6))),
              ShimmerEffect(width: 24, height: 90, borderRadius: BorderRadius.all(Radius.circular(6))),
              ShimmerEffect(width: 24, height: 110, borderRadius: BorderRadius.all(Radius.circular(6))),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends ConsumerWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(activityTrendProvider);
    return _SectionCard(
      title: l.dashActivity,
      trailing: l.dashLast7Days,
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
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: c.primaryDark,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      l.dashMovements,
                      style: AppTextStyles.caption.copyWith(color: c.textBody),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ActivityTrendChart(points: points),
            ],
          );
        },
        loading: () => const _GraphSkeleton(),
        error: (_, __) => _CardError(l.dashCouldNotLoadActivity),
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return _SectionCard(
      title: l.dashPassportStatus,
      trailing: '${stats.totalPassports} ${l.dashTotal}',
      child: Row(
        children: [
          DonutChart(
            size: 96,
            thickness: 12,
            segments: [
              DonutSegment(stats.inBox.toDouble(), c.primary),
              DonutSegment(stats.issued.toDouble(), c.success),
            ],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${stats.totalPassports}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.primaryDark,
                    height: 1,
                  ),
                ),
                Text(l.dashTotal,
                    style: AppTextStyles.caption
                        .copyWith(fontSize: 9, color: c.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _LegendRow(
                    color: c.primary, label: l.dashInVault, value: stats.inBox),
                const SizedBox(height: 12),
                _LegendRow(
                    color: c.success, label: l.dashIssued, value: stats.issued),
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
    final c = context.colors;
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
              style: AppTextStyles.bodyMedium.copyWith(color: c.textBody)),
        ),
        Text(
          '$value',
          style: AppTextStyles.titleMedium
              .copyWith(color: c.primaryDark, fontSize: 15),
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
    final l = AppLocalizations.of(context);
    final async = ref.watch(roomOccupancyProvider);
    return _SectionCard(
      title: l.dashStorageByRoom,
      trailing: async.maybeWhen(
        data: (r) => '${r.length} ${r.length == 1 ? l.dashRoom : l.dashRooms}',
        orElse: () => null,
      ),
      child: async.when(
        data: (rooms) => RoomOccupancyBars(rooms: rooms),
        loading: () => const _CardLoader(),
        error: (_, __) => _CardError(l.dashCouldNotLoadRooms),
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final logsAsync = ref.watch(activityLogsProvider);
    return _SectionCard(
      title: l.dashRecentActivity,
      child: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.dashNoRecentActivity,
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: c.textBody)),
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
                    title: _actionLabel(l, action),
                    subtitle: _buildSubtitle(l, action, passport, box),
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
        error: (_, __) => _CardError(l.dashCouldNotLoadActivity),
      ),
    );
  }

  String _actionLabel(AppLocalizations l, String action) {
    switch (action) {
      case 'PASSPORT_ASSIGNED':
        return l.actBatchAssignment;
      case 'PASSPORT_RETURNED':
        return l.actCustodyReturned;
      case 'PASSPORT_ISSUED':
        return l.actPassportIssued;
      case 'BOX_MOVED':
        return l.actBoxRelocated;
      default:
        return action;
    }
  }

  String _buildSubtitle(AppLocalizations l, String action,
      Map<String, dynamic>? passport, Map<String, dynamic>? box) {
    final name = passport?['holderName'] as String?;
    final qr = passport?['qrCode'] as String?;
    final lbl = box?['label'] as String?;
    if (name != null && qr != null) return '$name · $qr';
    if (lbl != null) return '${l.dashBoxPrefix} $lbl';
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(context.colors.primary)),
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
              style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textBody)),
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
          color: context.colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.border),
        ),
        child: Center(
          child: Text(text,
              style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textBody)),
        ),
      );
}

