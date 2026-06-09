/// porest-design `--z-*` SoT 정합 — DESIGN.desk.md / porest-tokens.css L168-174.
///
/// Flutter 는 widget tree 로 stacking 을 자동 처리하지만,
/// [Overlay.of].insert, [Navigator.overlay], custom [Stack] ordering 등을 직접
/// 다룰 때 layer 비교용. 숫자 자체는 web `z-index` 와 동일 의미.
abstract final class PZ {
  /// 기본 콘텐츠 layer.
  static const int base = 0;

  /// dropdown / select menu.
  static const int dropdown = 1000;

  /// sticky header / pinned bar.
  static const int sticky = 1100;

  /// drawer / side panel.
  static const int drawer = 1200;

  /// modal / dialog / bottomSheet.
  static const int modal = 1300;

  /// toast / snackbar.
  static const int toast = 1400;
}
