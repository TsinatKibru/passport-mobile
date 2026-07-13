import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'glass_card.dart';

class PendingTaskCard extends StatelessWidget {
  final String applicantName;
  final String taskType; // 'Issue Passport', 'Return Passport', 'Assign Box'
  final String priority; // 'HIGH', 'MEDIUM', 'LOW'
  final String timeText; // e.g. '2 hours ago', 'ETA: 10 mins'
  final VoidCallback onTap;

  const PendingTaskCard({
    super.key,
    required this.applicantName,
    required this.taskType,
    required this.priority,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    String priorityLabel;
    
    switch (priority.toUpperCase()) {
      case 'HIGH':
        priorityColor = AppColors.danger;
        priorityLabel = 'High Priority';
        break;
      case 'MEDIUM':
        priorityColor = AppColors.warning;
        priorityLabel = 'Medium Priority';
        break;
      case 'LOW':
      default:
        priorityColor = AppColors.success;
        priorityLabel = 'Low Priority';
        break;
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored priority strip on the left edge
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Task Type and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  priorityLabel,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeText,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            taskType,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textBody,
                              ),
                              children: [
                                const TextSpan(text: 'Applicant: '),
                                TextSpan(
                                  text: applicantName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Button
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(60, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
