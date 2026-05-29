import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// 백엔드의 카테고리/자산 `color` 컬럼 파싱.
///
/// - "#RRGGBB" / "#RRGGBBAA" / "RRGGBB" / "RGB" 지원
/// - "oklch(L C H)" / "oklch(L C H / A)" 지원 (CSS Color Module Level 4)
/// - 빈 값/null/잘못된 형식 → fallback
Color parseColor(String? raw, {Color fallback = const Color(0xFF6B6C43)}) {
  if (raw == null) return fallback;
  final s = raw.trim();
  if (s.isEmpty) return fallback;
  if (s.startsWith('oklch')) return _parseOklch(s) ?? fallback;

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

/// `oklch(L C H)` / `oklch(L C H / A)` → sRGB Color.
///
/// L: 0~1 (또는 0%~100%), C: 0~0.4 안쪽, H: 도 단위, A: 0~1.
/// CSS Color Module Level 4 명세 기반 OKLab → linear sRGB → gamma sRGB.
Color? _parseOklch(String raw) {
  final m = RegExp(
    r'oklch\(\s*([^\s/]+)\s+([^\s/]+)\s+([^\s/]+)(?:\s*/\s*([^\s)]+))?\s*\)',
    caseSensitive: false,
  ).firstMatch(raw);
  if (m == null) return null;

  double? num(String? s, {bool allowPct = true}) {
    if (s == null) return null;
    final t = s.trim();
    if (allowPct && t.endsWith('%')) {
      final v = double.tryParse(t.substring(0, t.length - 1));
      return v == null ? null : v / 100.0;
    }
    return double.tryParse(t);
  }

  final l = num(m.group(1));
  final c = num(m.group(2), allowPct: false);
  final h = num(m.group(3), allowPct: false);
  if (l == null || c == null || h == null) return null;
  final aRaw = num(m.group(4));
  final a = (aRaw ?? 1.0).clamp(0.0, 1.0);

  // OKLCH → OKLab
  final hRad = h * math.pi / 180.0;
  final aLab = c * math.cos(hRad);
  final bLab = c * math.sin(hRad);

  // OKLab → linear sRGB (CSS spec inverse matrix)
  final lp = l + 0.3963377774 * aLab + 0.2158037573 * bLab;
  final mp = l - 0.1055613458 * aLab - 0.0638541728 * bLab;
  final sp = l - 0.0894841775 * aLab - 1.2914855480 * bLab;
  final lc = lp * lp * lp;
  final mc = mp * mp * mp;
  final sc = sp * sp * sp;
  final r = 4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc;
  final g = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc;
  final b = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc;

  // linear → sRGB gamma
  int toByte(double v) {
    final clamped = v.clamp(0.0, 1.0);
    final gamma = clamped <= 0.0031308
        ? 12.92 * clamped
        : 1.055 * math.pow(clamped, 1 / 2.4) - 0.055;
    return (gamma * 255).round().clamp(0, 255);
  }

  return Color.fromARGB((a * 255).round(), toByte(r), toByte(g), toByte(b));
}

// softBg(context, base) 는 chart_palette.dart 로 이동 — 다크모드에서 chart light
// variant 기반 타일 배경(가시성)을 위해 BuildContext 필요.
