import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_tooltip.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';

/// 모바일 셸 상단 바 — front `.m-header` 미러.
///
/// CSS:
///   .m-header { padding: 8px 20px 12px; gap: 12px; }
///   h1 { font-size: 22px; font-weight: 700; letter-spacing: -0.02em; }
///   .ico-btn { 36×36 round, fg-primary }
///
/// 우측 액션 — 페이지당 1개 (클로드 디자인 MHeader 정합):
///  - 홈: 알림 벨 (+unread dot) — [trailingIcon]=bell
///  - 그 외: 검색 등 컨텍스트 아이콘 (기본 search)
/// 테마 전환은 설정>표시 설정, 금액 가리기는 홈·자산 순자산 카드 눈 버튼으로 이동.
class MobileHeader extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    final t = context.tokens;
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
              if (trailingIcon == LucideIcons.bell)
                _NotificationBell(tokens: t)
              else
                _IcoBtn(
                  trailingIcon,
                  onPressed: onTrailingTap ?? () => context.push('/search'),
                  tokens: t,
                  tooltip: '검색',
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
    return PTooltip(
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
              // front NotificationBell 정합 — 숫자 대신 작은 점(dot)으로 표시.
              // (count 배지가 아이콘을 가리던 문제 해소)
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tokens.fgExpense,
                      shape: BoxShape.circle,
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
    return PTooltip(
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
