import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/markdown_preview.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_meta.dart';

void showTodoEditDialog(BuildContext context, {Todo? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.todoAdd : l.todoEditTitle,
    // 컨텐츠 높이에 맞춰 wrap (web 다이얼로그처럼) — 기본 0.85 강제 높이 사용 X.
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _Body(
      edit: edit,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? l.calAdd : l.actionEdit,
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.controller,
  });
  final Todo? edit;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _previewContent = false;
  // 제목 입력 인터랙션 후에만 인라인 에러 노출.
  bool _titleTouched = false;
  // 태그 = 기존 category 필드(자유 텍스트 → select 7종). 저장은 category 로.
  late String _tag;
  late String _priority;
  DateTime? _due;
  bool _submitting = false;
  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.edit?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.edit?.content ?? '');
    _tag = todoTagOrDefault(widget.edit?.category);
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
          category: _tag, // 태그 7종을 기존 category 필드에 저장
          dueDate: _due == null ? null : _fmtDate(_due!),
        );
      } else {
        await repo.create(
          title: title,
          content:
              _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
          priority: _priority,
          category: _tag,
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
      showPSnackBar(context, '${AppLocalizations.of(context).todoActionFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.todoDeleteTitle,
      message: l.todoDeleteConfirm(widget.edit!.title),
      confirmLabel: l.actionDelete,
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
      showPSnackBar(context, '${AppLocalizations.of(context).todoDeleteFailed}: ${e.message}', severity: PSnackSeverity.error);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.calFieldTitle, style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _titleCtrl,
            placeholder: l.todoTitlePlaceholder,
            onChanged: (_) => setState(() => _titleTouched = true),
            errorText: _titleCtrl.text.trim().isEmpty && _titleTouched
                ? l.todoTitleRequired
                : null,
          ),
          const SizedBox(height: PSpace.x12),

          // 마감일 + 태그 2열.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.todoDueDate,
                        style:
                            PTypo.caption.copyWith(color: t.fgSecondary)),
                    const SizedBox(height: PSpace.x4),
                    PDateInput(
                      value: _due,
                      onChanged: (d) => setState(() => _due = d),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      placeholder: l.todoUnset,
                      allowClear: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.todoTag,
                        style:
                            PTypo.caption.copyWith(color: t.fgSecondary)),
                    const SizedBox(height: PSpace.x4),
                    PSelect<String>(
                      value: _tag,
                      title: l.todoTagSelect,
                      items: [
                        for (final tag in kTodoTags)
                          PSelectItem<String>(value: tag, label: tag),
                      ],
                      onChanged: (v) =>
                          setState(() => _tag = v ?? kTodoDefaultTag),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),

          Text(l.todoPriorityLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          _PriSeg(
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
              tokens: t),
          const SizedBox(height: PSpace.x12),

          Row(
            children: [
              Text(l.todoContentLabel,
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
                      Text(_previewContent ? l.todoEditMode : l.todoPreview,
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
                  ? Text(l.todoNoContent,
                      style: PTypo.caption.copyWith(color: t.fgTertiary))
                  : MarkdownPreview(_contentCtrl.text),
            )
          else
            PTextInput(
              controller: _contentCtrl,
              maxLines: 6,
              placeholder: l.todoContentPlaceholder,
            ),

          if (_isEdit) ...[
            const SizedBox(height: PSpace.x16),
            _SubtaskSection(parentId: widget.edit!.rowId, tokens: t),
          ],
        ],
      ),
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
    final l = AppLocalizations.of(context);
    final opts = [('HIGH', l.todoPriorityImportant), ('MEDIUM', l.todoPriorityMedium), ('LOW', l.todoPriorityRelaxed)];
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
      showPSnackBar(context, '${AppLocalizations.of(context).todoAddFailed}: ${e.message}', severity: PSnackSeverity.error);
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
      showPSnackBar(context, '${AppLocalizations.of(context).todoStatusChangeFailed}: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _deleteSubtask(int id) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.delete(id);
      ref.invalidate(todoSubtasksProvider(widget.parentId));
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${AppLocalizations.of(context).todoDeleteFailed}: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final l = AppLocalizations.of(context);
    final async = ref.watch(todoSubtasksProvider(widget.parentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.todoSubtask,
            style: PTypo.caption.copyWith(color: t.fgSecondary)),
        const SizedBox(height: PSpace.x4),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: PCircularProgressIndicator()),
          ),
          error: (e, _) => Text(l.todoSubtaskLoadError,
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
                placeholder: l.todoSubtaskAddHint,
                onSubmitted: (_) => _addSubtask(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 6),
            PButton(
              label: l.calAdd,
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
