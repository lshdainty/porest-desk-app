import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/color_parse.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_tabs.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import 'category_edit_dialog.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  int _tabIndex = 0;
  String _query = '';
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;
  final Set<int> _collapsed = <int>{};

  static const _kinds = [
    ('EXPENSE', '지출'),
    ('INCOME', '수입'),
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchFocusChange() {
    if (_searchFocusNode.hasFocus != _searchFocused) {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    }
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
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('카테고리'),
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
                  // 웹 manager 검색 input 톤 미러 (raw input + inline 토큰, h≈32, 13px).
                  // spec PTextInput(h40, body-lg) 가 아닌 manager-layout searchInputStyle 정합.
                  // 외부 Container 가 시각 전담 — focus 시 border 색(borderFocus) + 두께(2px) 로
                  // 웹 manager 검색 input 의 focus 톤(input 전체 둘레 감쌈) 미러.
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: t.bgSurface,
                      border: Border.all(
                        color: _searchFocused
                            ? t.borderFocus
                            : t.borderSubtle,
                        width: _searchFocused ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(PRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: PSpace.x12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 14,
                          color: t.fgTertiary,
                        ),
                        const SizedBox(width: PSpace.x8),
                        Expanded(
                          // InputDecoration.collapsed 는 border 만 None 으로 두고 focusedBorder/
                          // enabledBorder 는 null → Theme.inputDecorationTheme 기본값(Material
                          // primary 2px) 이 적용돼서 focus 시 안쪽에 박스가 그려짐. 모든 border
                          // field 를 InputBorder.none 으로 명시해서 차단.
                          child: TextField(
                            focusNode: _searchFocusNode,
                            onChanged: (v) => setState(() => _query = v),
                            cursorColor: t.fgBrand,
                            cursorWidth: 1.5,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                              hintText: '카테고리 검색',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: t.fgTertiary,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: t.fgPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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

    // visible flatten — [parent, (expanded 시) child, child, parent, ...]
    final visible = <ExpenseCategory>[];
    final hasChildrenMap = <int, bool>{};
    for (final entry in tree) {
      visible.add(entry.parent);
      hasChildrenMap[entry.parent.rowId] = entry.children.isNotEmpty;
      if (!collapsed.contains(entry.parent.rowId)) {
        for (final c in entry.children) {
          visible.add(c);
        }
      }
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
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: visible.length,
            itemBuilder: (ctx, i) {
              final c = visible[i];
              final isParent = c.parentRowId == null;
              final hasChildren =
                  isParent && (hasChildrenMap[c.rowId] ?? false);
              return _CategoryRow(
                key: ValueKey(c.rowId),
                index: i,
                category: c,
                isParent: isParent,
                hasChildren: hasChildren,
                isCollapsed: isParent && collapsed.contains(c.rowId),
                onToggle: hasChildren ? () => onToggleCollapse(c.rowId) : null,
                isLast: i == visible.length - 1,
                tokens: tokens,
              );
            },
            onReorder: (oldIndex, newIndex) {
              // Flutter ReorderableListView quirk
              if (newIndex > oldIndex) newIndex -= 1;
              if (oldIndex == newIndex) return;
              final from = visible[oldIndex];
              final to = visible[newIndex];
              // level guard — 같은 부모/같은 level 끼리만 reorder 허용
              if (from.parentRowId != to.parentRowId) return;
              final parentRowId = from.parentRowId;
              final siblings = visible
                  .where((v) => v.parentRowId == parentRowId)
                  .toList(growable: false);
              final sibOldIdx = siblings.indexOf(from);
              final sibNewIdx = siblings.indexOf(to);
              if (sibOldIdx < 0 || sibNewIdx < 0) return;
              final reordered = [...siblings];
              final moved = reordered.removeAt(sibOldIdx);
              reordered.insert(sibNewIdx, moved);
              final items =
                  <({int categoryRowId, int sortOrder, int? parentRowId})>[];
              for (var idx = 0; idx < reordered.length; idx++) {
                items.add((
                  categoryRowId: reordered[idx].rowId,
                  sortOrder: idx,
                  parentRowId: parentRowId,
                ));
              }
              onReorderSiblings(items);
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
          // drag handle 자리 (Padding(all:4) + Icon(16) = 24px)
          const SizedBox(width: 24),
          // 자식: 들여쓰기 20px / 부모: chevron 자리(24) + gap(4)
          if (!isParent) const SizedBox(width: PSpace.x20),
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
    final bg = softBg(fg);
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
                // 자식 들여쓰기 (좌측 20px)
                if (!isParent) const SizedBox(width: PSpace.x20),
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
                      BoxDecoration(color: bg, borderRadius: PRadius.brSm),
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
