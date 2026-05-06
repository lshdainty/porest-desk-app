import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../application/todo_providers.dart';
import '../domain/todo.dart';
import 'todo_edit_dialog.dart';

/// Todo 칸반 보드 — front `KanbanBoard` 미러.
///
/// 3개 컬럼 (PENDING / IN_PROGRESS / COMPLETED). 카드를 컬럼간 drag-and-drop 하면
/// `setStatus` 호출.
class TodoKanbanView extends ConsumerStatefulWidget {
  const TodoKanbanView({super.key, required this.priority});
  final String? priority;
  @override
  ConsumerState<TodoKanbanView> createState() => _TodoKanbanViewState();
}

class _TodoKanbanViewState extends ConsumerState<TodoKanbanView> {
  static const _columns = <(String code, String label, IconData icon)>[
    ('PENDING', '대기', LucideIcons.circle),
    ('IN_PROGRESS', '진행중', LucideIcons.arrowRightCircle),
    ('COMPLETED', '완료', LucideIcons.checkCircle),
  ];

  Future<void> _moveTo(Todo todo, String status) async {
    if (todo.status == status) return;
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.setStatus(todo.rowId, status);
      // 모든 status 의 todoListProvider 가족을 invalidate.
      ref.invalidate(todoListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이동 실패: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 전체 todo 한 번에 fetch (status=null) 후 클라이언트 분류.
    final async = ref.watch(
        todoListProvider((status: null, priority: widget.priority)));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(PSpace.x16),
        child: Text('할 일 로드 실패\n$e',
            style: PTypo.bodySm.copyWith(color: t.statusDanger)),
      ),
      data: (all) {
        Map<String, List<Todo>> byStatus = {
          for (final c in _columns) c.$1: <Todo>[],
        };
        for (final t in all) {
          final s = t.status ?? 'PENDING';
          (byStatus[s] ??= <Todo>[]).add(t);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
              PSpace.x12, PSpace.x12, PSpace.x12, PSpace.x80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final col in _columns)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 280,
                    child: _Column(
                      status: col.$1,
                      label: col.$2,
                      icon: col.$3,
                      items: byStatus[col.$1] ?? const [],
                      onAccept: (todo) => _moveTo(todo, col.$1),
                      tokens: t,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.status,
    required this.label,
    required this.icon,
    required this.items,
    required this.onAccept,
    required this.tokens,
  });
  final String status;
  final String label;
  final IconData icon;
  final List<Todo> items;
  final void Function(Todo) onAccept;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Todo>(
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (ctx, candidate, _) {
        final highlighted = candidate.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlighted ? tokens.bgBrandSubtle : tokens.bgMuted,
            borderRadius: PRadius.brMd,
            border: Border.all(
              color: highlighted ? tokens.borderBrand : tokens.borderSubtle,
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: tokens.fgSecondary),
                  const SizedBox(width: 6),
                  Text(label,
                      style: PTypo.bodySm.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.bgSurface,
                      borderRadius: PRadius.brXs,
                    ),
                    child: Text('${items.length}',
                        style: PTypo.caption.copyWith(
                            color: tokens.fgSecondary,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('비어있음',
                        style:
                            PTypo.caption.copyWith(color: tokens.fgTertiary)),
                  ),
                )
              else
                for (final t in items) _Card(todo: t, tokens: tokens),
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.todo, required this.tokens});
  final Todo todo;
  final PorestTokens tokens;

  Color _priColor(String? p) => switch (p) {
        'HIGH' => tokens.statusDanger,
        'MEDIUM' => tokens.statusWarning,
        'LOW' => tokens.statusInfo,
        _ => tokens.fgTertiary,
      };

  @override
  Widget build(BuildContext context) {
    final cardWidget = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: PRadius.brSm,
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if ((todo.priority ?? '').isNotEmpty) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: _priColor(todo.priority),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(todo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if ((todo.dueDate ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 11, color: tokens.fgTertiary),
                  const SizedBox(width: 4),
                  Text(todo.dueDate!,
                      style: PTypo.micro.copyWith(color: tokens.fgTertiary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: () => showTodoEditDialog(context, edit: todo),
      child: LongPressDraggable<Todo>(
        data: todo,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: SizedBox(width: 260, child: cardWidget),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: cardWidget),
        child: cardWidget,
      ),
    );
  }
}
