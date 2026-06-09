import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/format/chart_palette.dart';

/// 메모 카드 색 슬롯 — chart palette base hex 기반.
///
/// 웹 `screens-life.jsx` `MEMO_COLORS` 1:1 미러:
/// - bg  = chart색(테마 적응)을 `bg-surface` 와 틴트% 혼합 (web color-mix in oklab)
/// - fg  = chart색을 `fg-primary` 와 믹스% 혼합 (태그 라벨색 — 다크에서도 가독)
/// - swatch(dot·활성 핀·선택 보더) = chart색 그대로 (resolveChartColor)
///
/// `color` 가 null/미정의 hex 이면 blue(#2c70bf) 로 취급.
class MemoColorSlot {
  const MemoColorSlot({required this.bgTint, required this.fgMix});

  /// bg = lerp(bgSurface, 색, bgTint) — 카드 배경 비중.
  final double bgTint;

  /// fg = lerp(fgPrimary, 색, fgMix) — 태그 라벨 색 비중.
  final double fgMix;
}

/// base hex → (bgTint%, fgMix%) 매핑. 키는 소문자 hex.
const String kMemoDefaultColor = '#2c70bf'; // blue

const Map<String, MemoColorSlot> _kMemoSlots = {
  '#2c70bf': MemoColorSlot(bgTint: 0.12, fgMix: 0.72), // blue
  '#2d8060': MemoColorSlot(bgTint: 0.14, fgMix: 0.70), // green
  '#b83b7a': MemoColorSlot(bgTint: 0.12, fgMix: 0.72), // pink
  '#8b4dba': MemoColorSlot(bgTint: 0.12, fgMix: 0.72), // violet
  '#c73838': MemoColorSlot(bgTint: 0.12, fgMix: 0.72), // red
  '#b36418': MemoColorSlot(bgTint: 0.13, fgMix: 0.70), // orange
  '#5e60c8': MemoColorSlot(bgTint: 0.13, fgMix: 0.72), // indigo
  '#8c7400': MemoColorSlot(bgTint: 0.16, fgMix: 0.64), // yellow
  '#9a6536': MemoColorSlot(bgTint: 0.14, fgMix: 0.68), // brown
  '#6b7484': MemoColorSlot(bgTint: 0.16, fgMix: 0.60), // gray
};

/// 메모 color 값을 정규화 — null/빈값/미정의 hex → blue.
String memoColorOrDefault(String? raw) {
  final norm = raw?.trim().toLowerCase();
  if (norm == null || norm.isEmpty) return kMemoDefaultColor;
  return _kMemoSlots.containsKey(norm) ? norm : kMemoDefaultColor;
}

MemoColorSlot _slot(String hex) =>
    _kMemoSlots[hex] ?? _kMemoSlots[kMemoDefaultColor]!;

/// 카드 배경 — 테마 적응 chart색을 bgSurface 와 틴트% 혼합 (불투명).
Color memoCardBg(BuildContext context, String? color) {
  final hex = memoColorOrDefault(color);
  final t = context.tokens;
  final base = resolveChartColor(context, hex, fallback: t.fgBrand);
  return Color.lerp(t.bgSurface, base, _slot(hex).bgTint)!;
}

/// 태그 라벨 색 — chart색을 fgPrimary 와 믹스% 혼합 (테마 적응).
Color memoTagFg(BuildContext context, String? color) {
  final hex = memoColorOrDefault(color);
  final t = context.tokens;
  final base = resolveChartColor(context, hex, fallback: t.fgBrand);
  return Color.lerp(t.fgPrimary, base, _slot(hex).fgMix)!;
}

/// dot·활성 핀·선택 보더용 solid swatch 색 — chart 원색(테마 적응).
Color memoSwatch(BuildContext context, String? color) {
  final hex = memoColorOrDefault(color);
  return resolveChartColor(context, hex, fallback: context.tokens.fgBrand);
}
