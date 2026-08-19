import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/category/presentation/category_edit_dialog.dart';

/// 구분 필터 라벨 — index 0=지출/1=수입 → 로케일 문자열.
String _kindLabel(AppLocalizations l, int i) =>
    i == 0 ? l.expTypeExpense : l.expTypeIncome;

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  int _tabIndex = 0;
  String _query = '';
  // 순서 편집 모드 — 디자인 editMode: 켜야만 grip 노출·드래그 가능, 하위 강제 표시.
  bool _editMode = false;
  final Set<int> _collapsed = <int>{};
  // 낙관적 재정렬 오버레이: 드롭 즉시 로컬 순서를 반영하고 refetch가 끝나면 비운다.
  final Map<int, ({int sortOrder, int? parentRowId})> _optimistic = {};

  static const _kindValues = ['EXPENSE', 'INCOME'];

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 갱신 — categoriesProvider 는 keepAlive 라 자동 refetch 되지
    // 않으므로, 다른 클라이언트(웹 등) 변경을 따라잡기 위해 진입할 때 무효화한다.
    Future.microtask(() {
      if (mounted) ref.invalidate(categoriesProvider);
    });
  }

  void _toggleCollapse(int parentRowId) {
    setState(() {
      if (_collapsed.contains(parentRowId)) {
        _collapsed.remove(parentRowId);
      } else {
        _collapsed.add(parentRowId);
      }
    });
  }

  Future<void> _handleReorder(
    List<({int categoryRowId, int sortOrder, int? parentRowId})> items,
  ) async {
    // 낙관적 업데이트: 드롭 즉시 로컬 순서를 반영(스냅백 방지).
    setState(() {
      for (final it in items) {
        _optimistic[it.categoryRowId] =
            (sortOrder: it.sortOrder, parentRowId: it.parentRowId);
      }
    });
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.reorderCategories(items);
      // 서버 권위 데이터로 재동기 후 오버레이 제거 — refetch 완료를 기다려 깜빡임 방지.
      ref.invalidate(categoriesProvider);
      await ref.read(categoriesProvider.future);
    } catch (e) {
      debugPrint('reorderCategories failed: $e');
    } finally {
      if (mounted) setState(() => _optimistic.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    // 탭 카운트 — 웹·디자인 "지출 N / 수입 N" 정합(상위+하위 전체 수). 로딩 중엔 라벨만.
    final allCats = categoriesAsync.value;
    String tabLabel(int i) {
      if (allCats == null) return _kindLabel(l, i);
      final n = allCats
          .where((c) => (c.expenseType ?? 'EXPENSE') == _kindValues[i])
          .length;
      return '${_kindLabel(l, i)} $n';
    }

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.categoryManageTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          // 순서 편집 토글 — 디자인 m-subhead__action-btn('편집'↔'완료').
          Padding(
            padding: const EdgeInsets.only(right: PSpace.x8),
            child: PButton(
              label: _editMode ? l.actionDone : l.categoryReorderEdit,
              variant: PButtonVariant.ghost,
              size: PButtonSize.sm,
              onPressed: () => setState(() {
                _editMode = !_editMode;
                // 편집 진입 시 검색 초기화 — 필터된 일부만 보며 정렬하는 혼란 방지.
                if (_editMode) _query = '';
              }),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: PTabs<int>(
            items: [
              for (int i = 0; i < _kindValues.length; i++)
                PTabItem(value: i, label: tabLabel(i)),
            ],
            value: _tabIndex,
            onChanged: (v) => setState(() => _tabIndex = v),
            variant: PTabsVariant.underline,
            expand: true,
          ),
        ),
      ),
      body: Column(
        children: [
          // 편집 모드: 검색·추가 대신 드래그 안내문(디자인 editMode) / 평시: 검색 + 추가 row.
          if (_editMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpace.x20,
                PSpace.x12,
                PSpace.x20,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.categoryReorderHint,
                  style: PTypo.caption.copyWith(
                    color: t.fgTertiary,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpace.x20,
                PSpace.x16,
                PSpace.x20,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    // 공용 검색바 — 테두리/모양 통일(PSearchField canonical).
                    child: PSearchField(
                      hint: l.categorySearchHint,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  PButton(
                    label: l.calAdd,
                    icon: LucideIcons.plus,
                    variant: PButtonVariant.accent,
                    size: PButtonSize.sm,
                    onPressed: () => showCategoryEditDialog(
                      context,
                      defaultExpenseType: _kindValues[_tabIndex],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => ListView(
                padding: const EdgeInsets.fromLTRB(
                  PSpace.x20,
                  PSpace.x0, // 검색바 label 과 gap 0 (label·list 는 한 묶음, 사용자 결정)
                  PSpace.x20,
                  PSpace.x24,
                ),
                children: [
                  // 카드 다이어트 — 스켈레톤 플랫.
                  _CategorySkeleton(tokens: t),
                ],
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(PSpace.x16),
                child: Text(
                  '${l.categoryLoadError}\n$e',
                  style: PTypo.bodySm.copyWith(color: t.statusDanger),
                ),
              ),
              data: (categories) {
                // 낙관적 오버레이 적용 — 진행 중인 재정렬을 즉시 반영.
                final effective = _optimistic.isEmpty
                    ? categories
                    : categories.map((c) {
                        final o = _optimistic[c.rowId];
                        return o == null
                            ? c
                            : c.copyWith(
                                sortOrder: o.sortOrder,
                                parentRowId: o.parentRowId,
                              );
                      }).toList(growable: false);
                return IndexedStack(
                  index: _tabIndex,
                  children: [
                    for (final k in _kindValues)
                      _CategoryList(
                        categories: effective
                            .where((c) =>
                                (c.expenseType ?? 'EXPENSE') == k)
                            .toList(growable: false),
                        query: _query,
                        editMode: _editMode,
                        collapsed: _collapsed,
                        onToggleCollapse: _toggleCollapse,
                        onReorderSiblings: _handleReorder,
                        tokens: t,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.query,
    required this.editMode,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.onReorderSiblings,
    required this.tokens,
  });
  final List<ExpenseCategory> categories;
  final String query;
  final bool editMode;
  final Set<int> collapsed;
  final void Function(int parentRowId) onToggleCollapse;
  final void Function(
    List<({int categoryRowId, int sortOrder, int? parentRowId})> items,
  ) onReorderSiblings;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 트리 변환 (parentRowId + sortOrder) — 웹 CategoryManager.tree 미러.
    final sorted = [...categories]
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    final byParent = <int, List<ExpenseCategory>>{};
    final parents = <ExpenseCategory>[];
    for (final c in sorted) {
      if (c.parentRowId == null) {
        parents.add(c);
      } else {
        byParent.putIfAbsent(c.parentRowId!, () => <ExpenseCategory>[]).add(c);
      }
    }
    // 검색 — 그룹 단위 (부모 매치 or 자식 매치 시 그룹 노출).
    final q = query.trim();
    final tree = <_TreeEntry>[];
    for (final p in parents) {
      final children = byParent[p.rowId] ?? const <ExpenseCategory>[];
      if (q.isEmpty) {
        tree.add(_TreeEntry(p, children));
        continue;
      }
      final parentMatch = p.categoryName.contains(q);
      final filteredChildren = parentMatch
          ? children
          : children
              .where((c) => c.categoryName.contains(q))
              .toList(growable: false);
      if (!parentMatch && filteredChildren.isEmpty) continue;
      tree.add(_TreeEntry(p, filteredChildren));
    }

    if (tree.isEmpty) {
      return Center(
        child: PEmptyState(
          icon: LucideIcons.tag,
          message: q.isNotEmpty ? l.categoryNoResults : l.categoryEmpty,
          subMessage:
              q.isNotEmpty ? null : l.categoryEmptyHint,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x20,
        PSpace.x0, // 검색바 label 과 gap 0 (label·list 는 한 묶음, 사용자 결정)
        PSpace.x20,
        PSpace.x24,
      ),
      children: [
        // 카드 다이어트 — 카드 없이 reorder 리스트 플랫 렌더.
        // 웹 CategoryManager 미러: 부모 reorder(외곽) + 부모별 자식 reorder(내부) 분리.
        // 자식은 자기 부모 그룹 안에서만 드래그 가능 — 다른 부모로 넘어가지 않음.
        Material(
          color: Colors.transparent,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: tree.length,
            // onReorderItem 은 newIndex 를 프레임워크가 보정해 넘기고,
            // oldIndex == newIndex 면 아예 호출하지 않는다.
            onReorderItem: (oldIndex, newIndex) {
              final reordered = [for (final e in tree) e.parent];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              final items =
                  <({int categoryRowId, int sortOrder, int? parentRowId})>[];
              for (var idx = 0; idx < reordered.length; idx++) {
                items.add((
                  categoryRowId: reordered[idx].rowId,
                  sortOrder: idx,
                  parentRowId: null,
                ));
              }
              onReorderSiblings(items);
            },
            itemBuilder: (ctx, pi) {
              final entry = tree[pi];
              final parent = entry.parent;
              final hasChildren = entry.children.isNotEmpty;
              // 편집 모드는 하위 강제 표시(디자인 editMode || expanded) — 접힘 무시.
              final showChildren = hasChildren &&
                  (editMode || !collapsed.contains(parent.rowId));
              final isLastParent = pi == tree.length - 1;
              return Column(
                key: ValueKey('p-${parent.rowId}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CategoryRow(
                    index: pi,
                    category: parent,
                    editMode: editMode,
                    isParent: true,
                    hasChildren: hasChildren,
                    isCollapsed: collapsed.contains(parent.rowId),
                    onToggle: hasChildren && !editMode
                        ? () => onToggleCollapse(parent.rowId)
                        : null,
                    isLast: isLastParent && !showChildren,
                    tokens: tokens,
                  ),
                  if (showChildren)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: entry.children.length,
                      onReorderItem: (oldIndex, newIndex) {
                        final reordered = [...entry.children];
                        final moved = reordered.removeAt(oldIndex);
                        reordered.insert(newIndex, moved);
                        final items = <({
                          int categoryRowId,
                          int sortOrder,
                          int? parentRowId
                        })>[];
                        for (var idx = 0; idx < reordered.length; idx++) {
                          items.add((
                            categoryRowId: reordered[idx].rowId,
                            sortOrder: idx,
                            parentRowId: parent.rowId,
                          ));
                        }
                        onReorderSiblings(items);
                      },
                      itemBuilder: (ctx, ci) {
                        final child = entry.children[ci];
                        final isLastChild = isLastParent &&
                            ci == entry.children.length - 1;
                        return _CategoryRow(
                          key: ValueKey('c-${child.rowId}'),
                          index: ci,
                          category: child,
                          editMode: editMode,
                          isParent: false,
                          hasChildren: false,
                          isCollapsed: false,
                          onToggle: null,
                          isLast: isLastChild,
                          tokens: tokens,
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 카테고리 트리 구조 skeleton — _CategoryRow 레이아웃 1:1 미러.
/// 부모 2쌍(자식 각 2행) + 부모 1개 = 총 7행.
class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CatRowSkel(isParent: true,  showMeta: true,  isLast: false, tokens: tokens),
        _CatRowSkel(isParent: false, showMeta: false, isLast: false, tokens: tokens),
        _CatRowSkel(isParent: false, showMeta: false, isLast: false, tokens: tokens),
        _CatRowSkel(isParent: true,  showMeta: false, isLast: false, tokens: tokens),
        _CatRowSkel(isParent: false, showMeta: false, isLast: false, tokens: tokens),
        _CatRowSkel(isParent: true,  showMeta: true,  isLast: false, tokens: tokens),
        _CatRowSkel(isParent: false, showMeta: false, isLast: true,  tokens: tokens),
      ],
    );
  }
}

class _CatRowSkel extends StatelessWidget {
  const _CatRowSkel({
    required this.isParent,
    required this.showMeta,
    required this.isLast,
    required this.tokens,
  });
  final bool isParent;
  final bool showMeta;
  final bool isLast;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      // 좌우 0 — 페이지가 24 를 쥔다. 행이 더 얹으면 위 라벨과 어긋난다(설정 리스트 공통 규칙).
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: PSpace.x12,
      ),
      child: Row(
        children: [
          // 자식 들여쓰기 — web paddingLeft:28 미러
          if (!isParent) const SizedBox(width: 28),
          // grip 은 평시엔 없음(편집 모드 전용) — 스켈레톤은 평시 렌더 미러
          // 부모: chevron 자리(24) + gap(4)
          if (isParent) ...[
            const SizedBox(width: 24),
            const SizedBox(width: PSpace.x4),
          ],
          const PSkeleton(width: 36, height: 36),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PSkeleton.line(width: isParent ? 80 : 60),
                if (showMeta) ...[
                  const SizedBox(height: 4),
                  PSkeleton.line(width: 120, height: 11),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16), // chevronRight 자리
        ],
      ),
    );
  }
}

class _TreeEntry {
  const _TreeEntry(this.parent, this.children);
  final ExpenseCategory parent;
  final List<ExpenseCategory> children;
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.index,
    required this.category,
    required this.editMode,
    required this.isParent,
    required this.hasChildren,
    required this.isCollapsed,
    required this.onToggle,
    required this.isLast,
    required this.tokens,
  });
  final int index;
  final ExpenseCategory category;
  final bool editMode;
  final bool isParent;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback? onToggle;
  final bool isLast;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final fg = resolveChartColor(context, category.color, fallback: t.fgBrand);
    final bg = softBg(context, fg);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          // 마지막 row 제외 — 하단 border 로 divider 역할 (PDivider 대체, ReorderableListView 와 정합)
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: t.borderSubtle)),
        ),
        child: InkWell(
          // 편집 모드에선 행 탭(수정 다이얼로그) 비활성 — 드래그 전용(디자인 editMode).
          onTap: editMode
              ? null
              : () => showCategoryEditDialog(context, edit: category),
          child: Padding(
            // 좌우 0 — 페이지가 24 를 쥔다. 행이 더 얹으면 위 라벨과 어긋난다(설정 리스트 공통 규칙).
            padding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: PSpace.x12,
            ),
            child: Row(
              children: [
                // 자식 들여쓰기 — web paddingLeft:28 미러 (grip 앞, 행 전체가 밀림)
                if (!isParent) const SizedBox(width: 28),
                // drag handle — 편집 모드 전용(디자인: 평시엔 손잡이 자체가 없음).
                if (editMode)
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(PSpace.x4),
                      child: Icon(
                        LucideIcons.gripVertical,
                        size: 16,
                        color: t.fgTertiary,
                      ),
                    ),
                  ),
                // 부모 expand chevron (또는 chevron 자리) — 편집 모드엔 자리만(하위 강제 표시)
                if (isParent) ...[
                  if (!editMode && hasChildren && onToggle != null)
                    InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(PRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(PSpace.x4),
                        child: Icon(
                          isCollapsed
                              ? LucideIcons.chevronRight
                              : LucideIcons.chevronDown,
                          size: 16,
                          color: t.fgSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: PSpace.x4),
                ],
                Container(
                  width: 36,
                  height: 36,
                  decoration:
                      BoxDecoration(color: bg, borderRadius: PRadius.tile(36)),
                  alignment: Alignment.center,
                  child: Icon(lucideByName(category.icon), size: 18, color: fg),
                ),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.categoryName,
                        style: PTypo.body.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.medium,
                        ),
                      ),
                      if (isParent && hasChildren)
                        Text(
                          l.categoryHasSubcategories(category.expenseType == 'EXPENSE' ? l.expTypeExpense : l.expTypeIncome),
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                    ],
                  ),
                ),
                if (!editMode)
                  Icon(LucideIcons.chevronRight,
                      size: 16, color: t.fgTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
