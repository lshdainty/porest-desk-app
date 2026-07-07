import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/domain/memo_colors.dart';

/// 태그 select 옵션 7종 고정 (web `MemoEditDialog` select 미러). 기본값 '개인'.
const kMemoTags = <String>['가계부', '자산', '업무', '개인', '건강', '결제', '고정비'];
const kMemoDefaultTag = '개인';

void showMemoEditDialog(BuildContext context, {Memo? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.memoNew : l.memoEditTitle,
    contentBuilder: (ctx, scrollCtrl) => _Body(
      edit: edit,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.actionSave,
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final Memo? edit;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late String _tag;
  late String _color;
  late bool _pinned;
  bool _submitting = false;
  bool _titleError = false;
  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _tag = (e?.tag ?? '').isNotEmpty ? e!.tag! : kMemoDefaultTag;
    _color = memoColorOrDefault(e?.color);
    _pinned = e?.pinned ?? false;
    widget.controller.onSubmit = _submit;
    if (_isEdit) widget.controller.onDelete = _delete;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  // 저장 버튼은 항상 활성 — 제목 검증은 submit 시 인라인 에러로 처리(web 동작 미러).
  bool get _canSubmit => !_submitting;

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }
    final content = _contentCtrl.text.trim();
    _setSubmitting(true);
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      // 새 UI 는 폴더 폐기 — folderId 미전송.
      final pinChanged = (widget.edit?.pinned ?? false) != _pinned;
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: title,
          content: content.isEmpty ? null : content,
          tag: _tag,
          color: _color,
        );
        // pin 은 별도 토글 엔드포인트 — 변경 시에만 호출.
        if (pinChanged) await repo.pin(widget.edit!.rowId);
      } else {
        final created = await repo.create(
          title: title,
          content: content.isEmpty ? null : content,
          tag: _tag,
          color: _color,
        );
        if (_pinned) await repo.pin(created.rowId);
      }
      ref.invalidate(memoListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, l.memoActionFailed(e.message),
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.memoDeleteTitle,
      message: l.memoDeleteConfirm,
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(memoListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, l.memoDeleteFailed(e.message),
          severity: PSnackSeverity.error);
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
        // 제목 (필수).
        PSectionLabel(l.memoFieldTitle),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _titleCtrl,
          placeholder: l.memoFieldTitle,
          autofocus: !_isEdit,
          errorText: _titleError ? l.memoTitleRequired : null,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: PFontWeight.bold),
          onChanged: (_) {
            if (_titleError) setState(() => _titleError = false);
          },
        ),
        const SizedBox(height: PSpace.x16),

        // 내용.
        PSectionLabel(l.memoFieldContent),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _contentCtrl,
          placeholder: l.memoContentPlaceholder,
          maxLines: 12,
          minLines: 8,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: PSpace.x16),

        // 태그 + 고정 2열.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PSectionLabel(l.memoFieldTag),
                  const SizedBox(height: PSpace.x4),
                  PSelect<String>(
                    value: _tag,
                    title: l.memoFieldTag,
                    items: [
                      for (final tag in kMemoTags)
                        PSelectItem<String>(value: tag, label: tag),
                    ],
                    onChanged: (v) =>
                        setState(() => _tag = v ?? kMemoDefaultTag),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PSectionLabel(l.memoPin),
                  const SizedBox(height: PSpace.x4),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        PSwitch(
                          value: _pinned,
                          semanticLabel: l.memoPinToTop,
                          onChanged: (v) => setState(() => _pinned = v),
                        ),
                        Expanded(
                          child: Text(
                            l.memoPinToTop,
                            style:
                                PTypo.body.copyWith(color: t.fgPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // 색상 — chart palette base hex 저장.
        PSectionLabel(l.memoFieldColor),
        const SizedBox(height: PSpace.x8),
        PColorPicker(
          selected: _color,
          onChanged: (c) => setState(() => _color = c),
        ),
      ],
    );
  }
}
