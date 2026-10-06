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
