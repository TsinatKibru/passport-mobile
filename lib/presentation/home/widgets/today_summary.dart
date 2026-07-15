import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Clean workload summary — no gradient card, just strong typography and
/// three flat icon-button shortcuts at the bottom.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workload summary strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pendingTasks == 0 ? 'All clear today' : '$pendingTasks passports',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pendingTasks == 0
                    ? 'No pending actions at your station'
                    : 'currently in vault storage',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 22),
              // Three action buttons in a row
              Row(
                children: [
                  Expanded(child: _ShortcutButton(
                    label: 'Issue',
                    icon: Icons.upload_rounded,
                    onTap: onIssueTap,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ShortcutButton(
                    label: 'Return',
                    icon: Icons.download_rounded,
                    onTap: onReturnTap,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ShortcutButton(
                    label: 'Assign',
                    icon: Icons.archive_rounded,
                    onTap: onAssignTap,
                  )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 5),
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
    );
  }
}
