import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_checkbox.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/features/card/presentation/card_benefit_detail_sheet.dart';
import 'package:porest_desk_app/features/card/presentation/widgets/card_brand.dart';

/// 종류 필터 값 — index 0=전체(null)/1=신용/2=체크. 라벨은 [_typeLabel].
const _typeValues = <String?>[null, 'CREDIT', 'CHECK'];

/// 혜택 필터 값 — index 0=전체(null)/1=할인/2=적립/3=캐시백/4=마일리지. 라벨은 [_benefitLabel].
/// 매핑: 할인=DISCOUNT, 적립=POINT, 캐시백=POINT, 마일리지=MILEAGE.
const _benefitValues = <String?>[null, 'DISCOUNT', 'POINT', 'POINT', 'MILEAGE'];

/// 종류 필터 라벨 — index → 로케일 문자열.
String _typeLabel(AppLocalizations l, int i) => switch (i) {
      0 => l.expFilterAll,
      1 => l.assetCardShortCredit,
      _ => l.assetCardShortCheck,
    };

/// 혜택 필터 라벨 — index → 로케일 문자열.
String _benefitLabel(AppLocalizations l, int i) => switch (i) {
      0 => l.cardBenefitTypeAll,
      1 => l.cardBenefitTypeDiscount,
      2 => l.cardBenefitTypePoint,
      3 => l.cardBenefitTypeCashback,
      _ => l.cardBenefitTypeMileage,
    };

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
      cardType: _typeValues[_typeIndex],
      benefitType: _benefitValues[_benefitIndex],
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
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.cardBenefitsTitle),
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
            PSearchField(
              hint: l.cardSearchHintFull,
              controller: _kwCtrl,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: PSpace.x12),

            // 종류 필터 (전체/신용/체크) — 1행 (front 정합: 타입·혜택 별도 행)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: PTabs<int>(
                value: _typeIndex,
                onChanged: _setType,
                variant: PTabsVariant.pills,
                size: PTabsSize.sm,
                items: [
                  for (int i = 0; i < _typeValues.length; i++)
                    PTabItem(value: i, label: _typeLabel(l, i)),
                ],
              ),
            ),
            const SizedBox(height: PSpace.x8),

            // 혜택 필터 (혜택 전체/할인/적립/캐시백/마일리지) — 2행
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: PTabs<int>(
                value: _benefitIndex,
                onChanged: _setBenefit,
                variant: PTabsVariant.pills,
                size: PTabsSize.sm,
                items: [
                  for (int i = 0; i < _benefitValues.length; i++)
                    PTabItem(value: i, label: _benefitLabel(l, i)),
                ],
              ),
            ),
            const SizedBox(height: PSpace.x8),

            // 총 N건(좌) + 단종 카드 포함(우) — 한 줄 (front 정합, 줄 절약)
            Row(
              children: [
                Expanded(
                  child: _initialLoading
                      ? const PSkeleton.line(width: 56, height: 12)
                      : _cards.isNotEmpty
                          ? Text(l.cardTotalCount(_totalElements),
                              style: PTypo.caption.copyWith(color: t.fgTertiary))
                          : const SizedBox.shrink(),
                ),
                PCheckbox(
                  value: _includeDiscontinued,
                  onChanged: _toggleDiscontinued,
                  size: PCheckboxSize.sm,
                  label: l.cardIncludeDiscontinued,
                ),
              ],
            ),
            const SizedBox(height: PSpace.x8),

            // 결과 리스트 (누적식 인피니티 스크롤). 총 N건은 위 Row 로 이동.
            ..._buildResults(t, l),
          ],
        ),
      ),
    );
  }

  /// 결과 영역 — 초기로딩 / 에러 / 빈상태 / 누적 리스트 + 하단 인디케이터.
  List<Widget> _buildResults(PorestTokens t, AppLocalizations l) {
    // 초기 로딩 (첫 페이지 fetch 중, 누적 없음) — _CardTile 카드 스켈레톤만.
    if (_initialLoading) {
      return [
        for (int i = 0; i < 6; i++) ...[
          const _CardTileSkeleton(),
        ],
      ];
    }

    // 에러 (누적된 카드가 없을 때만 전체 에러 표시)
    if (_error != null && _cards.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: PSpace.x16),
          child: Text('${l.cardLoadError}\n$_error',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
        ),
      ];
    }

    // 빈 상태
    if (_cards.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: PSpace.x32),
          child: PEmptyState(
            icon: LucideIcons.searchX,
            message: l.cardNoResults,
            subMessage: l.cardNoResultsHint,
          ),
        ),
      ];
    }

    return [
      for (int i = 0; i < _cards.length; i++) ...[
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
          child: PCircularProgressIndicator(
              size: 24, strokeWidth: 2.5, color: t.bgBrand),
        ),
      ],
    ];
  }
}

/// `_CardTile` 로딩 placeholder — 실제 타일과 1:1 구조 정합.
/// 플랫 행(12/10) + 56×36 비주얼(brSm) + 이름/메타/실적 3줄 + chevron 자리.
class _CardTileSkeleton extends StatelessWidget {
  const _CardTileSkeleton();
  @override
  Widget build(BuildContext context) {
    // 카드 다이어트 — 실제 _CardTile 과 동일 플랫 리듬.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x12, horizontal: 10),
      child: Row(
        children: const [
          PSkeleton(width: 56, height: 36, borderRadius: PRadius.brSm),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.55,
                    child: PSkeleton.line(height: 14)),
                SizedBox(height: 6),
                FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.85,
                    child: PSkeleton.line(height: 12)),
                SizedBox(height: 5),
                FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.4,
                    child: PSkeleton.line(height: 12)),
              ],
            ),
          ),
          SizedBox(width: PSpace.x8),
          PSkeleton(width: 14, height: 14, borderRadius: PRadius.brSm),
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
    final l = AppLocalizations.of(context);
    final discontinued = card.isDiscontinued == 'Y';
    // 카드 다이어트 — 자산 acc-card 리듬 유추 적용: 카드 그림자/배경 없이
    // 플랫 행(12/10, radius 10, 탭 hover). 56×36 브랜드 비주얼 구조는 유지.
    return Opacity(
      opacity: discontinued ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12, horizontal: 10),
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
                          child: Text(l.assetDiscontinued,
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
                      card.cardType == 'CHECK' ? l.assetCardShortCheck : l.assetCardShortCredit,
                      l.cardAnnualFeeValue(_feeLabel(l, card.annualFee)),
                    ].whereType<String>().join(' · '),
                    style:
                        PTypo.caption.copyWith(color: t.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _performanceLabel(l, card.performance),
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
String _feeLabel(AppLocalizations l, CardAnnualFee? fee) {
  if (fee == null) return l.cardNone;
  // front annualFeeText 정합: amount>0 → "N원" 우선, 아니면 label, 둘 다 없으면 "없음".
  final amount = fee.amount;
  if (amount != null && amount > 0) return krwSigned(amount, false, unit: true);
  if (fee.label != null && fee.label!.isNotEmpty) return fee.label!;
  return l.cardNone;
}

/// 전월 실적 라벨 — requiredText 우선, 없으면 amount 0=실적 무관 / N원/월.
String _performanceLabel(AppLocalizations l, CardPerformance? perf) {
  if (perf == null) return l.cardPerfNone;
  // front performanceText 정합: isRequired='Y'일 때만, amount>0 → "실적 N원/월" 우선,
  // 없으면 requiredText. 그 외(미필수)는 항상 "실적 무관".
  final required = perf.isRequired == 'Y';
  if (!required) return l.cardPerfNone;
  final amount = perf.requiredAmount;
  if (amount != null && amount > 0) {
    return l.cardPerfMonthly(krwSigned(amount, false, unit: true));
  }
  if (perf.requiredText != null && perf.requiredText!.isNotEmpty) {
    return perf.requiredText!;
  }
  return l.cardPerfNone;
}
