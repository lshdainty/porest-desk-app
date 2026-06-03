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
import '../../../core/format/chart_palette.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/group_providers.dart';
import '../domain/group.dart';

/// 설정 진입 — 캘린더 관리·공유.
///
/// design `CalendarShareSection` 미러: "가족·친구와 일정 공유" 안내 + 새 캘린더 +
/// 내 캘린더(소유)/공유받은 캘린더 리스트 + 멤버 관리(권한변경/제거/초대코드).
///
/// 백엔드 = "그룹" 도메인. 소유 = 내 role OWNER, 공유받음 = 그 외. 받은-초대
/// 인박스 흐름은 백엔드에 없으므로 "초대코드로 참여" + "초대코드 공유"로 대체한다.
/// 그룹 detail(멤버/권한/초대코드)은 기존 `/groups/:id` 화면을 재사용.
class CalendarShareScreen extends ConsumerWidget {
  const CalendarShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final listAsync = ref.watch(groupListProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('캘린더 관리·공유'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PButton.icon(
            icon: LucideIcons.userPlus,
            tooltip: '초대 코드로 참여',
            onPressed: () => _showJoinDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(groupListProvider);
          await ref.read(groupListProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x20, vertical: PSpace.x24),
          children: [
            _IntroCard(
              tokens: t,
              onCreate: () => _showCreateDialog(context, ref),
            ),
            const SizedBox(height: PSpace.x20),

            listAsync.when(
              loading: () => const PListSkeleton(rows: 4, showAvatar: true),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                child: Text('캘린더 로드 실패\n$e',
                    style: PTypo.bodySm.copyWith(color: t.statusDanger)),
              ),
              data: (groups) => _CalendarSections(groups: groups, tokens: t),
            ),
            const SizedBox(height: PSpace.x16),

            // 초대 코드로 참여 (받은-초대 인박스 대체)
            _JoinCard(
              tokens: t,
              onJoin: () => _showJoinDialog(context, ref),
            ),
            const SizedBox(height: PSpace.x32),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.tokens, required this.onCreate});
  final PorestTokens tokens;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return PCard(
      variant: PCardVariant.brand,
      padding: const EdgeInsets.all(PSpace.x16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.bgBrand,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.users, size: 18, color: t.fgOnBrand),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('가족·친구와 일정 공유',
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    )),
                const SizedBox(height: 2),
                Text('여러 캘린더를 만들고 멤버를 초대해 함께 일정을 관리할 수 있어요.',
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          PButton(
            label: '새 캘린더',
            icon: LucideIcons.plus,
            size: PButtonSize.sm,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

/// 그룹 리스트를 소유/공유받음으로 분리. 각 그룹의 내 role 은 detail 에만 있으므로
/// 행 단위로 detail 을 watch 해 role 을 판정한다 (그룹 수가 적은 일반 케이스에 적합).
class _CalendarSections extends ConsumerWidget {
  const _CalendarSections({required this.groups, required this.tokens});
  final List<Group> groups;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tokens;
    final myId = ref.watch(authProvider).value?.rowId;

    if (groups.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: PSpace.x8),
            child: Text('내 캘린더 · 0',
                style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          ),
          PCard(
            variant: PCardVariant.shadow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x24),
              child: Center(
                child: Text('아직 캘린더가 없어요. "새 캘린더"로 만들어보세요.',
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
              ),
            ),
          ),
        ],
      );
    }

    final owned = <Group>[];
    final shared = <Group>[];
    for (final g in groups) {
      final detail = ref.watch(groupDetailProvider(g.rowId)).value;
      final isOwner = detail == null
          // detail 미도착 시 잠정적으로 소유 섹션에 배치(로드되면 재배치).
          ? true
          : detail.members
              .any((m) => m.userRowId == myId && m.role == 'OWNER');
      (isOwner ? owned : shared).add(g);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: '내 캘린더 · ${owned.length}',
          tokens: t,
          groups: owned,
          emptyText: '소유한 캘린더가 없어요',
        ),
        const SizedBox(height: PSpace.x20),
        _Section(
          title: '공유받은 캘린더 · ${shared.length}',
          tokens: t,
          groups: shared,
          emptyText: '공유받은 캘린더가 없어요',
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.tokens,
    required this.groups,
    required this.emptyText,
  });
  final String title;
  final PorestTokens tokens;
  final List<Group> groups;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: PSpace.x8),
          child: Text(title,
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
        ),
        if (groups.isEmpty)
          PCard(
            variant: PCardVariant.shadow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x20),
              child: Center(
                child: Text(emptyText,
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
              ),
            ),
          )
        else
          PCard(
            variant: PCardVariant.shadow,
            child: Column(
              children: [
                for (int i = 0; i < groups.length; i++) ...[
                  _CalendarRow(group: groups[i], tokens: t),
                  if (i < groups.length - 1) PDivider(indent: 56),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({required this.group, required this.tokens});
  final Group group;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final color = resolveChartColor(
        context, group.color ?? group.groupTypeColor,
        fallback: t.fgBrand);
    return InkWell(
      onTap: () => context.push('/groups/${group.rowId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: softBg(context, color),
                borderRadius: PRadius.brMd,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.calendar, size: 18, color: color),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.body.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.semi)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if ((group.groupTypeName ?? '').isNotEmpty)
                        group.groupTypeName!,
                      group.memberCount <= 1 ? '나만 사용' : '나 + ${group.memberCount - 1}명',
                    ].join(' · '),
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.tokens, required this.onJoin});
  final PorestTokens tokens;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return PCard(
      variant: PCardVariant.shadow,
      padding: const EdgeInsets.all(PSpace.x16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.bgMuted,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.link, size: 18, color: t.fgSecondary),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('초대 코드로 참여',
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    )),
                const SizedBox(height: 2),
                Text('공유받은 초대 코드를 입력해 캘린더에 참여하세요.',
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          PButton(
            label: '참여',
            variant: PButtonVariant.secondary,
            size: PButtonSize.sm,
            onPressed: onJoin,
          ),
        ],
      ),
    );
  }
}

// ─── 새 캘린더 만들기 ────────────────────────────────────────

void _showCreateDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final controller = PSheetController();
  var selectedColor = '#2c70bf'; // 기본 blue (chart blue)

  Future<void> submit() async {
    if (nameCtrl.text.trim().isEmpty) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(groupRepositoryProvider.future);
      await repo.create(
        groupName: nameCtrl.text.trim(),
        description:
            descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        color: selectedColor,
      );
      ref.invalidate(groupListProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '실패: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: '새 캘린더',
    contentBuilder: (ctx, scrollCtrl) {
      final t = ctx.tokens;
      return StatefulBuilder(
        builder: (ctx, setSheet) => ListView(
          controller: scrollCtrl,
          padding:
              const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
          children: [
            Text('이름', style: PTypo.caption.copyWith(color: t.fgSecondary)),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: nameCtrl,
              placeholder: '예: 가족, 업무, 운동 일정',
              onChanged: (v) => controller.setCanSubmit(v.trim().isNotEmpty),
            ),
            const SizedBox(height: PSpace.x12),
            Text('색상', style: PTypo.caption.copyWith(color: t.fgSecondary)),
            const SizedBox(height: PSpace.x8),
            Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final p in kChartPairs)
                  GestureDetector(
                    onTap: () => setSheet(() => selectedColor = p.baseHex),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: p.base,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == p.baseHex
                              ? t.fgPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: PSpace.x12),
            Text('설명 (선택)',
                style: PTypo.caption.copyWith(color: t.fgSecondary)),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: descCtrl,
              maxLines: 3,
              placeholder: '캘린더 설명',
            ),
          ],
        ),
      );
    },
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: '만들기'),
  );
}

// ─── 초대 코드로 참여 ───────────────────────────────────────

void _showJoinDialog(BuildContext context, WidgetRef ref) {
  final codeCtrl = TextEditingController();
  final controller = PSheetController();

  Future<void> submit() async {
    if (codeCtrl.text.trim().isEmpty) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(groupRepositoryProvider.future);
      final joined = await repo.joinByCode(codeCtrl.text.trim().toUpperCase());
      ref.invalidate(groupListProvider);
      ref.invalidate(groupDetailProvider(joined.rowId));
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, '"${joined.groupName}" 캘린더에 참여했어요',
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, '참여 실패: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: '초대 코드로 참여',
    contentBuilder: (ctx, scrollCtrl) {
      final t = ctx.tokens;
      return ListView(
        controller: scrollCtrl,
        padding:
            const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
        children: [
          Text('초대 코드', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: codeCtrl,
            placeholder: '예: ABC123',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            onChanged: (v) => controller.setCanSubmit(v.trim().isNotEmpty),
          ),
        ],
      );
    },
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: '참여'),
  );
}
