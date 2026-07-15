import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_provider.dart';
import '../../../core/locale_provider.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/analytics.dart';
import '../../../l10n/app_localizations.dart';
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
    final isActive = user?.isActive ?? true;
    final memberSince = _formatMonthYear(user?.createdAt);
    final activity = ref
        .watch(myActivityProvider)
        .maybeWhen(data: (v) => v, orElse: () => null);
    final l = AppLocalizations.of(context);

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
                  l.profileTitle,
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
                    _buildStaffIdCard(context, l, name, email, role, staffId,
                        isActive, memberSince),
                    const SizedBox(height: 24),

                    // Stats section
                    _buildStatsSection(l, activity),
                    const SizedBox(height: 24),
                    
                    // Options List
                    Text(
                      l.accountSettings,
                      style: const TextStyle(
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
                      title: l.changePassword,
                      subtitle: l.changePasswordDesc,
                      onTap: () => _showChangePasswordDialog(context, ref),
                    ),
                    _buildOptionTile(
                      icon: Icons.translate_rounded,
                      title: l.appLanguage,
                      subtitle: _languageLabel(l, ref.watch(localeProvider)),
                      onTap: () => _showLanguagePicker(context, ref),
                    ),
                    _buildOptionTile(
                      icon: Icons.info_outline_rounded,
                      title: l.aboutSystem,
                      subtitle: l.aboutSystemDesc,
                      onTap: () {
                        _showInfoDialog(
                            context, l.aboutInfoTitle, l.aboutInfoBody);
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // System info footer
                    Text(
                      l.orgFooter,
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

  Widget _buildStaffIdCard(BuildContext context, AppLocalizations l, String name,
      String email, String role, String staffId, bool isActive,
      String memberSince) {
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
                    _buildCardMeta(l.metaRole, role),
                    _buildCardMeta(l.metaStatus,
                        isActive ? l.statusActive : l.statusInactive),
                    _buildCardMeta(l.metaMemberSince, memberSince),
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

  Widget _buildStatsSection(AppLocalizations l, MyActivity? a) {
    String v(int? n) => a == null ? '—' : '${n ?? 0}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.activityToday,
          style: const TextStyle(
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
              child: _buildMiniStatCard(l.statIssued, v(a?.issuedToday),
                  Icons.assignment_turned_in_rounded, AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(l.statReturned, v(a?.returnsToday),
                  Icons.swap_horizontal_circle_rounded, AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(l.statBoxMoves, v(a?.boxMovesToday),
                  Icons.place_rounded, Colors.deepPurple),
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
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.signOut),
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.logout,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _languageLabel(AppLocalizations l, Locale? locale) {
    switch (locale?.languageCode) {
      case 'am':
        return l.languageAmharic;
      case 'en':
        return l.languageEnglish;
      default:
        return l.languageSystem;
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Widget option(String label, Locale? value) {
          final selected = value?.languageCode == current?.languageCode;
          return ListTile(
            title: Text(label,
                style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
            trailing: selected
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(value);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l.selectLanguage,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryDark)),
                ),
                const SizedBox(height: 8),
                option(l.languageEnglish, const Locale('en')),
                option(l.languageAmharic, const Locale('am')),
                option(l.languageSystem, null),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String info) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(info),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = dt.toLocal();
    return '${months[d.month - 1]} ${d.year}';
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(
        onSubmit: (current, newPass) => ref
            .read(authRepositoryProvider)
            .changePassword(currentPassword: current, newPassword: newPass),
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final Future<String?> Function(String current, String newPass) onSubmit;
  const _ChangePasswordSheet({required this.onSubmit});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obCurrent = true;
  bool _obNew = true;
  bool _obConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_current.text.isEmpty || _newPass.text.isEmpty) {
      setState(() => _error = l.fillAllFields);
      return;
    }
    if (_newPass.text != _confirm.text) {
      setState(() => _error = l.passwordsNoMatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.onSubmit(_current.text, _newPass.text);
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textBody, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 20,
            color: AppColors.textBody,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.changePassword,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: AppColors.primaryDark)),
                      const SizedBox(height: 2),
                      Text(l.changePasswordDesc,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textBody)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _passwordField(
                controller: _current,
                label: l.currentPassword,
                obscure: _obCurrent,
                onToggle: () => setState(() => _obCurrent = !_obCurrent),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _newPass,
                label: l.newPassword,
                obscure: _obNew,
                onToggle: () => setState(() => _obNew = !_obNew),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _confirm,
                label: l.confirmNewPassword,
                obscure: _obConfirm,
                onToggle: () => setState(() => _obConfirm = !_obConfirm),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 12)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text(
                l.passwordRule,
                style: const TextStyle(color: AppColors.textBody, fontSize: 11),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l.updatePassword,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
