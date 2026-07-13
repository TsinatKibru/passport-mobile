import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'glass_card.dart';

class SummaryCard extends StatelessWidget {
  final int totalTasks;
  final int issuedCount;
  final int returnedCount;

  const SummaryCard({
    super.key,
    required this.totalTasks,
    required this.issuedCount,
    required this.returnedCount,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      borderRadius: 20,
      child: Row(
        children: [
          _buildItem(
            context,
            title: 'Tasks',
            value: totalTasks.toString(),
            icon: Icons.assignment_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primary.withOpacity(0.08),
          ),
          _buildDivider(),
          _buildItem(
            context,
            title: 'Issued',
            value: issuedCount.toString(),
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            bgColor: AppColors.success.withOpacity(0.08),
          ),
          _buildDivider(),
          _buildItem(
            context,
            title: 'Returned',
            value: returnedCount.toString(),
            icon: Icons.swap_horizontal_circle_rounded,
            iconColor: AppColors.warning,
            bgColor: AppColors.warning.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    height: 1.1,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.border,
    );
  }
}
