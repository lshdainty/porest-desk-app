import 'package:flutter/painting.dart';

/// porest-design `--shadow-*` SoT 정합 — DESIGN.desk.md "Elevation & Depth"
/// / `porest-tokens.css` L132-139.
///
/// Light: base color cool-neutral `rgb(15,18,28)` (= #0F121C). 깊이감을 위해
/// 대부분 두 레이어 — wider blur/larger offset + sharper/closer.
///
/// Dark: pure black drop + `inset 0 1px 0 0 rgba(255,255,255,alpha)` 미세
/// 화이트 하이라이트(top edge bevel). Flutter `BlurStyle.inner` 는 CSS `inset`
/// 와 완전 동일하지 않으나 가장 가까운 표현 — blurRadius 0/offset (0,1) 로
/// SoT 의 1px 하이라이트 의도를 유지.
///
/// 옛 Mossy green-tinted `rgb(28,36,20)` 기반 잔재(xs/brand/focus)는 follow-up
/// task 에서 정리 예정.
abstract final class PShadow {
  // ==========================================================================
  // Light — base #0F121C (cool-neutral) — SoT 정합
  // ==========================================================================

  /// shadow-sm: `0 1px 2px 0 rgba(15,18,28,0.05)` — 카드/입력 기본 elevation.
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D0F121C), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// shadow-md: `0 2px 8px -1px rgba(15,18,28,0.08), 0 1px 3px -1px rgba(15,18,28,0.04)`
  /// — dropdown/popover 등 중간 elevation.
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x140F121C), offset: Offset(0, 2), blurRadius: 8, spreadRadius: -1),
    BoxShadow(color: Color(0x0A0F121C), offset: Offset(0, 1), blurRadius: 3, spreadRadius: -1),
  ];

  /// shadow-lg: `0 8px 24px -4px rgba(15,18,28,0.10), 0 2px 6px -2px rgba(15,18,28,0.05)`
  /// — sheet/dialog elevation.
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A0F121C), offset: Offset(0, 8), blurRadius: 24, spreadRadius: -4),
    BoxShadow(color: Color(0x0D0F121C), offset: Offset(0, 2), blurRadius: 6, spreadRadius: -2),
  ];

  /// shadow-xl: `0 24px 48px -8px rgba(15,18,28,0.16), 0 8px 16px -4px rgba(15,18,28,0.08)`
  /// — modal/hero elevation.
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x290F121C), offset: Offset(0, 24), blurRadius: 48, spreadRadius: -8),
    BoxShadow(color: Color(0x140F121C), offset: Offset(0, 8), blurRadius: 16, spreadRadius: -4),
  ];

  // ==========================================================================
  // Dark — pure black drop + inset white highlight (top edge bevel) — SoT 정합
  // ==========================================================================

  /// shadow-sm-dark: `0 1px 2px 0 rgba(0,0,0,0.30), inset 0 1px 0 0 rgba(255,255,255,0.05)`
  static const List<BoxShadow> smDark = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(0, 1), blurStyle: BlurStyle.inner),
  ];

  /// shadow-md-dark: `0 2px 8px -1px rgba(0,0,0,0.40), 0 1px 3px -1px rgba(0,0,0,0.20),`
  /// `inset 0 1px 0 0 rgba(255,255,255,0.06)`
  static const List<BoxShadow> mdDark = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8, spreadRadius: -1),
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 3, spreadRadius: -1),
    BoxShadow(color: Color(0x0FFFFFFF), offset: Offset(0, 1), blurStyle: BlurStyle.inner),
  ];

  /// shadow-lg-dark: `0 8px 24px -4px rgba(0,0,0,0.50), 0 2px 6px -2px rgba(0,0,0,0.25),`
  /// `inset 0 1px 0 0 rgba(255,255,255,0.08)`
  static const List<BoxShadow> lgDark = [
    BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24, spreadRadius: -4),
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 2), blurRadius: 6, spreadRadius: -2),
    BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1), blurStyle: BlurStyle.inner),
  ];

  /// shadow-xl-dark: `0 24px 48px -8px rgba(0,0,0,0.60), 0 8px 16px -4px rgba(0,0,0,0.30),`
  /// `inset 0 1px 0 0 rgba(255,255,255,0.10)`
  static const List<BoxShadow> xlDark = [
    BoxShadow(color: Color(0x99000000), offset: Offset(0, 24), blurRadius: 48, spreadRadius: -8),
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 8), blurRadius: 16, spreadRadius: -4),
    BoxShadow(color: Color(0x1AFFFFFF), offset: Offset(0, 1), blurStyle: BlurStyle.inner),
  ];

  // ==========================================================================
  // desk-app custom (SoT 외) — 보존. Mossy 잔재 cleanup 은 follow-up task.
  // ==========================================================================

  /// xs — desk-app 전용 sm 보다 약한 elevation (chip/tile 등).
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0D1C2414), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> xsDark = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// brand — focus/hover 강조용 brand-tinted shadow. 옛 Mossy oklch(0.52 0.06 110)
  /// 잔재 — Desk 브랜드 cobalt(#0147AD) 로 정합 필요 (follow-up).
  static const List<BoxShadow> brand = [
    BoxShadow(color: Color(0x597C9054), offset: Offset(0, 6), blurRadius: 16, spreadRadius: -4),
  ];

  /// focus — focus ring. brand 와 동일하게 Mossy 잔재.
  static const List<BoxShadow> focus = [
    BoxShadow(color: Color(0x337C9054), spreadRadius: 3),
  ];

  /// brand-dark — Mossy oklch(0.66 0.06 110) 잔재. cobalt-light(#5FA0E5) 로
  /// 정합 필요 (follow-up).
  static const List<BoxShadow> brandDark = [
    BoxShadow(color: Color(0x80A8BD7E), offset: Offset(0, 6), blurRadius: 16, spreadRadius: -4),
  ];

  static const List<BoxShadow> focusDark = [
    BoxShadow(color: Color(0x59A8BD7E), spreadRadius: 3),
  ];
}
