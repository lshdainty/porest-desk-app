import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';
import 'package:porest_desk_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';

/// 저축 목표 관리 (설정 > 저축 목표) — design GoalManager 미러 (웹 SavingGoalManager 정합).
///
/// 전체 진행률 요약(keep 카드) + 목표 목록(카드 탭 = 편집). 자산 화면은 조회 전용.
class SavingGoalScreen extends ConsumerWidget {
  const SavingGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(savingGoalListProvider);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.navSavingGoals),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
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
            child: Text('${l.savingGoalLoadError}\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (items) {
            final totalTarget =
                items.fold<int>(0, (s, g) => s + g.targetAmount);
            final totalCurrent =
                items.fold<int>(0, (s, g) => s + g.currentAmount);
            final totalPct =
                totalTarget > 0 ? (totalCurrent / totalTarget * 100) : 0.0;
            return ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: PSpace.x24, vertical: PSpace.x24),
              children: [
                // 전체 진행률 — design GoalManager p-card--keep.
                if (items.isNotEmpty) ...[
                  PCard(
                    variant: PCardVariant.raised,
                    padding: const EdgeInsets.all(PSpace.x16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.savingGoalOverallProgress,
                                  style: PTypo.caption
                                      .copyWith(color: t.fgTertiary)),
                              const SizedBox(height: 3),
                              Text.rich(
                                TextSpan(
                                  text: krwMasked(
                                      totalCurrent, ref.watch(hideCardProvider('asset.savingGoals')),
                                      mask: '••••'),
                                  style: PTypo.h4.copyWith(
                                      color: t.fgPrimary,
                                      fontWeight: PFontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text:
                                          ' / ${krwSigned(totalTarget, ref.watch(hideCardProvider('asset.savingGoals')), unit: true, mask: '••••')}',
                                      style: PTypo.bodySm.copyWith(
                                          color: t.fgTertiary,
                                          fontWeight: PFontWeight.semi),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text('${totalPct.toStringAsFixed(0)}%',
                            style: PTypo.h3.copyWith(
                                color: t.fgBrand,
                                fontWeight: PFontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: PSpace.x16),
                ],

                // 목록 라벨 + 추가 — design '목표 목록 · N개' + ghost 목표 추가.
                Row(
                  children: [
                    Text(l.savingGoalListCount(items.length),
                        style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold)),
                    const Spacer(),
                    // accent = 라벨·아이콘 모두 fgBrand (recurring_screen 추가 버튼 정합).
                    // ghost + iconColor 조합은 아이콘만 브랜드색이라 웹과 어긋났다.
                    PButton(
                      label: l.savingGoalAddAction,
                      icon: LucideIcons.plus,
                      variant: PButtonVariant.accent,
                      size: PButtonSize.sm,
                      onPressed: () => showSavingGoalEditDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: PSpace.x8),

                if (items.isEmpty)
                  // 카드 다이어트(recurring_screen _EmptyState 정합) — 아이콘·카드 없이 중앙 단문.
                  Padding(
                    padding: const EdgeInsets.all(PSpace.x40),
                    child: Center(
                      child: Text(
                        l.savingGoalEmpty,
                        textAlign: TextAlign.center,
                        style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0) const PDivider(),
                    _GoalCard(
                      goal: items[i],
                      masked: ref.watch(hideCardProvider('asset.savingGoals')),
                      tokens: t,
                      onEdit: () =>
                          showSavingGoalEditDialog(context, edit: items[i]),
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 저축 목표 skeleton — keep 카드 + 목록 카드 × 3.
class _SavingGoalSkeleton extends StatelessWidget {
  const _SavingGoalSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x24,
        vertical: PSpace.x24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PSkeleton(
            width: double.infinity, height: 74, borderRadius: PRadius.brLg),
        const SizedBox(height: PSpace.x16),
        const PSkeleton.line(width: 120),
        const SizedBox(height: PSpace.x8),
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: PSpace.x8),
          PSkeleton(
              width: double.infinity, height: 118, borderRadius: PRadius.brLg),
        ],
      ],
    );
  }
}

/// 목표 카드 — design GoalManager 모바일 카드: 탭 = 편집, chevron.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.masked,
    required this.tokens,
    required this.onEdit,
  });
  final SavingGoal goal;
  final bool masked;
  final PorestTokens tokens;
  final VoidCallback onEdit;

  String? _deadlineLabel() {
    final raw = goal.deadlineDate;
    if (raw == null || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = resolveChartColor(context, goal.color, fallback: tokens.fgBrand);
    final bg = softBg(context, color);
    final pct = (goal.progress * 100).round();
    // 카드 다이어트(recurring_screen 정합) — 항목마다 카드를 두지 않고 행 사이 PDivider 로만
    // 구분한다. 페이지 배경 위에 카드가 겹겹이 쌓이면 keep 카드(요약)의 위계가 죽는다.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          // 좌우 0 — 라벨·추가 버튼과 같은 지점에서 시작한다(설정 리스트 공통 규칙).
          padding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: PSpace.x12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: PRadius.tile(40)),
                    alignment: Alignment.center,
                    child: Icon(lucideByName(goal.icon, fallback: LucideIcons.piggyBank),
                        size: 19, color: color),
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
                                  overflow: TextOverflow.ellipsis,
                                  style: PTypo.body.copyWith(
                                      color: tokens.fgPrimary,
                                      fontWeight: PFontWeight.bold)),
                            ),
                            if (goal.achieved) ...[
                              const SizedBox(width: 6),
                              PBadge(
                                  label: l.savingGoalAchieved,
                                  variant: PBadgeVariant.softSuccess),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(_deadlineLabel() ?? l.savingGoalNoDeadline,
                            style: PTypo.caption
                                .copyWith(color: tokens.fgTertiary)),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight,
                      size: 18, color: tokens.fgTertiary),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              Row(
                children: [
                  Text(
                      '${krwMasked(goal.currentAmount, masked, mask: '••••')} / ${krwSigned(goal.targetAmount, masked, unit: true, mask: '••••')}',
                      style: PTypo.caption.copyWith(
                          color: tokens.fgSecondary,
                          fontWeight: PFontWeight.semi)),
                  const Spacer(),
                  Text('$pct%',
                      style: PTypo.bodySm.copyWith(
                          color: color, fontWeight: PFontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: PRadius.brXs,
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 6,
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
