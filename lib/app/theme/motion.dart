import 'package:flutter/animation.dart';

/// porest-design `--motion-*` SoT 정합 — DESIGN.desk.md / porest-tokens.css L142-148.
abstract final class PMotion {
  /// SoT 미정의 — desk-app custom (ripple 즉발용).
  static const Duration instant = Duration(milliseconds: 80);

  /// motion-duration-fast: 150ms — small UI transitions, hover/focus.
  static const Duration fast = Duration(milliseconds: 150);

  /// motion-duration-base: 200ms — default, dropdown/dialog.
  static const Duration base = Duration(milliseconds: 200);

  /// motion-duration-slow: 300ms — sheet, page transition.
  static const Duration slow = Duration(milliseconds: 300);

  /// motion-ease-out: `cubic-bezier(0.16, 1, 0.3, 1)` — Toss/Apple 톤 부드러운
  /// 감속곡선 (SoT 표준 easing).
  static const Curve standard = Cubic(0.16, 1, 0.3, 1);

  /// SoT 미정의 — desk-app custom: overshoot spring (FAB/onboarding).
  static const Curve spring = Cubic(0.34, 1.26, 0.5, 1);

  /// SoT 미정의 — desk-app custom: pure decelerate (snackbar/toast 진입).
  static const Curve decel = Cubic(0, 0, 0.2, 1);
}
