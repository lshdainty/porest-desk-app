import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/card_providers.dart';
import '../domain/card_catalog.dart';
import 'card_benefit_mapping_dialog.dart';

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
    final pageAsync = ref.watch(cardCatalogPageProvider(_searchKey));

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('카드 관리'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '혜택 매핑',
            icon: Icon(LucideIcons.settings,
                size: 20, color: t.fgSecondary),
            onPressed: () => showCardBenefitMappingDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, 0, PSpace.x16, PSpace.x12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PTextInput(
                  controller: _kwCtrl,
                  onChanged: _onChange,
                  placeholder: '카드명 검색',
                  prefix:
                      Icon(LucideIcons.search, size: 16, color: t.fgTertiary),
                ),
                const SizedBox(height: PSpace.x8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                          label: '전체',
                          selected: _typeFilter == null,
                          onTap: () => _setType(null),
                          tokens: t),
                      const SizedBox(width: 6),
                      _Chip(
                          label: '신용',
                          selected: _typeFilter == 'CREDIT',
                          onTap: () => _setType('CREDIT'),
                          tokens: t),
                      const SizedBox(width: 6),
                      _Chip(
                          label: '체크',
                          selected: _typeFilter == 'CHECK',
                          onTap: () => _setType('CHECK'),
                          tokens: t),
                      const SizedBox(width: 14),
                      _Chip(
                          label: '혜택 전체',
                          selected: _benefitFilter == null,
                          onTap: () => _setBenefit(null),
                          tokens: t),
                      const SizedBox(width: 6),
                      _Chip(
                          label: '할인',
                          selected: _benefitFilter == 'DISCOUNT',
                          onTap: () => _setBenefit('DISCOUNT'),
                          tokens: t),
                      const SizedBox(width: 6),
                      _Chip(
                          label: '적립',
                          selected: _benefitFilter == 'POINT',
                          onTap: () => _setBenefit('POINT'),
                          tokens: t),
                      const SizedBox(width: 6),
                      _Chip(
                          label: '캐시백',
                          selected: _benefitFilter == 'CASHBACK',
                          onTap: () => _setBenefit('CASHBACK'),
                          tokens: t),
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
                        Text('단종 카드 포함',
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('카드 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (page) {
            final cards = page.content;
            if (cards.isEmpty) {
              return ListView(children: const [
                PEmptyState(
                  icon: LucideIcons.creditCard,
                  message: '카드가 없습니다',
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
                    '총 ${page.totalElements}건',
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
        IconButton(
          onPressed: onPrev,
          icon: const Icon(LucideIcons.chevronLeft, size: 18),
          color: tokens.fgSecondary,
          disabledColor: tokens.fgDisabled,
        ),
        const SizedBox(width: 8),
        Text(
          '${(page.number as int) + 1} / ${page.totalPages == 0 ? 1 : page.totalPages}',
          style: PTypo.bodySm.copyWith(
              color: tokens.fgPrimary, fontWeight: PFontWeight.semi),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onNext,
          icon: const Icon(LucideIcons.chevronRight, size: 18),
          color: tokens.fgSecondary,
          disabledColor: tokens.fgDisabled,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrand : tokens.bgSurface,
          border: Border.all(
              color: selected ? tokens.borderBrand : tokens.borderSubtle),
          borderRadius: PRadius.brFull,
        ),
        child: Text(label,
            style: PTypo.caption.copyWith(
                color: selected ? tokens.fgOnBrand : tokens.fgSecondary,
                fontWeight: PFontWeight.semi)),
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
                        card.cardType == 'CREDIT' ? '신용' : '체크',
                        if (card.annualFee?.label != null)
                          '연회비 ${card.annualFee!.label}',
                      ].whereType<String>().join(' · '),
                      style:
                          PTypo.caption.copyWith(color: tokens.fgTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (card.performance?.requiredAmount != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '실적 ${krw(card.performance!.requiredAmount!)}원/월',
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
