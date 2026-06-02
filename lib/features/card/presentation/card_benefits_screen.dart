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
import 'widgets/card_brand.dart';

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
  final _scroll = ScrollController();
  int _typeIndex = 0;
  int _benefitIndex = 0;
  bool _includeDiscontinued = false;
  Timer? _debounce;
  CardSearchKey _searchKey = defaultCardSearchKey();

  // ─── 누적식 인피니티 스크롤 상태 ──────────────────────────
  final List<CardCatalogSummary> _cards = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _initialLoading = true;
  Object? _error;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // ref(Provider)·inherited widget 접근은 initState 완료 후로 미룸.
    // initState 안에서 동기 호출하면 _loadMore 의 ref.invalidate/ref.read 가
    // dependOnInheritedWidgetOfExactType<_UncontrolledProviderScope> 를 initState 완료 전에
    // 호출해 "카드 로드 실패" 에러가 발생함.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore(initial: true);
    });
  }

  /// 검색 키를 현재 필터 상태로 갱신. (page/size 제외)
  void _rebuildKey() {
    _searchKey = defaultCardSearchKey(
      keyword: _kwCtrl.text.trim().isEmpty ? null : _kwCtrl.text.trim(),
      cardType: _typeOptions[_typeIndex].$2,
      benefitType: _benefitOptions[_benefitIndex].$2,
      includeDiscontinued: _includeDiscontinued ? true : null,
    );
  }

  /// 특정 page 의 검색 키 파생 (record typedef 라 copyWith 대체).
  CardSearchKey _keyForPage(int page) => (
        keyword: _searchKey.keyword,
        cardType: _searchKey.cardType,
        benefitType: _searchKey.benefitType,
        includeDiscontinued: _searchKey.includeDiscontinued,
        page: page,
        size: _searchKey.size,
      );

  /// 필터/검색 변경 → 누적 리셋 후 첫 페이지부터 다시 로드.
  void _reset() {
    setState(() {
      _cards.clear();
      _page = 0;
      _hasMore = true;
      _initialLoading = true;
      _error = null;
    });
    _loadMore(initial: true);
  }

  Future<void> _loadMore({bool initial = false}) async {
    if (_loadingMore || (!initial && !_hasMore)) return;
    setState(() => _loadingMore = true);
    final key = _keyForPage(_page);
    try {
      // 새 페이지는 항상 최신 데이터를 받도록 캐시 무효화.
      ref.invalidate(cardCatalogPageProvider(key));
      final p = await ref.read(cardCatalogPageProvider(key).future);
      if (!mounted) return;
      setState(() {
        _cards.addAll(p.content);
        _totalElements = p.totalElements;
        _hasMore = !p.last;
        _page += 1;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initialLoading = false;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
            _scroll.position.maxScrollExtent - 300 &&
        _hasMore &&
        !_loadingMore) {
      _loadMore();
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _rebuildKey();
      _reset();
    });
  }

  void _setType(int i) {
    setState(() => _typeIndex = i);
    _rebuildKey();
    _reset();
  }

  void _setBenefit(int i) {
    setState(() => _benefitIndex = i);
    _rebuildKey();
    _reset();
  }

  void _toggleDiscontinued(bool? v) {
    setState(() => _includeDiscontinued = v ?? false);
    _rebuildKey();
    _reset();
  }

  @override
  void dispose() {
    _kwCtrl.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

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
        onRefresh: () async => _reset(),
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x40),
          children: [
            // 검색
            PTextInput(
              controller: _kwCtrl,
              onChanged: _onSearchChanged,
              placeholder: '카드명, 브랜드, 혜택으로 검색',
              search: true,
              prefix:
                  Icon(LucideIcons.search, size: 16, color: t.fgTertiary),
            ),
            const SizedBox(height: PSpace.x12),

            // 종류 필터 (전체/신용/체크) — 1행 (front 정합: 타입·혜택 별도 행)
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
                ],
              ),
            ),
            const SizedBox(height: PSpace.x8),

            // 혜택 필터 (혜택 전체/할인/적립/캐시백/마일리지) — 2행
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
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
            const SizedBox(height: PSpace.x8),

            // 단종 카드 포함 — 우측 정렬 (front 정합)
            Align(
              alignment: Alignment.centerRight,
              child: PCheckbox(
                value: _includeDiscontinued,
                onChanged: _toggleDiscontinued,
                size: PCheckboxSize.sm,
                label: '단종 카드 포함',
              ),
            ),
            const SizedBox(height: PSpace.x8),

            // 결과 카운트 + 리스트 (누적식 인피니티 스크롤)
            ..._buildResults(t),
          ],
        ),
      ),
    );
  }

  /// 결과 영역 — 초기로딩 / 에러 / 빈상태 / 누적 리스트 + 하단 인디케이터.
  List<Widget> _buildResults(PorestTokens t) {
    // 초기 로딩 (첫 페이지 fetch 중, 누적 없음)
    if (_initialLoading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: PSpace.x8),
          child: PListSkeleton(rows: 6, showAvatar: true),
        ),
      ];
    }

    // 에러 (누적된 카드가 없을 때만 전체 에러 표시)
    if (_error != null && _cards.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: PSpace.x16),
          child: Text('카드 로드 실패\n$_error',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
        ),
      ];
    }

    // 빈 상태
    if (_cards.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: PSpace.x32),
          child: PEmptyState(
            icon: LucideIcons.searchX,
            message: '결과가 없어요',
            subMessage: '다른 검색어를 시도해보세요',
          ),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(left: PSpace.x4, bottom: PSpace.x8),
        child: Text('총 $_totalElements건',
            style: PTypo.caption.copyWith(color: t.fgTertiary)),
      ),
      for (int i = 0; i < _cards.length; i++) ...[
        if (i > 0) const SizedBox(height: PSpace.x8),
        _CardTile(
          card: _cards[i],
          onTap: () =>
              showCardBenefitDetailSheet(context, _cards[i].rowId),
          tokens: t,
        ),
      ],
      // 추가 페이지 로딩 인디케이터
      if (_loadingMore) ...[
        const SizedBox(height: PSpace.x16),
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: t.bgBrand),
          ),
        ),
      ],
    ];
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
            _CardVisual(
                imgUrl: card.imgUrl, company: card.company?.name, tokens: t),
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

/// 56×36 카드 비주얼 — 3단계 fallback.
/// 1) imgUrl 로드 성공 → 실제 이미지.
/// 2) imgUrl 없음/로드 실패 + 브랜드 매칭 → 카드사 색 그라데이션 + 브랜드 약자.
/// 3) 브랜드 미상 → 중립 그라데이션(bgMuted~bgSunken) + 카드 아이콘.
class _CardVisual extends StatelessWidget {
  const _CardVisual({
    required this.imgUrl,
    required this.company,
    required this.tokens,
  });
  final String? imgUrl;
  final String? company;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final brand = getCardBrand(company);

    Widget neutralFallback() => DecoratedBox(
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

    // 브랜드명 약자 — company.name 첫 글자.
    Widget brandFallback() => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brand.bg1, brand.bg2],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 135deg 광택 — 기존 그라데이션 위 부드러운 하이라이트.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
              Center(
                child: Text(
                  _brandInitial(company),
                  style: PTypo.caption.copyWith(
                    color: brand.fg,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        );

    Widget fallback() => brand.known ? brandFallback() : neutralFallback();

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

/// 브랜드명 약자 — company.name 첫 글자(공백 제거). 비면 'C'.
String _brandInitial(String? company) {
  final n = (company ?? '').trim();
  if (n.isEmpty) return 'C';
  return n.characters.first;
}

/// 연회비 라벨 — label 우선, 없으면 amount 0=없음 / N원.
String _feeLabel(CardAnnualFee? fee) {
  if (fee == null) return '없음';
  // front annualFeeText 정합: amount>0 → "N원" 우선, 아니면 label, 둘 다 없으면 "없음".
  final amount = fee.amount;
  if (amount != null && amount > 0) return '${krw(amount)}원';
  if (fee.label != null && fee.label!.isNotEmpty) return fee.label!;
  return '없음';
}

/// 전월 실적 라벨 — requiredText 우선, 없으면 amount 0=실적 무관 / N원/월.
String _performanceLabel(CardPerformance? perf) {
  if (perf == null) return '실적 무관';
  // front performanceText 정합: isRequired='Y'일 때만, amount>0 → "실적 N원/월" 우선,
  // 없으면 requiredText. 그 외(미필수)는 항상 "실적 무관".
  final required = perf.isRequired == 'Y';
  if (!required) return '실적 무관';
  final amount = perf.requiredAmount;
  if (amount != null && amount > 0) return '실적 ${krw(amount)}원/월';
  if (perf.requiredText != null && perf.requiredText!.isNotEmpty) {
    return perf.requiredText!;
  }
  return '실적 무관';
}
