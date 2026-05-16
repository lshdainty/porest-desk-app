import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/settings/hide_amounts_unlock_dialog.dart';
import '../../core/settings/settings_notifier.dart';
import '../../features/notification/application/notification_providers.dart';

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
                    fontSize: PFontSize.h2,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: -0.44, // -0.02em × 22
                    height: PLineHeight.snug,
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
              _NotificationBell(tokens: t),
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

/// 헤더 종 아이콘 + unread 배지 — front `NotificationBell` 미러.
/// 탭 시 /notifications 라우트로 이동.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Tooltip(
      message: '알림',
      child: InkWell(
        onTap: () => context.push('/notifications'),
        borderRadius: PRadius.brFull,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(LucideIcons.bell, size: 20, color: tokens.fgPrimary),
              if (unread > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: tokens.statusDanger,
                      borderRadius: PRadius.brFull,
                      border: Border.all(color: tokens.bgSurface, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: tokens.fgOnDanger,
                          fontSize: PFontSize.micro,
                          fontWeight: PFontWeight.bold,
                          height: PLineHeight.tight,
                        ),
                      ),
                    ),
                  ),
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
        borderRadius: PRadius.brFull,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: tokens.fgPrimary),
        ),
      ),
    );
  }
}
