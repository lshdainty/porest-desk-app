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
import '../../asset/application/asset_providers.dart';
import '../../expense/application/expense_providers.dart';
import '../application/preset_providers.dart';
import '../domain/expense_template.dart';

void showPresetEditDialog(
  BuildContext context, {
  ExpenseTemplate? edit,
}) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(edit == null ? '프리셋 추가' : '프리셋 수정'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _Body(edit: edit),
      ),
    ],
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({this.edit});
  final ExpenseTemplate? edit;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _descCtrl;
  late String _expenseType;
  int? _categoryRowId;
  int? _assetRowId;
  late bool _lockAmount;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final t = widget.edit;
    _nameCtrl = TextEditingController(text: t?.templateName ?? '');
    _amountCtrl = TextEditingController(text: t?.amount.toString() ?? '');
    _merchantCtrl = TextEditingController(text: t?.merchant ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _expenseType = t?.expenseType ?? 'EXPENSE';
    _categoryRowId = t?.categoryRowId;
    _assetRowId = t?.assetRowId;
    _lockAmount = (t?.lockAmount ?? 'N') == 'Y';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final name = _nameCtrl.text.trim();
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    return !_submitting &&
        name.isNotEmpty &&
        amount != null &&
        amount > 0 &&
        _categoryRowId != null &&
        _assetRowId != null;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          templateName: _nameCtrl.text.trim(),
          categoryRowId: _categoryRowId!,
          assetRowId: _assetRowId!,
          expenseType: _expenseType,
          amount: amount,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          merchant: _merchantCtrl.text.trim().isEmpty
              ? null
              : _merchantCtrl.text.trim(),
          lockAmount: _lockAmount,
        );
      } else {
        await repo.create(
          templateName: _nameCtrl.text.trim(),
          categoryRowId: _categoryRowId!,
          assetRowId: _assetRowId!,
          expenseType: _expenseType,
          amount: amount,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          merchant: _merchantCtrl.text.trim().isEmpty
              ? null
              : _merchantCtrl.text.trim(),
          lockAmount: _lockAmount,
        );
      }
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '프리셋이 수정되었습니다' : '프리셋이 추가되었습니다')),
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
        title: const Text('프리셋 삭제'),
        content: Text('"${widget.edit!.templateName}" 프리셋을 삭제할까요?'),
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
      final repo = await ref.read(presetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(presetListProvider);
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
    final assetsAsync = ref.watch(assetsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유형
          _Seg(
            options: const [
              ('EXPENSE', '지출'),
              ('INCOME', '수입'),
            ],
            value: _expenseType,
            onChanged: (v) => setState(() => _expenseType = v),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x16),

          Text('프리셋 이름',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _nameCtrl,
            maxLength: 20,
            decoration: const InputDecoration(
              hintText: '예: 점심 김밥',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),

          Text('금액', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '0'),
            onChanged: (_) => setState(() {}),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('금액 잠금',
                style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
            subtitle: Text('체크 시 사용할 때 금액 변경 불가',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
            value: _lockAmount,
            onChanged: (v) => setState(() => _lockAmount = v),
          ),
          const SizedBox(height: PSpace.x8),

          Text('카테고리',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('카테고리 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (categories) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final c in categories
                    .where((c) =>
                        c.expenseType == null ||
                        c.expenseType == _expenseType))
                  _CatChip(
                    label: c.categoryName,
                    icon: lucideByName(c.icon),
                    fg: parseColor(c.color, fallback: t.fgBrand),
                    selected: _categoryRowId == c.rowId,
                    onTap: () => setState(() => _categoryRowId = c.rowId),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x12),

          Text('자산', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          assetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('자산 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (assets) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final a in assets)
                  _PlainChip(
                    label: a.assetName,
                    selected: _assetRowId == a.rowId,
                    onTap: () => setState(() => _assetRowId = a.rowId),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x12),

          Text('가맹점 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _merchantCtrl,
            decoration: const InputDecoration(hintText: '예: 김밥천국'),
          ),
          const SizedBox(height: PSpace.x12),

          Text('메모 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(hintText: '메모'),
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

class _Seg extends StatelessWidget {
  const _Seg(
      {required this.options,
      required this.value,
      required this.onChanged,
      required this.tokens});
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: tokens.bgMuted, borderRadius: PRadius.brMd),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        o.$1 == value ? tokens.bgSurface : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(o.$2,
                      textAlign: TextAlign.center,
                      style: PTypo.bodySm.copyWith(
                          color: o.$1 == value
                              ? tokens.fgPrimary
                              : tokens.fgTertiary,
                          fontWeight: o.$1 == value
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip(
      {required this.label,
      required this.icon,
      required this.fg,
      required this.selected,
      required this.onTap,
      required this.tokens});
  final String label;
  final IconData icon;
  final Color fg;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

class _PlainChip extends StatelessWidget {
  const _PlainChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.tokens});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: PRadius.brMd,
        ),
        child: Text(label,
            style: PTypo.bodySm.copyWith(
                color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
