/// DESIGN.desk.md `spacing.*` spec 매핑.
///
/// Spec 의미명 (semantic): xs(4) / sm(8) / md(12) / lg(16) / xl(24) / xl2(32) / xl3(48).
/// 픽셀명 (legacy): x0/x4/x8/x12/x16/x20/x24/x28/x32/x40/x48/x64/x80 — 신규 코드는
/// semantic 명 우선 사용 권장.
///
/// 사용 예: `EdgeInsets.all(PSpace.lg)`, `SizedBox(height: PSpace.sm)`.
abstract final class PSpace {
  // Spec semantic (DESIGN.desk.md)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xl2 = 32;
  static const double xl3 = 48;

  // Pixel-named (legacy, 호환성 유지)
  static const double x0 = 0;
  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x28 = 28;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x64 = 64;
  static const double x80 = 80;
}
