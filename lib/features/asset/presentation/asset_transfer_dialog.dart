import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_select.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';

void showAssetTransferDialog(BuildContext context) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: '자산 간 이체',
    contentBuilder: (ctx, scrollCtrl) => _TransferBody(
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: '이체'),
  );
}

class _TransferBody extends ConsumerStatefulWidget {
  const _TransferBody({
    required this.scrollController,
    required this.controller,
  });
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_TransferBody> createState() => _TransferBodyState();
}

class _TransferBodyState extends ConsumerState<_TransferBody> {
  int? _fromId;
  int? _toId;
  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onSubmit = _submit;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  bool get _canSubmit {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    return !_submitting &&
        _fromId != null &&
        _toId != null &&
        _fromId != _toId &&
        amount != null &&
        amount > 0;
  }

  Future<void> _submit() async {
    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    final fee = int.tryParse(_feeCtrl.text.replaceAll(',', ''));
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    final dateStr =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    _setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.createTransfer(
        fromAssetRowId: _fromId!,
        toAssetRowId: _toId!,
        amount: amount,
        fee: fee,
        description: desc,
        transferDate: dateStr,
      );
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이체가 완료되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final assetsAsync = ref.watch(assetsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return assetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(PSpace.x16),
        child: Text('자산 로드 실패: $e',
            style: PTypo.bodySm.copyWith(color: t.statusDanger)),
      ),
      data: (assets) {
        if (assets.length < 2) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x24),
            child: Center(
              child: Text('이체하려면 자산이 2개 이상 필요합니다',
                  style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
            ),
          );
        }
        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, 0, PSpace.x16, PSpace.x16),
          children: [
              _Label('출금 자산'),
              const SizedBox(height: PSpace.x4),
              _AssetSelector(
                  assets: assets,
                  selectedId: _fromId,
                  onChanged: (id) => setState(() => _fromId = id),
                  tokens: t),
              const SizedBox(height: PSpace.x12),
              Center(
                  child:
                      Icon(LucideIcons.arrowDown, size: 20, color: t.fgTertiary)),
              const SizedBox(height: PSpace.x12),
              _Label('입금 자산'),
              const SizedBox(height: PSpace.x4),
              _AssetSelector(
                  assets: assets,
                  selectedId: _toId,
                  onChanged: (id) => setState(() => _toId = id),
                  tokens: t),
              if (_fromId != null && _fromId == _toId)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('출금/입금 자산은 달라야 합니다',
                      style: PTypo.caption.copyWith(color: t.statusDanger)),
                ),
              const SizedBox(height: PSpace.x16),

              _Label('금액'),
              const SizedBox(height: PSpace.x4),
              PTextInput(
                controller: _amountCtrl,
                numbersOnly: true,
                style: PTypo.h3,
                placeholder: '0',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: PSpace.x16),

              _Label('수수료 (선택)'),
              const SizedBox(height: PSpace.x4),
              PTextInput(
                controller: _feeCtrl,
                numbersOnly: true,
                placeholder: '0',
              ),
              const SizedBox(height: PSpace.x16),

              _Label('날짜'),
              const SizedBox(height: PSpace.x4),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030, 12, 31),
                  );
                  if (p != null) setState(() => _date = p);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.bgMuted,
                    borderRadius: PRadius.brMd,
                    border: Border.all(color: t.borderDefault),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 18, color: t.fgSecondary),
                      const SizedBox(width: PSpace.x8),
                      Text(
                          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                          style: PTypo.body.copyWith(color: t.fgPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: PSpace.x16),

              _Label('메모 (선택)'),
              const SizedBox(height: PSpace.x4),
              PTextInput(
                controller: _descCtrl,
                placeholder: '메모',
              ),
            ],
          );
        },
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

class _AssetSelector extends StatelessWidget {
  const _AssetSelector({
    required this.assets,
    required this.selectedId,
    required this.onChanged,
    required this.tokens,
  });
  final List<Asset> assets;
  final int? selectedId;
  final ValueChanged<int> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return PSelect<int>(
      value: selectedId,
      placeholder: '자산 선택',
      items: [
        for (final a in assets)
          PSelectItem<int>(value: a.rowId, label: a.assetName),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
