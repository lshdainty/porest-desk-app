import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_dropdown_menu.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_floating_action_button.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_meta.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_kanban_view.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_project_management_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_tag_management_dialog.dart';

/// 할일 — 토스 톤 통계/퀵추가/필터/마감일 그룹 리스트 (web `TodoScreen` mobile 미러).
///
/// AppBar 의 리스트/칸반 토글 + 프로젝트/태그 관리 메뉴는 기존 기능 보존.
/// 데이터는 status=null 전체 fetch(칸반과 동일) 후 클라이언트 필터/그룹/통계.
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

/// 리스트 뷰 필터 4종.
enum _TodoFilterTab { today, week, all, done }

class _TodoScreenState extends ConsumerState<TodoScreen> {
  bool _kanban = false;
  _TodoFilterTab _tab = _TodoFilterTab.today;
  final _quickAddCtrl = TextEditingController();
  bool _quickAdding = false;

  /// 전체(status=null) fetch — 칸반과 동일 family 키 공유.
  static const TodoFilter _allFilter = (status: null, priority: null);

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
      // title 만으로 생성: due=오늘, priority MEDIUM, tag '개인'(category).
      final today = DateTime.now();
      await repo.create(
        title: title,
        priority: 'MEDIUM',
        category: kTodoDefaultTag,
        dueDate: _fmtDate(today),
      );
      _quickAddCtrl.clear();
      ref.invalidate(todoListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${AppLocalizations.of(context).todoAddFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _quickAdding = false);
    }
  }

  Future<void> _toggleDone(Todo t) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.setStatus(t.rowId, t.done ? 'PENDING' : 'COMPLETED');
      ref.invalidate(todoListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${AppLocalizations.of(context).todoActionFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(todoListProvider(_allFilter));

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.todoTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PButton.icon(
            icon: _kanban ? LucideIcons.list : LucideIcons.layoutGrid,
            tooltip: _kanban ? l.todoViewList : l.todoViewKanban,
            onPressed: () => setState(() => _kanban = !_kanban),
          ),
          PDropdownMenu(
            iconColor: t.fgSecondary,
            iconSize: 24,
            entries: [
              PDropdownItem(
                label: l.todoProjectMgmt,
                onTap: () => showTodoProjectManagementDialog(context),
              ),
              PDropdownItem(
                label: l.todoTagMgmt,
                onTap: () => showTodoTagManagementDialog(context),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        tooltip: l.todoAdd,
        onPressed: () => showTodoEditDialog(context),
      ),
      body: _kanban
          ? const TodoKanbanView(priority: null)
          : RefreshIndicator(
              color: t.bgBrand,
              onRefresh: () async {
                ref.invalidate(todoListProvider(_allFilter));
                await ref.read(todoListProvider(_allFilter).future);
              },
              child: listAsync.when(
                loading: () => _TodoSkeleton(tokens: t),
                error: (e, _) => ListView(
                  padding: const EdgeInsets.all(PSpace.x16),
                  children: [
                    Text('${l.todoLoadError}\n$e',
                        style:
                            PTypo.bodySm.copyWith(color: t.statusDanger)),
                  ],
                ),
                data: (all) => _buildBody(context, t, all),
              ),
            ),
    );
  }

  Widget _buildBody(BuildContext context, PorestTokens t, List<Todo> all) {
    final l = AppLocalizations.of(context);
    final today = DateTime.now();

    // ── 통계 (전체 기준) ──
    final incomplete = all.where((x) => !x.done).toList();
    final todayCount = incomplete
        .where((x) => x.due != null && _isSameDay(x.due!, today))
        .length;
    final weekCount = incomplete.where((x) {
      if (x.due == null) return false;
      final diff = dateOnly(x.due!).difference(dateOnly(today)).inDays;
      return diff >= 0 && diff <= 7;
    }).length;
    final completedCount = all.where((x) => x.done).length;
    final completedPct =
        all.isEmpty ? 0 : ((completedCount / all.length) * 100).round();

    // ── 필터 카운트 ──
    final counts = <_TodoFilterTab, int>{
      _TodoFilterTab.today: todayCount,
      _TodoFilterTab.week: weekCount,
      _TodoFilterTab.all: incomplete.length,
      _TodoFilterTab.done: completedCount,
    };

    // ── 현재 탭 필터 적용 ──
    final filtered = all.where((x) {
      switch (_tab) {
        case _TodoFilterTab.today:
          return !x.done && x.due != null && _isSameDay(x.due!, today);
        case _TodoFilterTab.week:
          if (x.done || x.due == null) return false;
          final diff = dateOnly(x.due!).difference(dateOnly(today)).inDays;
          return diff >= 0 && diff <= 7;
        case _TodoFilterTab.all:
          return !x.done;
        case _TodoFilterTab.done:
          return x.done;
      }
    }).toList();

    // ── 정렬: 우선순위 desc → due asc(없으면 맨 뒤) ──
    filtered.sort((a, b) {
      final pr = todoPrioRank(b.priority).compareTo(todoPrioRank(a.priority));
      if (pr != 0) return pr;
      final ad = a.due, bd = b.due;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });

    // ── due(YYYY-MM-DD)별 그룹 (없으면 맨 뒤) ──
    final groups = <String, List<Todo>>{};
    for (final x in filtered) {
      final key = x.due == null ? '' : _fmtDate(x.due!);
      (groups[key] ??= <Todo>[]).add(x);
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == b) return 0;
        if (a.isEmpty) return 1; // 마감일 없음 → 맨 뒤
        if (b.isEmpty) return -1;
        return a.compareTo(b);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, 96),
      children: [
        // ── 통계 3카드 ──
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l.calToday,
                value: '$todayCount',
                unit: l.countUnit,
                valueColor: todayCount > 0 ? t.fgBrand : t.fgPrimary,
                t: t,
              ),
            ),
            const SizedBox(width: PSpace.sm),
            Expanded(
              child: _StatCard(
                label: l.expPeriodWeek,
                value: '$weekCount',
                unit: l.countUnit,
                valueColor: t.fgPrimary,
                t: t,
              ),
            ),
            const SizedBox(width: PSpace.sm),
            Expanded(
              child: _StatCard(
                label: l.todoCompletionRate,
                value: '$completedPct',
                unit: '%',
                valueColor: t.statusSuccessFg,
                progress: all.isEmpty ? 0 : completedCount / all.length,
                t: t,
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.md),

        // ── 퀵추가 ──
        _QuickAdd(
          controller: _quickAddCtrl,
          adding: _quickAdding,
          onAdd: _quickAdd,
          onDetail: () => showTodoEditDialog(context),
          onChanged: () => setState(() {}),
          t: t,
        ),
        const SizedBox(height: PSpace.md),

        // ── 필터 칩 4종 → PTabs(pills, sm) (가계부 필터 선례 동일) ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: PTabs<_TodoFilterTab>(
            value: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
            variant: PTabsVariant.pills,
            size: PTabsSize.sm,
            items: [
              for (final tab in _TodoFilterTab.values)
                PTabItem(
                  value: tab,
                  label: '${_tabLabel(tab)} ${counts[tab] ?? 0}',
                ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.md),

        // ── 리스트 (마감일 그룹) or 빈 상태 — 둘 다 카드 안에 (web 정합) ──
        PCard(
          variant: PCardVariant.bordered,
          padding: filtered.isEmpty
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: PSpace.x16),
          child: filtered.isEmpty
              ? SizedBox(
                  width: double.infinity,
                  child: _EmptyTodo(tab: _tab),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final key in groupKeys) ...[
                      _GroupHeader(
                        label: todoGroupLabel(
                          l,
                          key.isEmpty ? null : DateTime.parse(key),
                          groups[key]!.length,
                        ),
                        t: t,
                      ),
                      for (final todo in groups[key]!)
                        _TodoRow(
                          todo: todo,
                          today: today,
                          onToggle: () => _toggleDone(todo),
                          onTap: () => showTodoEditDialog(context, edit: todo),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _tabLabel(_TodoFilterTab tab) {
    final l = AppLocalizations.of(context);
    return switch (tab) {
      _TodoFilterTab.today => l.calToday,
      _TodoFilterTab.week => l.expPeriodWeek,
      _TodoFilterTab.all => l.todoStatusAll,
      _TodoFilterTab.done => l.todoStatusCompleted,
    };
  }
}

/// 통계 카드 — 라벨(uppercase tracking) + 숫자(.num) + 단위, 완료율은 progress bar.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.t,
    this.progress,
  });
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final PorestTokens t;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        boxShadow: t.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: PTypo.micro.copyWith(
              color: t.fgTertiary,
              fontWeight: PFontWeight.semi,
              letterSpacing: 0.48,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: PTypo.h2.copyWith(
                  fontSize: 22,
                  color: valueColor,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.55,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: PRadius.brFull,
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: t.bgSunken,
                valueColor:
                    AlwaysStoppedAnimation<Color>(t.statusSuccess),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 퀵추가 카드 — plus 아이콘 + 투명 input + 추가/자세히 버튼.
///
/// input 자체엔 박스(테두리/배경) 없이 투명 처리하고, 포커스 시 바깥쪽 카드
/// 전체에 border-focus 보더를 입혀 포커스 상태를 표시(web `:focus-within` 정합).
class _QuickAdd extends StatefulWidget {
  const _QuickAdd({
    required this.controller,
    required this.adding,
    required this.onAdd,
    required this.onDetail,
    required this.onChanged,
    required this.t,
  });
  final TextEditingController controller;
  final bool adding;
  final VoidCallback onAdd;
  final VoidCallback onDetail;
  final VoidCallback onChanged;
  final PorestTokens t;

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final l = AppLocalizations.of(context);
    final focused = _focusNode.hasFocus;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        boxShadow: t.shadowSm,
        // 항상 1.5px 보더를 예약(transparent)해 포커스 전환 시 레이아웃 흔들림 방지.
        border: Border.all(
          color: focused ? t.borderFocus : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Icon(LucideIcons.plus, size: 18, color: t.fgTertiary),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: !widget.adding,
              style: PTypo.body.copyWith(color: t.fgPrimary),
              cursorColor: t.fgBrand,
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                // input 자체는 박스 없이 완전 투명 — 포커스 표시는 바깥 카드가 담당.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: l.todoQuickAddPlaceholder,
                hintStyle: PTypo.body.copyWith(color: t.fgPlaceholder),
              ),
              onChanged: (_) => widget.onChanged(),
              onSubmitted: (_) => widget.onAdd(),
            ),
          ),
          const SizedBox(width: 4),
          PButton(
            label: l.calAdd,
            size: PButtonSize.sm,
            loading: widget.adding,
            onPressed: widget.adding ? null : widget.onAdd,
          ),
          const SizedBox(width: 4),
          PButton(
            label: l.todoDetail,
            icon: LucideIcons.settings2,
            size: PButtonSize.sm,
            variant: PButtonVariant.outline,
            tooltip: l.todoDetail,
            onPressed: widget.onDetail,
          ),
        ],
      ),
    );
  }
}

/// 마감일 그룹 헤더 — '5월 19일 (월) · N건', borderBottom subtle.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.t});
  final String label;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: Text(
        label,
        style: PTypo.micro.copyWith(
          color: t.fgTertiary,
          fontWeight: PFontWeight.bold,
          letterSpacing: 0.44,
        ),
      ),
    );
  }
}

/// 할일 행 — 원형 체크(22) + 제목 + 메타(상대시간·태그·메모) + 우선순위 칩.
class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.today,
    required this.onToggle,
    required this.onTap,
  });
  final Todo todo;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final overdue = !todo.done && isTodoOverdue(todo.due, today);
    final overdueColor = todoOverdueColor(context);
    final prio = todoPrioOf(todo.priority);
    final tag = todoTagOrDefault(todo.category);
    final hasNote = (todo.content ?? '').trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: todo.done ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 원형 체크 22px.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: todo.done ? t.bgBrandSolid : Colors.transparent,
                    shape: BoxShape.circle,
                    border: todo.done
                        ? null
                        : Border.all(
                            color: overdue ? overdueColor : t.borderStrong,
                            width: 2,
                          ),
                  ),
                  child: todo.done
                      ? const Icon(LucideIcons.check,
                          size: 13, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // 제목 + 메타.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                        letterSpacing: -0.14,
                        decoration: todo.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          todoRelativeDate(l, todo.due, today),
                          style: PTypo.caption.copyWith(
                            color: overdue ? overdueColor : t.fgTertiary,
                            fontWeight: overdue
                                ? PFontWeight.semi
                                : PFontWeight.medium,
                          ),
                        ),
                        _MetaDot(t: t),
                        Text(
                          tag,
                          style:
                              PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                        if (hasNote) ...[
                          _MetaDot(t: t),
                          Icon(LucideIcons.alignLeft,
                              size: 11, color: t.fgTertiary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 우선순위 칩.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: prio.bg(context),
                  borderRadius: PRadius.brSm,
                ),
                child: Text(
                  todoPrioLabel(l, todo.priority),
                  style: PTypo.micro.copyWith(
                    color: prio.color(context),
                    fontWeight: PFontWeight.semi,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 메타 구분 dot (2px).
class _MetaDot extends StatelessWidget {
  const _MetaDot({required this.t});
  final PorestTokens t;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 2,
        height: 2,
        decoration: BoxDecoration(
          color: t.borderStrong,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// 빈 상태 — 56px 원형 아이콘 + 탭별 문구.
class _EmptyTodo extends StatelessWidget {
  const _EmptyTodo({required this.tab});
  final _TodoFilterTab tab;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final isDone = tab == _TodoFilterTab.done;
    final title = switch (tab) {
      _TodoFilterTab.today => l.todoEmptyToday,
      _TodoFilterTab.week => l.todoEmptyWeek,
      _TodoFilterTab.done => l.todoEmptyDone,
      _TodoFilterTab.all => l.todoEmptyAll,
    };
    final sub = isDone
        ? l.todoEmptyDoneHint
        : l.todoEmptyAddHint;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: t.bgSunken,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? LucideIcons.checkCheck : LucideIcons.sparkles,
              size: 24,
              color: t.fgTertiary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: PTypo.body.copyWith(
              fontSize: PFontSize.bodyMd,
              color: t.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 리스트 뷰 skeleton — 통계 placeholder + 카드 행.
class _TodoSkeleton extends StatelessWidget {
  const _TodoSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, 96),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Expanded(
                child: Container(
                  height: 78,
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    borderRadius: PRadius.brLg,
                    boxShadow: t.shadowSm,
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: PSpace.sm),
            ],
          ],
        ),
        const SizedBox(height: PSpace.md),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brLg,
            boxShadow: t.shadowSm,
          ),
        ),
        const SizedBox(height: PSpace.md),
        PCard(
          variant: PCardVariant.bordered,
          padding: const EdgeInsets.symmetric(horizontal: PSpace.x16),
          child: Column(
            children: [
              for (int i = 0; i < 6; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const PSkeleton(width: 22, height: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PSkeleton.line(width: 140),
                            const SizedBox(height: 4),
                            PSkeleton.line(width: 80, height: 12),
                          ],
                        ),
                      ),
                      const PSkeleton(width: 40, height: 20),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
