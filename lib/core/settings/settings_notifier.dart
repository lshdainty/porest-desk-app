import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/core/settings/user_locale.dart';

/// 사용자 표시 설정 모음.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.currency,
    required this.hideAmounts,
    required this.locale,
  });

  final ThemeMode themeMode;
  final String currency; // 'KRW' | 'USD' | 'EUR' | 'JPY'
  final bool hideAmounts;

  /// `null` = 시스템 로케일 따름. 그 외 'ko'/'en'.
  final Locale? locale;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    currency: 'KRW',
    hideAmounts: false,
    locale: null,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currency,
    bool? hideAmounts,
    Object? locale = _sentinel,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      hideAmounts: hideAmounts ?? this.hideAmounts,
      locale: identical(locale, _sentinel) ? this.locale : locale as Locale?,
    );
  }
}

const _sentinel = Object();

/// SharedPreferences 와 양방향 sync 되는 표시 설정 Notifier.
final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await ref.watch(prefsProvider.future);
    final loc = _parseLocale(prefs.getString(PrefsKeys.locale));
    UserLocale.current = loc;
    // 숫자·날짜 포맷터가 참조하는 전역 로케일 배선. 미선택(시스템)이면 ko 로 폴백
    // → 기존 출력 회귀 0. 명시적으로 en 을 고른 경우에만 영어 포맷.
    Intl.defaultLocale = loc?.languageCode ?? 'ko';
    return AppSettings(
      themeMode: _parseTheme(prefs.getString(PrefsKeys.themeMode)),
      currency: prefs.getString(PrefsKeys.currency) ?? AppSettings.defaults.currency,
      hideAmounts: prefs.getBool(PrefsKeys.hideAmounts) ?? false,
      locale: loc,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(PrefsKeys.themeMode, _serializeTheme(mode));
    state = AsyncData(_current.copyWith(themeMode: mode));
  }

  Future<void> setCurrency(String code) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(PrefsKeys.currency, code);
    state = AsyncData(_current.copyWith(currency: code));
  }

  Future<void> toggleHideAmounts() async {
    await setHideAmounts(!_current.hideAmounts);
  }

  Future<void> setHideAmounts(bool value) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setBool(PrefsKeys.hideAmounts, value);
    state = AsyncData(_current.copyWith(hideAmounts: value));
  }

  /// [locale] = `null` 이면 시스템 로케일을 따른다.
  Future<void> setLocale(Locale? locale) async {
    final prefs = await ref.read(prefsProvider.future);
    if (locale == null) {
      await prefs.remove(PrefsKeys.locale);
    } else {
      await prefs.setString(PrefsKeys.locale, locale.languageCode);
    }
    UserLocale.current = locale;
    Intl.defaultLocale = locale?.languageCode ?? 'ko';
    state = AsyncData(_current.copyWith(locale: locale));
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
  static Locale? _parseLocale(String? raw) => switch (raw) {
        'ko' => const Locale('ko'),
        'en' => const Locale('en'),
        _ => null,
      };
}
