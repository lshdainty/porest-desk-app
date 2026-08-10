import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/format/format_locale.dart';

/// porest-desk-front `KRW(n, {sign, abs})` 포팅.
///
/// 천단위 콤마, 부호 옵션, 절댓값 옵션.
String krw(int n, {bool sign = false, bool abs = false}) {
  final v = abs ? n.abs() : n;
  // 천단위 콤마 그룹핑은 ko/en 동일('10,000') → ko 출력 회귀 0. locale 만 현재값으로.
  final formatted =
      NumberFormat.decimalPattern(localeIsEn() ? 'en' : 'ko_KR').format(v);
  if (sign && n > 0) return '+$formatted';
  return formatted;
}

/// web `HIDE_AMOUNTS_MASK` 정합 — 기본 마스크는 점 6개. 작은/compact 표기는 `mask: '••••'`(4개).
const String kHideMask = '••••••';

/// 금액 숨김(마스킹) 토글이 켜진 경우 [mask] 점으로 대체.
String krwMasked(int n, bool masked,
    {bool sign = false, bool abs = false, String mask = kHideMask}) {
  if (masked) return mask;
  return krw(n, sign: sign, abs: abs);
}

/// 부호(±)·단위(원) 포함 금액 표기. masked면 부호·원 없이 [mask] 점만 노출.
///
/// web `MaskAmount`(부호를 마스크 안에 포함) + `HideUnit`(원) 정합 —
/// 금액을 숨겼을 때 `+`/`-`·`원` 이 같이 사라지고 점만 남도록.
String krwSigned(int n, bool masked,
    {String sign = '', bool unit = false, String mask = kHideMask}) {
  if (masked) return mask;
  // 통화 단위: ko '원' 접미 / en '₩' 접두 (부호는 항상 최선두). unit=false 면 숫자만.
  if (unit && localeIsEn()) return '$sign₩${krw(n)}';
  return '$sign${krw(n)}${unit ? '원' : ''}';
}

/// 통화 단위 라벨(정적) — ko '원' / en '₩'.
///
/// 입력필드 suffixText·표시 라벨 등 **독립 단위 라벨 자리** 정적 분기용.
/// (금액+단위 동시 포맷은 [krwSigned]`(unit:true)` 사용 — en 은 접두 ₩.)
String wonUnit() => localeIsEn() ? '₩' : '원';

/// 차트 Y축 라벨 — 한국어 단위 축약 (억/만) + 100만 단위 round.
/// 음수도 부호 prepend (`−` 가운데 dash). Web `formatChartAxis` 와 정합.
/// 예: -51,750,000 → '−5,200만', 1,200,000,000 → '12.0억'.
String formatChartAxis(double v) {
  // en: 로케일 compact 축약 (120M · 52K · -5.2M). intl 내장 en 데이터.
  if (localeIsEn()) return NumberFormat.compact(locale: 'en').format(v);
  // ko: 조/억/만 축약.
  //
  // 구간마다 정밀도를 달리한다. 한 자리로 뭉개면 축 눈금이 겹치고(84만짜리 차트에서
  // 25·50·75·100만이 "0만, 0만, 100만, 100만" 으로 나왔다), 반대로 늘 만 단위로 쓰면
  // 조 단위에서 "10000.0억" 같은 라벨이 나와 축 폭(reservedSize 52)을 넘는다.
  //
  //   1조~     1.2조        10억~    12억, 9,999억
  //   1억~     5.2억        1만~     25만, 9,999만
  //   ~1만     5000
  final n = v.abs();
  final ko = NumberFormat.decimalPattern('ko_KR');
  String body;
  if (n >= 1000000000000) {
    body = '${(n / 1000000000000).toStringAsFixed(1)}조';
  } else if (n >= 1000000000) {
    // 10억이 넘으면 소수 한 자리가 읽는 데 보태는 게 없다.
    body = '${ko.format((n / 100000000).round())}억';
  } else if (n >= 100000000) {
    body = '${(n / 100000000).toStringAsFixed(1)}억';
  } else if (n >= 10000) {
    body = '${ko.format((n / 10000).round())}만';
  } else {
    body = n.toStringAsFixed(0);
  }
  return v < 0 ? '−$body' : body;
}
