import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_select.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../expense/application/expense_providers.dart';
import '../application/card_providers.dart';
import '../domain/card_benefit_mapping.dart';

/// 카드 혜택 ↔ 가계부 카테고리 매핑 관리 — front `CardSettingsPage` 핵심 패널 미러.
void showCardBenefitMappingDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: '카드 혜택 매핑',
    contentBuilder: (ctx, scrollCtrl) => _Body(scrollController: scrollCtrl),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.scrollController});
  final ScrollController scrollController;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _benefitCtrl = TextEditingController();
  int? _selectedCategoryId;
  bool _adding = false;

  @override
  void dispose() {
    _benefitCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final benefit = _benefitCtrl.text.trim();
    if (benefit.isEmpty || _selectedCategoryId == null || _adding) return;
    setState(() => _adding = true);
    try {
      final repo = await ref.read(cardBenefitMappingRepositoryProvider.future);
      await repo.create(
        benefitCategory: benefit,
        expenseCategoryRowId: _selectedCategoryId!,
      );
      ref.invalidate(cardBenefitMappingsProvider);
      _benefitCtrl.clear();
      setState(() {
        _selectedCategoryId = null;
        _adding = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추가 실패: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final mappingsAsync = ref.watch(cardBenefitMappingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('새 매핑',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: 4),
          Text('카드 혜택 카테고리(예: 카페, 주유)를 가계부 카테고리와 연결하면 거래 입력 시 자동 추천에 활용됩니다.',
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: PTextInput(
                  controller: _benefitCtrl,
                  enabled: !_adding,
                  placeholder: '혜택 카테고리',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (cats) {
                    final exp = cats
                        .where((c) =>
                            (c.expenseType ?? 'EXPENSE') == 'EXPENSE')
                        .toList();
                    return PSelect<int?>(
                      value: _selectedCategoryId,
                      placeholder: '가계부 카테고리',
                      enabled: !_adding,
                      onChanged: (v) =>
                          setState(() => _selectedCategoryId = v),
                      items: [
                        for (final c in exp)
                          PSelectItem<int?>(
                              value: c.rowId, label: c.categoryName),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  (_benefitCtrl.text.trim().isEmpty ||
                          _selectedCategoryId == null ||
                          _adding)
                      ? null
                      : _add,
              child: _adding
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('매핑 추가'),
            ),
          ),
          const SizedBox(height: PSpace.x16),
          Divider(height: 1, color: t.borderSubtle),
          const SizedBox(height: PSpace.x16),
          Text('등록된 매핑',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          mappingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('매핑 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (mappings) {
              if (mappings.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text('등록된 매핑이 없습니다',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final m in mappings) _Row(mapping: m, tokens: t),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _Row extends ConsumerStatefulWidget {
  const _Row({required this.mapping, required this.tokens});
  final CardBenefitMapping mapping;
  final PorestTokens tokens;
  @override
  ConsumerState<_Row> createState() => _RowState();
}

class _RowState extends ConsumerState<_Row> {
  bool _busy = false;

  Future<void> _delete() async {
    if (!widget.mapping.isCustom) return; // 시스템 매핑은 삭제 불가
    setState(() => _busy = true);
    try {
      final repo =
          await ref.read(cardBenefitMappingRepositoryProvider.future);
      await repo.delete(widget.mapping.rowId);
      ref.invalidate(cardBenefitMappingsProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final m = widget.mapping;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brSm,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.bgMuted,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(m.benefitCategory,
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.arrowRight,
                    size: 12, color: t.fgTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.expenseCategoryName ?? '-',
                      style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
                ),
              ],
            ),
          ),
          if (!m.isCustom)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: t.bgBrandSubtle,
                borderRadius: PRadius.brXs,
              ),
              child: Text('기본',
                  style: PTypo.micro.copyWith(
                      color: t.fgBrand, fontWeight: PFontWeight.bold)),
            )
          else
            IconButton(
              icon: Icon(LucideIcons.trash2,
                  size: 14, color: t.statusDanger),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
    );
  }
}
