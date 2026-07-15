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
    final name = user?.name ?? 'Officer';
    final firstName = name.split(' ').first;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    final weekday = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][now.weekday - 1];
    final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month - 1];
    final dateStr = '$weekday, ${now.day} $month';

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 14, 22, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$greeting, $firstName',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: AppColors.primaryDark, size: 24),
                    if (pendingTasksCount > 0)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'O',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
