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
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
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
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('그룹 수정')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('그룹 삭제',
                        style: TextStyle(color: t.statusDangerFg)),
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
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _GroupHeaderCard(detail: detail, tokens: t),
                ),
                TabBar(
                  labelColor: t.fgPrimary,
                  unselectedLabelColor: t.fgTertiary,
                  indicatorColor: t.fgBrand,
                  tabs: const [
                    Tab(text: '멤버 · 초대'),
                    Tab(text: '일정'),
                    Tab(text: '지출'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: 기존 멤버 + 초대코드 패널
                      RefreshIndicator(
                        color: t.bgBrand,
                        onRefresh: () async {
                          ref.invalidate(groupDetailProvider(groupId));
                          await ref.read(groupDetailProvider(groupId).future);
                        },
                        child: ListView(
                          padding: const EdgeInsets.all(PSpace.x20),
                          children: [
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
                          ],
                        ),
                      ),
                      // Tab 2: 일정
                      _GroupEventsTab(groupId: groupId, tokens: t),
                      // Tab 3: 지출
                      _GroupExpensesTab(groupId: groupId, tokens: t),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupEventsTab extends ConsumerWidget {
  const _GroupEventsTab({required this.groupId, required this.tokens});
  final int groupId;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month + 2, 0);
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00';
    final async = ref.watch(groupEventsProvider((
      groupId: groupId,
      startDate: fmt(start),
      endDate: fmt(end),
    )));
    return RefreshIndicator(
      color: tokens.bgBrand,
      onRefresh: () async {
        ref.invalidate(groupEventsProvider);
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(PSpace.x20),
          child: Text('일정 로드 실패\n$e',
              style: PTypo.bodySm.copyWith(color: tokens.statusDanger)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(PSpace.x32),
                child: Center(
                  child: Text('등록된 일정이 없습니다',
                      style:
                          PTypo.body.copyWith(color: tokens.fgTertiary)),
                ),
              ),
            ]);
          }
          final sorted = [...list]
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          return ListView.separated(
            padding: const EdgeInsets.all(PSpace.x16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: PSpace.x8),
            itemBuilder: (_, i) {
              final e = sorted[i];
              final color = parseColor(e.color, fallback: tokens.fgBrand);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: PRadius.brMd,
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: PRadius.brXs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PTypo.bodySm.copyWith(
                                  color: tokens.fgPrimary,
                                  fontWeight: PFontWeight.bold)),
                          if (e.startDate.isNotEmpty)
                            Text(
                              e.startDate.substring(0, 16).replaceAll('T', ' '),
                              style: PTypo.caption
                                  .copyWith(color: tokens.fgTertiary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupExpensesTab extends ConsumerWidget {
  const _GroupExpensesTab({required this.groupId, required this.tokens});
  final int groupId;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final async = ref.watch(expensesByGroupProvider(
        (groupId: groupId, startDate: null, endDate: null)));
    return RefreshIndicator(
      color: tokens.bgBrand,
      onRefresh: () async {
        ref.invalidate(expensesByGroupProvider);
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(PSpace.x20),
          child: Text('지출 로드 실패\n$e',
              style: PTypo.bodySm.copyWith(color: tokens.statusDanger)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(PSpace.x32),
                child: Center(
                  child: Text('등록된 지출이 없습니다',
                      style:
                          PTypo.body.copyWith(color: tokens.fgTertiary)),
                ),
              ),
            ]);
          }
          final sorted = [...list]
            ..sort((a, b) =>
                (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
          final totalExp = sorted
              .where((e) => e.expenseType == 'EXPENSE')
              .fold<int>(0, (s, e) => s + e.amount);
          final totalInc = sorted
              .where((e) => e.expenseType == 'INCOME')
              .fold<int>(0, (s, e) => s + e.amount);
          return ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: PRadius.brMd,
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Row(
                  children: [
                    _SummaryCell(
                        label: '지출',
                        value: krwMasked(totalExp, settings.hideAmounts),
                        color: tokens.statusDanger,
                        tokens: tokens),
                    const SizedBox(width: 12),
                    _SummaryCell(
                        label: '수입',
                        value: krwMasked(totalInc, settings.hideAmounts),
                        color: tokens.statusSuccess,
                        tokens: tokens),
                    const SizedBox(width: 12),
                    _SummaryCell(
                        label: '건수',
                        value: '${sorted.length}',
                        color: tokens.fgPrimary,
                        tokens: tokens),
                  ],
                ),
              ),
              const SizedBox(height: PSpace.x12),
              for (final e in sorted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: tokens.bgSurface,
                      borderRadius: PRadius.brSm,
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  e.merchant ??
                                      e.description ??
                                      e.categoryName ??
                                      '거래',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PTypo.bodySm.copyWith(
                                      color: tokens.fgPrimary,
                                      fontWeight: PFontWeight.semi)),
                              if ((e.expenseDateOnly ?? '').isNotEmpty)
                                Text(e.expenseDateOnly!,
                                    style: PTypo.caption.copyWith(
                                        color: tokens.fgTertiary)),
                            ],
                          ),
                        ),
                        Text(
                          krwMasked(e.signedAmount, settings.hideAmounts,
                              sign: true),
                          style: PTypo.bodySm.copyWith(
                              color: e.expenseType == 'EXPENSE'
                                  ? tokens.fgPrimary
                                  : tokens.statusSuccess,
                              fontWeight: PFontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
    required this.tokens,
  });
  final String label;
  final String value;
  final Color color;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  PTypo.micro.copyWith(color: tokens.fgTertiary)),
          const SizedBox(height: 2),
          Text(value,
              style: PTypo.bodySm.copyWith(
                  color: color, fontWeight: PFontWeight.bold)),
        ],
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
              borderRadius: PRadius.brFull,
            ),
            child: Text(
                '${(detail.members as List).length}명',
                style: PTypo.caption.copyWith(
                    color: tokens.fgSecondary, fontWeight: PFontWeight.semi)),
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
                      color: tokens.fgPrimary, fontWeight: PFontWeight.bold)),
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
                          fontWeight: PFontWeight.bold,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ])),
                ),
              ),
              const SizedBox(width: 8),
              PButton.icon(
                icon: LucideIcons.copy,
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
              ),
              if (canManage)
                PButton.icon(
                  icon: LucideIcons.refreshCw,
                  tooltip: '재발급',
                  onPressed: () => _regenerate(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await showPConfirmDialog(
      context,
      title: '초대 코드 재발급',
      message: '기존 코드는 사용할 수 없게 됩니다. 재발급하시겠어요?',
      confirmLabel: '재발급',
    );
    if (!ok || !context.mounted) return;
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
                        fontWeight: PFontWeight.bold)),
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
                  color: tokens.fgSecondary, fontWeight: PFontWeight.bold),
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
                            fontWeight: PFontWeight.semi)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const PBadge(
                          label: '나', variant: PBadgeVariant.softBrand),
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
                PopupMenuItem(
                    value: 'remove',
                    child: Text('내보내기',
                        style: TextStyle(color: tokens.statusDangerFg))),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    try {
      if (action == 'remove') {
        final ok = await showPConfirmDialog(
          context,
          title: '멤버 내보내기',
          message: '${member.userName} 님을 그룹에서 내보내시겠어요?',
          confirmLabel: '내보내기',
          destructive: true,
        );
        if (!ok) return;
        final repo = await ref.read(groupRepositoryProvider.future);
        await repo.removeMember(groupId, member.rowId);
      } else {
        final repo = await ref.read(groupRepositoryProvider.future);
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
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: PBadge.softColor(label: label, color: color),
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
      return PFormAlertDialog(
        title: '그룹 수정',
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이름',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const SizedBox(height: 4),
              PTextInput(
                controller: nameCtrl,
                placeholder: '그룹 이름',
              ),
              const SizedBox(height: 12),
              Text('설명 (선택)',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const SizedBox(height: 4),
              PTextInput(
                controller: descCtrl,
                maxLines: 2,
                placeholder: '설명',
              ),
            ],
          ),
        ),
        actions: [
          PButton(
            label: '취소',
            variant: PButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          PButton(
            label: '저장',
            onPressed: () => Navigator.pop(ctx, true),
          ),
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
  final ok = await showPConfirmDialog(
    context,
    title: '그룹 삭제',
    message:
        '"${detail.groupName}" 그룹을 삭제하시겠어요? 멤버 모두가 그룹에서 제외되며 되돌릴 수 없습니다.',
    confirmLabel: '삭제',
    destructive: true,
  );
  if (!ok) return;
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
