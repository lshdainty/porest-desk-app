/// 검색해서 고르는 목록이 거르는 규칙 — 공용 한 벌(searchable-list.yaml results.filter). 웹 `matchesSearch` 와 같은 뜻이다.
///
/// 한글 NFC · 대소문자 무시 · 공백 무시 · 포함, 이름 + 별칭. 초성 검색은 보류(사용자가 나중에 정한다)라 하지 않는다.
/// 거르는 것은 쓰는 쪽이다 — Searchable List 묶음은 목록을 들지 않는다.
String normalizeSearch(String s) =>
    _nfc(s).toLowerCase().replaceAll(RegExp(r'\s+'), '');

/// [query] 가 비면 모두 맞는다.
bool matchesSearch(
  String name,
  String query, {
  List<String> aliases = const [],
}) {
  final q = normalizeSearch(query);
  return normalizeSearch(name).contains(q) ||
      aliases.any((a) => normalizeSearch(a).contains(q));
}

/// 한글 NFC — 낱자(초 · 중 · 종성 자모)로 쪼개져 들어온 글을 음절로 모은다(맥 · 일부 키보드의 입력). 한글 밖은 그대로 둔다.
String _nfc(String s) {
  if (!s.runes.any((r) => r >= 0x1100 && r <= 0x11FF)) return s;
  const sBase = 0xAC00, lBase = 0x1100, vBase = 0x1161, tBase = 0x11A7;
  const lCount = 19, vCount = 21, tCount = 28;
  final out = <int>[];
  for (final r in s.runes) {
    if (out.isNotEmpty) {
      final last = out.last;
      // 초성 + 중성 → 음절
      if (last >= lBase &&
          last < lBase + lCount &&
          r >= vBase &&
          r < vBase + vCount) {
        out[out.length - 1] =
            sBase + ((last - lBase) * vCount + (r - vBase)) * tCount;
        continue;
      }
      // 음절(받침 없음) + 종성 → 받침을 얹는다
      if (last >= sBase &&
          last < sBase + lCount * vCount * tCount &&
          (last - sBase) % tCount == 0 &&
          r > tBase &&
          r < tBase + tCount) {
        out[out.length - 1] = last + (r - tBase);
        continue;
      }
    }
    out.add(r);
  }
  return String.fromCharCodes(out);
}
