/// 서버 십진수(BigDecimal) → 문자열 정규화.
///
/// 백엔드는 `decimal(28,8)` 컬럼을 `BigDecimal` 로 내보내고, Jackson 은 그걸 JSON
/// **숫자**로 직렬화한다(`3.75000000`). 앱은 정밀도가 깎이지 않도록 문자열로 들고
/// 다니므로, 숫자로 온 값을 그대로 `String` 에 캐스트하면 터진다.
///
///     type 'double' is not a subtype of type 'String?' in type cast
///
/// 숫자·문자열 어느 쪽으로 와도 받고, 의미 없는 0 은 떼어 낸다(`3.75000000` → `3.75`).
/// 숫자는 `decimal(28,8)` 스케일까지만 평문으로 편다 — `1e-8` 같은 지수 표기를 만들지 않는다.
///
/// 수량·평단가처럼 **서버 계약이 BigDecimal 인 모든 필드**에 붙일 것. 하나라도 빠지면
/// 그 값이 실제로 채워지는 순간(보유가 생기는 순간) 화면 전체가 로드에 실패한다.
String? decimalStringFromJson(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return _trimDecimal(raw.trim());
  if (raw is int) return '$raw';
  if (raw is num) {
    final d = raw.toDouble();
    if (d.isNaN || d.isInfinite) return null;
    return _trimDecimal(d.toStringAsFixed(8));
  }
  return null;
}

/// 소수부 꼬리 0 제거 — `3.750000` → `3.75`, `3.00` → `3`. 정수 표기는 그대로 둔다.
String? _trimDecimal(String s) {
  if (s.isEmpty) return null;
  if (!s.contains('.')) return s;
  var out = s.replaceFirst(RegExp(r'0+$'), '');
  if (out.endsWith('.')) out = out.substring(0, out.length - 1);
  return out.isEmpty ? null : out;
}
