import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/settings/user_locale.dart';

/// 숫자·통화·날짜 포맷터가 참조하는 "현재 유효 로케일이 영어인지" 판정.
///
/// 앱이 설정 로케일을 [Intl.defaultLocale] 에 배선(`SettingsNotifier`)하므로 그걸
/// 1순위로 읽고, 아직 배선 전이면 [UserLocale.current](사용자 명시 선택)로 폴백한다.
/// 둘 다 없으면(= 시스템 로케일 따름) 한국어로 취급 → 기존 출력 회귀 0.
///
/// 즉 **사용자가 명시적으로 `en` 을 선택한 경우에만** 영어 포맷을 낸다.
bool localeIsEn() =>
    (Intl.defaultLocale ?? UserLocale.current?.languageCode) == 'en';
