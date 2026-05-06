import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/tokens.dart';
import '../../core/settings/hide_amounts_unlock_dialog.dart';
import '../../core/settings/settings_notifier.dart';

/// 모바일 셸 상단 바 — front `.m-header` 미러.
///
/// CSS:
///   .m-header { padding: 8px 20px 12px; gap: 12px; }
///   h1 { font-size: 22px; font-weight: 700; letter-spacing: -0.02em; }
///   .ico-btn { 36×36 round, fg-primary }
///
/// 우측 액션:
///  - moon/sun (테마 전환)
///  - eye/eyeOff (금액 숨김 토글)
///  - search 또는 bell (페이지마다 다름; 기본은 search)
class MobileHeader extends ConsumerWidget implements PreferredSizeWidget {
  const MobileHeader({
    required this.title,
    this.trailingIcon = LucideIcons.search,
    this.onTrailingTap,
    super.key,
  });

  final String title;
  final IconData trailingIcon;
  final VoidCallback? onTrailingTap;

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: t.fgPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.44, // -0.02em × 22
                    height: 1.25,
                  ),
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
              _IcoBtn(
                settings.hideAmounts ? LucideIcons.eyeOff : LucideIcons.eye,
                onPressed: () => toggleHideAmountsWithUnlock(context, ref),
                tokens: t,
                tooltip: settings.hideAmounts ? '금액 표시' : '금액 숨김',
              ),
              _IcoBtn(
                trailingIcon,
                onPressed: onTrailingTap ?? () => context.push('/search'),
                tokens: t,
                tooltip: trailingIcon == LucideIcons.bell ? '알림' : '검색',
              ),
            ],
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
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: tokens.fgPrimary),
        ),
      ),
    );
  }
}
