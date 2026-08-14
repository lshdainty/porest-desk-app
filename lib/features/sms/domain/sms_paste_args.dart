/// `/sms-paste` 로 넘기는 인자.
///
/// 알림·보관함에서 들어올 때는 원문 말고도 보관함 항목 id 가 필요하다
/// (저장에 성공하면 그 목록에서 빼야 한다). 홈 배너처럼 id 가 없는 경로도
/// 있어서 문자열 하나만 넘기는 것도 그대로 받는다.
class SmsPasteArgs {
  const SmsPasteArgs({required this.text, this.inboxId});

  final String text;
  final int? inboxId;

  /// 라우트 extra 해석 — 문자열이면 원문만, [SmsPasteArgs] 면 그대로.
  static SmsPasteArgs? from(Object? extra) {
    if (extra is SmsPasteArgs) return extra;
    if (extra is String && extra.isNotEmpty) return SmsPasteArgs(text: extra);
    return null;
  }
}
