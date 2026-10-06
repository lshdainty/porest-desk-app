import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/lifecycle/screen_visibility.dart';
import 'package:porest_desk_app/core/sync/query_freshness.dart';
import 'package:porest_desk_app/features/stocks/application/namu_providers.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/data/namu_repository.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

/// 나무증권 본문.
///
/// 토스 화면과 **합치지 않는다.** 나무엔 랭킹·시장지표·호가가 없고 대신 체결추이·투자자별·
/// 채권·금현물이 있다. 한 화면에 합치면 절반이 "이 증권사는 미지원" 이 된다.
///
/// 지금은 종목 검색 + 현재가까지다. 나무 고유 조회(체결추이·투자자별 등)는 이 파일에
/// 쌓으면 되고, 그때 토스 화면은 손대지 않는다.
class NamuStocksView extends ConsumerStatefulWidget {
  const NamuStocksView({super.key});

  @override
  ConsumerState<NamuStocksView> createState() => _NamuStocksViewState();
}

class _NamuStocksViewState extends ConsumerState<NamuStocksView> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';
  StockMasterItem? _selected;
  // 국내·해외는 나무 쪽 엔드포인트가 달라 한 번에 못 받는다 — 사용자가 고른다.
  String _currency = 'KRW';
  Timer? _priceTimer; // 고른 종목의 현재가 폴링 — 고르기 전에는 없다

  @override
  void initState() {
    super.initState();
    // 받아 둔 값은 앱을 끌 때까지 그대로다(autoDispose 가 아니다). 여기서 밀지 않으면
    // 아무도 안 민다 — 예전엔 처음 받은 시세·보유 종목이 앱을 다시 켤 때까지 굳어 있었다.
    // 박자는 웹 나무 화면과 같다(namu_providers.dart 의 표).
    //
    // 현재가 — 종목을 고른 뒤 30초마다, 그 종목 하나만([_pick]).
    // 보유 종목 — 주기로 조르지 않는다. 화면에 들어올 때·앱으로 돌아올 때·통화를 바꿀
    // 때 받은 지 30초가 지났으면 다시 받는다.
    ref.listenManual(appForegroundProvider, (wasForeground, isForeground) {
      if (isForeground && wasForeground == false) _refreshHoldingsIfStale();
    });
    // 첫 판정은 microtask 로 미룬다 — initState 안에서는 provider 를 비우지 못한다
    // (빌드 중이다).
    Future.microtask(_refreshHoldingsIfStale);
  }

  /// 종목을 고른다 — 그 자리에서 시세를 받고, 거기서부터 30초 박자를 센다.
  void _pick(StockMasterItem item) {
    // 예전에 본 종목이면 그때 값이 남아 있다. 안 비우면 다음 폴링까지 묵은 시세가
    // "현재가" 로 보인다.
    _refreshPrice(item);
    setState(() => _selected = item);
    // 박자는 **고른 순간부터** 센다(웹도 조회가 붙은 때부터 센다). 화면을 연 때부터
    // 세면 고른 지 몇 초 만에 한 번 더 나간다.
    _priceTimer?.cancel();
    _priceTimer = Timer.periodic(
      namuPricePollInterval,
      (_) => _refreshSelectedPrice(),
    );
  }

  /// 고른 종목의 현재가를 다시 받는다 — 폴링 한 박자.
  void _refreshSelectedPrice() {
    final selected = _selected;
    if (!mounted || selected == null) return;
    // 앱이 가려진 동안은 건너뛴다(웹도 탭이 가려지면 주기 조회를 멈춘다). 타이머는
    // 그대로 두므로 돌아오면 다음 박자에 이어서 받는다.
    if (!ref.read(appForegroundProvider)) return;
    _refreshPrice(selected);
  }

  /// [item] 의 현재가를 다시 받는다. 받는 중이면 그 결과를 기다린다 — 응답이 느릴 때
  /// 박자마다, 또는 같은 종목을 연달아 누를 때마다 겹쳐 나가면 나무 유량만 쓴다.
  void _refreshPrice(StockMasterItem item) {
    final price = namuPriceProvider(item);
    // 처음 고른 종목은 현재가 카드가 그려지면서 받는다.
    if (!ref.exists(price) || ref.read(price).isLoading) return;
    ref.invalidate(price);
  }

  /// 지금 보는 통화의 보유 종목이 낡았으면 다시 받는다.
  void _refreshHoldingsIfStale() {
    if (!mounted) return;
    final provider = namuHoldingsProvider(_currency);
    // 아직 안 읽은 통화는 패널이 그려지면서 처음 받는다.
    if (!ref.exists(provider)) return;
    // 받는 중이면 그 결과를 기다린다 — 여기서 또 비우면 같은 조회가 겹쳐 나간다.
    if (ref.read(provider).isLoading) return;
    // 시각은 **성공한 조회**만 남긴다. 실패한 조회는 그래서 늘 낡은 것으로 읽힌다 —
    // 처음부터 실패했으면 시각이 없고, 다시 받다 실패했으면 이미 30초가 지난 값이다.
    final fetchedAt = ref.read(namuHoldingsFetchedAtProvider)[_currency];
    if (namuHoldingsStale(fetchedAt, ref.read(freshnessClockProvider)())) {
      ref.invalidate(provider);
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: [
        PTabs<String>(
          value: _currency,
          onChanged: (v) {
            setState(() => _currency = v);
            _refreshHoldingsIfStale();
          },
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: [
            PTabItem(value: 'KRW', label: l.namuTabDomestic),
            PTabItem(value: 'USD', label: l.namuTabOverseas),
          ],
        ),
        const SizedBox(height: PSpace.x16),
        _HoldingsPanel(currency: _currency),
        const SizedBox(height: PSpace.x16),
        PSearchField(
          controller: _searchCtrl,
          hint: l.stocksSearch,
          onChanged: (v) => setState(() => _keyword = v.trim()),
        ),
        const SizedBox(height: PSpace.x16),
        if (_selected != null) ...[
          _PriceCard(item: _selected!),
          const SizedBox(height: PSpace.x16),
        ],
        if (_keyword.length >= 2)
          _SearchResults(keyword: _keyword, onPick: _pick)
        else
          Padding(
            padding: const EdgeInsets.only(top: PSpace.x32),
            child: PEmptyState(
              icon: LucideIcons.search,
              message: l.namuSearchPrompt,
              subMessage: l.namuScopeNotice,
            ),
          ),
        const SizedBox(height: PSpace.x16),
        Text(
          l.namuScopeNotice,
          style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5),
        ),
      ],
    );
  }
}

/// 보유 종목 — 요약 + 목록.
class _HoldingsPanel extends ConsumerWidget {
  const _HoldingsPanel({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final holdingsAsync = ref.watch(namuHoldingsProvider(currency));

    return holdingsAsync.when(
      // 다시 받다 실패하면 보던 값을 그대로 둔다. 예전엔 다시 받는 일이 없어 값이
      // 오류로 뒤집힐 일도 없었다 — 앱으로 돌아온 순간의 실패 한 번으로 보유 종목이
      // "계좌가 없을 수 있어요" 로 바뀌면 안 된다. 다음 진입·복귀 때 다시 받는다.
      skipError: true,
      loading: () => const PSkeleton(height: 140),
      // 계좌가 없거나 조회가 막히면 화면을 비우지 않고 이유를 보여준다.
      error: (_, _) => PCard(
        variant: PCardVariant.bordered,
        child: Row(
          children: [
            Icon(LucideIcons.unplug, size: 16, color: t.fgTertiary),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Text(
                l.namuHoldingsError,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          ],
        ),
      ),
      data: (h) => PCard(
        variant: PCardVariant.bordered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.namuHoldingsTitle,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
            const SizedBox(height: PSpace.x4),
            Text(
              '${_fmt(h.totalEvalValue)} ${h.currency}',
              style: PTypo.h3.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${h.totalProfitLossValue >= 0 ? '+' : ''}${_fmt(h.totalProfitLossValue)} '
              '(${h.profitRateValue.toStringAsFixed(2)}%)',
              style: PTypo.bodySm.copyWith(
                color: h.totalProfitLossValue >= 0
                    ? t.statusSuccessFg
                    : t.statusDangerFg,
                fontWeight: PFontWeight.semi,
              ),
            ),
            if (h.items.isEmpty) ...[
              const SizedBox(height: PSpace.x12),
              Text(
                l.namuHoldingsEmpty,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ] else
              for (final item in h.items)
                _HoldingRow(item: item, currency: h.currency),
          ],
        ),
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.item, required this.currency});

  final NamuHoldingItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final up = item.profitLossValue >= 0;

    return Padding(
      padding: const EdgeInsets.only(top: PSpace.x12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? item.symbol : item.name,
                  style: PTypo.bodySm.copyWith(color: t.fgPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  l.namuHoldingQty(item.quantity),
                  style: PTypo.micro.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(item.evalAmountValue)} $currency',
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${up ? '+' : ''}${_fmt(item.profitLossValue)}',
                style: PTypo.micro.copyWith(
                  color: up ? t.statusSuccessFg : t.statusDangerFg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 소수점이 의미 없는 원화와 있는 외화를 같은 함수로 다룬다.
String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.keyword, required this.onPick});

  final String keyword;
  final ValueChanged<StockMasterItem> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final results = ref.watch(stockSearchProvider(keyword));

    return results.when(
      loading: () => const PSkeleton(height: 120),
      error: (_, _) =>
          PEmptyState(icon: LucideIcons.unplug, message: l.stocksSearchError),
      data: (items) => items.isEmpty
          ? PEmptyState(icon: LucideIcons.search, message: l.stocksSearchEmpty)
          : Column(
              children: [
                for (final item in items)
                  InkWell(
                    onTap: () => onPick(item),
                    borderRadius: PRadius.brMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PSpace.x4,
                        vertical: PSpace.x12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nameKr,
                                  style: PTypo.bodySm.copyWith(
                                    color: t.fgPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.marketCode} · ${item.symbol}',
                                  style: PTypo.micro.copyWith(
                                    color: t.fgTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: t.fgTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// 선택 종목의 나무 현재가.
class _PriceCard extends ConsumerWidget {
  const _PriceCard({required this.item});

  final StockMasterItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final priceAsync = ref.watch(namuPriceProvider(item));

    return PCard(
      variant: PCardVariant.bordered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.nameKr,
            style: PTypo.body.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.marketCode} · ${item.symbol}',
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(height: PSpace.x12),
          priceAsync.when(
            // 폴링 한 번이 실패해도 방금까지 보던 시세를 그대로 둔다(웹과 같다).
            // 처음부터 못 받은 경우에만 오류 문구가 나온다.
            skipError: true,
            loading: () => const PSkeleton(height: 28, width: 140),
            error: (_, _) => Text(
              l.namuPriceError,
              style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            ),
            data: (price) => price == null
                ? Text(
                    l.namuPriceEmpty,
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                  )
                : Text(
                    '${price.price} ${price.currency}',
                    style: PTypo.h3.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
