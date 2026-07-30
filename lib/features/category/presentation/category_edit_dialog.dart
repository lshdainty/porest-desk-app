import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_icon_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';

/// 카테고리 추가/편집 시트 — 웹 `CategoryEditDialog.tsx` 미러.
///
/// 섹션 순서(웹 정합): 미리보기 카드 → 구분(지출/수입, 편집 시에도 변경 가능) →
/// 상위 카테고리(선택) → 이름(카운터 N/12 + 에러) → 색상 → 아이콘(34종).
void showCategoryEditDialog(
  BuildContext context, {
  ExpenseCategory? edit,
  String defaultExpenseType = 'EXPENSE',
}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.categoryAdd : l.categoryEdit,
    contentBuilder: (ctx, scrollCtrl) => _CategoryEditBody(
      edit: edit,
      defaultExpenseType: defaultExpenseType,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? l.calAdd : l.actionSave,
    ),
  );
}

/// 상위 카테고리 PSelect 의 "최상위" 항목 sentinel (rowId 는 1부터 시작).
const int _kRootParent = 0;

class _CategoryEditBody extends ConsumerStatefulWidget {
  const _CategoryEditBody({
    this.edit,
    required this.defaultExpenseType,
    required this.scrollController,
    required this.controller,
  });
  final ExpenseCategory? edit;
  final String defaultExpenseType;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_CategoryEditBody> createState() => _CategoryEditBodyState();
}

class _CategoryEditBodyState extends ConsumerState<_CategoryEditBody> {
  late final TextEditingController _nameCtrl;
  late String _expenseType;
  late String _icon;
  late String _color;
  late int? _parentRowId;
  bool _touched = false;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.edit;
    _nameCtrl = TextEditingController(text: c?.categoryName ?? '');
    _expenseType = c?.expenseType ?? widget.defaultExpenseType;
    _icon = c?.icon ?? 'tag';
    // 웹 정합 — 팔레트에 없는(레거시/커스텀) 색은 첫 색으로 정규화.
    // kChartBaseHexes 는 소문자라 비교 전 lower 정규화 (picker 도 정확 비교).
    final rawColor = c?.color?.trim().toLowerCase();
    _color = (rawColor != null && kChartBaseHexes.contains(rawColor))
        ? rawColor
        : kChartBaseHexes.first;
    _parentRowId = widget.edit?.parentRowId;
    widget.controller.onSubmit = _submit;
    if (_isEdit) widget.controller.onDelete = _delete;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<ExpenseCategory> get _categories =>
      ref.read(categoriesProvider).value ?? const [];

  String get _nameTrim => _nameCtrl.text.trim();

  /// 이름 중복 — 웹 정합: expenseType 무관 전체에서 자기 자신 제외 동명 검사.
  bool get _duplicate => _categories.any(
        (c) => c.categoryName == _nameTrim && c.rowId != widget.edit?.rowId,
      );

  bool get _valid =>
      _nameTrim.isNotEmpty && _nameTrim.length <= 12 && !_duplicate;

  /// 웹과 동일한 에러 문구 (touched 후에만 노출).
  String? get _nameError {
    if (!_touched || _valid) return null;
    final l = AppLocalizations.of(context);
    if (_nameTrim.isEmpty) return l.categoryNameRequired;
    if (_nameTrim.length > 12) return l.categoryNameTooLong;
    if (_duplicate) return l.categoryNameDuplicate;
    return null;
  }

  /// 본인이 이미 자식을 가진 부모면 상위 변경 불가 (깊이 2+ 방지 — 웹 정합).
  bool get _selfHasChildren =>
      _isEdit &&
      _categories.any((c) => c.parentRowId == widget.edit!.rowId);

  /// 웹 정합 — 저장 버튼은 touched 전엔 활성(눌러서 에러를 노출하는 플로우),
  /// touched 후엔 valid 일 때만 활성.
  bool get _canSubmit => !_submitting && (!_touched || _valid);

  /// 카테고리 변경(특히 상위 재배치) 후 집계 캐시 무효화 — 웹 expenseKeys.all 정합.
  ///
  /// rangeSummaryProvider 등 family FutureProvider 는 non-autoDispose 라 세션 내내
  /// 캐시가 살아 있어, categoriesProvider 만 무효화하면 예산 게이지·통계 도넛의
  /// categoryBreakdown(부모 귀속)이 stale 로 남는다 (pull-to-refresh 전까지).
  void _invalidateAggregates() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(rangeSummaryProvider);
    ref.invalidate(dashboardSummaryProvider);
  }

  /// 자식 이동 시 새 부모 예산 초과 확인 — 초과면 다이얼로그 1회(승인=true) (룰3).
  /// 예산 없음·미초과면 true(그대로 진행), 사용자가 취소하면 false.
  Future<bool> _confirmMoveIfExceedsBudget(int newParentRowId) async {
    final now = DateTime.now();
    final key = (year: now.year, month: now.month);
    final start =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final end =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final budgets = await ref.read(monthBudgetsProvider(key).future);
    final parentBudget = budgets
        .where((b) => b.categoryRowId == newParentRowId)
        .map((b) => b.budgetAmount)
        .firstOrNull;
    if (parentBudget == null) return true; // 새 부모에 예산 없음 → 경고 불필요

    final summary = await ref
        .read(rangeSummaryProvider((startDate: start, endDate: end)).future);
    final breakdown = summary.categoryBreakdown;
    final parentRollup = breakdown
        .where((c) =>
            c.categoryRowId == newParentRowId ||
            c.parentCategoryRowId == newParentRowId)
        .fold<int>(0, (s, c) => s + c.totalAmount);
    final movingSpent = breakdown
        .where((c) => c.categoryRowId == widget.edit!.rowId)
        .fold<int>(0, (s, c) => s + c.totalAmount);
    final projected = parentRollup + movingSpent;
    if (projected <= parentBudget) return true;

    if (!mounted) return false;
    final l = AppLocalizations.of(context);
    final parentName = _categories
        .where((c) => c.rowId == newParentRowId)
        .map((c) => c.categoryName)
        .firstOrNull ??
        l.categoryParent;
    return showPConfirmDialog(
      context,
      title: l.categoryBudgetExceedTitle,
      message: l.categoryBudgetExceedMessage(
          parentName, krwSigned(projected - parentBudget, false, unit: true)),
      confirmLabel: l.categoryMove,
    );
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() => _touched = true);
    if (_submitting || !_valid) return;
    final name = _nameTrim;
    final parentDisabled = _selfHasChildren;

    // 자식을 다른 부모로 이동 — 새 부모 예산 초과 시 한 번 확인 (룰3).
    if (_isEdit &&
        !parentDisabled &&
        _parentRowId != null &&
        _parentRowId != widget.edit!.parentRowId) {
      final ok = await _confirmMoveIfExceedsBudget(_parentRowId!);
      if (!ok || !mounted) return;
    }

    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      if (_isEdit) {
        await repo.updateCategory(
          id: widget.edit!.rowId,
          categoryName: name,
          icon: _icon,
          color: _color,
          expenseType: _expenseType,
          // 웹 정합 — parentRowId 는 항상 포함(null = 최상위). 자식 보유 시 기존 유지.
          includeParentRowId: true,
          parentRowId:
              parentDisabled ? widget.edit!.parentRowId : _parentRowId,
        );
      } else {
        await repo.createCategory(
          categoryName: name,
          icon: _icon,
          color: _color,
          expenseType: _expenseType,
          parentRowId: _parentRowId,
        );
      }
      _invalidateAggregates();
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, _isEdit ? l.categoryUpdated : l.categoryAdded, severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.categoryActionFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    // 웹 정합 — 하위 카테고리가 있으면 삭제 차단 안내.
    if (_selfHasChildren) {
      await showPConfirmDialog(
        context,
        title: l.categoryDeleteTitle,
        message: l.categoryDeleteHasChildren(widget.edit!.categoryName),
        confirmLabel: l.actionConfirm,
      );
      return;
    }
    // 예산이 걸린 카테고리면 함께 삭제됨을 안내 (백엔드 cascade).
    final now = DateTime.now();
    final budgets = await ref
        .read(monthBudgetsProvider((year: now.year, month: now.month)).future);
    if (!mounted) return;
    final hasBudget =
        budgets.any((b) => b.categoryRowId == widget.edit!.rowId);
    final ok = await showPConfirmDialog(
      context,
      title: l.categoryDeleteTitle,
      message: hasBudget
          ? l.categoryDeleteWithBudget(widget.edit!.categoryName)
          : l.categoryDeleteConfirm(widget.edit!.categoryName),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.deleteCategory(widget.edit!.rowId);
      _invalidateAggregates();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.categoryDeleteFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final previewFg = resolveChartColor(context, _color, fallback: t.fgBrand);
    final previewBg = softBg(context, previewFg);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final err = _nameError;

    // 상위 카테고리 후보 — 같은 구분의 최상위만, 자기 자신 제외 (웹 정합).
    final parentOptions = categories
        .where((c) =>
            c.expenseType == _expenseType &&
            c.parentRowId == null &&
            c.rowId != widget.edit?.rowId)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        // 미리보기 카드 — 웹: bg-muted + 아이콘 타일(44) + 이름 + 캡션, 실시간 반영.
        Container(
          padding: const EdgeInsets.all(14), // web 14px 정합
          decoration: BoxDecoration(
            color: t.bgMuted,
            borderRadius: PRadius.brLg,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: previewBg,
                  borderRadius: PRadius.brLg,
                ),
                child: Icon(lucideByName(_icon), size: 20, color: previewFg),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameTrim.isEmpty ? l.categoryNew : _nameTrim,
                      style: PTypo.body.copyWith(
                        fontSize: PFontSize.bodyMd,
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.categoryPreview(_expenseType == 'EXPENSE' ? l.expTypeExpense : l.expTypeIncome),
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x20),

        // 구분 — 웹 정합: 편집 모드에서도 변경 가능.
        Text(l.categoryTypeLabel, style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        PTabs<String>(
          value: _expenseType,
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: [
            PTabItem(value: 'EXPENSE', label: l.expTypeExpense),
            PTabItem(value: 'INCOME', label: l.expTypeIncome),
          ],
          onChanged: (v) => setState(() => _expenseType = v),
        ),
        const SizedBox(height: PSpace.x16),

        // 상위 카테고리 정책 (웹 정합):
        //  - 신규: 최상위 또는 특정 부모 아래로 생성(루트 옵션 포함).
        //  - 자식 편집: 다른 부모로만 이동(승격='최상위로 두기' 금지 → 루트 옵션 제거).
        //  - 최상위 편집: 강등 불가 → 필드 숨김.
        if (!_isEdit || widget.edit!.parentRowId != null) ...[
          Text.rich(
            TextSpan(
              text: l.categoryParent,
              style: PTypo.caption.copyWith(color: t.fgSecondary),
              children: [
                if (!_isEdit)
                  TextSpan(
                    text: l.categoryOptionalSuffix,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PSelect<int>(
            value: _parentRowId ?? _kRootParent,
            title: l.categoryParent,
            enabled: parentOptions.isNotEmpty,
            helperText: _isEdit
                ? l.categoryParentMoveHint
                : null,
            items: [
              if (!_isEdit)
                PSelectItem(
                    value: _kRootParent, label: l.categoryMakeRoot),
              for (final p in parentOptions)
                PSelectItem(value: p.rowId, label: p.categoryName),
            ],
            onChanged: (v) => setState(
                () => _parentRowId = (v == null || v == _kRootParent) ? null : v),
          ),
          const SizedBox(height: PSpace.x16),
        ],

        // 이름 — 카운터 N/12 또는 에러 (웹 정합).
        Text(l.calFieldName, style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _nameCtrl,
          placeholder: l.categoryNamePlaceholder,
          autofocus: !_isEdit,
          onChanged: (_) => setState(() => _touched = true),
        ),
        const SizedBox(height: PSpace.x4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            err ?? '${_nameTrim.length}/12',
            style: PTypo.micro.copyWith(
              color: err != null ? t.fgExpense : t.fgTertiary,
            ),
          ),
        ),
        const SizedBox(height: PSpace.x12),

        // 색상
        Text(l.calFieldColor, style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        PColorPicker(
          selected: _color,
          onChanged: (hex) => setState(() => _color = hex),
        ),
        const SizedBox(height: PSpace.x16),

        // 아이콘 — 전체 검색·선택, 웹 CategoryEditDialog 와 동일한 공통 픽커.
        Text(l.categoryIconLabel, style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        PIconPicker(
          value: _icon,
          onChanged: (v) => setState(() => _icon = v),
        ),
      ],
    );
  }
}
