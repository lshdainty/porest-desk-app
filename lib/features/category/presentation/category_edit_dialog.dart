import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import 'category_palette.dart';

void showCategoryEditDialog(
  BuildContext context, {
  ExpenseCategory? edit,
  String defaultExpenseType = 'EXPENSE',
}) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(edit == null ? '카테고리 추가' : '카테고리 수정'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _CategoryEditBody(
            edit: edit, defaultExpenseType: defaultExpenseType),
      ),
    ],
  );
}

class _CategoryEditBody extends ConsumerStatefulWidget {
  const _CategoryEditBody({this.edit, required this.defaultExpenseType});
  final ExpenseCategory? edit;
  final String defaultExpenseType;

  @override
  ConsumerState<_CategoryEditBody> createState() => _CategoryEditBodyState();
}

class _CategoryEditBodyState extends ConsumerState<_CategoryEditBody> {
  late final TextEditingController _nameCtrl;
  late String _expenseType;
  late String _icon;
  late int _paletteIdx;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.edit;
    _nameCtrl = TextEditingController(text: c?.categoryName ?? '');
    _expenseType = c?.expenseType ?? widget.defaultExpenseType;
    _icon = c?.icon ?? 'tag';
    _paletteIdx = CatPalette.indexByColor(c?.color) ?? 0;
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
    final color = CatPalette.all[_paletteIdx].toHex();
    setState(() => _submitting = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '카테고리가 수정되었습니다' : '카테고리가 추가되었습니다')),
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
        title: const Text('카테고리 삭제'),
        content: Text(
            '"${widget.edit!.categoryName}" 카테고리를 삭제할까요?\n이 카테고리에 연결된 거래는 영향을 받을 수 있습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
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
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.deleteCategory(widget.edit!.rowId);
      ref.invalidate(categoriesProvider);
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
    final palette = CatPalette.all[_paletteIdx];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 미리보기
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: palette.color.withValues(alpha: 0.13),
                borderRadius: PRadius.brLg,
              ),
              alignment: Alignment.center,
              child: Icon(lucideByName(_icon), size: 28, color: palette.color),
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 이름
          Text('이름',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _nameCtrl,
            maxLength: 12,
            decoration: const InputDecoration(
              hintText: '예: 식비',
              counterText: '',
            ),
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
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (int i = 0; i < CatPalette.all.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _paletteIdx = i),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CatPalette.all[i].color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == _paletteIdx
                            ? t.fgPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: i == _paletteIdx
                        ? const Icon(LucideIcons.check,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                ),
            ],
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

class _TypeSeg extends StatelessWidget {
  const _TypeSeg(
      {required this.value, required this.onChanged, required this.tokens});
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    const opts = [('EXPENSE', '지출'), ('INCOME', '수입'), ('TRANSFER', '이체')];
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
                          ? FontWeight.w700
                          : FontWeight.w500,
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
