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
import '../application/card_providers.dart';
import '../domain/card_catalog.dart';
import 'card_detail_screen.dart';

class CardScreen extends ConsumerStatefulWidget {
  const CardScreen({super.key});
  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen> {
  final _kwCtrl = TextEditingController();
  String? _typeFilter;
  Timer? _debounce;
  CardSearchKey _searchKey = (keyword: null, cardType: null);

  void _onChange(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _searchKey = (
            keyword: _kwCtrl.text.trim().isEmpty ? null : _kwCtrl.text.trim(),
            cardType: _typeFilter,
          ));
    });
  }

  void _setType(String? t) {
    setState(() {
      _typeFilter = t;
      _searchKey = (
        keyword: _kwCtrl.text.trim().isEmpty ? null : _kwCtrl.text.trim(),
        cardType: t,
      );
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
    final listAsync = ref.watch(cardCatalogSearchProvider(_searchKey));

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, 0, PSpace.x16, PSpace.x12),
            child: Column(
              children: [
                TextField(
                  controller: _kwCtrl,
                  onChanged: _onChange,
                  decoration: InputDecoration(
                    hintText: '카드명 검색',
                    isDense: true,
                    prefixIcon: Icon(LucideIcons.search,
                        size: 16, color: t.fgTertiary),
                    border: OutlineInputBorder(
                      borderRadius: PRadius.brMd,
                      borderSide: BorderSide(color: t.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: PRadius.brMd,
                      borderSide: BorderSide(color: t.borderDefault),
                    ),
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                Row(
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(cardCatalogSearchProvider(_searchKey));
          await ref.read(cardCatalogSearchProvider(_searchKey).future);
        },
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(PSpace.x16),
            child: Text('카드 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger)),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(PSpace.x32),
                  child: Column(children: [
                    Icon(LucideIcons.creditCard,
                        size: 48, color: t.fgDisabled),
                    const SizedBox(height: PSpace.x12),
                    Text('카드가 없습니다',
                        style: PTypo.body.copyWith(color: t.fgTertiary)),
                  ]),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x40),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: PSpace.x8),
              itemBuilder: (_, i) => _CardRow(card: cards[i], tokens: t),
            );
          },
        ),
      ),
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
          borderRadius: PRadius.brPill,
        ),
        child: Text(label,
            style: PTypo.caption.copyWith(
                color: selected ? tokens.fgOnBrand : tokens.fgSecondary,
                fontWeight: FontWeight.w600)),
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
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CardDetailScreen(catalogId: card.rowId))),
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
                            fontWeight: FontWeight.w700),
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
                            fontWeight: FontWeight.w600),
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
