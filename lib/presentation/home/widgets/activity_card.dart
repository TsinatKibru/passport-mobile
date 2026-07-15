import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Simple single-line activity row — icon, text, time. No stripes, no badges.
class ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final String actionType;

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.actionType,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(actionType.toUpperCase());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container — small, clean
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.icon, color: style.color, size: 17),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Timestamp
          Text(
            timestamp,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textBody.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _Style _styleFor(String action) {
    switch (action) {
      case 'PASSPORT_ISSUED':
        return _Style(Icons.upload_rounded, AppColors.success);
      case 'PASSPORT_RETURNED':
        return _Style(Icons.download_rounded, AppColors.warning);
      case 'BOX_MOVED':
        return _Style(Icons.swap_horiz_rounded, const Color(0xFF5B6B9E));
      default:
        return _Style(Icons.archive_rounded, AppColors.primary);
    }
  }
}

class _Style {
  final IconData icon;
  final Color color;
  const _Style(this.icon, this.color);
}
