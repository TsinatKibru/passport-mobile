import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_provider.dart';
import '../../../core/biometric_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'fingerprint_background.dart';

class BiometricGuard extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricGuard({super.key, required this.child});

  @override
  ConsumerState<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends ConsumerState<BiometricGuard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(biometricProvider.notifier).lock();
    } else if (state == AppLifecycleState.resumed) {
      _checkAndRequestAuth();
    }
  }

  void _checkAndRequestAuth() {
    final bioState = ref.read(biometricProvider);
    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.authenticated && bioState.isEnabled && !bioState.isUnlocked) {
      ref.read(biometricProvider.notifier).authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bioState = ref.watch(biometricProvider);
    final c = context.colors;

    // Show guard screen ONLY if authenticated, biometric is enabled, and session is locked
    final isLocked = authState.status == AuthStatus.authenticated && bioState.isEnabled && !bioState.isUnlocked;

    if (!isLocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: c.surface,
      body: FingerprintBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // Styling a premium lock icon with fingerprint watermark
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.primary.withValues(alpha: 0.15), width: 1.5),
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 72,
                      color: c.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'App Locked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.primaryDark,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Verify your identity using biometrics to access your session.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: c.textBody,
                  ),
                ),
                
                const Spacer(),
                
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(biometricProvider.notifier).authenticate();
                  },
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text(
                    'Unlock App',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Fallback sign out button
                TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: c.danger,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
