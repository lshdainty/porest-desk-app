import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/now_tick.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';
import 'package:porest_desk_app/features/notification/domain/notification.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(notificationListProvider);
    // 상대시각의 기준점 — 화면을 열어 둔 채로도 흐르게 한다(웹 `useNow` 정합).
    // 여기서 한 번 watch 해 행마다 내리는 건 모든 행이 **같은 '지금'** 을 쓰게 하려는 것이다.
    final now = ref.watch(nowTickProvider);

    return Scaffold(
      backgroundColor: t.bgSurface,
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
              } on ApiException {
                if (!context.mounted) return;
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
                    now: now,
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
                      } on ApiException {
                        if (!context.mounted) return;
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
    final l = AppLocalizations.of(context);
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
            TextSpan(text: l.notiUnreadPrefix),
            TextSpan(
              text: '$count',
              style: TextStyle(
                color: tokens.fgBrandStrong,
                fontWeight: PFontWeight.bold,
              ),
            ),
            TextSpan(text: l.notiUnreadSuffix),
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
    final l = AppLocalizations.of(context);
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
        label: l.notiSettings,
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
            // 아이콘 박스 — 실제 _NotiRow tone 박스(36x36, brMd) 정합.
            const PSkeleton(width: 36, height: 36, borderRadius: PRadius.brMd),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목(bodySm) 자리.
                  PSkeleton.line(width: i.isEven ? 140 : 100, height: 14),
                  const SizedBox(height: 3),
                  // 메시지(caption) 자리.
                  const PSkeleton.line(width: double.infinity, height: 12),
                ],
              ),
            ),
            // 상대시간(micro) 자리 — 우측 상단.
            const SizedBox(width: PSpace.x8),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: PSkeleton.line(width: 36, height: 11),
            ),
            // 삭제 버튼(PButton.icon sm = 32x32) 자리.
            const SizedBox(width: PSpace.x4),
            const PSkeleton(width: 32, height: 32, borderRadius: PRadius.brSm),
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
    required this.now,
    required this.onTap,
    required this.onDelete,
  });
  final AppNotification noti;
  final PorestTokens tokens;

  /// 상대시각의 기준점 — 호출부에서 `nowTickProvider` 로 받아 내린다.
  ///
  /// 기본값을 두지 않는다. 기본값이 있으면 안 넘긴 호출부가 조용히 [DateTime.now] 로
  /// 돌아가 그 자리만 다시 얼어붙는데, 화면은 멀쩡해 보여 눈으로는 못 잡는다.
  /// 필수로 두면 새 호출부가 생겨도 컴파일이 먼저 붙잡는다.
  final DateTime now;
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
  /// EVENT_REMINDER→info(subtle·fg) / SYSTEM·default→muted·secondary.
  /// 웹 notificationVisual 은 default 를 `--bg-sunken`(=surface-input=muted) 로 매핑.
  /// 앱은 bgSunken 이 다크에서 bgCanvas(slate950)와 동일 → 종 박스가 안 보임. bgMuted 사용.
  (Color, Color) _typeTone(PorestTokens t) => switch (noti.notificationType) {
    'BUDGET_ALERT' => (t.statusWarningSubtle, t.statusWarningFg),
    'TODO_REMINDER' => (t.bgBrandSubtle, t.fgBrandStrong),
    'EVENT_REMINDER' => (t.statusInfoSubtle, t.statusInfoFg),
    _ => (t.bgMuted, t.fgSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  _relativeTime(l, noti.createAt!, now),
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
              tooltip: l.actionDelete,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  /// SoT relativeTime 정합: 방금 / N분 전 / N시간 전 / 어제 / N일 전 / yyyy-MM-dd(≥7일).
  ///
  /// [iso] 는 `createAt` — 백엔드가 시간대 없이 직렬화한 UTC 다. [DateTime.tryParse] 로
  /// 읽으면 로컬로 오해해 KST(+9)에서 방금 온 알림이 "9시간 전" 으로 보였다.
  /// [parseServerUtc] 를 태우면 ≥7일 분기의 yyyy-MM-dd 도 함께 로컬 날짜가 된다.
  ///
  /// [now] 는 기준 시각이며 **인자로 받는다**. 여기서 [DateTime.now] 를 부르면 그 값은
  /// 화면을 다시 그릴 때만 바뀌는데, 이 화면을 다시 그리게 하는 건 새 알림뿐이라
  /// 열어 둔 채로는 "방금" 에 멈춘다. 넘길 값은 `nowTickProvider` 가 주는 흐르는 '지금'.
  String _relativeTime(AppLocalizations l, String iso, DateTime now) {
    final dt = parseServerUtc(iso);
    if (dt == null) return '';
    final diff = now.difference(dt);
    final m = diff.inMinutes;
    if (m < 1) return l.dateJustNow;
    if (m < 60) return l.dateMinutesAgo(m);
    final h = diff.inHours;
    if (h < 24) return l.dateHoursAgo(h);
    final d = diff.inDays;
    if (d == 1) return l.dateYesterday;
    if (d < 7) return l.dateDaysAgo(d);
    // 1주 이상 — yyyy-MM-dd (SoT createAt.slice(0,10) 정합).
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }
}
