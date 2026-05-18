import 'package:flutter/material.dart';

import '../../app/theme/elevation.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// specs/components/tooltip.md 미러.
///
/// True inverted tooltip — light 모드는 dark 배경(#1A1F2E) + 흰 텍스트, dark
/// 모드는 light 배경(#F5F6FA) + 검정 텍스트. bg=`fgPrimary` + fg=`bgSurface`
/// 조합은 두 토큰 모두 자동 swap이라 양방향 inverse가 자연 성립.
///
/// 모바일 터치 — long-press 1.5s 후 자동 close (Flutter 기본). 핵심 정보는
/// visible label로 — tooltip 신뢰성 낮음 (spec Don't 참조).
class PTooltip extends StatelessWidget {
  const PTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow,
    this.waitDuration = const Duration(milliseconds: 200),
  });

  final String message;
  final Widget child;

  /// `null`이면 Flutter 기본 배치 로직 (위 우선, 공간 부족 시 아래).
  final bool? preferBelow;

  final Duration waitDuration;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      waitDuration: waitDuration,
      verticalOffset: 12,
      decoration: BoxDecoration(
        color: t.fgPrimary, // inverse — light는 dark bg, dark는 light bg
        borderRadius: PRadius.brXs,
        boxShadow: PorestElevation.sm,
      ),
      textStyle: TextStyle(
        fontFamily: PTypo.sans,
        fontSize: PFontSize.bodySm, // label-sm 13/500
        fontWeight: PFontWeight.medium,
        color: t.bgSurface, // inverse — bg와 자동 swap 페어
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: child,
    );
  }
}
