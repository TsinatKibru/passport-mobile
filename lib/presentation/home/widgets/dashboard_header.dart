import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class DashboardHeader extends ConsumerWidget {
  final int pendingTasksCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.pendingTasksCount,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name?.split(' ').first ?? 'Officer';
    final role = user?.role ?? 'Immigration Officer';
    
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.light_mode_rounded;
    Color greetingColor = Colors.orangeAccent;

    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = Colors.amber;
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.dark_mode_rounded;
      greetingColor = Colors.indigoAccent;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Greeting and Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    greetingIcon,
                    color: greetingColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    greeting,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
              
              // Action Buttons: Notifications and Profile
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notification Button
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.onSurface,
                          size: 24,
                        ),
                        onPressed: onNotificationTap,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Profile Button / Avatar
                  InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'O',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Subtitle displaying Officer Name, Role and pending tasks count
          Text(
            user?.name ?? 'Tsinat',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                role,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBody,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.textBody.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                '$pendingTasksCount tasks waiting',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: pendingTasksCount > 0 ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
