import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _localeKey = 'app_locale';

/// Holds the app's chosen [Locale] (null = follow the device language).
/// Persisted so the choice survives restarts.
class LocaleController extends Notifier<Locale?> {
  final _storage = const FlutterSecureStorage();

  @override
  Locale? build() {
    _load();
    return null; // device default until the saved value loads
  }

  Future<void> _load() async {
    final code = await _storage.read(key: _localeKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _storage.delete(key: _localeKey);
    } else {
      await _storage.write(key: _localeKey, value: locale.languageCode);
    }
  }
}

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(() => LocaleController());
