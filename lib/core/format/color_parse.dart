import 'package:flutter/painting.dart';

/// 백엔드의 카테고리/자산 `color` 컬럼 파싱.
///
/// - "#RRGGBB" / "#RRGGBBAA" / "RRGGBB" 지원
/// - "oklch(...)" 같은 CSS 함수 표현은 v0.1 에서 미지원 → fallback
/// - 빈 값/null/잘못된 형식 → fallback
Color parseColor(String? raw, {Color fallback = const Color(0xFF6B6C43)}) {
  if (raw == null) return fallback;
  final s = raw.trim();
  if (s.isEmpty) return fallback;
  if (s.startsWith('oklch')) return fallback;

  final hex = s.startsWith('#') ? s.substring(1) : s;
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return fallback;

  switch (hex.length) {
    case 6:
      return Color(int.parse('FF$hex', radix: 16));
    case 8:
      // #RRGGBBAA → ARGB 재배치
      final rgb = hex.substring(0, 6);
      final a = hex.substring(6, 8);
      return Color(int.parse('$a$rgb', radix: 16));
    case 3:
      final r = hex[0] * 2;
      final g = hex[1] * 2;
      final b = hex[2] * 2;
      return Color(int.parse('FF$r$g$b', radix: 16));
    default:
      return fallback;
  }
}

/// 카테고리 색상 → 약하게 흐린 배경(타일) 색.
/// alpha 0x22 (~13%) 적용한 같은 색.
Color softBg(Color base) => base.withValues(alpha: 0.13);
