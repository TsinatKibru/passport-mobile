import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/dashboard_stats.dart';

/// Minimal stat section — two rows of two cards each.
/// Each card is plain white with one number and one label. No rings, no waves.
class StatisticsGrid extends StatelessWidget {
  final DashboardStats stats;
  const StatisticsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final occupancyPct = stats.totalCapacity > 0
        ? (stats.totalOccupied / stats.totalCapacity * 100).toStringAsFixed(0)
        : '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              value: stats.totalPassports.toString(),
              label: 'Total passports',
              accent: AppColors.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              value: stats.issued.toString(),
              label: 'Currently issued',
              accent: AppColors.success,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              value: stats.inBox.toString(),
              label: 'In vault',
              accent: const Color(0xFF5B6B9E),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              value: '$occupancyPct%',
              label: 'Vault occupancy',
              accent: AppColors.warning,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Capacity bar — one clean row
        _CapacityBar(
          occupied: stats.totalOccupied,
          total: stats.totalCapacity,
          vacant: stats.totalVacant,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _StatCard({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 3)),
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
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  final int occupied;
  final int total;
  final int vacant;

  const _CapacityBar({
    required this.occupied,
    required this.total,
    required this.vacant,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? occupied / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Storage capacity',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                '$occupied / $total slots',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 0.9 ? AppColors.danger : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$vacant slots available',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
