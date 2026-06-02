import 'package:intl/intl.dart';

/// porest-desk-front `KRW(n, {sign, abs})` 포팅.
///
/// 천단위 콤마 (`ko_KR`), 부호 옵션, 절댓값 옵션.
String krw(int n, {bool sign = false, bool abs = false}) {
  final v = abs ? n.abs() : n;
  final formatted = NumberFormat.decimalPattern('ko_KR').format(v);
  if (sign && n > 0) return '+$formatted';
  return formatted;
}

/// 금액 숨김(마스킹) 토글이 켜진 경우 `•••` 로 대체.
String krwMasked(int n, bool masked, {bool sign = false, bool abs = false}) {
  if (masked) return '•••';
  return krw(n, sign: sign, abs: abs);
}

/// 부호(±)·단위(원) 포함 금액 표기. masked면 부호·원 없이 마스크 점만 노출.
///
/// web `MaskAmount`(부호를 마스크 안에 포함) + `HideUnit`(원) 정합 —
/// 금액을 숨겼을 때 `+`/`-`·`원` 이 같이 사라지고 점만 남도록.
String krwSigned(int n, bool masked, {String sign = '', bool unit = false}) {
  if (masked) return krwMasked(n, masked);
  return '$sign${krw(n)}${unit ? '원' : ''}';
}

/// 차트 Y축 라벨 — 한국어 단위 축약 (억/만) + 100만 단위 round.
/// 음수도 부호 prepend (`−` 가운데 dash). Web `formatChartAxis` 와 정합.
/// 예: -51,750,000 → '−5,200만', 1,200,000,000 → '12.0억'.
String formatChartAxis(double v) {
  final n = v.abs();
  String body;
  if (n >= 100000000) {
    body = '${(n / 100000000).toStringAsFixed(1)}억';
  } else if (n >= 10000) {
    final mil = (n / 1000000).round() * 100;
    body = '${NumberFormat.decimalPattern('ko_KR').format(mil)}만';
  } else {
    body = n.toStringAsFixed(0);
  }
  return v < 0 ? '−$body' : body;
}
