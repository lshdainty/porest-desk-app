import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/settings/settings_notifier.dart';

/// 모바일 셸 상단 바.
///
/// porest-desk-front `MobileHeader.tsx` 매핑:
/// - 좌측: 타이틀 (현재 탭 이름)
/// - 우측: 테마 토글 + 금액 숨김 토글 + 알림(stub, Phase 후속에서 연결)
class MobileHeader extends ConsumerWidget implements PreferredSizeWidget {
  const MobileHeader({required this.title, super.key});
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                _IcoBtn(
                  isDark ? LucideIcons.sun : LucideIcons.moon,
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
                  tokens: t,
                  tooltip: '테마 전환',
                ),
                const SizedBox(width: PSpace.x4),
                _IcoBtn(
                  settings.hideAmounts ? LucideIcons.eyeOff : LucideIcons.eye,
                  onPressed: () =>
                      ref.read(settingsProvider.notifier).toggleHideAmounts(),
                  tokens: t,
                  tooltip: settings.hideAmounts ? '금액 표시' : '금액 숨김',
                ),
                const SizedBox(width: PSpace.x4),
                _IcoBtn(
                  LucideIcons.bell,
                  onPressed: () {}, // Phase 후속: 알림 패널
                  tokens: t,
                  tooltip: '알림',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IcoBtn extends StatelessWidget {
  const _IcoBtn(this.icon,
      {required this.onPressed, required this.tokens, this.tooltip});
  final IconData icon;
  final VoidCallback onPressed;
  final PorestTokens tokens;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        tooltip: tooltip,
        icon: Icon(icon, color: tokens.fgSecondary),
        onPressed: onPressed,
      ),
    );
  }
}
