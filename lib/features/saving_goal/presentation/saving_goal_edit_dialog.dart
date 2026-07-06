import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';

void showSavingGoalEditDialog(BuildContext context, {SavingGoal? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.savingGoalAdd : l.savingGoalEdit,
    contentBuilder: (ctx, scrollCtrl) => _Body(
      edit: edit,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? l.savingGoalSubmitAdd : l.actionEdit,
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final SavingGoal? edit;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _deadline;
  late String _color;
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
    final editColor = widget.edit?.color?.toLowerCase();
    _color = editColor != null && kChartBaseHexes.contains(editColor)
        ? editColor
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
    final l = AppLocalizations.of(context);
    _setSubmitting(true);
    try {
      final repo = await ref.read(savingGoalRepositoryProvider.future);
      final amt = int.parse(_amountCtrl.text.replaceAll(',', ''));
      final color = _color;
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
      showPSnackBar(context, '${l.savingGoalActionFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.savingGoalDeleteTitle,
      message: l.savingGoalDeleteConfirm(widget.edit!.title),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(savingGoalRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(savingGoalListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.savingGoalDeleteFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text(l.savingGoalNameLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _titleCtrl,
            placeholder: l.savingGoalNameHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),
          Text(l.savingGoalAmountLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _amountCtrl,
            numbersOnly: true,
            style: PTypo.h3,
            placeholder: '0',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),
          Text(l.savingGoalDeadlineLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PDateInput(
            value: _deadline,
            onChanged: (d) => setState(() => _deadline = d),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            placeholder: l.savingGoalDeadlineHint,
            allowClear: true,
          ),
          const SizedBox(height: PSpace.x16),
          Text(l.savingGoalColorLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          PColorPicker(
            selected: _color,
            onChanged: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: PSpace.x12),
          Text(l.savingGoalDescLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _descCtrl,
            maxLines: 2,
            placeholder: l.savingGoalDescHint,
          ),
      ],
    );
  }
}
