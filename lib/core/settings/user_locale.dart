import 'dart:ui';

/// 사용자가 명시적으로 선택한 언어를 다른 시스템(예: dio interceptor)에서
/// 동기적으로 읽기 위한 가벼운 글로벌 캐시.
///
/// `SettingsNotifier.setLocale` 이 변경 시 [UserLocale.current] 를 업데이트한다.
/// `null` 이면 OS 로케일을 따른다는 의미.
abstract final class UserLocale {
  static Locale? current;
}
