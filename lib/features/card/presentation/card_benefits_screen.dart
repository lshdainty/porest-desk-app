import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_checkbox.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/card_providers.dart';
import '../domain/card_catalog.dart';
import 'card_benefit_detail_sheet.dart';

/// 종류 필터 옵션 — (라벨, cardType). cardType=null 이면 전체.
const _typeOptions = <(String, String?)>[
  ('전체', null),
  ('신용', 'CREDIT'),
  ('체크', 'CHECK'),
];

/// 혜택 필터 옵션 — (라벨, benefitType). 라벨 5개 유지.
/// 매핑: 할인=DISCOUNT, 적립=POINT, 캐시백=POINT, 마일리지=MILEAGE.
const _benefitOptions = <(String, String?)>[
  ('혜택 전체', null),
  ('할인', 'DISCOUNT'),
  ('적립', 'POINT'),
  ('캐시백', 'POINT'),
  ('마일리지', 'MILEAGE'),
];

/// 카드 혜택 라이브러리 — front `CardBenefitsScreen` 미러 (모바일 list 레이아웃).
class CardBenefitsScreen extends ConsumerStatefulWidget {
  const CardBenefitsScreen({super.key});

  @override
  ConsumerState<CardBenefitsScreen> createState() =>
      _CardBenefitsScreenState();
}

class _CardBenefitsScreenState extends ConsumerState<CardBenefitsScreen> {
  final _kwCtrl = TextEditingController();
  int _typeIndex = 0;
  int _benefitIndex = 0;
  bool _includeDiscontinued = false;
  Timer? _debounce;
  CardSearchKey _searchKey = defaultCardSearchKey();

  void _rebuildKey() {
    _searchKey = defaultCardSearchKey(
      keyword: _kwCtrl.text.trim().isEmpty ? null : _kwCtrl.text.trim(),
      cardType: _typeOptions[_typeIndex].$2,
      benefitType: _benefitOptions[_benefitIndex].$2,
      includeDiscontinued: _includeDiscontinued ? true : null,
    );
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(_rebuildKey);
    });
  }

  void _setType(int i) => setState(() {
        _typeIndex = i;
        _rebuildKey();
      });

  void _setBenefit(int i) => setState(() {
        _benefitIndex = i;
        _rebuildKey();
      });

  void _toggleDiscontinued(bool? v) => setState(() {
        _includeDiscontinued = v ?? false;
        _rebuildKey();
      });

  void _goPage(int delta) => setState(() {
        _searchKey = (
          keyword: _searchKey.keyword,
          cardType: _searchKey.cardType,
          benefitType: _searchKey.benefitType,
          includeDiscontinued: _searchKey.includeDiscontinued,
          page: _searchKey.page + delta,
          size: _searchKey.size,
        );
      });

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
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('카드 혜택'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(cardCatalogPageProvider(_searchKey));
          await ref.read(cardCatalogPageProvider(_searchKey).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x40),
          children: [
            // 안내 배너
            const _HeroBanner(),
            const SizedBox(height: PSpace.x12),

            // 검색
            PTextInput(
              controller: _kwCtrl,
              onChanged: _onSearchChanged,
              placeholder: '카드명, 브랜드, 혜택으로 검색',
              prefix:
                  Icon(LucideIcons.search, size: 16, color: t.fgTertiary),
            ),
            const SizedBox(height: PSpace.x12),

            // 종류 필터 (3) + 혜택 필터 (5)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _typeOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    PChip(
                      label: _typeOptions[i].$1,
                      selected: _typeIndex == i,
                      onTap: () => _setType(i),
                    ),
                  ],
                  const SizedBox(width: 14),
                  for (int i = 0; i < _benefitOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    PChip(
                      label: _benefitOptions[i].$1,
                      selected: _benefitIndex == i,
                      onTap: () => _setBenefit(i),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: PSpace.x4),

            // 단종 카드 포함
            Align(
              alignment: Alignment.centerLeft,
              child: PCheckbox(
                value: _includeDiscontinued,
                onChanged: _toggleDiscontinued,
                size: PCheckboxSize.sm,
                label: '단종 카드 포함',
              ),
            ),
            const SizedBox(height: PSpace.x8),

            // 결과 카운트 + 리스트
            pageAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: PSpace.x8),
                child: PListSkeleton(rows: 6, showAvatar: true),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: PSpace.x16),
                child: Text('카드 로드 실패\n$e',
                    style:
                        PTypo.bodySm.copyWith(color: t.statusDanger)),
              ),
              data: (page) {
                final cards = page.content;
                if (cards.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: PSpace.x32),
                    child: PEmptyState(
                      icon: LucideIcons.searchX,
                      message: '결과가 없어요',
                      subMessage: '다른 검색어를 시도해보세요',
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: PSpace.x4, bottom: PSpace.x8),
                      child: Text('총 ${page.totalElements}건',
                          style: PTypo.caption
                              .copyWith(color: t.fgTertiary)),
                    ),
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: PSpace.x8),
                      _CardTile(
                        card: cards[i],
                        onTap: () => showCardBenefitDetailSheet(
                            context, cards[i].rowId),
                        tokens: t,
                      ),
                    ],
                    if (page.totalPages > 1) ...[
                      const SizedBox(height: PSpace.x16),
                      _Paginator(
                        page: page,
                        onPrev: page.first ? null : () => _goPage(-1),
                        onNext: page.last ? null : () => _goPage(1),
                        tokens: t,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 카드 혜택 라이브러리 안내 배너 — front hero 카드 미러.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.bgBrandSubtle,
              borderRadius: PRadius.brMd,
            ),
            child: Icon(LucideIcons.creditCard,
                size: 20, color: t.fgBrand),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('카드 혜택 라이브러리',
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold)),
                const SizedBox(height: 2),
                Text('신용·체크 카드의 혜택을 한 번에',
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 가로형 카드 타일 — front 모바일 list 타일 미러.
/// 좌측 카드 비주얼(imgUrl, fallback 그라데이션) + 이름/메타 + chevron.
class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.onTap,
    required this.tokens,
  });
  final CardCatalogSummary card;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final discontinued = card.isDiscontinued == 'Y';
    return Opacity(
      opacity: discontinued ? 0.6 : 1,
      child: PCard(
        variant: PCardVariant.shadow,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            _CardVisual(imgUrl: card.imgUrl, tokens: t),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(card.cardName,
                            style: PTypo.bodySm.copyWith(
                                color: t.fgPrimary,
                                fontWeight: PFontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (discontinued) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: t.bgSunken,
                            borderRadius: PRadius.brXs,
                          ),
                          child: Text('단종',
                              style: PTypo.micro.copyWith(
                                  color: t.fgTertiary,
                                  fontWeight: PFontWeight.bold,
                                  letterSpacing: 0)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      card.company?.name,
                      card.cardType == 'CHECK' ? '체크' : '신용',
                      '연회비 ${_feeLabel(card.annualFee)}',
                    ].whereType<String>().join(' · '),
                    style:
                        PTypo.caption.copyWith(color: t.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _performanceLabel(card.performance),
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Icon(LucideIcons.chevronRight, size: 14, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

/// 56×36 카드 비주얼 — imgUrl 실제 이미지, 실패/없음 시 중립 그라데이션.
class _CardVisual extends StatelessWidget {
  const _CardVisual({required this.imgUrl, required this.tokens});
  final String? imgUrl;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    Widget fallback() => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [t.bgMuted, t.bgSunken],
            ),
          ),
          child: Center(
            child:
                Icon(LucideIcons.creditCard, size: 16, color: t.fgTertiary),
          ),
        );
    return ClipRRect(
      borderRadius: PRadius.brSm,
      child: SizedBox(
        width: 56,
        height: 36,
        child: (imgUrl != null && imgUrl!.isNotEmpty)
            ? Image.network(imgUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback())
            : fallback(),
      ),
    );
  }
}

/// 연회비 라벨 — label 우선, 없으면 amount 0=없음 / N원.
String _feeLabel(CardAnnualFee? fee) {
  if (fee == null) return '없음';
  if (fee.label != null && fee.label!.isNotEmpty) return fee.label!;
  final amount = fee.amount;
  if (amount == null || amount == 0) return '없음';
  return '${krw(amount)}원';
}

/// 전월 실적 라벨 — requiredText 우선, 없으면 amount 0=실적 무관 / N원/월.
String _performanceLabel(CardPerformance? perf) {
  if (perf == null) return '실적 무관';
  if (perf.requiredText != null && perf.requiredText!.isNotEmpty) {
    return perf.requiredText!;
  }
  final amount = perf.requiredAmount;
  if (amount == null || amount == 0) return '실적 무관';
  return '실적 ${krw(amount)}원/월';
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
    final t = tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageArrow(
            icon: LucideIcons.chevronLeft, onTap: onPrev, tokens: t),
        const SizedBox(width: 12),
        Text(
          '${(page.number as int) + 1} / ${page.totalPages == 0 ? 1 : page.totalPages}',
          style: PTypo.bodySm.copyWith(
              color: t.fgPrimary, fontWeight: PFontWeight.semi),
        ),
        const SizedBox(width: 12),
        _PageArrow(
            icon: LucideIcons.chevronRight, onTap: onNext, tokens: t),
      ],
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow(
      {required this.icon, required this.onTap, required this.tokens});
  final IconData icon;
  final VoidCallback? onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: PRadius.brFull,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon,
              size: 18, color: disabled ? t.fgDisabled : t.fgSecondary),
        ),
      ),
    );
  }
}
