import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/density.dart';
import '../storage/prefs_provider.dart';

/// 사용자 표시 설정 모음.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.density,
    required this.currency,
    required this.hideAmounts,
  });

  final ThemeMode themeMode;
  final PDensity density;
  final String currency; // 'KRW' | 'USD' | 'EUR' | 'JPY'
  final bool hideAmounts;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    density: PDensity.comfortable,
    currency: 'KRW',
    hideAmounts: false,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    PDensity? density,
    String? currency,
    bool? hideAmounts,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      density: density ?? this.density,
      currency: currency ?? this.currency,
      hideAmounts: hideAmounts ?? this.hideAmounts,
    );
  }
}

/// SharedPreferences 와 양방향 sync 되는 표시 설정 Notifier.
final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await ref.watch(prefsProvider.future);
    return AppSettings(
      themeMode: _parseTheme(prefs.getString(PrefsKeys.themeMode)),
      density: _parseDensity(prefs.getString(PrefsKeys.density)),
      currency: prefs.getString(PrefsKeys.currency) ?? AppSettings.defaults.currency,
      hideAmounts: prefs.getBool(PrefsKeys.hideAmounts) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(PrefsKeys.themeMode, _serializeTheme(mode));
    state = AsyncData(_current.copyWith(themeMode: mode));
  }

  Future<void> setDensity(PDensity d) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(PrefsKeys.density, d.name);
    state = AsyncData(_current.copyWith(density: d));
  }

  Future<void> setCurrency(String code) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(PrefsKeys.currency, code);
    state = AsyncData(_current.copyWith(currency: code));
  }

  Future<void> toggleHideAmounts() async {
    final prefs = await ref.read(prefsProvider.future);
    final next = !_current.hideAmounts;
    await prefs.setBool(PrefsKeys.hideAmounts, next);
    state = AsyncData(_current.copyWith(hideAmounts: next));
  }

  AppSettings get _current => state.value ?? AppSettings.defaults;

  static ThemeMode _parseTheme(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
  static String _serializeTheme(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
  static PDensity _parseDensity(String? raw) => switch (raw) {
        'compact' => PDensity.compact,
        'spacious' => PDensity.spacious,
        _ => PDensity.comfortable,
      };
}
