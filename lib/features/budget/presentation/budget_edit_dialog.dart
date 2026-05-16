import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_section_label.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import '../application/budget_providers.dart';
import '../domain/budget.dart';

void showBudgetEditDialog(
  BuildContext context, {
  required int year,
  required int month,
  Budget? edit,
  Set<int> usedCategoryIds = const {},
  bool overallNew = false,
}) {
  final isOverall = overallNew || (edit?.categoryRowId == null && edit != null);
  final title = edit == null
      ? (overallNew ? '월 전체 상한 설정' : '카테고리 예산 추가')
      : (isOverall ? '월 전체 상한 수정' : '카테고리 예산 수정');
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
      submitLabel: edit == null ? '추가' : '수정',
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
      showPSnackBar(context, _isEdit ? '예산이 수정되었습니다' : '예산이 추가되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    final ok = await showPConfirmDialog(
      context,
      title: '예산 삭제',
      message: '이 예산을 삭제하시겠습니까?',
      confirmLabel: '삭제',
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
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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

        PSectionLabel('카테고리'),
        const SizedBox(height: PSpace.x8),
        if (widget.overallNew)
          _LockedCategory(
              category: ExpenseCategory(rowId: 0, categoryName: '월 전체 상한'),
              tokens: t)
        else if (_isEdit)
          _LockedCategory(
              category: widget.edit!.categoryRowId == null
                  ? ExpenseCategory(rowId: 0, categoryName: '월 전체 상한')
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
            error: (e, _) => Text('카테고리 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (categories) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final c in categories
                    .where((c) => c.expenseType != 'INCOME'))
                  Opacity(
                    opacity: widget.usedCategoryIds.contains(c.rowId)
                        ? 0.4
                        : 1.0,
                    child: PChip(
                      label: c.categoryName,
                      icon: lucideByName(c.icon),
                      iconColor: parseColor(c.color, fallback: t.fgBrand),
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

        PSectionLabel('월 예산 한도'),
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
              color: parseColor(category!.color, fallback: tokens.fgBrand)),
          const SizedBox(width: 6),
          Text(category!.categoryName,
              style: PTypo.bodySm.copyWith(
                  color: tokens.fgPrimary, fontWeight: PFontWeight.medium)),
        ],
      ),
    );
  }
}

