import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

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
      showPSnackBar(context, '이동 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 전체 todo 한 번에 fetch (status=null) 후 클라이언트 분류.
    final async = ref.watch(
        todoListProvider((status: null, priority: widget.priority)));

    return async.when(
      loading: () => _KanbanSkeleton(columns: _columns, tokens: t),
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

/// 칸반 보드 skeleton — 정적 보드 틀(컬럼 shell + 실제 헤더 아이콘/라벨)은
/// 그대로 렌더하고, 데이터 영역(카운트 배지 + 카드 목록)만 placeholder.
/// 컬럼 shell·카드 치수는 로딩 후 [_Column]/[_Card]와 1:1 정합.
class _KanbanSkeleton extends StatelessWidget {
  const _KanbanSkeleton({required this.columns, required this.tokens});
  final List<(String code, String label, IconData icon)> columns;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        PSpace.x12,
        PSpace.x12,
        PSpace.x12,
        PSpace.x80,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 280,
                // 실제 _Column shell 정합: bgMuted + borderSubtle + brMd, padding 10.
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.bgMuted,
                    borderRadius: PRadius.brMd,
                    border: Border.all(color: t.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 정적 헤더 틀: 실제 아이콘 + 라벨 텍스트(서버 무관) 렌더.
                      Row(
                        children: [
                          Icon(col.$3, size: 14, color: t.fgSecondary),
                          const SizedBox(width: 6),
                          Text(col.$2,
                              style: PTypo.bodySm.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.bold)),
                          const Spacer(),
                          // 카운트만 데이터 의존 → placeholder.
                          const PSkeleton(width: 18, height: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 데이터 영역: 카드 placeholder (실제 _Card 치수 정합).
                      for (int i = 0; i < 2; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: t.bgSurface,
                              borderRadius: PRadius.brSm,
                              border: Border.all(color: t.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 우선순위 dot(6) + 제목 라인(bodySm 16).
                                Row(
                                  children: [
                                    PSkeleton.circle(size: 6),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: PSkeleton.line(
                                            width: i == 0 ? 160 : 120),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 마감일 행: 아이콘(11) + micro 텍스트.
                                Row(
                                  children: [
                                    const PSkeleton(width: 11, height: 11),
                                    const SizedBox(width: 4),
                                    PSkeleton.line(width: 64, height: 11),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
                          fontWeight: PFontWeight.bold)),
                  const Spacer(),
                  PBadge(
                    label: '${items.length}',
                    variant: PBadgeVariant.secondary,
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
                          fontWeight: PFontWeight.semi)),
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
