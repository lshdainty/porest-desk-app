import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../asset/application/asset_providers.dart';
import '../application/expense_providers.dart';

/// 카테고리/자산 multi-select 필터.
///
/// v0.1: 클라이언트 사이드 필터 (월간 조회 결과를 화면에서 필터). 빈 set 이면 "전체".
/// v0.2 에서 백엔드 query param (categoryId, assetId) 으로 이전 예정.
class ExpenseFilter {
  const ExpenseFilter({this.categoryIds = const {}, this.assetIds = const {}});
  final Set<int> categoryIds;
  final Set<int> assetIds;

  bool get isEmpty => categoryIds.isEmpty && assetIds.isEmpty;

  ExpenseFilter copyWith({Set<int>? categoryIds, Set<int>? assetIds}) =>
      ExpenseFilter(
        categoryIds: categoryIds ?? this.categoryIds,
        assetIds: assetIds ?? this.assetIds,
      );
}

Future<ExpenseFilter?> showFilterDialog(
    BuildContext context, ExpenseFilter current) async {
  return WoltModalSheet.show<ExpenseFilter>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: const Text('필터'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _FilterBody(initial: current),
      ),
    ],
  );
}

class _FilterBody extends ConsumerStatefulWidget {
  const _FilterBody({required this.initial});
  final ExpenseFilter initial;

  @override
  ConsumerState<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends ConsumerState<_FilterBody> {
  late Set<int> _categoryIds;
  late Set<int> _assetIds;

  @override
  void initState() {
    super.initState();
    _categoryIds = {...widget.initial.categoryIds};
    _assetIds = {...widget.initial.assetIds};
  }

  void _apply() => Navigator.of(context).pop(
        ExpenseFilter(categoryIds: _categoryIds, assetIds: _assetIds),
      );

  void _reset() {
    setState(() {
      _categoryIds.clear();
      _assetIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('카테고리',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('카테고리 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (categories) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final c in categories)
                  _CatChip(
                    label: c.categoryName,
                    icon: lucideByName(c.icon),
                    fg: parseColor(c.color, fallback: t.fgBrand),
                    selected: _categoryIds.contains(c.rowId),
                    onTap: () => setState(() {
                      _categoryIds.contains(c.rowId)
                          ? _categoryIds.remove(c.rowId)
                          : _categoryIds.add(c.rowId);
                    }),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x20),
          Text('자산', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          assetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('자산 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (assets) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final a in assets)
                  _PlainChip(
                    label: a.assetName,
                    selected: _assetIds.contains(a.rowId),
                    onTap: () => setState(() {
                      _assetIds.contains(a.rowId)
                          ? _assetIds.remove(a.rowId)
                          : _assetIds.add(a.rowId);
                    }),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('초기화'),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('적용'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.icon,
    required this.fg,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final String label;
  final IconData icon;
  final Color fg;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: PRadius.brPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label,
                style: PTypo.bodySm.copyWith(
                    color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PlainChip extends StatelessWidget {
  const _PlainChip(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: PRadius.brMd,
        ),
        child: Text(label,
            style: PTypo.bodySm.copyWith(
                color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
