import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return SafeArea(
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Floating glassmorphic container
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: c.card.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: c.border.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(c, 0, Icons.grid_view_rounded, l.navHome),
                      _buildNavItem(c, 1, Icons.explore_outlined, l.navExplorer),
                      // Placeholder space for center button
                      const SizedBox(width: 56),
                      _buildNavItem(c, 3, Icons.inventory_2_outlined, l.dashBoxes),
                      _buildNavItem(c, 4, Icons.person_outline_rounded, l.navProfile),
                    ],
                  ),
                ),
              ),
            ),
            
            // Center Scan button, floating slightly higher
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: c.card,
                      width: 3.0,
                    ),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: c.onPrimary,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(AppPalette c, int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? c.primary : c.textBody.withOpacity(0.6);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, isSelected ? -2 : 0, 0),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
