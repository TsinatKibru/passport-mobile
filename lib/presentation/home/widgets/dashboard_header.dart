import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_provider.dart';
import '../../../core/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class DashboardHeader extends ConsumerWidget {
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? l.officer;
    final firstName = name.split(' ').first;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? l.greetingMorning
        : hour < 17
            ? l.greetingAfternoon
            : l.greetingEvening;

    final weekday = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][now.weekday - 1];
    final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month - 1];
    final dateStr = '$weekday, ${now.day} $month';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = context.colors;

    return Container(
      color: c.appBar,
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textBody,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$greeting, $firstName',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c.primaryDark,
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
              // Theme toggle (replaces the notification bell — no push
              // notifications in this build). Sun ⇄ moon by active brightness.
              GestureDetector(
                onTap: () => ref.read(themeProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      key: ValueKey(isDark),
                      color: c.primaryDark,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: c.primary,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'O',
                    style: TextStyle(
                      color: c.onPrimary,
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
