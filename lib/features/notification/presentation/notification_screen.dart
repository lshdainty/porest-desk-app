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
import '../../../shared/widgets/p_empty_state.dart';
import '../application/notification_providers.dart';
import '../domain/notification.dart';

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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l.notiTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final repo =
                    await ref.read(notificationRepositoryProvider.future);
                await repo.markAllRead();
                ref.invalidate(notificationListProvider);
                ref.invalidate(unreadCountProvider);
              } on ApiException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l.stateError}: ${e.message}')),
                );
              }
            },
            child: Text(l.notiMarkAllRead),
          ),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('${l.stateError}\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: [
                PEmptyState(
                  icon: LucideIcons.bell,
                  message: l.notiEmpty,
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: t.borderSubtle, indent: 56),
              itemBuilder: (_, i) => _NotiRow(
                noti: items[i],
                tokens: t,
                onTap: () async {
                  if (!items[i].isRead) {
                    try {
                      final repo = await ref
                          .read(notificationRepositoryProvider.future);
                      await repo.markRead(items[i].rowId);
                      ref.invalidate(notificationListProvider);
                      ref.invalidate(unreadCountProvider);
                    } catch (_) {}
                  }
                },
                onDelete: () async {
                  try {
                    final repo = await ref
                        .read(notificationRepositoryProvider.future);
                    await repo.delete(items[i].rowId);
                    ref.invalidate(notificationListProvider);
                    ref.invalidate(unreadCountProvider);
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('실패: ${e.message}')),
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

  @override
  Widget build(BuildContext context) {
    final unread = !noti.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? tokens.bgBrandSubtle.withValues(alpha: 0.4) : null,
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: tokens.bgMuted, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(_typeIcon(), size: 18, color: tokens.fgSecondary),
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
                              color: tokens.fgBrand, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(noti.title,
                            style: PTypo.bodySm.copyWith(
                                color: tokens.fgPrimary,
                                fontWeight: unread
                                    ? PFontWeight.bold
                                    : PFontWeight.semi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if ((noti.message ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(noti.message!,
                        style: PTypo.caption
                            .copyWith(color: tokens.fgSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if ((noti.createAt ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_relativeTime(noti.createAt!),
                        style: PTypo.caption
                            .copyWith(color: tokens.fgTertiary, fontSize: PFontSize.micro)),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(LucideIcons.x,
                  size: 14, color: tokens.fgTertiary),
              tooltip: '삭제',
              visualDensity: VisualDensity.compact,
              constraints:
                  const BoxConstraints.tightFor(width: 28, height: 28),
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
