import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 표준 로딩 인디케이터 — `fgBrand` 토큰 사용.
///
/// Material 기본 `CircularProgressIndicator`는 Theme.primary를 색으로 쓰는데
/// 일부 다이얼로그/시트에서 그 값이 의도와 어긋남. 토큰 기반으로 통일.
///
/// 사용:
/// ```dart
/// const PCircularProgressIndicator()         // 기본 size 36
/// PCircularProgressIndicator(size: 16)       // 인라인 작은 사이즈
/// PCircularProgressIndicator(strokeWidth: 2) // 가는 라인
/// ```
class PCircularProgressIndicator extends StatelessWidget {
  const PCircularProgressIndicator({
    super.key,
    this.size,
    this.strokeWidth = 4,
    this.color,
  });

  /// 위젯 크기. null이면 Material 기본 (~36px). 다이얼로그 본문 중앙에선 기본.
  final double? size;
  final double strokeWidth;

  /// brand 색 override (예: 다크 hero 위에서 fgOnBrand 사용).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final indicator = CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color ?? t.fgBrand,
    );
    if (size == null) return indicator;
    return SizedBox(width: size, height: size, child: indicator);
  }
}
