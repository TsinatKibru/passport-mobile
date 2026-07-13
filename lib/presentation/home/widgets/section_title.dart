import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtle vertical accent bar in ICS Blue
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textBody.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
