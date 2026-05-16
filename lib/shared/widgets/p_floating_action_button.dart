import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 단일 primary FAB — brand 색 채움 + onBrand 아이콘.
///
/// porest-design에는 FAB 전용 spec이 없어, desk-app의 9개 FAB 사용처에서
/// 동일하게 사용하던 `FloatingActionButton(bgBrand/fgOnBrand)` 패턴을
/// 그대로 추상화. 추후 spec 추가 시 시각 분기는 이 위젯 내부에서.
class PFloatingActionButton extends StatelessWidget {
  const PFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.heroTag,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: t.bgBrand,
      foregroundColor: t.fgOnBrand,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
