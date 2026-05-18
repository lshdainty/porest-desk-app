import 'package:flutter/material.dart';

import 'color_parse.dart';

/// porest-design chart palette base ↔ light variant 매핑.
///
/// DB (expense_category.color) 는 base hex 만 저장하는 single-source.
/// 다크모드에서는 light variant 로 swap 한다 — Theme.of(context).brightness
/// 분기로 결정.
///
/// porest-tokens.css `--color-chart-*` 값 미러.
class ChartPair {
  const ChartPair({
    required this.key,
    required this.baseHex,
    required this.lightHex,
    required this.base,
    required this.light,
  });
  final String key;

  /// 라이트 모드 hex 문자열 (DB 저장값).
  final String baseHex;

  /// 다크 모드 hex 문자열.
  final String lightHex;

  final Color base;
  final Color light;
}

const kChartPairs = <ChartPair>[
  ChartPair(key: 'red',    baseHex: '#c73838', lightHex: '#eca0a0', base: Color(0xFFC73838), light: Color(0xFFECA0A0)),
  ChartPair(key: 'orange', baseHex: '#b36418', lightHex: '#e8b266', base: Color(0xFFB36418), light: Color(0xFFE8B266)),
  ChartPair(key: 'yellow', baseHex: '#8c7400', lightHex: '#d4b83a', base: Color(0xFF8C7400), light: Color(0xFFD4B83A)),
  ChartPair(key: 'green',  baseHex: '#2d8060', lightHex: '#6bcb86', base: Color(0xFF2D8060), light: Color(0xFF6BCB86)),
  ChartPair(key: 'blue',   baseHex: '#2c70bf', lightHex: '#7bbbed', base: Color(0xFF2C70BF), light: Color(0xFF7BBBED)),
  ChartPair(key: 'indigo', baseHex: '#5e60c8', lightHex: '#abb0f0', base: Color(0xFF5E60C8), light: Color(0xFFABB0F0)),
  ChartPair(key: 'violet', baseHex: '#8b4dba', lightHex: '#d2a8ec', base: Color(0xFF8B4DBA), light: Color(0xFFD2A8EC)),
  ChartPair(key: 'pink',   baseHex: '#b83b7a', lightHex: '#eca0bc', base: Color(0xFFB83B7A), light: Color(0xFFECA0BC)),
  ChartPair(key: 'brown',  baseHex: '#9a6536', lightHex: '#dcb088', base: Color(0xFF9A6536), light: Color(0xFFDCB088)),
  ChartPair(key: 'gray',   baseHex: '#6b7484', lightHex: '#b5bbc5', base: Color(0xFF6B7484), light: Color(0xFFB5BBC5)),
];

final Map<String, ChartPair> _kBaseHexToPair = {
  for (final p in kChartPairs) p.baseHex.toLowerCase(): p,
};

/// 카테고리 fg Color 결정 — 라이트/다크 자동 분기.
///
/// - hex 가 chart palette base hex 이면 다크모드일 때 light variant 반환
/// - 그 외 hex 는 raw 파싱 (사용자 커스텀 색)
/// - null / 빈 값 / 잘못된 형식 → fallback
Color resolveChartColor(
  BuildContext context,
  String? rawHex, {
  Color? fallback,
}) {
  final fb = fallback ?? Theme.of(context).colorScheme.primary;
  if (rawHex == null || rawHex.trim().isEmpty) return fb;
  final norm = rawHex.trim().toLowerCase();
  final pair = _kBaseHexToPair[norm];
  if (pair != null) {
    return Theme.of(context).brightness == Brightness.dark
        ? pair.light
        : pair.base;
  }
  return parseColor(rawHex, fallback: fb);
}
