import 'package:flutter_test/flutter_test.dart';
import 'package:passport_track_mobile/core/biometric_provider.dart';

void main() {
  group('BiometricState Tests', () {
    test('initial state values are set correctly', () {
      final state = BiometricState(
        isSupported: false,
        isEnabled: false,
        isUnlocked: true,
        isAuthenticating: false,
      );

      expect(state.isSupported, false);
      expect(state.isEnabled, false);
      expect(state.isUnlocked, true);
      expect(state.isAuthenticating, false);
    });

    test('copyWith updates specified fields only', () {
      final state = BiometricState(
        isSupported: false,
        isEnabled: false,
        isUnlocked: true,
        isAuthenticating: false,
      );

      final updated = state.copyWith(
        isEnabled: true,
        isUnlocked: false,
        isAuthenticating: true,
      );

      expect(updated.isSupported, false);
      expect(updated.isEnabled, true);
      expect(updated.isUnlocked, false);
      expect(updated.isAuthenticating, true);
    });
  });
}
