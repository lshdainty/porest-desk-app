import 'package:flutter/painting.dart';

import 'colors.dart';

/// 차트 카테고리 구분용 8색 팔레트.
///
/// 카테고리별 도넛/막대 차트 등에서 인접 카테고리를 시각적으로 구분하기 위한
/// 글로벌 색상 집합. brand(cobalt)와 의미 분리 — 카테고리 자체에 의미가 있는
/// 경우(수입/지출/이체)는 [PorestTokens.fgIncome/fgExpense/fgTransfer]를 사용.
///
/// porest-desk-front `--chart-1` ~ `--chart-8` 미러.
abstract final class PorestChartPalette {
  /// 카테고리 인덱스로 색 선택 (자동 wrap).
  static Color category(int i) => categories[i % categories.length];

  static const List<Color> categories = <Color>[
    PorestPalette.bark500,   // 따뜻한 warm-brown
    PorestPalette.berry500,  // 핑크-레드
    PorestPalette.sprout500, // 옐로-그린
    PorestPalette.sky500,    // 블루
    PorestPalette.cobalt400, // 라이트 코발트
    PorestPalette.sunlit500, // 옐로
    PorestPalette.mossy500,  // 올리브
    PorestPalette.cobalt700, // 딥 코발트
  ];
}
