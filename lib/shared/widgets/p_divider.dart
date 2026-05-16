import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 표준 1px 가로 구분선 — `borderSubtle` 토큰 사용.
///
/// 22+ 사이트에서 반복되던 `Divider(height: 1, color: t.borderSubtle)` 패턴을
/// 추출. light/dark 모드 분기는 token이 처리.
///
/// 사용:
/// ```dart
/// const PDivider()
/// PDivider(indent: 56)   // 좌측 들여쓰기 (icon 영역 비울 때)
/// ```
class PDivider extends StatelessWidget {
  const PDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 1,
  });

  /// 좌측 들여쓰기. ListTile 같은 icon-leading 행에서 icon 영역 비울 때 사용.
  final double indent;
  final double endIndent;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Divider(
      height: thickness,
      thickness: thickness,
      color: t.borderSubtle,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
