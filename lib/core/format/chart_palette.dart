import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/format/color_parse.dart';

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

/// 색상 picker 가 노출해야 하는 **차트 10색 base hex** 목록.
///
/// DB(라벨/카테고리/캘린더/태그/프로젝트/그룹타입 color)는 이 10색 중 하나만
/// 저장해야 토큰 매핑(resolveChartColor/softBg)이 라이트·다크 swap 된다.
/// `kChartPairs` 의 baseHex 순서와 1:1 미러(const 제약상 리터럴로 선언).
const kChartBaseHexes = <String>[
  '#c73838', // red
  '#b36418', // orange
  '#8c7400', // yellow
  '#2d8060', // green
  '#2c70bf', // blue
  '#5e60c8', // indigo
  '#8b4dba', // violet
  '#b83b7a', // pink
  '#9a6536', // brown
  '#6b7484', // gray
];

final Map<String, ChartPair> _kBaseHexToPair = {
  for (final p in kChartPairs) p.baseHex.toLowerCase(): p,
};

/// base/light hex 둘 다 → ChartPair (Color 역조회용).
final Map<int, ChartPair> _kArgbToPair = {
  for (final p in kChartPairs) ...{
    p.base.toARGB32(): p,
    p.light.toARGB32(): p,
  },
};

/// 카테고리 아이콘 타일 배경 색 — 라이트/다크 자동 분기.
///
/// 받은 [base]가 chart palette 색(base 또는 light variant)이면:
/// - dark: light variant 기반 (어두운 배경에서 가시성 확보) @ 22%
/// - light: base 기반 @ 13%
/// palette 밖 커스텀 색은 그대로 + 동일 alpha.
///
/// 웹 `getPaletteByColor` bg(`--color-cat-* @ 18%`, dark에서 light variant) 정합.
Color softBg(BuildContext context, Color base) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final pair = _kArgbToPair[base.toARGB32()];
  if (isDark) {
    final c = pair?.light ?? base;
    return c.withValues(alpha: 0.22);
  }
  final c = pair?.base ?? base;
  return c.withValues(alpha: 0.13);
}

/// 카테고리 fg Color 결정 — 라이트/다크 자동 분기.
///
/// - hex 가 chart palette base hex 이면 다크모드일 때 light variant 반환
/// - 그 외 hex(사용자 커스텀/브랜드 색)는 다크모드일 때 white 38% 혼합으로 lift
///   — 웹 `--swatch-lift`(라이트 0% / 다크 38%, getPaletteByColor 커스텀 분기) 정합.
///   삼성 네이비(#1428A0)처럼 어두운 브랜드 색이 다크 배경에 묻히는 것 방지.
/// - null / 빈 값 / 잘못된 형식 → fallback (테마 인지 토큰이므로 lift 없음)
/// chart red 시멘틱(캘린더 일요일 등) — 다크에서 light variant 스왑.
/// 웹 `--color-cat-red`(라이트 chart-red / 다크 chart-red-light) 미러.
Color chartRedOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFECA0A0) // chart-red-light
        : const Color(0xFFC73838); // chart-red

Color resolveChartColor(
  BuildContext context,
  String? rawHex, {
  Color? fallback,
}) {
  final fb = fallback ?? Theme.of(context).colorScheme.primary;
  if (rawHex == null || rawHex.trim().isEmpty) return fb;
  final norm = rawHex.trim().toLowerCase();
  final pair = _kBaseHexToPair[norm];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (pair != null) {
    return isDark ? pair.light : pair.base;
  }
  final parsed = parseColor(rawHex, fallback: fb);
  if (isDark && parsed != fb) {
    return Color.lerp(parsed, Colors.white, 0.38)!;
  }
  return parsed;
}

/// 캘린더/라벨 **솔리드 스와치**(체크박스·점·색 미리보기)용 색 — 다크에서 light 톤.
///
/// [resolveChartColor] 가 팔레트 색(light variant)·커스텀 색(white 38% lift) 모두
/// 웹 `--swatch-lift` 정합으로 처리하므로 그대로 위임한다 (과거 HSL 명도 근사 폐기).
Color solidSwatchColor(BuildContext context, String? rawHex, {Color? fallback}) {
  return resolveChartColor(context, rawHex, fallback: fallback);
}

/// 캘린더 이벤트 칩 **배경** — base 색을 surface 와 불투명 혼합.
///
/// 웹 `color-mix(in oklab, <색> 17%, var(--bg-surface))` 정합.
/// 알파(투명) 대신 [Color.lerp] 로 surface 와 섞어 **불투명** 틴트를 만든다
/// (다크에서 뒷배경이 비치지 않음). [t] = base 색 비중(기본 0.17).
Color chipFill(BuildContext context, Color base, {double t = 0.17}) {
  return Color.lerp(context.tokens.bgSurface, base, t)!;
}

/// 캘린더 이벤트 칩 **텍스트** — base 색을 fg-primary 와 혼합.
///
/// 웹 `color-mix(in oklab, <색> 70%, var(--fg-primary))` 정합.
/// 다크에선 fg-primary(밝음)와 섞여 자동으로 light → 어두운 칩 위 가독성 확보.
/// [t] = base 색 비중(기본 0.70).
Color chipText(BuildContext context, Color base, {double t = 0.70}) {
  return Color.lerp(context.tokens.fgPrimary, base, t)!;
}
