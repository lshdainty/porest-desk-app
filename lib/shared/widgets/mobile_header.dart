import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 모바일 셸 상단 바.
///
/// porest-desk-front `MobileHeader.tsx` 매핑:
/// - 좌측: 타이틀 (현재 탭 이름)
/// - 우측: 테마 토글 + 금액 숨김 토글 + 알림 (Phase 7 에서 동작 연결)
class MobileHeader extends StatelessWidget implements PreferredSizeWidget {
  const MobileHeader({required this.title, super.key});
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.bgSurface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpace.x16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: PTypo.h4.copyWith(color: t.fgPrimary),
                  ),
                ),
                _IcoBtn(LucideIcons.sunMoon, onPressed: () {}, tokens: t),
                const SizedBox(width: PSpace.x4),
                _IcoBtn(LucideIcons.eyeOff, onPressed: () {}, tokens: t),
                const SizedBox(width: PSpace.x4),
                _IcoBtn(LucideIcons.bell, onPressed: () {}, tokens: t),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IcoBtn extends StatelessWidget {
  const _IcoBtn(this.icon, {required this.onPressed, required this.tokens});
  final IconData icon;
  final VoidCallback onPressed;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icon, color: tokens.fgSecondary),
        onPressed: onPressed,
      ),
    );
  }
}
