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
