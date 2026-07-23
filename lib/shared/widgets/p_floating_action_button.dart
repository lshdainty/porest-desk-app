import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';

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
    // 웹 Fab 미러 — 52px 완전 원형, brand 채움(다크에서도 primary 고정),
    // shadow-lg 상당 elevation, 아이콘 22 (M3 기본 FAB 56/라운드사각 대체).
    Widget fab = Material(
      color: t.bgBrandSolid,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, size: 22, color: t.fgOnBrand),
        ),
      ),
    );
    if (tooltip != null) fab = Tooltip(message: tooltip!, child: fab);
    if (heroTag != null) fab = Hero(tag: heroTag!, child: fab);
    return fab;
  }
}
