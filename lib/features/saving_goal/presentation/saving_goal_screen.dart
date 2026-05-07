import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('저금 목표'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () => showSavingGoalEditDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(savingGoalListProvider);
          await ref.read(savingGoalListProvider.future);
        },
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('저금 목표 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(PSpace.x32),
                  child: Column(children: [
                    Icon(LucideIcons.piggyBank,
                        size: 48, color: t.fgDisabled),
                    const SizedBox(height: PSpace.x12),
                    Text('등록된 저금 목표가 없습니다',
                        style:
                            PTypo.body.copyWith(color: t.fgTertiary)),
                  ]),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x80),
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
          builder: (_, setS) => AlertDialog(
            title: Text('"${g.title}" 적립'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: '금액 (음수 가능)', suffixText: '원'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소')),
              FilledButton(
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
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('실패: ${e.message}')));
                        }
                      },
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Text('적립'),
              ),
            ],
          ),
        );
      },
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
    final color = parseColor(goal.color, fallback: tokens.fgBrand);
    final bg = softBg(color);
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
                        color: bg, borderRadius: PRadius.brSm),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tokens.statusSuccessSubtle,
                                  borderRadius: PRadius.brXs,
                                ),
                                child: Text('달성!',
                                    style: PTypo.caption.copyWith(
                                        color: tokens.statusSuccessFg,
                                        fontWeight: PFontWeight.bold,
                                        fontSize: 10)),
                              ),
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
                  IconButton(
                    onPressed: onContribute,
                    icon: Icon(LucideIcons.plus,
                        size: 16, color: tokens.fgBrand),
                    tooltip: '적립',
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 32),
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(krwMasked(goal.currentAmount, masked),
                      style: PTypo.h4.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.heavy)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('/ ${krwMasked(goal.targetAmount, masked)}',
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
