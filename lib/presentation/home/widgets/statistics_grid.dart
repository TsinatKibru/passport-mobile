import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/dashboard_stats.dart';
import 'glass_card.dart';
import 'wave_painter.dart';

class StatisticsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatisticsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final occupancyRate = stats.totalPassports > 0
        ? '${((stats.inBox / stats.totalPassports) * 100).toStringAsFixed(1)}%'
        : '0%';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        _buildStatCard(
          title: 'Total Boxes',
          value: stats.totalBoxes.toString(),
          subtitle: 'All registered boxes',
          icon: Icons.inventory_2_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primary.withOpacity(0.08),
        ),
        _buildStatCard(
          title: 'Occupied Boxes',
          value: stats.occupiedBoxes.toString(),
          subtitle: 'Currently in use',
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          iconBg: AppColors.success.withOpacity(0.08),
        ),
        _buildStatCard(
          title: 'Vacant Space',
          value: stats.totalVacant.toString(),
          subtitle: 'Available slots',
          icon: Icons.unarchive_rounded,
          iconColor: AppColors.warning,
          iconBg: AppColors.warning.withOpacity(0.08),
        ),
        _buildStatCard(
          title: 'Occupancy',
          value: occupancyRate,
          subtitle: 'Overall rate',
          icon: Icons.trending_up_rounded,
          iconColor: Colors.deepPurple,
          iconBg: Colors.deepPurple.withOpacity(0.08),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 24.0,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Wave decoration only at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: IgnorePointer(
              child: CustomPaint(
                painter: WavePainter(
                  color: iconColor,
                  waveHeightPercent: 0.8,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Value text
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                // Subtitle text
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
