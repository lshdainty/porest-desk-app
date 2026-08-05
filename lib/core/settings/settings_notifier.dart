import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/core/settings/user_locale.dart';

/// 사용자 표시 설정 모음.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.currency,
    required this.hideCards,
    required this.locale,
  });

  final ThemeMode themeMode;
  final String currency; // 'KRW' | 'USD' | 'EUR' | 'JPY'

  /// 지금 가려 둔 카드들. 비어 있으면 아무것도 안 가린 상태다.
  /// 카드 목록은 [kHideCards] 에 있다.
  final Set<String> hideCards;

  /// 하나라도 가려져 있는가 — 눈 아이콘처럼 "지금 가린 게 있나" 만 보는 자리용.
  bool get hasHidden => hideCards.isNotEmpty;

  bool isHidden(String card) => hideCards.contains(card);

  /// `null` = 시스템 로케일 따름. 그 외 'ko'/'en'.
  final Locale? locale;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    currency: 'KRW',
    hideCards: <String>{},
    locale: null,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currency,
    Set<String>? hideCards,
    Object? locale = _sentinel,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      hideCards: hideCards ?? this.hideCards,
      locale: identical(locale, _sentinel) ? this.locale : locale as Locale?,
    );
  }
}

const _sentinel = Object();

/// 저장된 카드 목록을 읽는다.
///
/// 예전 사용자는 "전부 가림" 상태였다 — 켜져 있었으면 그대로 전부 켠 채로 옮긴다.
/// 안 그러면 업데이트하자마자 금액이 통째로 드러난다.
Set<String> _loadHideCards(SharedPreferences prefs) {
  final legacy = prefs.getBool(PrefsKeys.hideAmounts);
  if (legacy != null) {
    prefs.remove(PrefsKeys.hideAmounts);
    final migrated = legacy ? kAllHideCards.toSet() : <String>{};
    prefs.setStringList(PrefsKeys.hideCards, migrated.toList());
    return migrated;
  }
  final saved = prefs.getStringList(PrefsKeys.hideCards) ?? const <String>[];
  // 없어진 카드 키는 버린다 — 남겨 두면 영영 못 지우는 유령이 된다.
  return saved.where(kHideCards.containsKey).toSet();
}

/// 이 카드가 가려져 있는가. 화면에서 `masked:` 에 그대로 넘긴다.
final hideCardProvider = Provider.family<bool, String>((ref, card) {
  return ref.watch(settingsProvider).value?.isHidden(card) ?? false;
});

/// 하나라도 가려져 있는가 — 눈 아이콘 표시용.
final anyHiddenProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).value?.hasHidden ?? false;
});

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
      hideCards: _loadHideCards(prefs),
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

  /// 가리기 — 인증 없이 자유롭게 켠다. 푸는 쪽만 인증을 받는다(화면 책임).
  Future<void> hideCards(Iterable<String> cards) async {
    await _writeHideCards({..._current.hideCards, ...cards});
  }

  /// 풀기 — 호출 전에 인증을 거칠 것.
  Future<void> revealCards(Iterable<String> cards) async {
    await _writeHideCards({..._current.hideCards}..removeAll(cards));
  }

  Future<void> hideAllCards() => hideCards(kAllHideCards);

  Future<void> revealAllCards() => _writeHideCards(<String>{});

  Future<void> _writeHideCards(Set<String> next) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setStringList(PrefsKeys.hideCards, next.toList());
    state = AsyncData(_current.copyWith(hideCards: next));
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
