import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/features/card/presentation/card_benefit_mapping_dialog.dart';

class CardScreen extends ConsumerStatefulWidget {
  const CardScreen({super.key});
  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen> {
  final _kwCtrl = TextEditingController();
  String? _typeFilter;
  String? _benefitFilter;
  bool _includeDiscontinued = false;
  Timer? _debounce;
  CardSearchKey _searchKey = defaultCardSearchKey();

  void _rebuildKey() {
    _searchKey = defaultCardSearchKey(
      keyword: _kwCtrl.text.trim().isEmpty ? null : _kwCtrl.text.trim(),
      cardType: _typeFilter,
      benefitType: _benefitFilter,
      includeDiscontinued: _includeDiscontinued ? true : null,
    );
  }

  void _onChange(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(_rebuildKey);
    });
  }

  void _setType(String? t) {
    setState(() {
      _typeFilter = t;
      _rebuildKey();
    });
  }

  void _setBenefit(String? b) {
    setState(() {
      _benefitFilter = b;
      _rebuildKey();
    });
  }

  void _toggleDiscontinued() {
    setState(() {
      _includeDiscontinued = !_includeDiscontinued;
      _rebuildKey();
    });
  }

  @override
  void dispose() {
    _kwCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final pageAsync = ref.watch(cardCatalogPageProvider(_searchKey));

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.cardManageTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PButton.icon(
            icon: LucideIcons.settings,
            tooltip: l.cardBenefitMappingTooltip,
            onPressed: () => showCardBenefitMappingDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Padding(
            padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PSearchField(
                  controller: _kwCtrl,
                  onChanged: _onChange,
                  hint: l.cardSearchHintName,
                ),
                const SizedBox(height: PSpace.x8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PTabs<String?>(
                        value: _typeFilter,
                        onChanged: _setType,
                        variant: PTabsVariant.pills,
                        size: PTabsSize.sm,
                        items: [
                          PTabItem(value: null, label: l.expFilterAll),
                          PTabItem(value: 'CREDIT', label: l.assetCardShortCredit),
                          PTabItem(value: 'CHECK', label: l.assetCardShortCheck),
                        ],
                      ),
                      const SizedBox(width: 14),
                      PTabs<String?>(
                        value: _benefitFilter,
                        onChanged: _setBenefit,
                        variant: PTabsVariant.pills,
                        size: PTabsSize.sm,
                        items: [
                          PTabItem(value: null, label: l.cardBenefitTypeAll),
                          PTabItem(value: 'DISCOUNT', label: l.cardBenefitTypeDiscount),
                          PTabItem(value: 'POINT', label: l.cardBenefitTypePoint),
                          PTabItem(value: 'CASHBACK', label: l.cardBenefitTypeCashback),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _toggleDiscontinued,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            _includeDiscontinued
                                ? LucideIcons.checkSquare
                                : LucideIcons.square,
                            size: 14,
                            color: _includeDiscontinued
                                ? t.fgBrand
                                : t.fgTertiary),
                        const SizedBox(width: 6),
                        Text(l.cardIncludeDiscontinued,
                            style: PTypo.caption.copyWith(
                                color: t.fgSecondary,
                                fontWeight: PFontWeight.medium)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(cardCatalogPageProvider(_searchKey));
          await ref.read(cardCatalogPageProvider(_searchKey).future);
        },
        child: pageAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x40),
            children: [
              // '총 N건' 카운트 자리
              Padding(
                padding: const EdgeInsets.only(bottom: PSpace.x8),
                child: PSkeleton.line(width: 56, height: 12),
              ),
              for (int i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(height: PSpace.x8),
                _CardRowSkeleton(tokens: t),
              ],
            ],
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('${l.cardLoadError}\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (page) {
            final cards = page.content;
            if (cards.isEmpty) {
              return ListView(children: [
                PEmptyState(
                  icon: LucideIcons.creditCard,
                  message: l.cardEmpty,
                ),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x40),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: PSpace.x8),
                  child: Text(
                    l.cardTotalCount(page.totalElements),
                    style:
                        PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ),
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: PSpace.x8),
                  _CardRow(card: cards[i], tokens: t),
                ],
                const SizedBox(height: PSpace.x16),
                _Paginator(
                  page: page,
                  onPrev: page.first
                      ? null
                      : () => setState(() {
                            _searchKey = (
                              keyword: _searchKey.keyword,
                              cardType: _searchKey.cardType,
                              benefitType: _searchKey.benefitType,
                              includeDiscontinued:
                                  _searchKey.includeDiscontinued,
                              page: _searchKey.page - 1,
                              size: _searchKey.size,
                            );
                          }),
                  onNext: page.last
                      ? null
                      : () => setState(() {
                            _searchKey = (
                              keyword: _searchKey.keyword,
                              cardType: _searchKey.cardType,
                              benefitType: _searchKey.benefitType,
                              includeDiscontinued:
                                  _searchKey.includeDiscontinued,
                              page: _searchKey.page + 1,
                              size: _searchKey.size,
                            );
                          }),
                  tokens: t,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Paginator extends StatelessWidget {
  const _Paginator({
    required this.page,
    required this.onPrev,
    required this.onNext,
    required this.tokens,
  });
  final dynamic page;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PButton.icon(
          icon: LucideIcons.chevronLeft,
          onPressed: onPrev,
        ),
        const SizedBox(width: 8),
        Text(
          '${(page.number as int) + 1} / ${page.totalPages == 0 ? 1 : page.totalPages}',
          style: PTypo.bodySm.copyWith(
              color: tokens.fgPrimary, fontWeight: PFontWeight.semi),
        ),
        const SizedBox(width: 8),
        PButton.icon(
          icon: LucideIcons.chevronRight,
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// `_CardRow` 로딩 placeholder — 실제 행과 1:1 구조 정합.
/// bordered 박스(radius brLg, border borderSubtle, padding 12) + 56×36 비주얼(brSm)
/// + 이름/메타 2줄 + chevron 자리.
class _CardRowSkeleton extends StatelessWidget {
  const _CardRowSkeleton({required this.tokens});
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PSpace.x12),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          const PSkeleton(width: 56, height: 36, borderRadius: PRadius.brSm),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6,
                    child: PSkeleton.line(height: 14)),
                SizedBox(height: 6),
                FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.85,
                    child: PSkeleton.line(height: 12)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x12),
          const PSkeleton(width: 16, height: 16, borderRadius: PRadius.brSm),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.tokens});
  final CardCatalogSummary card;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: tokens.bgSurface,
      borderRadius: PRadius.brLg,
      child: InkWell(
        onTap: () => context.push('/cards/${card.rowId}'),
        borderRadius: PRadius.brLg,
        child: Container(
          padding: const EdgeInsets.all(PSpace.x12),
          decoration: BoxDecoration(
            borderRadius: PRadius.brLg,
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: PRadius.brSm,
                child: SizedBox(
                  width: 56,
                  height: 36,
                  child: card.imgUrl != null
                      ? Image.network(card.imgUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                              color: tokens.bgMuted,
                              child: Icon(LucideIcons.creditCard,
                                  size: 18, color: tokens.fgTertiary)))
                      : Container(
                          color: tokens.bgMuted,
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.creditCard,
                              size: 18, color: tokens.fgTertiary),
                        ),
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.cardName,
                        style: PTypo.bodySm.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: PFontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      [
                        card.company?.name,
                        card.cardType == 'CREDIT' ? l.assetCardShortCredit : l.assetCardShortCheck,
                        if (card.annualFee?.label != null)
                          l.cardAnnualFeeValue(card.annualFee!.label!),
                      ].whereType<String>().join(' · '),
                      style:
                          PTypo.caption.copyWith(color: tokens.fgTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (card.performance?.requiredAmount != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l.cardPerfMonthly(
                            krwSigned(card.performance!.requiredAmount!, false, unit: true)),
                        style: PTypo.caption.copyWith(
                            color: tokens.fgSecondary,
                            fontWeight: PFontWeight.semi),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: tokens.fgTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
