import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';
import 'package:porest_desk_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 저금 목표 상세 시트 — 카드 탭 → 읽기 전용 상세 → 수정 버튼 → 편집 폼.
/// tx_detail_dialog(웹 SavingGoalDetailDialog) 패턴 미러: hero(진행률) + field rows + 뷰 footer.
void showSavingGoalDetailDialog(BuildContext context, SavingGoal goal) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.savingGoalDetailTitle,
    contentBuilder: (ctx, scrollCtrl) => _DetailBody(
      goal: goal,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => _DetailFooter(goal: goal, controller: controller),
  ).whenComplete(controller.dispose);
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({required this.goal, required this.controller});
  final SavingGoal goal;
  final PSheetController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final busy = controller.submitting;
        return PViewFooter(
          onDelete: controller.onDelete,
          deleting: busy,
          onEdit: busy
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  showSavingGoalEditDialog(ctx, edit: goal);
                },
          onConfirm: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.goal,
    required this.scrollController,
    required this.controller,
  });
  final SavingGoal goal;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.onDelete = _delete;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.savingGoalDeleteTitle,
      message: l.savingGoalDeleteConfirm(widget.goal.title),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    widget.controller.setSubmitting(true);
    try {
      final repo = await ref.read(savingGoalRepositoryProvider.future);
      await repo.delete(widget.goal.rowId);
      ref.invalidate(savingGoalListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${l.savingGoalDeleteFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) widget.controller.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final goal = widget.goal;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    final color = resolveChartColor(context, goal.color, fallback: t.fgBrand);
    final bg = softBg(context, color);
    final pct = (goal.progress * 100).round();
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(0, goal.targetAmount);
    final desc = (goal.description ?? '').trim();
    final achievedAt = (goal.achievedAt ?? '').length >= 10
        ? goal.achievedAt!.substring(0, 10)
        : goal.achievedAt;

    String amount(int n) => masked ? '••••••' : '${krw(n)}${wonUnit()}';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x16),
      children: [
        // Hero — 목표 색 틴트 + 진행률
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bg, t.bgSurface],
              stops: const [0.0, 0.85],
            ),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: PRadius.brXl,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: PRadius.tile(40),
                ),
                alignment: Alignment.center,
                child: Icon(
                  lucideByName(goal.icon, fallback: LucideIcons.piggyBank),
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      goal.title,
                      textAlign: TextAlign.center,
                      style: PTypo.h4.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (goal.achieved) ...[
                    const SizedBox(width: 6),
                    PBadge(
                      label: l.savingGoalAchieved,
                      variant: PBadgeVariant.softSuccess,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$pct%',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: PFontSize.displayMd,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -1.02,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Container(color: t.bgSunken),
                      FractionallySizedBox(
                        widthFactor: goal.progress,
                        child: Container(color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Field rows
        Container(
          decoration: BoxDecoration(
            color: t.borderSubtle,
            border: Border.all(color: t.borderSubtle),
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              _FieldRow(
                label: l.savingGoalAmountLabel,
                tokens: t,
                isFirst: true,
                child: Text(
                  amount(goal.targetAmount),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
              ),
              _FieldRow(
                label: l.savingGoalDetailCurrent,
                tokens: t,
                child: Text(
                  amount(goal.currentAmount),
                  style: PTypo.bodySm.copyWith(
                    color: color,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
              ),
              _FieldRow(
                label: l.savingGoalDetailRemaining,
                tokens: t,
                child: Text(
                  amount(remaining),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ),
              _FieldRow(
                label: l.savingGoalDetailDeadline,
                tokens: t,
                isLast: desc.isEmpty && !(goal.achieved && achievedAt != null),
                child: Text(
                  (goal.deadlineDate ?? '').isNotEmpty
                      ? goal.deadlineDate!
                      : l.savingGoalDetailDeadlineNone,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
              if (goal.achieved && achievedAt != null)
                _FieldRow(
                  label: l.savingGoalDetailAchievedAt,
                  tokens: t,
                  isLast: desc.isEmpty,
                  child: Text(
                    achievedAt,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ),
              if (desc.isNotEmpty)
                _FieldRow(
                  label: l.savingGoalDetailDescription,
                  tokens: t,
                  isLast: true,
                  child: Text(
                    desc,
                    textAlign: TextAlign.right,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.child,
    required this.tokens,
    this.isFirst = false,
    this.isLast = false,
  });
  final String label;
  final Widget child;
  final PorestTokens tokens;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(PRadius.lg) : Radius.zero,
          bottom: isLast ? const Radius.circular(PRadius.lg) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: PTypo.caption.copyWith(color: tokens.fgTertiary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}
