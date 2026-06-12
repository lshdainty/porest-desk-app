import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/category/presentation/category_edit_dialog.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  int _tabIndex = 0;
  String _query = '';
  final Set<int> _collapsed = <int>{};

  static const _kinds = [
    ('EXPENSE', '지출'),
    ('INCOME', '수입'),
  ];

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
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.reorderCategories(items);
      ref.invalidate(categoriesProvider);
    } catch (e) {
      debugPrint('reorderCategories failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('카테고리 관리'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: PTabs<int>(
            items: [
              for (int i = 0; i < _kinds.length; i++)
                PTabItem(value: i, label: _kinds[i].$2),
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
          // 검색 + 추가 row (계좌·카드 관리 accent 버튼 톤 미러)
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
                    hint: '카테고리 검색',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                PButton(
                  label: '추가',
                  icon: LucideIcons.plus,
                  variant: PButtonVariant.accent,
                  size: PButtonSize.sm,
                  onPressed: () => showCategoryEditDialog(
                    context,
                    defaultExpenseType: _kinds[_tabIndex].$1,
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
                  PSpace.x8,
                  PSpace.x20,
                  PSpace.x24,
                ),
                children: [
                  PCard(
                    variant: PCardVariant.shadow,
                    padding: EdgeInsets.zero,
                    child: _CategorySkeleton(tokens: t),
                  ),
                ],
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(PSpace.x16),
                child: Text(
                  '카테고리 로드 실패\n$e',
                  style: PTypo.bodySm.copyWith(color: t.statusDanger),
                ),
              ),
              data: (categories) {
                return IndexedStack(
                  index: _tabIndex,
                  children: [
                    for (final k in _kinds)
                      _CategoryList(
                        categories: categories
                            .where((c) =>
                                (c.expenseType ?? 'EXPENSE') == k.$1)
                            .toList(growable: false),
                        query: _query,
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
    required this.collapsed,
    required this.onToggleCollapse,
    required this.onReorderSiblings,
    required this.tokens,
  });
  final List<ExpenseCategory> categories;
  final String query;
  final Set<int> collapsed;
  final void Function(int parentRowId) onToggleCollapse;
  final void Function(
    List<({int categoryRowId, int sortOrder, int? parentRowId})> items,
  ) onReorderSiblings;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
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
          message: q.isNotEmpty ? '검색 결과가 없어요' : '카테고리가 없습니다',
          subMessage:
              q.isNotEmpty ? null : "상단 '추가' 버튼으로 추가하세요",
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x20,
        PSpace.x8,
        PSpace.x20,
        PSpace.x24,
      ),
      children: [
        PCard(
          variant: PCardVariant.shadow,
          padding: EdgeInsets.zero,
          // 웹 CategoryManager 미러: 부모 reorder(외곽) + 부모별 자식 reorder(내부) 분리.
          // 자식은 자기 부모 그룹 안에서만 드래그 가능 — 다른 부모로 넘어가지 않음.
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: tree.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              if (oldIndex == newIndex) return;
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
              final showChildren =
                  hasChildren && !collapsed.contains(parent.rowId);
              final isLastParent = pi == tree.length - 1;
              return Column(
                key: ValueKey('p-${parent.rowId}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CategoryRow(
                    index: pi,
                    category: parent,
                    isParent: true,
                    hasChildren: hasChildren,
                    isCollapsed: collapsed.contains(parent.rowId),
                    onToggle: hasChildren
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
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        if (oldIndex == newIndex) return;
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
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x12,
        vertical: PSpace.x12,
      ),
      child: Row(
        children: [
          // 자식 들여쓰기 — web paddingLeft:28 미러 (grip 앞)
          if (!isParent) const SizedBox(width: 28),
          // drag handle 자리 (Padding(all:4) + Icon(16) = 24px)
          const SizedBox(width: 24),
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
    required this.isParent,
    required this.hasChildren,
    required this.isCollapsed,
    required this.onToggle,
    required this.isLast,
    required this.tokens,
  });
  final int index;
  final ExpenseCategory category;
  final bool isParent;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback? onToggle;
  final bool isLast;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
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
          onTap: () => showCategoryEditDialog(context, edit: category),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x12,
              vertical: PSpace.x12,
            ),
            child: Row(
              children: [
                // 자식 들여쓰기 — web paddingLeft:28 미러 (grip 앞, 행 전체가 밀림)
                if (!isParent) const SizedBox(width: 28),
                // drag handle (좌측 GripVertical, 웹 CategoryManager 미러)
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
                // 부모 expand chevron (또는 chevron 자리)
                if (isParent) ...[
                  if (hasChildren && onToggle != null)
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
                          '${category.expenseType == 'EXPENSE' ? '지출' : '수입'} · 하위 카테고리 있음',
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                    ],
                  ),
                ),
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
