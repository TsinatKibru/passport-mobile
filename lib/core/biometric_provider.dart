import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricState {
  final bool isSupported;
  final bool isEnabled;
  final bool isUnlocked;
  final bool isAuthenticating;

  BiometricState({
    required this.isSupported,
    required this.isEnabled,
    required this.isUnlocked,
    required this.isAuthenticating,
  });

  BiometricState copyWith({
    bool? isSupported,
    bool? isEnabled,
    bool? isUnlocked,
    bool? isAuthenticating,
  }) {
    return BiometricState(
      isSupported: isSupported ?? this.isSupported,
      isEnabled: isEnabled ?? this.isEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }
}

class BiometricNotifier extends Notifier<BiometricState> {
  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  @override
  BiometricState build() {
    initialize();
    return BiometricState(
      isSupported: false,
      isEnabled: false,
      isUnlocked: true,
      isAuthenticating: false,
    );
  }

  Future<void> initialize() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final hasBiometrics = await _auth.canCheckBiometrics;
      final enabledStr = await _storage.read(key: 'biometricEnabled');
      final isEnabled = enabledStr == 'true';

      state = BiometricState(
        isSupported: isSupported && hasBiometrics,
        isEnabled: isEnabled,
        isUnlocked: !isEnabled,
        isAuthenticating: false,
      );
    } catch (e) {
      debugPrint('Error initializing biometrics: $e');
      state = BiometricState(
        isSupported: false,
        isEnabled: false,
        isUnlocked: true,
        isAuthenticating: false,
      );
    }
  }

  Future<String?> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      try {
        final success = await _auth.authenticate(
          localizedReason: 'Verify biometrics to update security settings',
          biometricOnly: true,
        );
        if (!success) {
          return 'Verification cancelled or failed';
        }
      } catch (e) {
        debugPrint('Failed to authenticate silently: $e');
        return 'Verification error: ${e.toString()}';
      }
    }

    try {
      await _storage.write(key: 'biometricEnabled', value: enabled ? 'true' : 'false');
      state = state.copyWith(
        isEnabled: enabled,
        isUnlocked: !enabled || state.isUnlocked,
      );
      return null;
    } catch (e) {
      debugPrint('Failed to save biometric settings: $e');
      return 'Storage error: ${e.toString()}';
    }
  }

  Future<bool> authenticate() async {
    if (!state.isEnabled) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }

    if (state.isAuthenticating) return false;

    state = state.copyWith(isAuthenticating: true);
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock Passport Track',
        persistAcrossBackgrounding: true,
      );

      state = state.copyWith(
        isUnlocked: success,
        isAuthenticating: false,
      );
      return success;
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      state = state.copyWith(isAuthenticating: false);
      return false;
    }
  }

  void lock() {
    if (state.isEnabled) {
      state = state.copyWith(isUnlocked: false);
    }
  }
}

final biometricProvider = NotifierProvider<BiometricNotifier, BiometricState>(() {
  return BiometricNotifier();
});
