import 'package:flutter/material.dart';

import 'colors.dart';

/// 차트 카테고리 구분용 8색 팔레트 — light/dark 분기.
///
/// 카테고리별 도넛/막대 차트 등에서 인접 카테고리를 시각적으로 구분하기 위한
/// 글로벌 색상 집합. brand(cobalt)와 의미 분리 — 카테고리 자체에 의미가 있는
/// 경우(수입/지출/이체)는 [PorestTokens.fgIncome/fgExpense/fgTransfer]를 사용.
///
/// porest-desk-front `--chart-1` ~ `--chart-8` 미러. dark mode는 lightness를
/// 한 단계 위로 옮긴 *Light variant 사용 — 어두운 배경에서도 대비 확보.
///
/// 사용:
/// ```dart
/// final color = PorestChartPalette.category(context, idx);
/// ```
abstract final class PorestChartPalette {
  /// 카테고리 인덱스로 색 선택 — 자동 wrap, 현재 테마 brightness 기반 분기.
  static Color category(BuildContext context, int i) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = isDark ? _dark : _light;
    return list[i % list.length];
  }

  /// 팔레트 길이 — legend 미리 색 수 알아야 할 때.
  static int get length => _light.length;

  /// theme-independent 접근이 필요한 곳(예: legend 미리보기). 가능하면 [category] 사용.
  static const List<Color> categoriesLight = _light;
  static const List<Color> categoriesDark = _dark;

  static const List<Color> _light = <Color>[
    PorestPalette.bark500,   // 따뜻한 warm-brown
    PorestPalette.berry500,  // 핑크-레드
    PorestPalette.sprout500, // 옐로-그린
    PorestPalette.sky500,    // 블루
    PorestPalette.cobalt400, // 라이트 코발트
    PorestPalette.sunlit500, // 옐로
    PorestPalette.mossy500,  // 올리브
    PorestPalette.cobalt700, // 딥 코발트
  ];

  /// Dark variant — 어두운 배경에서도 contrast 유지. *300 톤 위주.
  static const List<Color> _dark = <Color>[
    PorestPalette.bark300,
    PorestPalette.berry300,
    PorestPalette.sprout300,
    PorestPalette.sky300,
    PorestPalette.cobalt300,
    PorestPalette.sunlit300,
    PorestPalette.mossy300,
    PorestPalette.cobalt400,
  ];
}
