import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
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
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(title),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _BudgetEditBody(
          year: year,
          month: month,
          edit: edit,
          usedCategoryIds: usedCategoryIds,
          overallNew: overallNew,
        ),
      ),
    ],
  );
}

class _BudgetEditBody extends ConsumerStatefulWidget {
  const _BudgetEditBody({
    required this.year,
    required this.month,
    this.edit,
    required this.usedCategoryIds,
    this.overallNew = false,
  });
  final int year;
  final int month;
  final Budget? edit;
  final Set<int> usedCategoryIds;
  final bool overallNew;

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
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
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
    setState(() => _submitting = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '예산이 수정되었습니다' : '예산이 추가되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('예산 삭제'),
        content: const Text('이 예산을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.tokens.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(monthBudgetsProvider(
          (year: widget.year, month: widget.month)));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.year}년 ${widget.month}월',
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x12),

          _Label('카테고리'),
          const SizedBox(height: PSpace.x8),
          if (widget.overallNew)
            _LockedCategory(
                category: ExpenseCategory(rowId: 0, categoryName: '월 전체 상한'),
                tokens: t)
          else if (_isEdit)
            // 수정 시엔 카테고리 변경 불가. categoryRowId 가 null 이면
            // '월 전체 상한' 으로 표기 (web 동일 패턴).
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
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('카테고리 로드 실패',
                  style: PTypo.caption.copyWith(color: t.statusDanger)),
              data: (categories) => Wrap(
                spacing: PSpace.x8,
                runSpacing: PSpace.x8,
                children: [
                  for (final c in categories
                      .where((c) => c.expenseType != 'INCOME'))
                    _CatChip(
                      label: c.categoryName,
                      icon: lucideByName(c.icon),
                      fg: parseColor(c.color, fallback: t.fgBrand),
                      selected: _categoryRowId == c.rowId,
                      disabled: widget.usedCategoryIds.contains(c.rowId),
                      onTap: () => setState(() => _categoryRowId = c.rowId),
                      tokens: t,
                    ),
                ],
              ),
            ),
          const SizedBox(height: PSpace.x16),

          _Label('월 예산 한도'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: PTypo.h3.copyWith(color: t.fgPrimary),
            decoration: const InputDecoration(hintText: '0'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x24),

          Row(
            children: [
              if (_isEdit) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.statusDanger,
                      side: BorderSide(
                          color: t.statusDanger.withValues(alpha: 0.5)),
                    ),
                    onPressed: _submitting ? null : _delete,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('삭제'),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
              ],
              Expanded(
                flex: _isEdit ? 1 : 2,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? '수정' : '추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(text, style: PTypo.caption.copyWith(color: t.fgSecondary));
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

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.icon,
    required this.fg,
    required this.selected,
    required this.disabled,
    required this.onTap,
    required this.tokens,
  });
  final String label;
  final IconData icon;
  final Color fg;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
            border: Border.all(
              color: selected ? tokens.borderBrand : tokens.borderDefault,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: PRadius.brPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: PTypo.bodySm.copyWith(
                    color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                    fontWeight: selected ? PFontWeight.semi : PFontWeight.medium,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
