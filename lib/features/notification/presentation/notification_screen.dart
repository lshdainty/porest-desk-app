import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/p_back_button.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../application/notification_providers.dart';
import '../domain/notification.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.notiTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PButton(
            label: l.notiMarkAllRead,
            variant: PButtonVariant.ghost,
            size: PButtonSize.sm,
            onPressed: () async {
              try {
                final repo = await ref.read(
                  notificationRepositoryProvider.future,
                );
                await repo.markAllRead();
                ref.invalidate(notificationListProvider);
                ref.invalidate(unreadCountProvider);
              } on ApiException catch (e) {
                if (!context.mounted) return;
                showPSnackBar(context, '${l.stateError}: ${e.message}');
              }
            },
          ),
          const SizedBox(width: PSpace.x8),
        ],
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(notificationListProvider);
          ref.invalidate(unreadCountProvider);
          await ref.read(notificationListProvider.future);
        },
        child: listAsync.when(
          loading: () => _NotiSkeleton(tokens: t),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text(
              '${l.stateError}\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDanger),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  PEmptyState(icon: LucideIcons.bell, message: l.notiEmpty),
                  _NotiSettingsFooter(tokens: t),
                ],
              );
            }
            final unread = items.where((n) => !n.isRead).length;
            // SoT(NotificationsPopover) 정합 구조:
            //   [헤더 서브 '읽지 않은 알림 N개'] / [행 목록(구분선 없음)] / [footer '알림 설정 ›']
            // 행 사이 divider 미사용(SoT) — 위계는 unread 배경/좌측 엣지바로만.
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
              children: [
                if (unread > 0) _UnreadSubHeader(count: unread, tokens: t),
                for (final n in items)
                  _NotiRow(
                    noti: n,
                    tokens: t,
                    onTap: () async {
                      if (!n.isRead) {
                        try {
                          final repo = await ref.read(
                            notificationRepositoryProvider.future,
                          );
                          await repo.markRead(n.rowId);
                          ref.invalidate(notificationListProvider);
                          ref.invalidate(unreadCountProvider);
                        } catch (_) {}
                      }
                    },
                    onDelete: () async {
                      try {
                        final repo = await ref.read(
                          notificationRepositoryProvider.future,
                        );
                        await repo.delete(n.rowId);
                        ref.invalidate(notificationListProvider);
                        ref.invalidate(unreadCountProvider);
                      } on ApiException catch (e) {
                        if (!context.mounted) return;
                        showPSnackBar(
                          context,
                          '실패: ${e.message}',
                          severity: PSnackSeverity.error,
                        );
                      }
                    },
                  ),
                _NotiSettingsFooter(tokens: t),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// SoT 헤더 서브카운터 '읽지 않은 알림 N개' (caption / fg-tertiary, N만 fg-brand-strong).
/// 웹은 dialog 헤더에 있으나 앱은 AppBar 가 타이틀을 담당하므로 본문 상단에 배치.
class _UnreadSubHeader extends StatelessWidget {
  const _UnreadSubHeader({required this.count, required this.tokens});
  final int count;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x16,
        PSpace.x8,
        PSpace.x16,
        PSpace.x8,
      ),
      child: Text.rich(
        TextSpan(
          style: PTypo.caption.copyWith(color: tokens.fgTertiary),
          children: [
            const TextSpan(text: '읽지 않은 알림 '),
            TextSpan(
              text: '$count',
              style: TextStyle(
                color: tokens.fgBrandStrong,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const TextSpan(text: '개'),
          ],
        ),
      ),
    );
  }
}

/// SoT footer '알림 설정 ›' — ghost full-width, 탭 시 /settings/notifications push.
class _NotiSettingsFooter extends StatelessWidget {
  const _NotiSettingsFooter({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: PSpace.x4),
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x12,
        vertical: PSpace.x8,
      ),
      decoration: BoxDecoration(
        color: tokens.bgSunken,
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: PButton(
        label: '알림 설정',
        trailingIcon: LucideIcons.chevronRight,
        variant: PButtonVariant.ghost,
        size: PButtonSize.sm,
        fullWidth: true,
        onPressed: () => context.push('/settings/notifications'),
      ),
    );
  }
}

/// 알림 목록 skeleton — 아이콘(36x36) + 제목/메시지 + 시간 행 × 5 (SoT 5행, 구분선 없음).
class _NotiSkeleton extends StatelessWidget {
  const _NotiSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: PSpace.x12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PSkeleton(width: 36, height: 36),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PSkeleton.line(width: i.isEven ? 140 : 100),
                  const SizedBox(height: 4),
                  const PSkeleton.line(width: double.infinity, height: 12),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x12),
            const PSkeleton.line(width: 36, height: 11),
          ],
        ),
      ),
    );
  }
}

class _NotiRow extends StatelessWidget {
  const _NotiRow({
    required this.noti,
    required this.tokens,
    required this.onTap,
    required this.onDelete,
  });
  final AppNotification noti;
  final PorestTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// notificationType → lucide 아이콘. SoT(notificationVisual) 매핑 정합:
  /// BUDGET_ALERT→AlertTriangle / TODO_REMINDER→ListChecks /
  /// EVENT_REMINDER→CalendarClock / SYSTEM·default→Bell.
  IconData _typeIcon() => switch (noti.notificationType) {
    'BUDGET_ALERT' => LucideIcons.alertTriangle,
    'TODO_REMINDER' => LucideIcons.squareCheckBig,
    'EVENT_REMINDER' => LucideIcons.calendarClock,
    _ => LucideIcons.bell,
  };

  /// notificationType 별 (배경, 전경) tone 토큰 쌍 — SoT notificationVisual 정합.
  /// BUDGET_ALERT→warning(subtle·fg) / TODO_REMINDER→brand(subtle·strong) /
  /// EVENT_REMINDER→info(subtle·fg) / SYSTEM·default→sunken·secondary.
  (Color, Color) _typeTone(PorestTokens t) => switch (noti.notificationType) {
    'BUDGET_ALERT' => (t.statusWarningSubtle, t.statusWarningFg),
    'TODO_REMINDER' => (t.bgBrandSubtle, t.fgBrandStrong),
    'EVENT_REMINDER' => (t.statusInfoSubtle, t.statusInfoFg),
    _ => (t.bgSunken, t.fgSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final unread = !noti.isRead;
    final (toneBg, toneFg) = _typeTone(tokens);
    return InkWell(
      onTap: onTap,
      child: Container(
        // 클로드 디자인 원본 정합 — 플랫 틴트(그라데이션 아님):
        // 라이트 = bgBrandSubtle, 다크 = primary-light 15%(rgba(95,160,229,.15)).
        // fgBrand 가 다크에서 primary-light(cobalt400) 로 swap 되므로 alpha 만 분기.
        decoration: BoxDecoration(
          color: unread
              ? (Theme.of(context).brightness == Brightness.dark
                    ? tokens.fgBrand.withValues(alpha: 0.15)
                    : tokens.bgBrandSubtle)
              : null,
          border: Border(
            left: BorderSide(
              color: unread ? tokens.borderBrand : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: PSpace.x12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: toneBg,
                borderRadius: PRadius.brMd,
              ),
              alignment: Alignment.center,
              child: Icon(_typeIcon(), size: 16, color: toneFg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 행: [제목 ... unread dot] + 우측 상단 상대시간.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          noti.title,
                          style: PTypo.bodySm.copyWith(
                            color: tokens.fgPrimary,
                            // SoT: read/unread 굵기 분기 없음 — 항상 semi(600).
                            fontWeight: PFontWeight.semi,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // SoT: unread dot 은 제목 '뒤'(우측), bg-brand 색, 6px.
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: tokens.bgBrand,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if ((noti.message ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      noti.message!,
                      style: PTypo.caption.copyWith(color: tokens.fgSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // 날짜는 우측 상단(웹 정합 — 좌측=내용, 우측=날짜+X).
            if ((noti.createAt ?? '').isNotEmpty) ...[
              const SizedBox(width: PSpace.x8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _relativeTime(noti.createAt!),
                  style: PTypo.micro.copyWith(
                    color: tokens.fgTertiary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
            const SizedBox(width: PSpace.x4),
            PButton.icon(
              icon: LucideIcons.x,
              size: PButtonSize.sm,
              iconColor: tokens.fgTertiary,
              tooltip: '삭제',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  /// SoT relativeTime 정합: 방금 / N분 전 / N시간 전 / 어제 / N일 전 / yyyy-MM-dd(≥7일).
  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    final m = diff.inMinutes;
    if (m < 1) return '방금';
    if (m < 60) return '$m분 전';
    final h = diff.inHours;
    if (h < 24) return '$h시간 전';
    final d = diff.inDays;
    if (d == 1) return '어제';
    if (d < 7) return '$d일 전';
    // 1주 이상 — yyyy-MM-dd (SoT createAt.slice(0,10) 정합).
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }
}
