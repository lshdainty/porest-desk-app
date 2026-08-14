import 'package:porest_desk_app/features/sms/data/sms_repository.dart';

/// 결제 문자에서 만든 거래 초안 — 원문 + 서버 해석 결과.
///
/// 거래 시트에 그대로 넘겨 초기값으로 쓴다. 원문을 함께 들고 다니는 이유는
/// 저장 시 서버가 다시 파싱해 취소 문자를 걸러내고 카드 매핑 키를 도출하기 때문이다.
class SmsDraft {
  const SmsDraft({required this.text, required this.parsed});

  /// 문자 원문.
  final String text;

  /// 서버 해석 결과.
  final SmsParseResult parsed;

  /// "이 카드로 기억" 을 물어볼 만한가 — 카드를 식별했는데 아직 안 외운 경우.
  bool get canRememberCard =>
      (parsed.cardHint?.isNotEmpty ?? false) && !parsed.assetRemembered;
}
