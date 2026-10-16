import 'package:flutter/animation.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 옛 이름의 모션 — 값은 v104 시간 눈금(`PDuration` d1~d6)과 곡선(`PEasing`)의 별칭이다(01A-060 · 061). 새 코드는 `PDuration` ·
/// `PEasing` 을 쓴다. 이관이 끝나면 걷는다.
abstract final class PMotion {
  /// SoT 미정의 — desk-app custom (ripple 즉발용).
  static const Duration instant = PDuration.d2;

  /// motion-duration-fast: 150ms — small UI transitions, hover/focus.
  static const Duration fast = PDuration.d3;

  /// motion-duration-base: 200ms — default, dropdown/dialog.
  static const Duration base = PDuration.d4;

  /// motion-duration-slow: 300ms — sheet, page transition.
  static const Duration slow = PDuration.d6;

  /// motion-ease-out: `cubic-bezier(0.16, 1, 0.3, 1)` — Toss/Apple 톤 부드러운
  /// 감속곡선 (SoT 표준 easing).
  static const Curve standard = PEasing.easing;

  /// SoT 미정의 — desk-app custom: overshoot spring (FAB/onboarding).
  static const Curve spring = Cubic(0.34, 1.26, 0.5, 1);

  /// SoT 미정의 — desk-app custom: pure decelerate (snackbar/toast 진입).
  static const Curve decel = PEasing.enter;
}
