import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/colors.dart';

/// 카테고리 fallback 차트 팔레트 10색 — desk-front `CATEGORY_PALETTE` 정확 미러.
///
/// 카테고리 자체의 저장된 색(`cat.color`)이 1순위, 그 다음 인덱스 기반 fallback
/// 이 팔레트 적용. brand(cobalt) 의미 분리 — 의미가 있는 경우(수입/지출/이체)는
/// [PorestTokens.fgIncome/fgExpense/fgTransfer] 사용.
///
/// 순서/색은 `src/pages/dashboard/ui/DashboardPage.tsx` CATEGORY_PALETTE 와 1:1:
///   blue → green → orange → violet → pink → indigo → red → yellow → brown → gray
///
/// dark mode 는 `--color-chart-*-light` 페어 사용 (어두운 배경 대비 확보).
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

  // desk-front CATEGORY_PALETTE 순서: blue/green/orange/violet/pink/indigo/red/yellow/brown/gray
  static const List<Color> _light = <Color>[
    PorestPalette.chartBlue,
    PorestPalette.chartGreen,
    PorestPalette.chartOrange,
    PorestPalette.chartViolet,
    PorestPalette.chartPink,
    PorestPalette.chartIndigo,
    PorestPalette.chartRed,
    PorestPalette.chartYellow,
    PorestPalette.chartBrown,
    PorestPalette.chartGray,
  ];

  /// Dark — `--color-chart-*-light` 사용 (어두운 배경에서 채도/명도 확보).
  static const List<Color> _dark = <Color>[
    PorestPalette.chartBlueLight,
    PorestPalette.chartGreenLight,
    PorestPalette.chartOrangeLight,
    PorestPalette.chartVioletLight,
    PorestPalette.chartPinkLight,
    PorestPalette.chartIndigoLight,
    PorestPalette.chartRedLight,
    PorestPalette.chartYellowLight,
    PorestPalette.chartBrownLight,
    PorestPalette.chartGrayLight,
  ];
}
