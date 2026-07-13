import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'glass_card.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final String actionType; // 'PASSPORT_ASSIGNED', 'PASSPORT_RETURNED', 'PASSPORT_ISSUED', 'BOX_MOVED'

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.actionType,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    Color iconBg;

    switch (actionType.toUpperCase()) {
      case 'PASSPORT_ISSUED':
        iconData = Icons.assignment_turned_in_rounded;
        iconColor = AppColors.success;
        iconBg = AppColors.success.withOpacity(0.08);
        break;
      case 'PASSPORT_RETURNED':
        iconData = Icons.swap_horizontal_circle_rounded;
        iconColor = AppColors.warning;
        iconBg = AppColors.warning.withOpacity(0.08);
        break;
      case 'BOX_MOVED':
        iconData = Icons.place_rounded;
        iconColor = Colors.deepPurple;
        iconBg = Colors.deepPurple.withOpacity(0.08);
        break;
      case 'PASSPORT_ASSIGNED':
      default:
        iconData = Icons.inventory_2_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primary.withOpacity(0.08);
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timestamp,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textBody.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
