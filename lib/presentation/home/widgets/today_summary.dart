import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'glass_card.dart';

class TodaySummary extends StatelessWidget {
  final int pendingTasks;
  final VoidCallback onIssueTap;
  final VoidCallback onReturnTap;
  final VoidCallback onAssignTap;

  const TodaySummary({
    super.key,
    required this.pendingTasks,
    required this.onIssueTap,
    required this.onReturnTap,
    required this.onAssignTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 24.0,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary,
          AppColors.primaryDark,
        ],
      ),
      child: Stack(
        children: [
          // Subtle circular patterns on background representing geometric watermark
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.fingerprint_rounded,
              size: 140,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TODAY'S WORKLOAD",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Active Shift",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pendingTasks == 0 ? "All caught up! 🎉" : "$pendingTasks Tasks Waiting",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingTasks == 0
                      ? "There are no pending actions for your station today."
                      : "Process pending documents to maintain operational custody standards.",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                // Quick shortcut pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildShortcutPill(
                        context,
                        label: 'Issue Passport',
                        icon: Icons.assignment_turned_in_rounded,
                        onTap: onIssueTap,
                      ),
                      const SizedBox(width: 8),
                      _buildShortcutPill(
                        context,
                        label: 'Return',
                        icon: Icons.swap_horizontal_circle_rounded,
                        onTap: onReturnTap,
                      ),
                      const SizedBox(width: 8),
                      _buildShortcutPill(
                        context,
                        label: 'Assign Box',
                        icon: Icons.inventory_2_rounded,
                        onTap: onAssignTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
