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
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
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
  static const _kinds = [
    ('EXPENSE', '지출'),
    ('INCOME', '수입'),
    ('TRANSFER', '이체'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
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
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        onPressed: () => showCategoryEditDialog(context,
            defaultExpenseType: _kinds[_tabIndex].$1),
      ),
      body: categoriesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(PSpace.x16),
          child: PListSkeleton(rows: 8, showAvatar: true),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Text('카테고리 로드 실패\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
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
                  tokens: t,
                ),
            ],
          );
        },
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
          PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x80),
      children: [
        PCard(
          variant: PCardVariant.bordered,
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
