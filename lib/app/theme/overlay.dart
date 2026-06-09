import 'package:flutter/painting.dart';

/// porest-design `--overlay-dim-*` SoT 정합 — DESIGN.desk.md / porest-tokens.css L151-152.
///
/// 모달/sheet/dialog barrier 색. Flutter 기본 `Colors.black54` (alpha ≈0.54) 대신
/// 이 토큰을 `showDialog`/`showModalBottomSheet` 의 `barrierColor` 에 명시 사용.
/// 라이트/다크 모드 분기는 호출처가 `Theme.of(context).brightness` 로 결정.
abstract final class POverlay {
  /// overlay-dim-light: `rgba(0, 0, 0, 0.50)` — alpha 0x80.
  static const Color dimLight = Color(0x80000000);

  /// overlay-dim-dark: `rgba(0, 0, 0, 0.65)` — alpha 0xA6.
  static const Color dimDark = Color(0xA6000000);
}
