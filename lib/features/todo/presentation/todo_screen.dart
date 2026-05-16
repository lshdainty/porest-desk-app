import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/todo_providers.dart';
import '../domain/todo.dart';
import 'todo_edit_dialog.dart';
import 'todo_kanban_view.dart';
import 'todo_project_management_dialog.dart';
import 'todo_tag_management_dialog.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  String? _statusFilter; // null = 전체, PENDING, IN_PROGRESS, COMPLETED
  String? _priorityFilter; // null = 전체, HIGH, MEDIUM, LOW
  bool _kanban = false;
  final _quickAddCtrl = TextEditingController();
  bool _quickAdding = false;

  TodoFilter get _filter =>
      (status: _statusFilter, priority: _priorityFilter);

  @override
  void dispose() {
    _quickAddCtrl.dispose();
    super.dispose();
  }

  Future<void> _quickAdd() async {
    final title = _quickAddCtrl.text.trim();
    if (title.isEmpty || _quickAdding) return;
    setState(() => _quickAdding = true);
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.create(title: title, priority: _priorityFilter);
      _quickAddCtrl.clear();
      ref.invalidate(todoListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '추가 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _quickAdding = false);
    }
  }

  Future<void> _toggleDone(Todo t) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.setStatus(t.rowId, t.done ? 'PENDING' : 'COMPLETED');
      ref.invalidate(todoListProvider(_filter));
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _pin(Todo t) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.pin(t.rowId);
      ref.invalidate(todoListProvider(_filter));
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final listAsync = ref.watch(todoListProvider(_filter));

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('할 일'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PButton.icon(
            icon: _kanban ? LucideIcons.list : LucideIcons.layoutGrid,
            tooltip: _kanban ? '리스트 보기' : '칸반 보기',
            onPressed: () => setState(() => _kanban = !_kanban),
          ),
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: t.fgSecondary),
            onSelected: (v) {
              switch (v) {
                case 'projects':
                  showTodoProjectManagementDialog(context);
                  break;
                case 'tags':
                  showTodoTagManagementDialog(context);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'projects', child: Text('프로젝트 관리')),
              PopupMenuItem(value: 'tags', child: Text('태그 관리')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, 0, PSpace.x16, PSpace.x8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 빠른 추가 (#327)
                Row(
                  children: [
                    Expanded(
                      child: PTextInput(
                        controller: _quickAddCtrl,
                        enabled: !_quickAdding,
                        placeholder: '빠른 할 일 추가',
                        prefix: Icon(LucideIcons.plus,
                            size: 16, color: t.fgTertiary),
                        onSubmitted: (_) => _quickAdd(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_quickAddCtrl.text.trim().isNotEmpty || _quickAdding) ...[
                      const SizedBox(width: 6),
                      PButton(
                        label: '추가',
                        loading: _quickAdding,
                        onPressed: _quickAdding ? null : _quickAdd,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PChip(
                        label: '전체',
                        selected: _statusFilter == null,
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 6),
                      PChip(
                        label: '진행중',
                        selected: _statusFilter == 'IN_PROGRESS',
                        onTap: () => setState(
                            () => _statusFilter = 'IN_PROGRESS'),
                      ),
                      const SizedBox(width: 6),
                      PChip(
                        label: '대기',
                        selected: _statusFilter == 'PENDING',
                        onTap: () =>
                            setState(() => _statusFilter = 'PENDING'),
                      ),
                      const SizedBox(width: 6),
                      PChip(
                        label: '완료',
                        selected: _statusFilter == 'COMPLETED',
                        onTap: () =>
                            setState(() => _statusFilter = 'COMPLETED'),
                      ),
                      const SizedBox(width: 14),
                      PChip(
                        label: '우선순위',
                        selected: _priorityFilter == null,
                        onTap: () =>
                            setState(() => _priorityFilter = null),
                      ),
                      const SizedBox(width: 6),
                      PChip(
                        label: 'HIGH',
                        selected: _priorityFilter == 'HIGH',
                        onTap: () =>
                            setState(() => _priorityFilter = 'HIGH'),
                      ),
                      const SizedBox(width: 6),
                      PChip(
                        label: 'MEDIUM',
                        selected: _priorityFilter == 'MEDIUM',
                        onTap: () =>
                            setState(() => _priorityFilter = 'MEDIUM'),
                      ),
                      const SizedBox(width: 6),
                      PChip(
                        label: 'LOW',
                        selected: _priorityFilter == 'LOW',
                        onTap: () =>
                            setState(() => _priorityFilter = 'LOW'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        onPressed: () => showTodoEditDialog(context),
      ),
      body: _kanban
          ? const TodoKanbanView(priority: null)
          : RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(todoListProvider(_filter));
          await ref.read(todoListProvider(_filter).future);
        },
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('할 일 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: const [
                PEmptyState(
                  icon: LucideIcons.checkSquare,
                  message: '할 일이 없습니다',
                ),
              ]);
            }
            final sorted = [...items]..sort((a, b) {
                if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
                if (a.done != b.done) return a.done ? 1 : -1;
                return (a.due ?? DateTime(2100))
                    .compareTo(b.due ?? DateTime(2100));
              });
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x80),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    borderRadius: PRadius.brLg,
                    border: Border.all(color: t.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < sorted.length; i++) ...[
                        _TodoRow(
                          todo: sorted[i],
                          tokens: t,
                          onToggle: () => _toggleDone(sorted[i]),
                          onPin: () => _pin(sorted[i]),
                          onTap: () => showTodoEditDialog(context,
                              edit: sorted[i]),
                        ),
                        if (i < sorted.length - 1)
                          Divider(
                              height: 1,
                              color: t.borderSubtle,
                              indent: 48),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.tokens,
    required this.onToggle,
    required this.onPin,
    required this.onTap,
  });
  final Todo todo;
  final PorestTokens tokens;
  final VoidCallback onToggle;
  final VoidCallback onPin;
  final VoidCallback onTap;

  Color _priorityColor(PorestTokens t) => switch (todo.priority) {
        'HIGH' => t.statusDanger,
        'MEDIUM' => t.statusWarning,
        'LOW' => t.statusInfo,
        _ => t.fgTertiary,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x12, vertical: PSpace.x12),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: todo.done ? tokens.statusSuccess : Colors.transparent,
                  borderRadius: PRadius.brSm,
                  border: Border.all(
                      color: todo.done
                          ? tokens.statusSuccess
                          : tokens.borderStrong,
                      width: 1.5),
                ),
                child: todo.done
                    ? const Icon(LucideIcons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: _priorityColor(tokens),
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          todo.title,
                          style: PTypo.body.copyWith(
                            color: todo.done
                                ? tokens.fgTertiary
                                : tokens.fgPrimary,
                            fontWeight: PFontWeight.semi,
                            decoration: todo.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if ((todo.dueDate ?? '').isNotEmpty ||
                      (todo.category ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if ((todo.dueDate ?? '').isNotEmpty)
                          '~${todo.dueDate}',
                        if ((todo.category ?? '').isNotEmpty)
                          todo.category!,
                      ].join(' · '),
                      style: PTypo.caption
                          .copyWith(color: tokens.fgTertiary),
                    ),
                  ],
                ],
              ),
            ),
            PButton.icon(
              icon: LucideIcons.pin,
              size: PButtonSize.sm,
              iconColor:
                  todo.pinned ? tokens.fgBrand : tokens.fgTertiary,
              tooltip: todo.pinned ? '고정 해제' : '고정',
              onPressed: onPin,
            ),
          ],
        ),
      ),
    );
  }
}
