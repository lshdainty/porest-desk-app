import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/network/api_exception.dart';
import '../application/group_providers.dart';
import '../domain/group_member.dart';

/// 그룹 상세 — 멤버 관리, 초대 코드, 권한 변경, 멤버 제거.
///
/// front `GroupFullWidget` + 멤버 패널 미러.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final myUser = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.groupName),
          orElse: () => const Text('그룹'),
        ),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: detailAsync.maybeWhen(
          data: (detail) {
            final me = detail.members.firstWhere(
              (m) => m.userRowId == myUser?.rowId,
              orElse: () => const GroupMember(
                  rowId: 0, userName: '', role: 'MEMBER'),
            );
            if (!me.isOwner) return null;
            return [
              PopupMenuButton<String>(
                icon: Icon(LucideIcons.moreVertical, color: t.fgSecondary),
                onSelected: (v) async {
                  if (v == 'edit') {
                    await _showEditDialog(context, ref, detail);
                  } else if (v == 'delete') {
                    await _confirmDelete(context, ref, detail);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('그룹 수정')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('그룹 삭제',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ];
          },
          orElse: () => null,
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PSpace.x20),
            child: Text('그룹을 불러오지 못했습니다\n$e',
                textAlign: TextAlign.center,
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
        ),
        data: (detail) {
          final me = detail.members.firstWhere(
            (m) => m.userRowId == myUser?.rowId,
            orElse: () => detail.members.isNotEmpty
                ? detail.members.first
                : const GroupMember(rowId: 0, userName: '', role: 'MEMBER'),
          );
          final canManage = me.isOwner || me.isAdmin;
          return RefreshIndicator(
            color: t.bgBrand,
            onRefresh: () async {
              ref.invalidate(groupDetailProvider(groupId));
              await ref.read(groupDetailProvider(groupId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(PSpace.x20),
              children: [
                _GroupHeaderCard(detail: detail, tokens: t),
                const SizedBox(height: PSpace.x16),
                _InviteCodeCard(
                  detail: detail,
                  canManage: canManage,
                  tokens: t,
                ),
                const SizedBox(height: PSpace.x16),
                _MembersCard(
                  detail: detail,
                  myUserRowId: myUser?.rowId,
                  canManage: canManage,
                  tokens: t,
                ),
                const SizedBox(height: PSpace.x32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupHeaderCard extends StatelessWidget {
  const _GroupHeaderCard({required this.detail, required this.tokens});
  final dynamic detail;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.users, color: tokens.fgBrand, size: 22),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.groupName as String,
                    style: PTypo.h3.copyWith(color: tokens.fgPrimary)),
                if ((detail.description as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(detail.description as String,
                      style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.bgMuted,
              borderRadius: PRadius.brPill,
            ),
            child: Text(
                '${(detail.members as List).length}명',
                style: PTypo.caption.copyWith(
                    color: tokens.fgSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends ConsumerWidget {
  const _InviteCodeCard({
    required this.detail,
    required this.canManage,
    required this.tokens,
  });
  final dynamic detail;
  final bool canManage;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = (detail.inviteCode as String?) ?? '-';
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.link, size: 16, color: tokens.fgSecondary),
              const SizedBox(width: 6),
              Text('초대 코드',
                  style: PTypo.bodySm.copyWith(
                      color: tokens.fgPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: tokens.bgMuted,
                    borderRadius: PRadius.brMd,
                  ),
                  child: Text(code,
                      style: PTypo.body.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ])),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '복사',
                onPressed: code == '-'
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('초대 코드를 복사했습니다')),
                        );
                      },
                icon: Icon(LucideIcons.copy,
                    size: 18, color: tokens.fgSecondary),
              ),
              if (canManage)
                IconButton(
                  tooltip: '재발급',
                  onPressed: () => _regenerate(context, ref),
                  icon: Icon(LucideIcons.refreshCw,
                      size: 18, color: tokens.fgSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('초대 코드 재발급'),
        content: const Text('기존 코드는 사용할 수 없게 됩니다. 재발급하시겠어요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('재발급')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final repo = await ref.read(groupRepositoryProvider.future);
      await repo.regenerateInviteCode(detail.rowId as int);
      ref.invalidate(groupDetailProvider(detail.rowId as int));
      ref.invalidate(groupListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대 코드를 재발급했습니다')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('재발급 실패: ${e.message}')),
      );
    }
  }
}

class _MembersCard extends ConsumerWidget {
  const _MembersCard({
    required this.detail,
    required this.myUserRowId,
    required this.canManage,
    required this.tokens,
  });
  final dynamic detail;
  final int? myUserRowId;
  final bool canManage;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = (detail.members as List).cast<GroupMember>();
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x8),
            child: Row(
              children: [
                Icon(LucideIcons.users, size: 16, color: tokens.fgSecondary),
                const SizedBox(width: 6),
                Text('멤버',
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${members.length}명',
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              ],
            ),
          ),
          for (int i = 0; i < members.length; i++) ...[
            if (i > 0) Divider(height: 1, color: tokens.borderSubtle, indent: 60),
            _MemberRow(
              member: members[i],
              isMe: members[i].userRowId == myUserRowId,
              canManage: canManage && members[i].userRowId != myUserRowId,
              groupId: detail.rowId as int,
              tokens: tokens,
            ),
          ],
          const SizedBox(height: PSpace.x8),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.canManage,
    required this.groupId,
    required this.tokens,
  });
  final GroupMember member;
  final bool isMe;
  final bool canManage;
  final int groupId;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tokens.bgMuted,
            child: Text(
              (member.userName.isNotEmpty ? member.userName[0] : '?')
                  .toUpperCase(),
              style: PTypo.bodySm.copyWith(
                  color: tokens.fgSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.userName,
                        style: PTypo.body.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: FontWeight.w600)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.bgBrandSubtle,
                          borderRadius: PRadius.brSm,
                        ),
                        child: Text('나',
                            style: PTypo.micro.copyWith(
                                color: tokens.fgBrand,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                if (member.userEmail?.isNotEmpty == true)
                  Text(member.userEmail!,
                      style:
                          PTypo.caption.copyWith(color: tokens.fgTertiary)),
              ],
            ),
          ),
          _RoleBadge(role: member.role, tokens: tokens),
          if (canManage)
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreVertical,
                  size: 18, color: tokens.fgTertiary),
              onSelected: (v) => _handleAction(context, ref, v),
              itemBuilder: (_) => [
                if (member.role != 'ADMIN')
                  const PopupMenuItem(
                      value: 'ADMIN', child: Text('관리자로 지정')),
                if (member.role != 'MEMBER')
                  const PopupMenuItem(
                      value: 'MEMBER', child: Text('일반 멤버로')),
                const PopupMenuItem(
                    value: 'remove',
                    child: Text('내보내기',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = await ref.read(groupRepositoryProvider.future);
    try {
      if (action == 'remove') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('멤버 내보내기'),
            content: Text('${member.userName} 님을 그룹에서 내보내시겠어요?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: context.tokens.statusDanger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('내보내기'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        await repo.removeMember(groupId, member.rowId);
      } else {
        await repo.changeMemberRole(groupId, member.rowId, action);
      }
      ref.invalidate(groupDetailProvider(groupId));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    }
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.tokens});
  final String role;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'OWNER' => ('소유자', tokens.fgBrand),
      'ADMIN' => ('관리자', tokens.statusInfo),
      _ => ('멤버', tokens.fgTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: PRadius.brSm,
      ),
      child: Text(label,
          style: PTypo.micro.copyWith(
              color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── 그룹 수정/삭제 ──────────────────────────────────────────

Future<void> _showEditDialog(
    BuildContext context, WidgetRef ref, GroupDetail detail) async {
  final nameCtrl = TextEditingController(text: detail.groupName);
  final descCtrl = TextEditingController(text: detail.description ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      return AlertDialog(
        backgroundColor: t.bgSurface,
        title: const Text('그룹 수정'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이름',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: '그룹 이름'),
              ),
              const SizedBox(height: 12),
              Text('설명 (선택)',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const SizedBox(height: 4),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: '설명'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('저장')),
        ],
      );
    },
  );
  if (ok != true) return;
  final name = nameCtrl.text.trim();
  if (name.isEmpty) return;
  try {
    final repo = await ref.read(groupRepositoryProvider.future);
    await repo.update(
      id: detail.rowId,
      groupName: name,
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );
    ref.invalidate(groupDetailProvider(detail.rowId));
    ref.invalidate(groupListProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('그룹이 수정되었습니다')),
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('수정 실패: ${e.message}')),
    );
  }
}

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, GroupDetail detail) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('그룹 삭제'),
      content: Text(
          '"${detail.groupName}" 그룹을 삭제하시겠어요? 멤버 모두가 그룹에서 제외되며 되돌릴 수 없습니다.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: ctx.tokens.statusDanger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    final repo = await ref.read(groupRepositoryProvider.future);
    await repo.delete(detail.rowId);
    ref.invalidate(groupListProvider);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('그룹이 삭제되었습니다')),
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('삭제 실패: ${e.message}')),
    );
  }
}
