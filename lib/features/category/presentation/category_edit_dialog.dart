import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_color_picker.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import 'category_palette.dart';

void showCategoryEditDialog(
  BuildContext context, {
  ExpenseCategory? edit,
  String defaultExpenseType = 'EXPENSE',
}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '카테고리 추가' : '카테고리 수정',
    contentBuilder: (ctx, scrollCtrl) => _CategoryEditBody(
      edit: edit,
      defaultExpenseType: defaultExpenseType,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? '추가' : '수정',
    ),
  );
}

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
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.edit;
    _nameCtrl = TextEditingController(text: c?.categoryName ?? '');
    _expenseType = c?.expenseType ?? widget.defaultExpenseType;
    _icon = c?.icon ?? 'tag';
    _color = (c?.color != null && c!.color!.trim().isNotEmpty)
        ? c.color!
        : kChartBaseHexes.first;
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

  bool get _canSubmit {
    final name = _nameCtrl.text.trim();
    return !_submitting && name.isNotEmpty && name.length <= 12;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final name = _nameCtrl.text.trim();
    final color = _color;
    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      if (_isEdit) {
        await repo.updateCategory(
          id: widget.edit!.rowId,
          categoryName: name,
          icon: _icon,
          color: color,
        );
      } else {
        await repo.createCategory(
          categoryName: name,
          icon: _icon,
          color: color,
          expenseType: _expenseType,
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
    final ok = await showPConfirmDialog(
      context,
      title: '카테고리 삭제',
      message:
          '"${widget.edit!.categoryName}" 카테고리를 삭제할까요?\n이 카테고리에 연결된 거래는 영향을 받을 수 있습니다.',
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
    final previewColor = resolveChartColor(context, _color, fallback: t.fgBrand);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          // 미리보기
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: previewColor.withValues(alpha: 0.13),
                borderRadius: PRadius.brLg,
              ),
              alignment: Alignment.center,
              child: Icon(lucideByName(_icon), size: 28, color: previewColor),
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 이름
          Text('이름',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _nameCtrl,
            placeholder: '예: 식비',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x16),

          if (!_isEdit) ...[
            Text('유형',
                style: PTypo.caption.copyWith(color: t.fgSecondary)),
            const SizedBox(height: PSpace.x8),
            _TypeSeg(
              value: _expenseType,
              onChanged: (v) => setState(() => _expenseType = v),
              tokens: t,
            ),
            const SizedBox(height: PSpace.x16),
          ],

          // 색상
          Text('색상',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          PColorPicker(
            selected: _color,
            onChanged: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: PSpace.x16),

          // 아이콘
          Text('아이콘',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (final name in CatPalette.icons)
                GestureDetector(
                  onTap: () => setState(() => _icon = name),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          name == _icon ? t.bgBrandSubtle : t.bgMuted,
                      borderRadius: PRadius.brSm,
                      border: Border.all(
                        color: name == _icon
                            ? t.borderBrand
                            : t.borderSubtle,
                        width: name == _icon ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(lucideByName(name),
                        size: 18,
                        color:
                            name == _icon ? t.fgBrand : t.fgSecondary),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _TypeSeg extends StatelessWidget {
  const _TypeSeg(
      {required this.value, required this.onChanged, required this.tokens});
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    const opts = [('EXPENSE', '지출'), ('INCOME', '수입')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.bgMuted,
        borderRadius: PRadius.brMd,
      ),
      child: Row(
        children: [
          for (final o in opts)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: o.$1 == value
                        ? tokens.bgSurface
                        : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    o.$2,
                    textAlign: TextAlign.center,
                    style: PTypo.bodySm.copyWith(
                      color: o.$1 == value
                          ? tokens.fgPrimary
                          : tokens.fgTertiary,
                      fontWeight: o.$1 == value
                          ? PFontWeight.bold
                          : PFontWeight.medium,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
