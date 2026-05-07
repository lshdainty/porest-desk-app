import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/network/api_exception.dart';
import '../application/group_providers.dart';
import '../domain/group.dart';
import 'group_type_management_dialog.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final listAsync = ref.watch(groupListProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('그룹'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.tag),
            tooltip: '그룹 타입 관리',
            onPressed: () => showGroupTypeManagementDialog(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: '초대 코드로 참여',
            onPressed: () => _showJoinDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(groupListProvider);
          await ref.read(groupListProvider.future);
        },
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('그룹 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(PSpace.x32),
                  child: Column(children: [
                    Icon(LucideIcons.users, size: 48, color: t.fgDisabled),
                    const SizedBox(height: PSpace.x12),
                    Text('등록된 그룹이 없습니다',
                        style: PTypo.body.copyWith(color: t.fgTertiary)),
                  ]),
                ),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x80),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    borderRadius: PRadius.brLg,
                    border: Border.all(color: t.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < groups.length; i++) ...[
                        _GroupRow(group: groups[i], tokens: t),
                        if (i < groups.length - 1)
                          Divider(
                              height: 1,
                              color: t.borderSubtle,
                              indent: 56),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _showCreateDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) {
      bool submitting = false;
      return [
        WoltModalSheetPage(
          topBarTitle: const Text('그룹 만들기'),
          isTopBarLayerAlwaysVisible: true,
          backgroundColor:
              Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
          trailingNavBarWidget: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: Navigator.of(modalCtx).pop,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              final t = ctx.tokens;
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                    PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('그룹명',
                        style: PTypo.caption
                            .copyWith(color: t.fgSecondary)),
                    const SizedBox(height: PSpace.x4),
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(hintText: '예: 가족, 회사 동료'),
                    ),
                    const SizedBox(height: PSpace.x12),
                    Text('설명 (선택)',
                        style: PTypo.caption
                            .copyWith(color: t.fgSecondary)),
                    const SizedBox(height: PSpace.x4),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: '그룹 설명'),
                    ),
                    const SizedBox(height: PSpace.x24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                setState(() => submitting = true);
                                try {
                                  final repo = await ref.read(
                                      groupRepositoryProvider.future);
                                  await repo.create(
                                    groupName: nameCtrl.text.trim(),
                                    description:
                                        descCtrl.text.trim().isEmpty
                                            ? null
                                            : descCtrl.text.trim(),
                                  );
                                  ref.invalidate(groupListProvider);
                                  if (!ctx.mounted) return;
                                  Navigator.of(ctx).pop();
                                } on ApiException catch (e) {
                                  if (!ctx.mounted) return;
                                  setState(() => submitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content: Text('실패: ${e.message}')),
                                  );
                                }
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Text('만들기'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ];
    },
  );
}

void _showJoinDialog(BuildContext context, WidgetRef ref) {
  final codeCtrl = TextEditingController();
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) {
      bool submitting = false;
      return [
        WoltModalSheetPage(
          topBarTitle: const Text('초대 코드로 참여'),
          isTopBarLayerAlwaysVisible: true,
          backgroundColor:
              Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
          trailingNavBarWidget: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: Navigator.of(modalCtx).pop,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              final t = ctx.tokens;
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                    PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('초대 코드',
                        style: PTypo.caption
                            .copyWith(color: t.fgSecondary)),
                    const SizedBox(height: PSpace.x4),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                          hintText: '예: ABC123'),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'))
                      ],
                    ),
                    const SizedBox(height: PSpace.x24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (codeCtrl.text.trim().isEmpty) return;
                                setState(() => submitting = true);
                                try {
                                  final repo = await ref.read(
                                      groupRepositoryProvider.future);
                                  await repo.joinByCode(
                                      codeCtrl.text.trim().toUpperCase());
                                  ref.invalidate(groupListProvider);
                                  if (!ctx.mounted) return;
                                  Navigator.of(ctx).pop();
                                } on ApiException catch (e) {
                                  if (!ctx.mounted) return;
                                  setState(() => submitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content: Text('참여 실패: ${e.message}')),
                                  );
                                }
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Text('참여'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ];
    },
  );
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.tokens});
  final Group group;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final color =
        parseColor(group.groupTypeColor, fallback: tokens.fgBrand);
    final bg = softBg(color);
    return InkWell(
      onTap: () => context.push('/groups/${group.rowId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.brMd),
              alignment: Alignment.center,
              child: Icon(LucideIcons.users, size: 20, color: color),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.groupName,
                      style: PTypo.body.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.semi)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if ((group.groupTypeName ?? '').isNotEmpty)
                        group.groupTypeName!,
                      '${group.memberCount}명',
                    ].join(' · '),
                    style: PTypo.caption
                        .copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: tokens.fgTertiary),
          ],
        ),
      ),
    );
  }
}
