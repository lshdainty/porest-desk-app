import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/markdown_preview.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/todo_providers.dart';
import '../domain/todo.dart';

void showTodoEditDialog(BuildContext context, {Todo? edit}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '할 일 추가' : '할 일 수정',
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
  final Todo? edit;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _previewContent = false;
  late final TextEditingController _categoryCtrl;
  late String _priority;
  DateTime? _due;
  bool _submitting = false;
  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.edit?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.edit?.content ?? '');
    _categoryCtrl = TextEditingController(text: widget.edit?.category ?? '');
    _priority = widget.edit?.priority ?? 'MEDIUM';
    _due = widget.edit?.due;
    widget.controller.onSubmit = _submit;
    if (_isEdit) widget.controller.onDelete = _delete;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  bool get _canSubmit =>
      !_submitting && _titleCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: title,
          content:
              _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
          priority: _priority,
          category: _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
          dueDate: _due == null ? null : _fmtDate(_due!),
        );
      } else {
        await repo.create(
          title: title,
          content:
              _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
          priority: _priority,
          category: _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
          dueDate: _due == null ? null : _fmtDate(_due!),
        );
      }
      // invalidate every TodoFilter currently active is hard;
      // safest: invalidate the unfiltered one and let consumers refetch.
      ref.invalidate(todoListProvider);
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
      title: '할 일 삭제',
      message: '"${widget.edit!.title}" 을(를) 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(todoListProvider);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('제목', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _titleCtrl,
            placeholder: '예: 보고서 작성',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),

          Text('우선순위',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          _PriSeg(
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
              tokens: t),
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
                      initialDate: _due ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _due = d);
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
                        Text(_due == null ? '미설정' : _fmtDate(_due!),
                            style: PTypo.bodySm.copyWith(
                                color: _due == null
                                    ? t.fgPlaceholder
                                    : t.fgPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_due != null)
                PButton.icon(
                  icon: LucideIcons.x,
                  size: PButtonSize.sm,
                  iconColor: t.fgTertiary,
                  tooltip: '마감일 제거',
                  onPressed: () => setState(() => _due = null),
                ),
            ],
          ),
          const SizedBox(height: PSpace.x12),

          Text('카테고리 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _categoryCtrl,
            placeholder: '예: 업무, 개인',
          ),
          const SizedBox(height: PSpace.x12),

          Row(
            children: [
              Text('상세 내용 (선택)',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    setState(() => _previewContent = !_previewContent),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _previewContent
                              ? LucideIcons.pencil
                              : LucideIcons.eye,
                          size: 12,
                          color: t.fgSecondary),
                      const SizedBox(width: 4),
                      Text(_previewContent ? '편집' : '미리보기',
                          style: PTypo.caption.copyWith(
                              color: t.fgSecondary,
                              fontWeight: PFontWeight.semi)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          if (_previewContent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brSm,
                border: Border.all(color: t.borderSubtle),
              ),
              child: _contentCtrl.text.trim().isEmpty
                  ? Text('내용 없음',
                      style: PTypo.caption.copyWith(color: t.fgTertiary))
                  : MarkdownPreview(_contentCtrl.text),
            )
          else
            PTextInput(
              controller: _contentCtrl,
              maxLines: 6,
              placeholder: '예: # 제목 / **굵게** / - 항목 / - [ ] 체크',
            ),

          if (_isEdit) ...[
            const SizedBox(height: PSpace.x16),
            _SubtaskSection(parentId: widget.edit!.rowId, tokens: t),
          ],
      ],
    );
  }
}

class _PriSeg extends StatelessWidget {
  const _PriSeg(
      {required this.value, required this.onChanged, required this.tokens});
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    const opts = [('HIGH', '높음'), ('MEDIUM', '보통'), ('LOW', '낮음')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: tokens.bgMuted, borderRadius: PRadius.brMd),
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

/// Todo 서브태스크 섹션 (#323).
class _SubtaskSection extends ConsumerStatefulWidget {
  const _SubtaskSection({required this.parentId, required this.tokens});
  final int parentId;
  final PorestTokens tokens;
  @override
  ConsumerState<_SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends ConsumerState<_SubtaskSection> {
  final _ctrl = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _addSubtask() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.create(title: title);
      ref.invalidate(todoSubtasksProvider(widget.parentId));
      _ctrl.clear();
      setState(() => _adding = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      showPSnackBar(context, '추가 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _toggleStatus(Todo sub) async {
    final next =
        sub.status == 'COMPLETED' ? 'PENDING' : 'COMPLETED';
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.setStatus(sub.rowId, next);
      ref.invalidate(todoSubtasksProvider(widget.parentId));
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '상태 변경 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _deleteSubtask(int id) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.delete(id);
      ref.invalidate(todoSubtasksProvider(widget.parentId));
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final async = ref.watch(todoSubtasksProvider(widget.parentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('하위 작업',
            style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x4),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('하위 작업 로드 실패',
              style: PTypo.caption.copyWith(color: t.statusDanger)),
          data: (subs) {
            if (subs.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                for (final s in subs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        PButton.icon(
                          icon: s.status == 'COMPLETED'
                              ? LucideIcons.checkCircle
                              : LucideIcons.circle,
                          size: PButtonSize.sm,
                          iconColor: s.status == 'COMPLETED'
                              ? t.statusSuccess
                              : t.fgTertiary,
                          onPressed: () => _toggleStatus(s),
                        ),
                        Expanded(
                          child: Text(
                            s.title,
                            style: PTypo.bodySm.copyWith(
                              color: t.fgPrimary,
                              decoration: s.status == 'COMPLETED'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        PButton.icon(
                          icon: LucideIcons.x,
                          size: PButtonSize.sm,
                          iconColor: t.fgTertiary,
                          onPressed: () => _deleteSubtask(s.rowId),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: PTextInput(
                controller: _ctrl,
                enabled: !_adding,
                placeholder: '+ 하위 작업 추가',
                onSubmitted: (_) => _addSubtask(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 6),
            PButton(
              label: '추가',
              loading: _adding,
              onPressed:
                  (_ctrl.text.trim().isEmpty || _adding) ? null : _addSubtask,
            ),
          ],
        ),
      ],
    );
  }
}
