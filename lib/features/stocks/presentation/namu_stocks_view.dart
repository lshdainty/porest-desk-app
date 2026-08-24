import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(PSpace.x24, PSpace.x16, PSpace.x24, PSpace.x24),
      children: [
        PTabs<String>(
          value: _currency,
          onChanged: (v) => setState(() => _currency = v),
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
          _SearchResults(
            keyword: _keyword,
            onPick: (item) => setState(() => _selected = item),
          )
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
      loading: () => const PSkeleton(height: 140),
      // 계좌가 없거나 조회가 막히면 화면을 비우지 않고 이유를 보여준다.
      error: (_, _) => PCard(
        variant: PCardVariant.bordered,
        child: Row(
          children: [
            Icon(LucideIcons.unplug, size: 16, color: t.fgTertiary),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Text(l.namuHoldingsError,
                  style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
            ),
          ],
        ),
      ),
      data: (h) => PCard(
        variant: PCardVariant.bordered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.namuHoldingsTitle, style: PTypo.caption.copyWith(color: t.fgTertiary)),
            const SizedBox(height: PSpace.x4),
            Text(
              '${_fmt(h.totalEvalValue)} ${h.currency}',
              style: PTypo.h3.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '${h.totalProfitLossValue >= 0 ? '+' : ''}${_fmt(h.totalProfitLossValue)} '
              '(${h.profitRateValue.toStringAsFixed(2)}%)',
              style: PTypo.bodySm.copyWith(
                color: h.totalProfitLossValue >= 0 ? t.statusSuccessFg : t.statusDanger,
                fontWeight: PFontWeight.semi,
              ),
            ),
            if (h.items.isEmpty) ...[
              const SizedBox(height: PSpace.x12),
              Text(l.namuHoldingsEmpty, style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
            ] else
              for (final item in h.items) _HoldingRow(item: item, currency: h.currency),
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
                Text(item.name.isEmpty ? item.symbol : item.name,
                    style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
                const SizedBox(height: 2),
                Text(l.namuHoldingQty(item.quantity),
                    style: PTypo.micro.copyWith(color: t.fgTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_fmt(item.evalAmountValue)} $currency',
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.semi)),
              const SizedBox(height: 2),
              Text('${up ? '+' : ''}${_fmt(item.profitLossValue)}',
                  style: PTypo.micro.copyWith(
                      color: up ? t.statusSuccessFg : t.statusDanger)),
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
      error: (_, _) => PEmptyState(icon: LucideIcons.unplug, message: l.stocksSearchError),
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
                          horizontal: PSpace.x4, vertical: PSpace.x12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.nameKr,
                                    style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
                                const SizedBox(height: 2),
                                Text('${item.marketCode} · ${item.symbol}',
                                    style: PTypo.micro.copyWith(color: t.fgTertiary)),
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
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
          Text(item.nameKr,
              style: PTypo.body.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: 2),
          Text('${item.marketCode} · ${item.symbol}',
              style: PTypo.micro.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x12),
          priceAsync.when(
            loading: () => const PSkeleton(height: 28, width: 140),
            error: (_, _) => Text(l.namuPriceError,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
            data: (price) => price == null
                ? Text(l.namuPriceEmpty,
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary))
                : Text(
                    '${price.price} ${price.currency}',
                    style: PTypo.h3.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
