import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_meta.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_actions.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/markdown_preview.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 할 일 상세 시트 — 행 탭 → 읽기 전용 상세 → 수정 버튼 → 편집 폼.
/// tx_detail_dialog(웹 TxDetailDialog) 패턴 미러: hero + field rows + 뷰 footer.
void showTodoDetailDialog(BuildContext context, Todo todo) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.todoDetailTitle,
    contentBuilder: (ctx, scrollCtrl) => _DetailBody(
      todo: todo,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => _DetailFooter(todo: todo, controller: controller),
  ).whenComplete(controller.dispose);
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({required this.todo, required this.controller});
  final Todo todo;
  final PSheetController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final busy = controller.submitting;
        return PViewFooter(
          onDelete: controller.onDelete,
          deleting: busy,
          onEdit: busy
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  showTodoEditDialog(ctx, edit: todo);
                },
          onConfirm: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.todo,
    required this.scrollController,
    required this.controller,
  });
  final Todo todo;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.onDelete = _delete;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.todoDeleteTitle,
      message: todoActions.deleteConfirmMessage(context, widget.todo),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    widget.controller.setSubmitting(true);
    try {
      // 삭제는 todoActions 가 한다 — 목록 행(스와이프)도 같은 것을 부른다.
      final deleted = await todoActions.delete(context, ref, widget.todo);
      if (deleted && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) widget.controller.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final todo = widget.todo;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prio = todoPrioOf(todo.priority);
    final prioColor = prio.color(context);
    final prioBg = prio.bg(context);
    final overdue = !todo.done && isTodoOverdue(todo.due, today);
    final overdueColor = todoOverdueColor(context);
    final content = (todo.content ?? '').trim();
    final completedAt = (todo.completedAt ?? '').length >= 16
        ? todo.completedAt!.substring(0, 16).replaceFirst('T', ' ')
        : todo.completedAt;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x16),
      children: [
        // Hero — 우선순위 틴트
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [prioBg, t.bgSurface],
              stops: const [0.0, 0.85],
            ),
            border: Border.all(color: prioColor.withValues(alpha: 0.2)),
            borderRadius: PRadius.brXl,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: prioBg,
                  borderRadius: PRadius.tile(40),
                ),
                alignment: Alignment.center,
                child: Icon(
                  todo.done ? LucideIcons.checkCheck : LucideIcons.circleDot,
                  size: 20,
                  color: prioColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                todo.title,
                textAlign: TextAlign.center,
                style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.3,
                  decoration: todo.done ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                todoRelativeDate(l, todo.due, today),
                style: PTypo.caption.copyWith(
                  color: overdue ? overdueColor : t.fgTertiary,
                  fontWeight: overdue ? PFontWeight.semi : PFontWeight.regular,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Field rows
        Container(
          decoration: BoxDecoration(
            color: t.borderSubtle,
            border: Border.all(color: t.borderSubtle),
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              _FieldRow(
                label: l.todoDueDate,
                tokens: t,
                isFirst: true,
                child: Text(
                  todo.dueDate ?? l.todoNoDue,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
              _FieldRow(
                label: l.todoTag,
                tokens: t,
                child: Text(
                  todoTagOrDefault(todo.category),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
              _FieldRow(
                label: l.todoPriorityLabel,
                tokens: t,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: prioBg,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    todoPrioLabel(l, todo.priority),
                    style: PTypo.micro.copyWith(
                      color: prioColor,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ),
              ),
              _FieldRow(
                label: l.todoDetailStatus,
                tokens: t,
                isLast: todo.completedAt == null || !todo.done,
                child: Text(
                  todo.done ? l.todoStatusCompleted : l.todoStatusPending,
                  style: PTypo.bodySm.copyWith(
                    color: todo.done ? t.fgBrand : t.fgSecondary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ),
              if (todo.done && completedAt != null)
                _FieldRow(
                  label: l.todoDetailCompletedAt,
                  tokens: t,
                  isLast: true,
                  child: Text(
                    completedAt,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // 상세 내용 (markdown)
        Text(
          l.todoDetailContent,
          style: PTypo.caption.copyWith(
            color: t.fgTertiary,
            fontWeight: PFontWeight.semi,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PSpace.x16),
          decoration: BoxDecoration(
            color: t.bgSurface,
            border: Border.all(color: t.borderSubtle),
            borderRadius: PRadius.brLg,
          ),
          child: content.isEmpty
              ? Text(
                  l.todoNoContent,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                )
              : MarkdownPreview(content),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.child,
    required this.tokens,
    this.isFirst = false,
    this.isLast = false,
  });
  final String label;
  final Widget child;
  final PorestTokens tokens;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(PRadius.lg) : Radius.zero,
          bottom: isLast ? const Radius.circular(PRadius.lg) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: PTypo.caption.copyWith(color: tokens.fgTertiary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}
