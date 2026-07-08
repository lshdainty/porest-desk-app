import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';

/// 모바일 셸 상단 바 — front `.m-header` 미러.
///
/// CSS:
///   .m-header { padding: 8px 20px 12px; gap: 12px; }
///   h1 { font-size: 22px; font-weight: 700; letter-spacing: -0.02em; }
///
/// 우측 액션 — 페이지당 1개 (클로드 디자인 MHeader 정합):
///  - 홈: 알림 벨 (+unread dot) — [trailingIcon]=bell
///  - 그 외: 검색 등 컨텍스트 아이콘 (기본 search)
/// 버튼은 `PButton.icon(size: iconLg)` (36×36 원형, glyph 20px, ghost 중립색 —
/// button.md v97). 테마 전환은 설정>표시 설정, 금액 가리기는 홈·자산 순자산
/// 카드 눈 버튼으로 이동.
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
    final l = AppLocalizations.of(context);
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
                const _NotificationBell()
              else
                PButton.icon(
                  icon: trailingIcon,
                  size: PButtonSize.iconLg,
                  tooltip: l.actionSearch,
                  onPressed: onTrailingTap ?? () => context.push('/search'),
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
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PButton.icon(
          icon: LucideIcons.bell,
          size: PButtonSize.iconLg,
          tooltip: l.navNotifications,
          onPressed: () => context.push('/notifications'),
        ),
        // front NotificationBell 정합 — 숫자 대신 작은 점(dot)으로 표시.
        // (count 배지가 아이콘을 가리던 문제 해소)
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: t.fgExpense,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
