/// 낱말 단위 줄바꿈(DESIGN.md v114 — 웹의 word-break: keep-all) — 낱말 안의 글자 사이에 이음 문자(U+2060 WORD
/// JOINER)를 넣어 띄어쓰기에서만 줄이 바뀌게 한다. 한 줄보다 긴 낱말은 Flutter 가 칸 끝에서 끊는다(웹의
/// overflow-wrap: break-word 와 같다). 보조 기술은 이음 문자를 읽지 않는다.
String keepAll(String text) {
  final out = StringBuffer();
  final chars = text.runes.toList();
  for (var i = 0; i < chars.length; i++) {
    out.writeCharCode(chars[i]);
    if (i + 1 < chars.length &&
        !_breakable(chars[i]) &&
        !_breakable(chars[i + 1])) {
      out.writeCharCode(0x2060);
    }
  }
  return out.toString();
}

// 공백 · 줄바꿈 자리에서는 끊을 수 있게 둔다
bool _breakable(int rune) =>
    rune == 0x20 || rune == 0x0A || rune == 0x09 || rune == 0x3000;

/// 금액 — [keepAll] 처럼 낱말 단위로 묶되 **쉼표 뒤에서만** 줄을 바꿀 수 있게 한다(03-D 결정 2 B, Typography v114 의
/// 예외). 지표 · 순자산 · 목록 금액이 칸보다 길 때 숫자 한가운데(`−123,4` / `56,789,`)가 아니라 `−123,` / `456,` /
/// `789원` 처럼 쉼표 자리에서 끊긴다. 웹은 `<wbr>`, 앱은 쉼표 바로 뒤의 이음 문자(U+2060) 한 자리를 너비 0 공백
/// (U+200B)으로 바꾼다.
///
/// **보이는 글에만** 쓴다. 읽는 이름은 원래 글이어야 해서 `Text(..., semanticsLabel: 원래 글)` 로 함께 넘긴다 —
/// 복사 · 낭독 · 비교에는 이 글이 들어가지 않는다. 금액을 이 앱에서 보이는 글로 바꾸는 자리는 이 함수 하나다.
String keepAllAmount(String amount) =>
    keepAll(amount).replaceAll(_commaJoined, _commaBreak);

// 포매터가 \u 이스케이프를 보이지 않는 글자 그대로 풀어 버려, 코드 값으로 만든다
final String _commaJoined = ',${String.fromCharCode(0x2060)}';
final String _commaBreak = ',${String.fromCharCode(0x200B)}';
