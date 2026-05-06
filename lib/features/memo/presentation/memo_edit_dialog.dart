import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../application/memo_providers.dart';
import '../domain/memo.dart';

void showMemoEditDialog(BuildContext context, {Memo? edit}) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(edit == null ? '메모 추가' : '메모 수정'),
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
  final Memo? edit;
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
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) return;
    setState(() => _submitting = true);
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
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제할까요?'),
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
      final repo = await ref.read(memoRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(memoListProvider);
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
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: '제목',
              border: InputBorder.none,
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: t.fgPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: PSpace.x8),
          TextField(
            controller: _contentCtrl,
            decoration: const InputDecoration(
              hintText: '내용을 입력하세요...',
              border: InputBorder.none,
            ),
            maxLines: 12,
            minLines: 6,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: t.fgPrimary),
          ),
          const SizedBox(height: PSpace.x16),
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
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? '수정' : '저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
