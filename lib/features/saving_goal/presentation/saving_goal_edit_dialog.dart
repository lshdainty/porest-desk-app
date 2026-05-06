import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../category/presentation/category_palette.dart';
import '../application/saving_goal_providers.dart';
import '../domain/saving_goal.dart';

void showSavingGoalEditDialog(BuildContext context, {SavingGoal? edit}) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(edit == null ? '저금 목표 추가' : '저금 목표 수정'),
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
  final SavingGoal? edit;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _deadline;
  late int _paletteIdx;
  bool _submitting = false;
  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.edit?.title ?? '');
    _amountCtrl = TextEditingController(
        text: widget.edit?.targetAmount.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.edit?.description ?? '');
    _deadline = widget.edit?.deadlineDate == null
        ? null
        : DateTime.tryParse(widget.edit!.deadlineDate!);
    _paletteIdx = CatPalette.indexByColor(widget.edit?.color) ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _canSubmit {
    if (_submitting) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    final amt = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    return amt != null && amt > 0;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(savingGoalRepositoryProvider.future);
      final amt = int.parse(_amountCtrl.text.replaceAll(',', ''));
      final color = CatPalette.all[_paletteIdx].toHex();
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          targetAmount: amt,
          deadlineDate: _deadline == null ? null : _fmtDate(_deadline!),
          color: color,
          icon: 'piggy-bank',
        );
      } else {
        await repo.create(
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          targetAmount: amt,
          deadlineDate: _deadline == null ? null : _fmtDate(_deadline!),
          color: color,
          icon: 'piggy-bank',
        );
      }
      ref.invalidate(savingGoalListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
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
        title: const Text('저금 목표 삭제'),
        content: Text('"${widget.edit!.title}"을(를) 삭제할까요?'),
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
      final repo = await ref.read(savingGoalRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(savingGoalListProvider);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('목표 이름',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: '예: 비상금'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),
          Text('목표 금액',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: PTypo.h3.copyWith(color: t.fgPrimary),
            decoration: const InputDecoration(hintText: '0'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),
          Text('마감일 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _deadline ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _deadline = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.bgMuted,
                      borderRadius: PRadius.brMd,
                      border: Border.all(color: t.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar,
                            size: 16, color: t.fgSecondary),
                        const SizedBox(width: 6),
                        Text(_deadline == null ? '미설정' : _fmtDate(_deadline!),
                            style: PTypo.bodySm.copyWith(
                                color: _deadline == null
                                    ? t.fgPlaceholder
                                    : t.fgPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_deadline != null)
                IconButton(
                  onPressed: () => setState(() => _deadline = null),
                  icon: Icon(LucideIcons.x,
                      size: 16, color: t.fgTertiary),
                ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          Text('색상',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < CatPalette.all.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _paletteIdx = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CatPalette.all[i].color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: i == _paletteIdx
                              ? t.fgPrimary
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: i == _paletteIdx
                        ? const Icon(LucideIcons.check,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          Text('설명 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
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
