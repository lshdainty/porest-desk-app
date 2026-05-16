import 'package:flutter/painting.dart';

/// 카드/팝업의 elevation shadow 토큰.
///
/// porest-desk-front `--shadow-sm` / `--shadow-md` 미러.
/// 그림자 색은 brand-agnostic neutral (mossy-tinted 어두운 톤) — 라이트/다크 모드 공통.
abstract final class PorestElevation {
  /// `--shadow-sm: 0 1px 2px rgba(28,36,20,0.06), 0 1px 3px rgba(28,36,20,0.04)`
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0F1C2414),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0A1C2414),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// 좀 더 명확한 elevation — modal, dropdown 등.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x141C2414),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0x0A1C2414),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
}
