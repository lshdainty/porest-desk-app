import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_back_button.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/saving_goal_providers.dart';
import '../domain/saving_goal.dart';
import 'saving_goal_edit_dialog.dart';

class SavingGoalScreen extends ConsumerWidget {
  const SavingGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final listAsync = ref.watch(savingGoalListProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('저금 목표'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        onPressed: () => showSavingGoalEditDialog(context),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(savingGoalListProvider);
          await ref.read(savingGoalListProvider.future);
        },
        child: listAsync.when(
          loading: () => const _SavingGoalSkeleton(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('저금 목표 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: const [
                PEmptyState(
                  icon: LucideIcons.piggyBank,
                  message: '등록된 저금 목표가 없습니다',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: PSpace.x8),
              itemBuilder: (_, i) => _GoalCard(
                goal: items[i],
                masked: settings.hideAmounts,
                tokens: t,
                onContribute: () =>
                    _showContribute(context, ref, items[i]),
                onEdit: () => showSavingGoalEditDialog(context,
                    edit: items[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showContribute(BuildContext context, WidgetRef ref, SavingGoal g) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool busy = false;
        return StatefulBuilder(
          builder: (_, setS) => PFormAlertDialog(
            title: '"${g.title}" 적립',
            content: PTextInput(
              controller: ctrl,
              numbersOnly: true,
              autofocus: true,
              placeholder: '금액 (음수 가능)',
              suffixText: '원',
            ),
            actions: [
              PButton(
                label: '취소',
                variant: PButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx),
              ),
              PButton(
                label: '적립',
                loading: busy,
                onPressed: busy
                    ? null
                    : () async {
                        final amt = int.tryParse(ctrl.text);
                        if (amt == null) return;
                        setS(() => busy = true);
                        try {
                          final repo = await ref
                              .read(savingGoalRepositoryProvider.future);
                          await repo.contribute(g.rowId, amount: amt);
                          ref.invalidate(savingGoalListProvider);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                        } on ApiException catch (e) {
                          if (!ctx.mounted) return;
                          setS(() => busy = false);
                          showPSnackBar(ctx, '실패: ${e.message}', severity: PSnackSeverity.error);
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 저금 목표 skeleton — 카드(아이콘+제목+기한+진행바) × 3.
class _SavingGoalSkeleton extends StatelessWidget {
  const _SavingGoalSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
        vertical: PSpace.x24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: PSpace.x8),
      itemBuilder: (_, _) => PCard(
        variant: PCardVariant.bordered,
        padding: const EdgeInsets.all(PSpace.x12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PSkeleton(width: 36, height: 36, borderRadius: PRadius.tile(36)),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PSkeleton.line(width: 120),
                      const SizedBox(height: 4),
                      const PSkeleton.line(width: 72, height: 12),
                    ],
                  ),
                ),
                PSkeleton(width: 32, height: 32, borderRadius: PRadius.brMd),
              ],
            ),
            const SizedBox(height: PSpace.x12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const PSkeleton.line(width: 80, height: 18),
                const SizedBox(width: 4),
                const PSkeleton.line(width: 60, height: 12),
                const Spacer(),
                const PSkeleton.line(width: 36, height: 12),
              ],
            ),
            const SizedBox(height: PSpace.x8),
            PSkeleton(
              width: double.infinity,
              height: 8,
              borderRadius: PRadius.brXs,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.masked,
    required this.tokens,
    required this.onContribute,
    required this.onEdit,
  });
  final SavingGoal goal;
  final bool masked;
  final PorestTokens tokens;
  final VoidCallback onContribute;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = resolveChartColor(context, goal.color, fallback: tokens.fgBrand);
    final bg = softBg(context, color);
    final pct = (goal.progress * 100).round();
    return Material(
      color: tokens.bgSurface,
      borderRadius: PRadius.brLg,
      child: InkWell(
        onTap: onEdit,
        borderRadius: PRadius.brLg,
        child: Container(
          padding: const EdgeInsets.all(PSpace.x12),
          decoration: BoxDecoration(
            borderRadius: PRadius.brLg,
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: PRadius.tile(36)),
                    alignment: Alignment.center,
                    child: Icon(lucideByName(goal.icon, fallback: LucideIcons.piggyBank),
                        size: 18, color: color),
                  ),
                  const SizedBox(width: PSpace.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(goal.title,
                                  style: PTypo.body.copyWith(
                                      color: tokens.fgPrimary,
                                      fontWeight: PFontWeight.bold)),
                            ),
                            if (goal.achieved) ...[
                              const SizedBox(width: 6),
                              const PBadge(
                                  label: '달성!',
                                  variant: PBadgeVariant.softSuccess),
                            ],
                          ],
                        ),
                        if ((goal.deadlineDate ?? '').isNotEmpty)
                          Text('~ ${goal.deadlineDate}',
                              style: PTypo.caption
                                  .copyWith(color: tokens.fgTertiary)),
                      ],
                    ),
                  ),
                  PButton.icon(
                    icon: LucideIcons.plus,
                    size: PButtonSize.sm,
                    iconColor: tokens.fgBrand,
                    tooltip: '적립',
                    onPressed: onContribute,
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(krwMasked(goal.currentAmount, masked, mask: '••••'),
                      style: PTypo.h4.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.bold)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('/ ${krwMasked(goal.targetAmount, masked, mask: '••••')}',
                        style: PTypo.caption
                            .copyWith(color: tokens.fgTertiary)),
                  ),
                  const Spacer(),
                  Text('$pct%',
                      style: PTypo.bodySm.copyWith(
                          color: color, fontWeight: PFontWeight.bold)),
                ],
              ),
              const SizedBox(height: PSpace.x8),
              ClipRRect(
                borderRadius: PRadius.brXs,
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: tokens.bgTrack,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
