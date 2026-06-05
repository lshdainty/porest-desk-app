import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_divider.dart';
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
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
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
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
              itemCount: items.length,
              separatorBuilder: (_, _) => PDivider(indent: 56),
              itemBuilder: (_, i) => _NotiRow(
                noti: items[i],
                tokens: t,
                onTap: () async {
                  if (!items[i].isRead) {
                    try {
                      final repo = await ref.read(
                        notificationRepositoryProvider.future,
                      );
                      await repo.markRead(items[i].rowId);
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
                    await repo.delete(items[i].rowId);
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
            );
          },
        ),
      ),
    );
  }
}

/// 알림 목록 skeleton — 아이콘(36x36) + 제목+메시지+시간 행 × 6 + PDivider(indent:56).
class _NotiSkeleton extends StatelessWidget {
  const _NotiSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      separatorBuilder: (_, _) => PDivider(indent: 56),
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
                  const SizedBox(height: 3),
                  PSkeleton.line(width: 56, height: 11),
                ],
              ),
            ),
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

  IconData _typeIcon() => switch (noti.notificationType) {
    'EXPENSE' => LucideIcons.receipt,
    'BUDGET' => LucideIcons.target,
    'CALENDAR' => LucideIcons.calendar,
    'TODO' => LucideIcons.checkSquare,
    'GROUP' => LucideIcons.users,
    _ => LucideIcons.bell,
  };

  /// notificationType 별 (배경, 전경) tone 토큰 쌍.
  (Color, Color) _typeTone(PorestTokens t) => switch (noti.notificationType) {
    'BUDGET' => (t.statusWarningSubtle, t.statusWarningFg),
    'EXPENSE' => (t.bgBrandSubtle, t.fgBrandStrong),
    'CALENDAR' => (t.statusInfoSubtle, t.statusInfoFg),
    'TODO' => (t.statusSuccessSubtle, t.statusSuccessFg),
    'GROUP' => (t.statusInfoSubtle, t.statusInfoFg),
    _ => (t.bgMuted, t.fgSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final unread = !noti.isRead;
    final (toneBg, toneFg) = _typeTone(tokens);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? tokens.bgBrandSubtle.withValues(alpha: 0.4) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: PSpace.x12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: toneBg,
                borderRadius: PRadius.brMd,
              ),
              alignment: Alignment.center,
              child: Icon(_typeIcon(), size: 18, color: toneFg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (unread) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: tokens.fgBrand,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          noti.title,
                          style: PTypo.bodySm.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: unread
                                ? PFontWeight.bold
                                : PFontWeight.semi,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if ((noti.message ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      noti.message!,
                      style: PTypo.caption.copyWith(color: tokens.fgSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((noti.createAt ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(noti.createAt!),
                      style: PTypo.caption.copyWith(
                        color: tokens.fgTertiary,
                        fontSize: PFontSize.micro,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}
