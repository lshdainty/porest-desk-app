import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../application/todo_providers.dart';
import '../domain/todo.dart';
import 'todo_edit_dialog.dart';
import 'todo_project_management_dialog.dart';
import 'todo_tag_management_dialog.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  String? _statusFilter; // null = 전체, PENDING, IN_PROGRESS, COMPLETED

  TodoFilter get _filter => (status: _statusFilter, priority: null);

  Future<void> _toggleDone(Todo t) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.setStatus(t.rowId, t.done ? 'PENDING' : 'COMPLETED');
      ref.invalidate(todoListProvider(_filter));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    }
  }

  Future<void> _pin(Todo t) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.pin(t.rowId);
      ref.invalidate(todoListProvider(_filter));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
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
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, 0, PSpace.x16, PSpace.x8),
            child: Row(
              children: [
                _Chip(
                  label: '전체',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                  tokens: t,
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: '진행중',
                  selected: _statusFilter == 'IN_PROGRESS',
                  onTap: () =>
                      setState(() => _statusFilter = 'IN_PROGRESS'),
                  tokens: t,
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: '대기',
                  selected: _statusFilter == 'PENDING',
                  onTap: () => setState(() => _statusFilter = 'PENDING'),
                  tokens: t,
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: '완료',
                  selected: _statusFilter == 'COMPLETED',
                  onTap: () =>
                      setState(() => _statusFilter = 'COMPLETED'),
                  tokens: t,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () => showTodoEditDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
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
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(PSpace.x32),
                  child: Column(children: [
                    Icon(LucideIcons.checkSquare,
                        size: 48, color: t.fgDisabled),
                    const SizedBox(height: PSpace.x12),
                    Text('할 일이 없습니다',
                        style: PTypo.body.copyWith(color: t.fgTertiary)),
                  ]),
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

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.tokens});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrand : tokens.bgSurface,
          border: Border.all(
              color: selected ? tokens.borderBrand : tokens.borderSubtle),
          borderRadius: PRadius.brPill,
        ),
        child: Text(label,
            style: PTypo.caption.copyWith(
                color: selected ? tokens.fgOnBrand : tokens.fgSecondary,
                fontWeight: FontWeight.w600)),
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
                  borderRadius: BorderRadius.circular(6),
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
                            fontWeight: FontWeight.w600,
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
            IconButton(
              onPressed: onPin,
              icon: Icon(LucideIcons.pin,
                  size: 14,
                  color: todo.pinned ? tokens.fgBrand : tokens.fgTertiary),
              tooltip: todo.pinned ? '고정 해제' : '고정',
              visualDensity: VisualDensity.compact,
              constraints:
                  const BoxConstraints.tightFor(width: 28, height: 28),
            ),
          ],
        ),
      ),
    );
  }
}
