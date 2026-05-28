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
import '../../../shared/widgets/p_divider.dart';
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
  static const _kinds = [
    ('EXPENSE', '지출'),
    ('INCOME', '수입'),
  ];

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
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: t.bgSurface,
                      border: Border.all(color: t.borderSubtle),
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
                          // collapsed — Material 기본 focusedBorder(파란 두꺼운 border) 제거.
                          // 시각은 외부 Container(bg + border + radius) 가 전부 담당.
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration.collapsed(
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
              loading: () => const Padding(
                padding: EdgeInsets.all(PSpace.x16),
                child: PListSkeleton(rows: 8, showAvatar: true),
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
                                (c.expenseType ?? 'EXPENSE') == k.$1 &&
                                (_query.isEmpty ||
                                    c.categoryName.contains(_query)))
                            .toList(growable: false),
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
  const _CategoryList({required this.categories, required this.tokens});
  final List<ExpenseCategory> categories;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: PEmptyState(
          icon: LucideIcons.tag,
          message: '카테고리가 없습니다',
          subMessage: '우하단 + 버튼으로 추가하세요',
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
          child: Column(
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                _CategoryRow(category: categories[i], tokens: tokens),
                if (i < categories.length - 1)
                  PDivider(indent: PSpace.x16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.tokens});
  final ExpenseCategory category;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fg = resolveChartColor(context, category.color, fallback: tokens.fgBrand);
    final bg = softBg(fg);
    return InkWell(
      onTap: () => showCategoryEditDialog(context, edit: category),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(lucideByName(category.icon), size: 18, color: fg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Text(category.categoryName,
                  style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.medium)),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: tokens.fgTertiary),
          ],
        ),
      ),
    );
  }
}
