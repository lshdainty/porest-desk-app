import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/amount_limits.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';

const _presets = [100000, 200000, 300000, 500000, 800000, 1000000];

/// 한국어는 '10만원', 영어는 통화 포맷 — 웹 `isEn() ? money(p) : `${p/10000}만원`` 미러.
String _presetLabel(BuildContext context, int v) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'en') return krw(v);
  return '${(v / 10000).round()}만원';
}

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
    // 내용이 짧은 폼이라 화면 비율로 강제 점유하지 않고 content 높이로 wrap 한다
    // (웹 dialog 정합 — 빈 여백이 절반을 먹던 문제).
    shrinkWrap: true,
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
      submitLabel: edit == null ? l.calAdd : l.actionSave,
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
      ref.invalidate(
        monthBudgetsProvider((year: widget.year, month: widget.month)),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
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

    // 헤더에 띄울 카테고리 — 편집/전체상한은 고정, 신규는 선택값을 따라간다(웹 정합).
    final selectedCat = _isOverall
        ? ExpenseCategory(rowId: 0, categoryName: l.budgetOverallCap)
        : (_isEdit
              ? categoriesAsync.value?.firstWhere(
                  (c) => c.rowId == widget.edit!.categoryRowId,
                  orElse: () => ExpenseCategory(
                    rowId: widget.edit!.categoryRowId!,
                    categoryName: widget.edit!.categoryName ?? '-',
                  ),
                )
              : categoriesAsync.value
                    ?.where((c) => c.rowId == _categoryRowId)
                    .firstOrNull);
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

    // shrinkWrap sheet 라 바깥이 이미 스크롤 — 여기선 Column 을 쓴다(중첩 스크롤 금지).
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 카드 — 아이콘 + 이름 + 월 한도 미리보기(웹 BudgetEditDialog 미러).
          Container(
            padding: const EdgeInsets.all(PSpace.x12),
            decoration: BoxDecoration(
              color: t.bgMuted,
              borderRadius: PRadius.tile(56),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: softBg(
                      context,
                      resolveChartColor(
                        context,
                        selectedCat?.color,
                        fallback: t.fgBrand,
                      ),
                    ),
                    borderRadius: PRadius.tile(44),
                  ),
                  child: Icon(
                    lucideByName(selectedCat?.icon),
                    size: 18,
                    color: resolveChartColor(
                      context,
                      selectedCat?.color,
                      fallback: t.fgBrand,
                    ),
                  ),
                ),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCat?.categoryName ?? l.expCategory,
                        style: PTypo.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: t.fgPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l.budgetLimitPreview} ${krw(amount)}',
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x20),

          // 카테고리 선택 — 신규일 때만(편집은 헤더가 대신한다).
          if (!_isEdit && !widget.overallNew) ...[
            PSectionLabel(l.expCategory),
            const SizedBox(height: PSpace.x8),
            categoriesAsync.when(
              loading: () => const Center(child: PCircularProgressIndicator()),
              error: (e, _) => Text(
                l.budgetCategoryLoadError,
                style: PTypo.caption.copyWith(color: t.statusDanger),
              ),
              data: (categories) => Wrap(
                spacing: PSpace.x8,
                runSpacing: PSpace.x8,
                children: [
                  // 웹 기준 통일: 예산 가능 카테고리 = EXPENSE 최상위(부모)만.
                  // 자식 지출은 부모로 roll-up 집계되므로 leaf 는 제외.
                  for (final c in categories.where(
                    (c) => c.expenseType == 'EXPENSE' && c.parentRowId == null,
                  ))
                    Opacity(
                      opacity: widget.usedCategoryIds.contains(c.rowId)
                          ? 0.4
                          : 1.0,
                      child: PChip(
                        label: c.categoryName,
                        icon: lucideByName(c.icon),
                        iconColor: resolveChartColor(
                          context,
                          c.color,
                          fallback: t.fgBrand,
                        ),
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
          ],

          PSectionLabel(l.budgetMonthlyLimitField),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _amountCtrl,
            numbersOnly: true,
            amountMax: kAmountMax,
            style: PTypo.h3,
            placeholder: '0',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x8),

          // 빠른 금액 — 웹 ToggleGroup preset 미러.
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (final v in _presets)
                PChip(
                  label: _presetLabel(context, v),
                  variant: PChipVariant.subtle,
                  selected: amount == v,
                  onTap: () => setState(() {
                    _amountCtrl.text = v.toString();
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
