import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';

void showBudgetEditDialog(
  BuildContext context, {
  required int year,
  required int month,
  Budget? edit,
  Set<int> usedCategoryIds = const {},
  bool overallNew = false,
}) {
  final l = AppLocalizations.of(context);
  final isOverall = overallNew || (edit?.categoryRowId == null && edit != null);
  final title = edit == null
      ? (overallNew ? l.budgetOverallCapNew : l.budgetCategoryAdd)
      : (isOverall ? l.budgetOverallCapEdit : l.budgetCategoryEdit);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: title,
    contentBuilder: (ctx, scrollCtrl) => _BudgetEditBody(
      year: year,
      month: month,
      edit: edit,
      usedCategoryIds: usedCategoryIds,
      overallNew: overallNew,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? l.calAdd : l.actionEdit,
    ),
  );
}

class _BudgetEditBody extends ConsumerStatefulWidget {
  const _BudgetEditBody({
    required this.year,
    required this.month,
    this.edit,
    required this.usedCategoryIds,
    this.overallNew = false,
    required this.scrollController,
    required this.controller,
  });
  final int year;
  final int month;
  final Budget? edit;
  final Set<int> usedCategoryIds;
  final bool overallNew;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_BudgetEditBody> createState() => _BudgetEditBodyState();
}

class _BudgetEditBodyState extends ConsumerState<_BudgetEditBody> {
  late final TextEditingController _amountCtrl;
  int? _categoryRowId;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.edit == null ? '' : widget.edit!.budgetAmount.toString(),
    );
    _categoryRowId = widget.edit?.categoryRowId;
    widget.controller.onSubmit = _submit;
    if (_isEdit) widget.controller.onDelete = _delete;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  bool get _isOverall =>
      widget.overallNew || (_isEdit && widget.edit!.categoryRowId == null);

  bool get _canSubmit {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    return !_submitting &&
        amount != null &&
        amount > 0 &&
        (_isOverall || _categoryRowId != null);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    _setSubmitting(true);
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(id: widget.edit!.rowId, budgetAmount: amount);
      } else {
        await repo.create(
          categoryRowId: _isOverall ? null : _categoryRowId!,
          budgetAmount: amount,
          budgetYear: widget.year,
          budgetMonth: widget.month,
        );
      }
      ref.invalidate(monthBudgetsProvider(
          (year: widget.year, month: widget.month)));
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, _isEdit ? l.budgetUpdated : l.budgetAdded, severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.budgetActionFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.budgetDeleteTitle,
      message: l.budgetDeleteConfirm,
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(monthBudgetsProvider(
          (year: widget.year, month: widget.month)));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.budgetDeleteFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        Text('${widget.year}년 ${widget.month}월',
            style: PTypo.caption.copyWith(color: t.fgTertiary)),
        const SizedBox(height: PSpace.x12),

        PSectionLabel(l.expCategory),
        const SizedBox(height: PSpace.x8),
        if (widget.overallNew)
          _LockedCategory(
              category: ExpenseCategory(rowId: 0, categoryName: l.budgetOverallCap),
              tokens: t)
        else if (_isEdit)
          _LockedCategory(
              category: widget.edit!.categoryRowId == null
                  ? ExpenseCategory(rowId: 0, categoryName: l.budgetOverallCap)
                  : categoriesAsync.value?.firstWhere(
                      (c) => c.rowId == widget.edit!.categoryRowId,
                      orElse: () => ExpenseCategory(
                          rowId: widget.edit!.categoryRowId!,
                          categoryName: widget.edit!.categoryName ?? '-')),
              tokens: t)
        else
          categoriesAsync.when(
            loading: () =>
                const Center(child: PCircularProgressIndicator()),
            error: (e, _) => Text(l.budgetCategoryLoadError,
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (categories) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                // 웹 기준 통일: 예산 가능 카테고리 = EXPENSE 최상위(부모)만.
                // 자식 지출은 부모로 roll-up 집계되므로 leaf 는 제외.
                for (final c in categories.where(
                    (c) => c.expenseType == 'EXPENSE' && c.parentRowId == null))
                  Opacity(
                    opacity: widget.usedCategoryIds.contains(c.rowId)
                        ? 0.4
                        : 1.0,
                    child: PChip(
                      label: c.categoryName,
                      icon: lucideByName(c.icon),
                      iconColor: resolveChartColor(context, c.color, fallback: t.fgBrand),
                      variant: PChipVariant.subtle,
                      selected: _categoryRowId == c.rowId,
                      onTap: widget.usedCategoryIds.contains(c.rowId)
                          ? () {}
                          : () => setState(() => _categoryRowId = c.rowId),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: PSpace.x16),

        PSectionLabel(l.budgetMonthlyLimit),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _amountCtrl,
          numbersOnly: true,
          style: PTypo.h3,
          placeholder: '0',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _LockedCategory extends StatelessWidget {
  const _LockedCategory({required this.category, required this.tokens});
  final ExpenseCategory? category;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    if (category == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.bgMuted,
        borderRadius: PRadius.brMd,
      ),
      child: Row(
        children: [
          Icon(lucideByName(category!.icon),
              size: 16,
              color: resolveChartColor(context, category!.color, fallback: tokens.fgBrand)),
          const SizedBox(width: 6),
          Text(category!.categoryName,
              style: PTypo.bodySm.copyWith(
                  color: tokens.fgPrimary, fontWeight: PFontWeight.medium)),
        ],
      ),
    );
  }
}

