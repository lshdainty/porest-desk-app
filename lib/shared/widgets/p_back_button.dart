import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';

/// 공통 뒤로가기 버튼 — AppBar leading 표준.
///
/// chevron-left(`<`) 아이콘 + 타이트한 탭 영역(padding 6 → 36px). web 헤더
/// (설정 섹션 `<` 버튼)와 아이콘·간격을 통일하기 위함.
///
/// AppBar 에서는 `leadingWidth: 40, titleSpacing: 0` 과 함께 써서 아이콘과
/// 타이틀 사이 간격을 좁힌다 (기본 leadingWidth 56 + titleSpacing 16 이면 너무 벌어짐).
class PBackButton extends StatelessWidget {
  const PBackButton({super.key, this.onPressed, this.tooltip});

  /// AppBar leading 표준 폭 — 이 버튼과 함께 AppBar 에 지정.
  static const double leadingWidth = 40;

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final btn = InkWell(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(LucideIcons.chevronLeft, size: 24, color: t.fgPrimary),
      ),
    );
    return Semantics(
      button: true,
      label: tooltip ?? '뒤로',
      child: tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn,
    );
  }
}
