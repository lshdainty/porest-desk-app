import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/memo_providers.dart';
import '../domain/memo.dart';

void showMemoEditDialog(BuildContext context, {Memo? edit}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '메모 추가' : '메모 수정',
    contentBuilder: (ctx, scrollCtrl) => _Body(
      edit: edit,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? '저장' : '수정',
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
  bool _submitting = false;
  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.edit?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.edit?.content ?? '');
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

  bool get _canSubmit {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    return !_submitting && (title.isNotEmpty || content.isNotEmpty);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    _setSubmitting(true);
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: title.isEmpty ? null : title,
          content: content.isEmpty ? null : content,
        );
      } else {
        await repo.create(
          title: title.isEmpty ? null : title,
          content: content.isEmpty ? null : content,
        );
      }
      ref.invalidate(memoListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
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
      title: '메모 삭제',
      message: '이 메모를 삭제할까요?',
      confirmLabel: '삭제',
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
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        PTextInput(
          controller: _titleCtrl,
          placeholder: '제목',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: PFontWeight.bold),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _contentCtrl,
          placeholder: '내용을 입력하세요...',
          maxLines: 12,
          minLines: 6,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
