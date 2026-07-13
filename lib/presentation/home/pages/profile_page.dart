import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/fingerprint_background.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Tsinat Welde';
    final email = user?.email ?? 'tsinat.welde@immigration.gov.et';
    final role = user?.role ?? 'IMMIGRATION_OFFICER';
    final staffId = user?.id.substring(0, 8).toUpperCase() ?? 'ICS-94827';
    
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: CustomScrollView(
          slivers: [
            // Premium Large Header
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  'My Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  onPressed: () {
                    _showLogoutConfirm(context, ref);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Digital Staff ID Card
                    _buildStaffIdCard(context, name, email, role, staffId),
                    const SizedBox(height: 24),
                    
                    // Stats section
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    
                    // Options List
                    const Text(
                      'ACCOUNT SETTINGS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBody,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    _buildOptionTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update security credentials',
                      onTap: () {
                        // TODO: Implement password reset
                        _showInfoDialog(context, 'Change Password', 'This option is managed by directory service settings.');
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.shield_outlined,
                      title: 'Biometric Login',
                      subtitle: 'Enable fingerprint authentication',
                      onTap: () {
                        _showInfoDialog(context, 'Biometrics', 'Biometric settings are tied to system lock settings.');
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.translate_rounded,
                      title: 'App Language',
                      subtitle: 'English (US) / Amharic',
                      onTap: () {
                        _showInfoDialog(context, 'Language Selection', 'Only English language pack is currently installed.');
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About System',
                      subtitle: 'Version 2.4.1 (Production)',
                      onTap: () {
                        _showInfoDialog(context, 'App Information', 'Passport Custody & Tracking Mobile Client\nBuild: 2026.07.13.1\nDepartment: Ministry of Immigration (ICS)');
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // System info footer
                    Text(
                      'IMMIGRATION & CITIZENSHIP SERVICE (ICS)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffIdCard(BuildContext context, String name, String email, String role, String staffId) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.surfaceVariant.withOpacity(0.5),
        ],
      ),
      child: Stack(
        children: [
          // Geometric security line drawing on right edge
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.fingerprint_rounded,
              size: 160,
              color: AppColors.primary.withOpacity(0.04),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top logo row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/ics-logo.png',
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ICS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Officer details
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'O',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textBody,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'STAFF ID: $staffId',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                
                // Bottom metadata
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardMeta('OFFICE', 'HQ - Addis Ababa'),
                    _buildCardMeta('ISSUED', 'July 2026'),
                    _buildCardMeta('SECURITY', 'Level 2'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.textBody.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR ACTIVITY STATISTICS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textBody,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard('Issued Today', '14', Icons.assignment_turned_in_rounded, AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard('Returns', '5', Icons.swap_horizontal_circle_rounded, AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard('Box Shifts', '2', Icons.place_rounded, Colors.deepPurple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textBody.withOpacity(0.4),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of the Passport Custody & Tracking system?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(info),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
