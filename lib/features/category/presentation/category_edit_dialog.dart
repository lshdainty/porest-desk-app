import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/category/presentation/category_palette.dart';

/// 카테고리 추가/편집 시트 — 웹 `CategoryEditDialog.tsx` 미러.
///
/// 섹션 순서(웹 정합): 미리보기 카드 → 구분(지출/수입, 편집 시에도 변경 가능) →
/// 상위 카테고리(선택) → 이름(카운터 N/12 + 에러) → 색상 → 아이콘(34종).
void showCategoryEditDialog(
  BuildContext context, {
  ExpenseCategory? edit,
  String defaultExpenseType = 'EXPENSE',
}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '카테고리 추가' : '카테고리 편집',
    contentBuilder: (ctx, scrollCtrl) => _CategoryEditBody(
      edit: edit,
      defaultExpenseType: defaultExpenseType,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? '추가' : '저장',
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
    if (_nameTrim.isEmpty) return '이름을 입력해 주세요.';
    if (_nameTrim.length > 12) return '이름은 12자 이내로 입력해 주세요.';
    if (_duplicate) return '같은 이름의 카테고리가 있습니다.';
    return null;
  }

  /// 본인이 이미 자식을 가진 부모면 상위 변경 불가 (깊이 2+ 방지 — 웹 정합).
  bool get _selfHasChildren =>
      _isEdit &&
      _categories.any((c) => c.parentRowId == widget.edit!.rowId);

  /// 웹 정합 — 저장 버튼은 touched 전엔 활성(눌러서 에러를 노출하는 플로우),
  /// touched 후엔 valid 일 때만 활성.
  bool get _canSubmit => !_submitting && (!_touched || _valid);

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_submitting || !_valid) return;
    final name = _nameTrim;
    final parentDisabled = _selfHasChildren;
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
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, _isEdit ? '카테고리가 수정되었습니다' : '카테고리가 추가되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    // 웹 정합 — 하위 카테고리가 있으면 삭제 차단 안내.
    if (_selfHasChildren) {
      await showPConfirmDialog(
        context,
        title: '카테고리 삭제',
        message:
            '"${widget.edit!.categoryName}" 카테고리에 하위 카테고리가 있어 삭제할 수 없어요. 먼저 하위 카테고리를 정리해 주세요.',
        confirmLabel: '확인',
      );
      return;
    }
    final ok = await showPConfirmDialog(
      context,
      title: '카테고리 삭제',
      message: '"${widget.edit!.categoryName}" 카테고리를 삭제하시겠어요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.deleteCategory(widget.edit!.rowId);
      ref.invalidate(categoriesProvider);
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
    final parentDisabled = _selfHasChildren;

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
                      _nameTrim.isEmpty ? '새 카테고리' : _nameTrim,
                      style: PTypo.body.copyWith(
                        fontSize: PFontSize.bodyMd,
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_expenseType == 'EXPENSE' ? '지출' : '수입'} 카테고리 · 미리보기',
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
        Text('구분', style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        PTabs<String>(
          value: _expenseType,
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: const [
            PTabItem(value: 'EXPENSE', label: '지출'),
            PTabItem(value: 'INCOME', label: '수입'),
          ],
          onChanged: (v) => setState(() => _expenseType = v),
        ),
        const SizedBox(height: PSpace.x16),

        // 상위 카테고리 (선택)
        Text.rich(
          TextSpan(
            text: '상위 카테고리',
            style: PTypo.caption.copyWith(color: t.fgSecondary),
            children: [
              TextSpan(
                text: ' (선택)',
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x8),
        PSelect<int>(
          value: _parentRowId ?? _kRootParent,
          title: '상위 카테고리',
          enabled: !parentDisabled && parentOptions.isNotEmpty,
          helperText:
              parentDisabled ? '하위 카테고리가 있어 상위를 변경할 수 없어요.' : null,
          items: [
            const PSelectItem(
                value: _kRootParent, label: '— 최상위 카테고리로 두기 —'),
            for (final p in parentOptions)
              PSelectItem(value: p.rowId, label: p.categoryName),
          ],
          onChanged: (v) => setState(
              () => _parentRowId = (v == null || v == _kRootParent) ? null : v),
        ),
        const SizedBox(height: PSpace.x16),

        // 이름 — 카운터 N/12 또는 에러 (웹 정합).
        Text('이름', style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _nameCtrl,
          placeholder: '예: 반려동물, 부수입',
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
        Text('색상', style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        PColorPicker(
          selected: _color,
          onChanged: (hex) => setState(() => _color = hex),
        ),
        const SizedBox(height: PSpace.x16),

        // 아이콘 — 웹 ICON_CHOICES 34종.
        Text('아이콘', style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x8),
        Wrap(
          spacing: PSpace.x8,
          runSpacing: PSpace.x8,
          children: [
            for (final name in kCategoryIcons)
              GestureDetector(
                onTap: () => setState(() => _icon = name),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: name == _icon ? t.bgBrandSubtle : t.bgMuted,
                    borderRadius: PRadius.brSm,
                    border: Border.all(
                      color: name == _icon ? t.borderBrand : t.borderSubtle,
                      width: name == _icon ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(lucideByName(name),
                      size: 18,
                      color: name == _icon ? t.fgBrand : t.fgSecondary),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
