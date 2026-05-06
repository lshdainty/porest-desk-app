import 'package:flutter/animation.dart';

/// porest-desk-front `--dur-*` / `--ease-*` 토큰 매핑.
abstract final class PMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  // cubic-bezier(0.2, 0, 0, 1)
  static const Curve standard = Cubic(0.2, 0, 0, 1);
  // cubic-bezier(0.34, 1.26, 0.5, 1) — overshoot spring
  static const Curve spring = Cubic(0.34, 1.26, 0.5, 1);
  // cubic-bezier(0, 0, 0.2, 1) — decel
  static const Curve decel = Cubic(0, 0, 0.2, 1);
}
