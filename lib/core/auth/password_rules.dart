import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 비밀번호 규칙 — SSO 서버 정책과 1:1.
///   @Size(min = 8)                     → 길이
///   @Pattern(^(?=.*[^a-zA-Z0-9]).+$)   → 특수문자
///
/// desk 백엔드의 비밀번호 변경은 SSO 로 위임되므로 정책이 동일하다.
/// 입력 중 체크리스트와 제출 가능 여부(_canSubmit)가 이 소스를 함께 쓰기 때문에
/// 표시와 실제 검증 결과가 어긋나지 않는다. front `shared/lib/password.ts` 미러.
class PasswordRule {
  const PasswordRule(this.label, this.test);

  /// 로케일에 맞는 규칙 라벨
  final String Function(AppLocalizations) label;
  final bool Function(String) test;
}

final List<PasswordRule> kPasswordRules = [
  PasswordRule((l) => l.passwordRuleLength, (v) => v.length >= 8),
  PasswordRule(
    (l) => l.passwordRuleSpecial,
    (v) => RegExp(r'[^a-zA-Z0-9]').hasMatch(v),
  ),
];

/// 모든 규칙 충족 여부
bool isPasswordValid(String value) =>
    kPasswordRules.every((rule) => rule.test(value));
