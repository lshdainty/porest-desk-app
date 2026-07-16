import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_benefit_mapping.dart';

/// 카드 혜택 ↔ 가계부 카테고리 매핑 관리 — front `CardSettingsPage` 핵심 패널 미러.
void showCardBenefitMappingDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  showPSheet<void>(
    context,
    title: l.cardBenefitMappingTitle,
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
  void initState() {
    super.initState();
    // 진입 시 갱신 — keepAlive provider 라 다른 클라이언트 변경 반영 위해 무효화.
    Future.microtask(() {
      if (mounted) ref.invalidate(cardBenefitMappingsProvider);
    });
  }

  @override
  void dispose() {
    _benefitCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
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
      showPSnackBar(context, '${l.cardAddFailed}: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final mappingsAsync = ref.watch(cardBenefitMappingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text(l.cardMappingNew,
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: 4),
          Text(l.cardMappingNewDesc,
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: PTextInput(
                  controller: _benefitCtrl,
                  enabled: !_adding,
                  placeholder: l.cardMappingBenefitPlaceholder,
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
                      placeholder: l.cardMappingCategoryPlaceholder,
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
          PButton(
            label: l.cardMappingAdd,
            loading: _adding,
            fullWidth: true,
            onPressed:
                (_benefitCtrl.text.trim().isEmpty ||
                        _selectedCategoryId == null ||
                        _adding)
                    ? null
                    : _add,
          ),
          const SizedBox(height: PSpace.x16),
          PDivider(),
          const SizedBox(height: PSpace.x16),
          Text(l.cardMappingRegistered,
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          mappingsAsync.when(
            loading: () => const Center(child: PCircularProgressIndicator()),
            error: (e, _) => Text('${l.cardMappingLoadError}: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (mappings) {
              if (mappings.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text(l.cardMappingEmpty,
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
    final l = AppLocalizations.of(context);
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
      showPSnackBar(context, '${l.cardDeleteFailed}: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final l = AppLocalizations.of(context);
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
            PBadge(
                label: l.cardMappingDefault, variant: PBadgeVariant.softBrand)
          else
            PButton.icon(
              icon: LucideIcons.trash2,
              size: PButtonSize.sm,
              iconColor: t.fgExpense,
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
    );
  }
}
