import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeKey = 'app_theme';

/// Holds the app's chosen [ThemeMode] (system = follow the device).
/// Persisted to secure storage so the choice survives restarts.
class ThemeController extends Notifier<ThemeMode> {
  final _storage = const FlutterSecureStorage();

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system; // device default until the saved value loads
  }

  Future<void> _load() async {
    final v = await _storage.read(key: _themeKey);
    switch (v) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
        state = ThemeMode.system;
        break;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _themeKey, value: mode.name); // light | dark | system
  }
}

final themeProvider =
    NotifierProvider<ThemeController, ThemeMode>(() => ThemeController());
