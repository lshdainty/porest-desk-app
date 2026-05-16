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
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../asset/application/asset_providers.dart';
import '../../expense/application/expense_providers.dart';
import '../application/preset_providers.dart';
import '../domain/expense_template.dart';

void showPresetEditDialog(
  BuildContext context, {
  ExpenseTemplate? edit,
}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '프리셋 추가' : '프리셋 수정',
    contentBuilder: (ctx, scrollCtrl) => _Body(
      edit: edit,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? '추가' : '수정',
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final ExpenseTemplate? edit;
  final ScrollController scrollController;
  final PSheetController controller;
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
    _setSubmitting(true);
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
      showPSnackBar(context, _isEdit ? '프리셋이 수정되었습니다' : '프리셋이 추가되었습니다', severity: PSnackSeverity.success);
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
      title: '프리셋 삭제',
      message: '"${widget.edit!.templateName}" 프리셋을 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(presetListProvider);
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
    final assetsAsync = ref.watch(assetsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
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
          PTextInput(
            controller: _nameCtrl,
            placeholder: '예: 점심 김밥',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),

          Text('금액', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _amountCtrl,
            numbersOnly: true,
            placeholder: '0',
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
                  PChip(
                    label: c.categoryName,
                    icon: lucideByName(c.icon),
                    iconColor: parseColor(c.color, fallback: t.fgBrand),
                    variant: PChipVariant.subtle,
                    selected: _categoryRowId == c.rowId,
                    onTap: () => setState(() => _categoryRowId = c.rowId),
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
                  PChip(
                    label: a.assetName,
                    selected: _assetRowId == a.rowId,
                    variant: PChipVariant.subtle,
                    shape: PChipShape.rounded,
                    onTap: () => setState(() => _assetRowId = a.rowId),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x12),

          Text('가맹점 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _merchantCtrl,
            placeholder: '예: 김밥천국',
          ),
          const SizedBox(height: PSpace.x12),

          Text('메모 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _descCtrl,
            placeholder: '메모',
          ),
      ],
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
                              ? PFontWeight.bold
                              : PFontWeight.medium)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

