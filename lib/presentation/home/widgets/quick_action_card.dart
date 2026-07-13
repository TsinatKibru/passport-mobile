import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'glass_card.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;
  final String? badgeText;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          padding: const EdgeInsets.all(16.0),
          borderRadius: 20,
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge (Optional)
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // Chevron Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textBody.withOpacity(0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
