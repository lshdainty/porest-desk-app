import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/colors.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/format_locale.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/presentation/chart_web_view.dart';
import 'package:porest_desk_app/features/stocks/presentation/stock_market_label.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';
import 'package:porest_desk_app/features/stocks/data/watch_dto.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';

/// 증권 — 시세 · 보유 · 관심 · 호가 (토스증권 Open API 실연동).
/// 웹 `pages/stocks/ui/StocksPage.tsx` 미러 (디자인 리뉴얼 반영).
/// 차트·일별시세=실 candles, 등락률=prices+전일종가, 장상태=market-calendar,
/// 기본정보=stocks+price-limits, 매수유의=warnings, 호가/체결=실데이터 전용.
/// 검색=서버 stock_master, 관심=서버 stock-watch, 발견=토스 rankings — mock 전면 제거.
/// 상승=statusDangerFg / 하락=fgBrand (국내 증권 통념, 기존 시맨틱 토큰 재활용).
class TossStocksView extends ConsumerStatefulWidget {
  const TossStocksView({super.key});

  @override
  ConsumerState<TossStocksView> createState() => _TossStocksViewState();
}

enum _Seg { holdings, watch, discover }

/// 숫자 정렬용 tabular figures — 웹 `.num`(tnum) 미러. 가격·수량·수익률 등에 적용.
const List<FontFeature> _tnum = [FontFeature.tabularFigures()];

class _TossStocksViewState extends ConsumerState<TossStocksView> {
  _Seg _seg = _Seg.holdings;

  /// 활성 관심 그룹 rowId — 서버 그룹 목록에 없으면 build 에서 첫 그룹으로 보정.
  int? _activeGroupId;
  Timer? _priceTimer; // 라이브 시세 폴링 — 헤더 가격/등락%·리스트 시세 주기 갱신

  @override
  void initState() {
    super.initState();
    // 라이브 갱신 — 10초마다:
    // - prices: 관심/상세 현재가 재조회(family invalidate — watch 중인 키만 재요청).
    //   prevClose(전일 종가)는 하루 단위 값이라 invalidate 하지 않는다.
    // - orderbook/trades: 호가·체결 family provider 일괄 invalidate(현재 보이는 종목만 자동 재조회).
    // - candles: 일별표 1d 캔들 재조회(family invalidate).
    // - holdings: 보유종목 평가액(현재가 반영) 재조회 → 상세 보유정보 갱신.
    // family 들은 화면이 watch 하지 않으면 NOP.
    _priceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      ref.invalidate(tossPricesProvider);
      ref.invalidate(tossOrderbookProvider);
      ref.invalidate(tossTradesProvider);
      ref.invalidate(tossCandlesProvider);
      ref.invalidate(tossHoldingsProvider);
    });
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    super.dispose();
  }

  /// 전 그룹에서 심볼이 담긴 항목을 찾는다 (별 토글 판정·전체 해제용). 웹 findWatchEntries 미러.
  List<WatchItem> _watchEntriesOf(
    List<StockWatchGroup> groups,
    String symbol,
  ) => [for (final g in groups) ...g.items.where((i) => i.symbol == symbol)];

  /// 관심 별 토글 — 서버 뮤테이션(stock-watch). 어느 그룹에든 있으면 전부 해제,
  /// 없으면 활성 그룹(그룹 0개면 기본 그룹 생성 후)에 추가. 웹 toggleWatch 미러.
  Future<void> _toggleWatch(String symbol, {String? marketCode}) async {
    final l = AppLocalizations.of(context);
    final groups =
        ref.read(watchGroupsProvider).asData?.value ??
        const <StockWatchGroup>[];
    try {
      final repo = await ref.read(stocksRepositoryProvider.future);
      final entries = _watchEntriesOf(groups, symbol);
      if (entries.isNotEmpty) {
        // 별 해제 = 모든 그룹에서 제거 (기존 UX 유지)
        for (final e in entries) {
          await repo.removeWatchItem(e.rowId);
        }
      } else if (groups.isEmpty) {
        // 첫 관심 등록이면 기본 그룹부터 만든다.
        final g = await repo.createWatchGroup(l.stocksWatchDefaultGroupName);
        await repo.addWatchItem(g.rowId, symbol, marketCode: marketCode);
      } else {
        final groupId = groups.any((g) => g.rowId == _activeGroupId)
            ? _activeGroupId!
            : groups.first.rowId;
        await repo.addWatchItem(groupId, symbol, marketCode: marketCode);
      }
      ref.invalidate(watchGroupsProvider);
    } on ApiException {
      // 서버 에러는 ErrorToastInterceptor 가 띄운다.
    } catch (_) {
      // API 가 아닌 예외는 인터셉터가 못 잡는다 — 여기서 알린다.
      if (mounted) {
        showPSnackBar(
          context,
          l.stocksWatchAddFail,
          severity: PSnackSeverity.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('stocks.summary'));

    // 보유자산 — 키 연결 시 실데이터, 미연결 시 null(연결 유도 빈 상태). mock 미사용.
    final holdings = ref.watch(tossHoldingsProvider).asData?.value;
    final holdingItems = holdings == null
        ? const <TossHoldingsItem>[]
        : ([...holdings.items]..sort(
            (a, b) =>
                b.marketValueAmountValue.compareTo(a.marketValueAmountValue),
          ));

    // 관심목록 — 서버 영속(stock-watch). 활성 그룹이 목록에 없으면 첫 그룹으로 보정.
    final watchGroups =
        ref.watch(watchGroupsProvider).asData?.value ??
        const <StockWatchGroup>[];
    final activeGroupId = watchGroups.isEmpty
        ? null
        : (watchGroups.any((g) => g.rowId == _activeGroupId)
              ? _activeGroupId
              : watchGroups.first.rowId);
    final curGroup = activeGroupId == null
        ? null
        : watchGroups.firstWhere((g) => g.rowId == activeGroupId);
    // 관심 탭 카운트 = 전 그룹 유니크 심볼 수.
    final watchedSymbols = {
      for (final g in watchGroups) ...g.items.map((i) => i.symbol),
    };

    // Scaffold·AppBar 는 증권사 셸(StocksScreen)이 소유한다 — 증권사를 바꿔도 헤더가 유지된다.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: [
        const _MarketStatusBar(),
        const SizedBox(height: PSpace.x16),
        _SummaryCard(masked: masked, holdings: holdings),
        const SizedBox(height: PSpace.x16),
        // 종목 검색 트리거 — 공통 PSearchField 시각(36px) 그대로, 탭 시 검색 시트
        GestureDetector(
          onTap: _openSearch,
          child: AbsorbPointer(child: PSearchField(hint: l.stocksSearch)),
        ),
        const SizedBox(height: 14),
        PTabs<_Seg>(
          value: _seg,
          onChanged: (v) => setState(() => _seg = v),
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: [
            PTabItem(
              value: _Seg.holdings,
              label: l.stocksTabHoldings(holdingItems.length),
            ),
            PTabItem(
              value: _Seg.watch,
              label: l.stocksTabWatch(watchedSymbols.length),
            ),
            PTabItem(value: _Seg.discover, label: l.stocksTabDiscover),
          ],
        ),
        const SizedBox(height: 14),
        if (_seg == _Seg.discover)
          _DiscoverPanel(onPick: _openDetail)
        else if (_seg == _Seg.holdings)
          holdings == null
              ? _HoldingsEmpty(onConnect: () => context.push('/account'))
              : holdingItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: PSpace.x32,
                    horizontal: PSpace.x20,
                  ),
                  child: Center(
                    child: Text(
                      l.stocksNoHoldings,
                      style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final h in holdingItems)
                      _StockRow(
                        symbol: h.symbol,
                        name: h.name.isNotEmpty ? h.name : h.symbol,
                        countryCode: h.isUs ? 'US' : 'KR',
                        currency: h.currency,
                        sub: l.stocksSharesHeld(h.quantity),
                        onTap: () => _openDetail(h.symbol),
                        right: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              krwMasked(
                                h.marketValueAmountValue.round(),
                                masked,
                                mask: '••••',
                              ),
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontFeatures: _tnum,
                                fontSize: 13.5,
                                fontWeight: PFontWeight.bold,
                                color: t.fgPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${h.profitLossRateValue >= 0 ? '+' : ''}${h.profitLossRateValue.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontFeatures: _tnum,
                                fontSize: PFontSize.micro,
                                fontWeight: PFontWeight.bold,
                                color: _trendColor(t, h.profitLossAmountValue),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
        else ...[
          // 그룹 탭 + 그룹 편집(이름변경/추가) — 웹 watch 탭 헤더 미러.
          Row(
            children: [
              Expanded(
                child: watchGroups.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: PTabs<String>(
                          value: '$activeGroupId',
                          onChanged: (v) =>
                              setState(() => _activeGroupId = int.tryParse(v)),
                          variant: PTabsVariant.container,
                          size: PTabsSize.sm,
                          items: [
                            for (final g in watchGroups)
                              PTabItem(
                                value: '${g.rowId}',
                                label: '${g.groupName} ${g.items.length}',
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: PSpace.x8),
              if (curGroup != null)
                PButton.icon(
                  icon: LucideIcons.pencil,
                  size: PButtonSize.sm,
                  tooltip: l.stocksWatchGroupRename,
                  onPressed: () => _openGroupEditor(group: curGroup),
                ),
              PButton.icon(
                icon: LucideIcons.plus,
                size: PButtonSize.sm,
                tooltip: l.stocksWatchGroupAdd,
                onPressed: () => _openGroupEditor(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (curGroup == null || curGroup.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: PSpace.x32,
                horizontal: PSpace.x20,
              ),
              child: Center(
                child: Text(
                  l.stocksNoWatchlist,
                  style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                ),
              ),
            )
          else
            Column(
              children: [
                // 시세는 그룹 심볼 콤마 조인 1콜(tossPrices) + 행별 전일종가.
                for (final item in curGroup.items)
                  _WatchRow(
                    item: item,
                    joinedSymbols: curGroup.items
                        .map((i) => i.symbol)
                        .join(','),
                    onTap: () => _openDetail(item.symbol),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  void _openSearch() {
    final l = AppLocalizations.of(context);
    showPSheet<void>(
      context,
      title: l.stocksSearch,
      initialChildSize: 0.9,
      contentBuilder: (sheetCtx, scrollCtrl) => _SearchSheetBody(
        scrollController: scrollCtrl,
        onPick: (symbol) {
          Navigator.of(sheetCtx).pop();
          _openDetail(symbol);
        },
      ),
    );
  }

  /// 관심 그룹 추가/이름변경(+삭제) 시트 — 웹 WatchGroupDialog 미러.
  void _openGroupEditor({StockWatchGroup? group}) {
    final l = AppLocalizations.of(context);
    showPSheet<void>(
      context,
      title: group == null ? l.stocksWatchGroupAdd : l.stocksWatchGroupRename,
      shrinkWrap: true,
      contentBuilder: (sheetCtx, _) => _GroupEditorSheetBody(group: group),
    );
  }

  void _openDetail(String symbol) {
    final l = AppLocalizations.of(context);
    showPSheet<void>(
      context,
      title: l.stocksDetailTitle,
      initialChildSize: 0.9,
      contentBuilder: (sheetCtx, scrollCtrl) => _StockDetailBody(
        ticker: symbol,
        onToggleWatch: (marketCode) =>
            _toggleWatch(symbol, marketCode: marketCode),
        scrollController: scrollCtrl,
      ),
    );
  }
}

// ---- 종목 검색 시트 (서버 stock_master — 국내 + 해외 6개국) -------------------

class _SearchSheetBody extends ConsumerStatefulWidget {
  const _SearchSheetBody({
    required this.scrollController,
    required this.onPick,
  });
  final ScrollController scrollController;
  final void Function(String symbol) onPick;

  @override
  ConsumerState<_SearchSheetBody> createState() => _SearchSheetBodyState();
}

class _SearchSheetBodyState extends ConsumerState<_SearchSheetBody> {
  // 서버 검색 디바운스 — 키 입력마다 요청이 나가지 않게 300ms 지연.
  Timer? _searchDebounce;
  String _query = '';
  String _debouncedQuery = '';

  void _onChanged(String v) {
    setState(() => _query = v);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _debouncedQuery = _query.trim());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final q = _query.trim();
    final searchAsync = ref.watch(stockSearchProvider(_debouncedQuery));
    final results = searchAsync.asData?.value ?? const <StockMasterItem>[];
    // 빈 결과 문구는 응답이 끝난 뒤에만 노출해 깜빡임을 막는다 (웹 searched 미러).
    final searched =
        _debouncedQuery.isNotEmpty &&
        q == _debouncedQuery &&
        searchAsync.hasValue;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x24),
      children: [
        PSearchField(
          hint: l.stocksSearchPlaceholder,
          autofocus: true,
          onChanged: _onChanged,
        ),
        const SizedBox(height: PSpace.x8),
        if (q.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x40),
            child: Center(
              child: Text(
                l.stocksSearchHint,
                textAlign: TextAlign.center,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else if (searched && results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x40),
            child: Center(
              child: Text(
                l.stocksSearchNoResults(q),
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else
          for (final s in results)
            _StockRow(
              symbol: s.symbol,
              name: s.nameKr.isNotEmpty ? s.nameKr : s.symbol,
              countryCode: s.countryCode,
              currency: s.currency,
              sub:
                  '${stockMarketLabel(l, s.marketCode)}'
                  ' · ${stockSecurityTypeLabel(l, s.securityType)}',
              // 검색 행은 시세 미표시 (웹 right=<span/> 미러).
              right: const SizedBox.shrink(),
              onTap: () => widget.onPick(s.symbol),
            ),
      ],
    );
  }
}

// ---- 관심 그룹 편집 시트 (추가/이름변경/삭제 — 웹 WatchGroupDialog 미러) ------

class _GroupEditorSheetBody extends ConsumerStatefulWidget {
  const _GroupEditorSheetBody({required this.group});

  /// null = 그룹 추가, 비 null = 이름변경(+삭제).
  final StockWatchGroup? group;

  @override
  ConsumerState<_GroupEditorSheetBody> createState() =>
      _GroupEditorSheetBodyState();
}

class _GroupEditorSheetBodyState extends ConsumerState<_GroupEditorSheetBody> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.group?.groupName ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 뮤테이션 공통 — 성공 시 invalidate + 시트 닫기, 실패 시 시트 유지 + 에러 스낵바.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(watchGroupsProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException {
      // 서버 에러는 ErrorToastInterceptor 가 띄운다.
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      // API 가 아닌 예외는 인터셉터가 못 잡는다 — 여기서 알린다.
      if (mounted) {
        setState(() => _busy = false);
        showPSnackBar(
          context,
          AppLocalizations.of(context).stocksWatchGroupSaveFail,
          severity: PSnackSeverity.error,
        );
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await _run(() async {
      final repo = await ref.read(stocksRepositoryProvider.future);
      final g = widget.group;
      if (g == null) {
        await repo.createWatchGroup(name);
      } else {
        await repo.renameWatchGroup(g.rowId, name);
      }
    });
  }

  Future<void> _delete() async {
    final g = widget.group;
    if (g == null || _busy) return;
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.stocksWatchGroupDelete,
      message: l.stocksWatchGroupDeleteConfirm(g.groupName),
      destructive: true,
    );
    if (!ok) return;
    await _run(() async {
      final repo = await ref.read(stocksRepositoryProvider.future);
      await repo.deleteWatchGroup(g.rowId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canSave = _nameCtrl.text.trim().isNotEmpty && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PTextInput(
            controller: _nameCtrl,
            placeholder: l.stocksWatchGroupNamePlaceholder,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: PSpace.x12),
          // 삭제·저장은 화면 폭을 반씩 나눠 갖는다 (spec drawer.md "flex:1 평등 분배").
          // 삭제만 내용 폭이면 파괴적 액션이 구석의 작은 알약이 돼 오탭이 는다.
          Row(
            children: [
              Expanded(
                child: PButton(
                  label: l.actionSave,
                  size: PButtonSize.sm,
                  fullWidth: true,
                  loading: _busy,
                  onPressed: canSave ? _save : null,
                ),
              ),
              if (widget.group != null) ...[
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: PButton(
                    label: l.stocksWatchGroupDelete,
                    variant: PButtonVariant.danger,
                    size: PButtonSize.sm,
                    fullWidth: true,
                    onPressed: _busy ? null : _delete,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---- 색 헬퍼 ---------------------------------------------------------------

/// 상승/하락 색 — 국내 증권 통념: 상승=빨강(error), 하락=파랑(primary).
Color _trendColor(PorestTokens t, double pct) =>
    pct >= 0 ? t.statusDangerFg : t.fgBrand;

/// 종목 심볼 배지 tone — 국가별 chart palette (다크 light swap). 웹 COUNTRY_TONE 미러.
/// KR=blue / US=violet / CN=orange / JP=pink / HK=green / VN=indigo.
Color _countryTone(BuildContext context, String countryCode) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (countryCode) {
    'US' => dark ? PorestPalette.chartVioletLight : PorestPalette.chartViolet,
    'CN' => dark ? PorestPalette.chartOrangeLight : PorestPalette.chartOrange,
    'JP' => dark ? PorestPalette.chartPinkLight : PorestPalette.chartPink,
    'HK' => dark ? PorestPalette.chartGreenLight : PorestPalette.chartGreen,
    'VN' => dark ? PorestPalette.chartIndigoLight : PorestPalette.chartIndigo,
    _ => dark ? PorestPalette.chartBlueLight : PorestPalette.chartBlue,
  };
}

/// 통화별 가격 표기 — KRW=원화, USD=$ 소수 2자리, 그 외(CNY·JPY 등)=값+통화코드.
/// 웹 fmtByCurrency 미러 (toLocaleString maximumFractionDigits 2 정합).
String _fmtByCurrency(double price, String currency) {
  if (currency == 'USD') return '\$${price.toStringAsFixed(2)}';
  if (currency == 'KRW') return krwSigned(price.round(), false, unit: true);
  final cents = (price * 100).round();
  final whole = cents ~/ 100;
  final frac = (cents % 100).abs();
  final fracStr = frac == 0
      ? ''
      : (frac % 10 == 0
            ? '.${frac ~/ 10}'
            : '.${frac.toString().padLeft(2, '0')}');
  return '${krw(whole)}$fracStr $currency';
}

/// 지수 포인트 표기 — 천단위 구분 + 소수 2자리(뒤 0 은 생략). 통화 기호가 없다.
String _fmtIndexPoint(double v) {
  final cents = (v * 100).round();
  final whole = cents ~/ 100;
  final frac = (cents % 100).abs();
  if (frac == 0) return krw(whole);
  return frac % 10 == 0
      ? '${krw(whole)}.${frac ~/ 10}'
      : '${krw(whole)}.${frac.toString().padLeft(2, '0')}';
}

String _two(int v) => v.toString().padLeft(2, '0');

// ---- 매수 유의사항 라벨 (토스 warningType → 한글) ----------------------------

/// 토스 warningType → 로케일 라벨 (웹 `warning.*` 키 미러). 모르는 타입은 원문 노출.
String _warningLabel(AppLocalizations l, String type) => switch (type) {
  'LIQUIDATION_TRADING' => l.stocksWarningLiquidationTrading,
  'OVERHEATED' => l.stocksWarningOverheated,
  'SHORT_TERM_OVERHEAT' => l.stocksWarningShortTermOverheat,
  'EXCESSIVE_RISE' => l.stocksWarningExcessiveRise,
  'INVESTMENT_WARNING' => l.stocksWarningInvestmentWarning,
  'INVESTMENT_RISK' => l.stocksWarningInvestmentRisk,
  'INVESTMENT_CAUTION' => l.stocksWarningInvestmentCaution,
  'VI' || 'VI_STATIC_AND_DYNAMIC' => l.stocksWarningVi,
  'VI_STATIC' => l.stocksWarningViStatic,
  'VI_DYNAMIC' => l.stocksWarningViDynamic,
  'STOCK_WARRANTS' => l.stocksWarningStockWarrants,
  'ADMINISTRATIVE' => l.stocksWarningAdministrative,
  'ADJUSTMENT_OF_SHARES' => l.stocksWarningAdjustmentOfShares,
  _ => type,
};

// ---- 장 상태 계산 (시장 현지 시각 vs 정규장 운영시간) -------------------------

enum _Tz { kr, us }

/// 'HH:MM:SS' → 'HH:MM'
String? _hhmm(String? s) =>
    (s != null && s.length >= 5) ? s.substring(0, 5) : null;

DateTime _nthSundayUtc(int year, int month, int n) {
  var d = DateTime.utc(year, month, 1);
  var count = 0;
  while (true) {
    if (d.weekday == DateTime.sunday) {
      count++;
      if (count == n) return d;
    }
    d = d.add(const Duration(days: 1));
  }
}

/// 미국 동부 서머타임 여부 (3월 둘째 일요일 02:00 ~ 11월 첫째 일요일 02:00).
bool _isUsEasternDst(DateTime utc) {
  final start = _nthSundayUtc(utc.year, 3, 2).add(const Duration(hours: 7));
  final end = _nthSundayUtc(utc.year, 11, 1).add(const Duration(hours: 6));
  return utc.isAfter(start) && utc.isBefore(end);
}

/// 시장 현지 시각 'HH:MM' (KR=UTC+9, US 동부=DST 반영). 웹 `nowInTz` 미러.
String _nowInTz(_Tz tz) {
  final utc = DateTime.now().toUtc();
  final local = tz == _Tz.kr
      ? utc.add(const Duration(hours: 9))
      : utc.subtract(Duration(hours: _isUsEasternDst(utc) ? 4 : 5));
  return '${_two(local.hour)}:${_two(local.minute)}';
}

({bool open, String detail}) _marketState(
  TossMarketSession? session,
  _Tz tz,
  AppLocalizations l,
) {
  final start = _hhmm(session?.startTime);
  final end = _hhmm(session?.endTime);
  if (start == null || end == null) {
    return (open: false, detail: l.stocksMarketHoliday);
  }
  final now = _nowInTz(tz);
  if (now.compareTo(start) >= 0 && now.compareTo(end) <= 0) {
    return (open: true, detail: l.stocksMarketTrading(now));
  }
  if (now.compareTo(start) < 0) {
    return (open: false, detail: l.stocksMarketOpensAt(start));
  }
  return (open: false, detail: l.stocksMarketClosed);
}

// ---- 장 상태 바 (토스 market-calendar) --------------------------------------

class _MarketStatusBar extends ConsumerWidget {
  const _MarketStatusBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final krCal = ref.watch(tossMarketCalendarKrProvider).asData?.value;
    final usCal = ref.watch(tossMarketCalendarUsProvider).asData?.value;
    final kr = _marketState(krCal?.today.regularMarket, _Tz.kr, l);
    final us = _marketState(usCal?.today.regularMarket, _Tz.us, l);
    final markets = <({String name, bool open, String detail})>[
      (name: l.stocksMarketKr, open: kr.open, detail: kr.detail),
      (name: l.stocksMarketUs, open: us.open, detail: us.detail),
    ];
    // 국내 지수 현재가 (토스 시장지표 — 코스피·코스닥 포인트). 미조회·0 이면 표시하지 않는다.
    final indices = (ref.watch(tossIndicatorPricesProvider).asData?.value ?? [])
        .where((i) => i.priceValue > 0)
        .toList();
    return Wrap(
      spacing: PSpace.x8,
      runSpacing: PSpace.x8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final m in markets)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: t.bgSunken,
              borderRadius: PRadius.brFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.open ? t.statusSuccessFg : t.fgTertiary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  m.name,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 12.5,
                    fontWeight: PFontWeight.semi,
                    color: t.fgPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  m.detail,
                  style: PTypo.caption.copyWith(
                    color: m.open ? t.fgSecondary : t.fgTertiary,
                    fontFeatures: _tnum,
                  ),
                ),
              ],
            ),
          ),
        // 지수는 장 상태 pill 과 달리 배경 없이 텍스트만 (웹 MarketStatusBar 미러).
        for (final i in indices)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                i.symbol == 'KOSPI' ? l.stockMarketKospi : l.stockMarketKosdaq,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 12.5,
                  fontWeight: PFontWeight.semi,
                  color: t.fgSecondary,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _fmtIndexPoint(i.priceValue),
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontFeatures: _tnum,
                  fontSize: 12.5,
                  fontWeight: PFontWeight.bold,
                  color: t.fgPrimary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ---- 등락률 배지 (색 + 부호 + 아이콘 3중 병기 — A11y 1.4.1) -------------------

class _PctBadge extends StatelessWidget {
  const _PctBadge({required this.pct, this.size = 13});
  final double pct;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final up = pct >= 0;
    final color = _trendColor(t, pct);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          size: size + 2,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '${up ? '+' : ''}${pct.toStringAsFixed(2)}%',
          style: TextStyle(
            fontFamily: PTypo.sans,
            fontFeatures: _tnum,
            fontSize: size,
            fontWeight: PFontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---- 종목 심볼 배지 ----------------------------------------------------------

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.symbol,
    required this.name,
    required this.countryCode,
    this.size = 40,
  });
  final String symbol;
  final String name;
  final String countryCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = _countryTone(context, countryCode);
    // 알파벳 심볼=앞 2글자, 그 외=이름 첫 글자 (웹 StockBadge 미러).
    final String initial;
    if (symbol.isNotEmpty && RegExp(r'^[A-Za-z]').hasMatch(symbol)) {
      initial = symbol.length >= 2 ? symbol.substring(0, 2) : symbol;
    } else if (name.isNotEmpty) {
      initial = name.substring(0, 1);
    } else {
      initial = symbol.isNotEmpty ? symbol.substring(0, 1) : '?';
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: chipFill(context, tone, t: 0.16),
        borderRadius: PRadius.tile(size),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: size * 0.34,
          fontWeight: PFontWeight.bold,
          letterSpacing: -0.02 * size * 0.34,
          color: chipText(context, tone, t: 0.72),
        ),
      ),
    );
  }
}

// ---- 종목 리스트 행 (표시 전용 — 데이터는 각 패널이 공급, 웹 StockRow 미러) ----

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.symbol,
    required this.name,
    required this.countryCode,
    required this.currency,
    required this.onTap,
    this.sub,
    this.price,
    this.changePct,
    this.right,
  });
  final String symbol;
  final String name;
  final String countryCode;
  final String currency;
  final VoidCallback onTap;
  final String? sub;
  final double? price;
  final double? changePct;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Padding(
        // 좌우는 페이지가 쥔다(ListView padding 24). 행이 여기서 14 를 더 얹으면
        // 위 탭 스트립·섹션 제목과 어긋난다. 상하만 준다(행 리듬).
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        child: Row(
          children: [
            _StockBadge(symbol: symbol, name: name, countryCode: countryCode),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub == null ? symbol : '$symbol · $sub',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.micro.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 78),
              child:
                  right ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price != null ? _fmtByCurrency(price!, currency) : '—',
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontFeatures: _tnum,
                          fontSize: 13.5,
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                      if (changePct != null) ...[
                        const SizedBox(height: 1),
                        _PctBadge(pct: changePct!, size: 11.5),
                      ],
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- 관심목록 행 (시세 = 그룹 배치 1콜 + 행별 전일종가 — 웹 WatchRowItem 미러) --

class _WatchRow extends ConsumerWidget {
  const _WatchRow({
    required this.item,
    required this.joinedSymbols,
    required this.onTap,
  });
  final WatchItem item;

  /// 현재 그룹 심볼 콤마 조인 — tossPrices 배치 1콜 키 (행들이 같은 키를 공유).
  final String joinedSymbols;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prices =
        ref.watch(tossPricesProvider(joinedSymbols)).asData?.value ??
        const <TossPrice>[];
    double? last;
    for (final p in prices) {
      if (p.symbol == item.symbol) {
        final v = double.tryParse(p.lastPrice);
        if (v != null && v > 0) last = v;
        break;
      }
    }
    final prevClose = ref.watch(prevCloseProvider(item.symbol)).asData?.value;
    return _StockRow(
      symbol: item.symbol,
      name: item.nameKr.isNotEmpty ? item.nameKr : item.symbol,
      countryCode: item.countryCode,
      currency: item.currency,
      sub: stockMarketLabel(l, item.marketCode),
      price: last,
      changePct: changePctOf(last, prevClose),
      onTap: onTap,
    );
  }
}

// ---- 보유 빈 상태 (증권 계정 미연결) -----------------------------------------

class _HoldingsEmpty extends StatelessWidget {
  const _HoldingsEmpty({required this.onConnect});
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 카드 다이어트 — 빈 상태 플랫.
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: PSpace.x32,
        horizontal: PSpace.x20,
      ),
      child: Column(
        children: [
          Icon(LucideIcons.wallet, size: 32, color: t.fgTertiary),
          const SizedBox(height: PSpace.x12),
          Text(
            l.stocksConnectPrompt,
            style: PTypo.body.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.semi,
            ),
          ),
          const SizedBox(height: PSpace.x4),
          Text(
            l.stocksConnectDesc,
            textAlign: TextAlign.center,
            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(height: PSpace.x16),
          PButton(
            label: l.stocksConnectAccount,
            variant: PButtonVariant.outline,
            size: PButtonSize.sm,
            onPressed: onConnect,
          ),
        ],
      ),
    );
  }
}

// ---- 요약 카드 ---------------------------------------------------------------

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.masked, required this.holdings});
  final bool masked;

  /// 키 연결 시 보유 요약(서버 계산). null 이면 연결 유도 빈 상태.
  final TossHoldings? holdings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final h = holdings;
    if (h == null) {
      // 미연결 — 연결 유도 카드 (mock 평가금액 노출 안 함). keep(raised) — design p-card--keep.
      return PCard(
        variant: PCardVariant.raised,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.stocksMyEval,
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: 12.5,
                fontWeight: PFontWeight.semi,
                color: t.fgTertiary,
              ),
            ),
            const SizedBox(height: PSpace.x8),
            Text(
              l.stocksConnectShowAssets,
              style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            ),
          ],
        ),
      );
    }
    final totalEval = h.marketValueAmountValue.round();
    final totalCost = h.totalPurchaseAmountValue.round();
    final totalPnl = h.profitLossAmountValue.round();
    final totalPnlPct = h.profitLossRateValue;
    final pnlColor = _trendColor(t, totalPnl.toDouble());
    // 환율 (토스 exchange-rate) — 미조회 시 '—'. 웹 summary.fxRate 미러.
    final fxRaw = ref.watch(tossExchangeRateProvider).asData?.value?.rateValue;
    final fxRate = (fxRaw != null && fxRaw > 0) ? fxRaw : null;

    // 내 투자 요약 — design `p-card--keep` (raised + shadow-lg, padding 18).
    return PCard(
      variant: PCardVariant.raised,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.stocksMyEval,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: 12.5,
              fontWeight: PFontWeight.semi,
              color: t.fgTertiary,
            ),
          ),
          const SizedBox(height: PSpace.x4),
          Text(
            masked ? kHideMask : krwSigned(totalEval, false, unit: true),
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontFeatures: _tnum,
              fontSize: 28,
              fontWeight: PFontWeight.bold,
              letterSpacing: -0.56,
              color: t.fgPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                masked
                    ? '••••'
                    : krwSigned(
                        totalPnl.abs(),
                        false,
                        sign: totalPnl >= 0 ? '+' : '−',
                        unit: true,
                      ),
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontFeatures: _tnum,
                  fontSize: 13.5,
                  fontWeight: PFontWeight.bold,
                  color: pnlColor,
                ),
              ),
              const SizedBox(width: PSpace.x8),
              _PctBadge(pct: totalPnlPct),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          Container(height: 1, color: t.borderSubtle),
          const SizedBox(height: PSpace.x16),
          Row(
            children: [
              for (final (label, value) in [
                (
                  l.stocksPurchaseAmount,
                  masked ? '••••' : krwSigned(totalCost, false, unit: true),
                ),
                (l.stocksHoldingsLabel, l.stocksUnitCount(h.items.length)),
                (
                  l.stocksExchangeRate,
                  fxRate != null ? '₩${krw(fxRate.round())}' : '—',
                ),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: PTypo.micro.copyWith(color: t.fgTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontFeatures: _tnum,
                          fontSize: 13.5,
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- 차트 기간 탭 목록 (차트 자체는 ChartWebView = desk-front 임베드) -----------

/// 기간 값은 ChartWebView 임베드 querystring 의 식별자라 보존하고, 표시 라벨만 로케일로 바꾼다
/// (웹 `RANGE_LABEL_KEY` 미러).
const _kRanges = ['1D', '1주', '1개월', '3개월', '1년'];

String _rangeLabel(AppLocalizations l, String range) => switch (range) {
  '1주' => l.stocksRange1w,
  '1개월' => l.stocksRange1m,
  '3개월' => l.stocksRange3m,
  '1년' => l.stocksRange1y,
  _ => l.stocksRange1d,
};

// ---- 종목 상세 ---------------------------------------------------------------

/// 심볼 정확 일치 마스터 항목 (KR/US 우선 — 시장 간 심볼 중복 대비).
/// stockSymbolNameProvider 의 우선순위 로직 미러 (상세는 항목 전체가 필요해 로컬 계산).
StockMasterItem? _findMaster(List<StockMasterItem> items, String symbol) {
  final up = symbol.toUpperCase();
  final exact = [
    for (final s in items)
      if (s.symbol.toUpperCase() == up) s,
  ];
  if (exact.isEmpty) return null;
  for (final s in exact) {
    if (s.countryCode == 'KR' || s.countryCode == 'US') return s;
  }
  return exact.first;
}

class _StockDetailBody extends ConsumerStatefulWidget {
  const _StockDetailBody({
    required this.ticker,
    required this.onToggleWatch,
    required this.scrollController,
  });
  final String ticker;

  /// 별 토글 — 마스터 marketCode(모르면 null)를 넘겨 서버가 시장을 해석하게 한다.
  final void Function(String? marketCode) onToggleWatch;
  final ScrollController scrollController;

  @override
  ConsumerState<_StockDetailBody> createState() => _StockDetailBodyState();
}

class _StockDetailBodyState extends ConsumerState<_StockDetailBody> {
  String _range = '1D';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    final symbol = widget.ticker;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final starTone = dark
        ? PorestPalette.chartYellowLight
        : PorestPalette.chartYellow;

    // 종목 정체성: 마스터(이름·시장·통화) + 토스 종목정보 병행. 마스터에 없는
    // 심볼(보유 이관 등)은 토스 정보 → 보유 → 심볼 순 폴백. 웹 StockDetailBody 미러.
    final master = _findMaster(
      ref.watch(stockSearchProvider(symbol)).asData?.value ??
          const <StockMasterItem>[],
      symbol,
    );
    final info = ref.watch(tossStockInfoProvider(symbol)).asData?.value;
    final holding = ref
        .watch(tossHoldingsProvider)
        .asData
        ?.value
        ?.items
        .where((h) => h.symbol == symbol)
        .firstOrNull;
    final watchGroups =
        ref.watch(watchGroupsProvider).asData?.value ??
        const <StockWatchGroup>[];
    final watched = watchGroups.any(
      (g) => g.items.any((i) => i.symbol == symbol),
    );
    final warnings =
        ref.watch(tossWarningsProvider(symbol)).asData?.value ??
        const <TossStockWarning>[];

    final name = master?.nameKr.isNotEmpty == true
        ? master!.nameKr
        : (info?.name.isNotEmpty == true
              ? info!.name
              : (holding?.name.isNotEmpty == true ? holding!.name : symbol));
    final currency = info?.currency.isNotEmpty == true
        ? info!.currency
        : (master?.currency.isNotEmpty == true
              ? master!.currency
              : (holding?.currency.isNotEmpty == true
                    ? holding!.currency
                    : 'KRW'));
    final countryCode =
        master?.countryCode ?? (currency == 'USD' ? 'US' : 'KR');
    final isUs = currency == 'USD';

    // 현재가 (토스 prices — KR/US 만 제공) · 등락률(전일 종가 대비) · 환율.
    final pricesAsync = ref.watch(tossPricesProvider(symbol));
    final lastRaw = pricesAsync.asData?.value.firstOrNull?.lastPrice;
    final lastParsed = lastRaw == null ? null : double.tryParse(lastRaw);
    final last = (lastParsed != null && lastParsed > 0) ? lastParsed : null;
    final prevClose = ref.watch(prevCloseProvider(symbol)).asData?.value;
    final changePct = changePctOf(last, prevClose);
    final fxRaw = ref.watch(tossExchangeRateProvider).asData?.value?.rateValue;
    final fxRate = (fxRaw != null && fxRaw > 0) ? fxRaw : null;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x24),
      children: [
        // 헤더: 종목명 · 관심 토글
        Row(
          children: [
            _StockBadge(
              symbol: symbol,
              name: name,
              countryCode: countryCode,
              size: 46,
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 17,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -0.17,
                      color: t.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          symbol,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      PBadge(
                        label: master != null
                            ? stockMarketLabel(l, master.marketCode)
                            : (info?.market ?? ''),
                        variant: PBadgeVariant.secondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '· ${info?.isEtf == true ? 'ETF' : stockSecurityTypeLabel(l, master?.securityType ?? 'STOCK')}',
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 관심 토글 — active=chart-yellow blend (spec)
            InkWell(
              onTap: () => widget.onToggleWatch(master?.marketCode),
              borderRadius: PRadius.tile(38),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: watched
                      ? chipFill(context, starTone, t: 0.18)
                      : t.bgSunken,
                  borderRadius: PRadius.tile(38),
                  border: Border.all(color: t.borderSubtle),
                ),
                child: Icon(
                  LucideIcons.star,
                  size: 18,
                  fill: watched ? 1 : 0,
                  color: watched
                      ? chipText(context, starTone, t: 0.62)
                      : t.fgTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // 현재가 (토스 prices — KR/US 만 제공. 그 외 시장은 미지원 안내)
        Text(
          last != null ? _fmtByCurrency(last, currency) : '—',
          style: TextStyle(
            fontFamily: PTypo.sans,
            fontFeatures: _tnum,
            fontSize: PFontSize.h1,
            fontWeight: PFontWeight.bold,
            letterSpacing: -0.6,
            color: t.fgPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: PSpace.x8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (changePct != null) _PctBadge(pct: changePct, size: 14),
            if (isUs && last != null && fxRate != null)
              Text(
                '≈ ${krwSigned((last * fxRate).round(), false, unit: true)}',
                style: PTypo.caption.copyWith(
                  color: t.fgTertiary,
                  fontFeatures: _tnum,
                ),
              ),
            if (last == null && !pricesAsync.isLoading)
              Text(
                l.stocksPriceUnavailable,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
          ],
        ),

        // 매수 유의사항 (토스 warnings)
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: PSpace.x12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in warnings)
                PBadge(
                  label: _warningLabel(l, w.warningType),
                  variant: PBadgeVariant.softWarning,
                  icon: LucideIcons.triangleAlert,
                ),
            ],
          ),
        ],
        const SizedBox(height: PSpace.x16),

        // 차트 + 기간
        PCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Column(
            children: [
              ChartWebView(
                symbol: symbol,
                isUs: isUs,
                range: _range,
                height: 168,
              ),
              const SizedBox(height: PSpace.x8),
              PTabs<String>(
                value: _range,
                onChanged: (v) => setState(() => _range = v),
                variant: PTabsVariant.container,
                size: PTabsSize.sm,
                expand: true,
                items: [
                  for (final r in _kRanges)
                    PTabItem(value: r, label: _rangeLabel(l, r)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 내 보유 (9행)
        if (holding != null) ...[
          _HoldingDetailCard(holding: holding, masked: masked),
          const SizedBox(height: PSpace.x16),
        ],

        // 호가 / 체결 (실데이터 전용)
        _QuotesCard(
          symbol: symbol,
          currency: currency,
          lastPrice: last,
          changePct: changePct ?? 0,
        ),
        const SizedBox(height: PSpace.x16),

        // 기본 정보 (토스 stocks + price-limits)
        _StockInfoCard(
          symbol: symbol,
          currency: currency,
          info: info,
          lastPrice: last,
          fxRate: fxRate,
        ),
        const SizedBox(height: PSpace.x16),

        // 일별 시세 (토스 candles 1d)
        _DailyQuoteTable(symbol: symbol, isUs: isUs),
        const SizedBox(height: PSpace.x16),

        // 매매 (모의) — 매도=primary(파랑), 매수=danger(빨강) — 국내 통념
        Row(
          children: [
            Expanded(
              child: PButton(
                label: l.stocksSell,
                size: PButtonSize.lg,
                fullWidth: true,
                onPressed: () => showPSnackBar(
                  context,
                  l.stocksSellOrderStub(name),
                  severity: PSnackSeverity.info,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PButton(
                label: l.stocksBuy,
                variant: PButtonVariant.danger,
                size: PButtonSize.lg,
                fullWidth: true,
                onPressed: () => showPSnackBar(
                  context,
                  l.stocksBuyOrderStub(name),
                  severity: PSnackSeverity.info,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),
        // 수수료 안내 — 토스증권 Open API 기준
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 14, color: t.fgTertiary),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: Text(
                  isUs ? l.stocksFeeUs : l.stocksFeeKr,
                  style: PTypo.micro.copyWith(
                    color: t.fgSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),
        Text(
          l.stocksOrderDisclaimer,
          textAlign: TextAlign.center,
          style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5),
        ),
      ],
    );
  }
}

// ---- 내 보유 상세 카드 (9행) -------------------------------------------------

class _HoldingDetailCard extends StatelessWidget {
  const _HoldingDetailCard({required this.holding, required this.masked});
  final TossHoldingsItem holding;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final h = holding;
    final ev = h.marketValueAmountValue.round();
    final pnl = h.profitLossAmountValue.round();
    final pnlPct = h.profitLossRateValue;
    final dayPnl = h.dailyProfitLossAmountValue.round();
    final purchase = h.purchaseAmountValue.round();
    final fees = h.feesValue.round();
    final avg = h.averagePurchasePriceValue;
    final qty = h.quantityValue;
    final qtyLabel = l.stocksSharesUnit(
      qty == qty.roundToDouble() ? '${qty.round()}' : qty.toStringAsFixed(4),
    );

    String money(int v) => masked ? '••••' : krwSigned(v, false, unit: true);
    String moneySigned(int v) => masked
        ? '••••'
        : krwSigned(v.abs(), false, sign: v >= 0 ? '+' : '−', unit: true);

    final rows = <(String, String, Color)>[
      (l.stocksEvalAmount, money(ev), t.fgPrimary),
      (l.stocksEvalPnl, moneySigned(pnl), _trendColor(t, pnl.toDouble())),
      (l.stocksQuantityHeld, qtyLabel, t.fgPrimary),
      (
        l.stocksReturnRate,
        '${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
        _trendColor(t, pnl.toDouble()),
      ),
      (l.stocksDayPnl, moneySigned(dayPnl), _trendColor(t, dayPnl.toDouble())),
      (
        l.stocksAvgPrice,
        h.isUs
            ? '\$${avg.toStringAsFixed(2)}'
            : krwSigned(avg.round(), false, unit: true),
        t.fgSecondary,
      ),
      (l.stocksPurchaseAmount, money(purchase), t.fgSecondary),
      (l.stocksFeesTax, krwSigned(fees, false, unit: true), t.fgSecondary),
      (l.stocksSellable, qtyLabel, t.fgSecondary),
    ];

    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l.stocksMyHoldings, tokens: t),
          const SizedBox(height: PSpace.x12),
          for (var i = 0; i < rows.length; i += 2) ...[
            if (i > 0) const SizedBox(height: PSpace.x12),
            Row(
              children: [
                Expanded(child: _KvCell(rows[i], tokens: t)),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < rows.length
                      ? _KvCell(rows[i + 1], tokens: t)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.tokens});
  final String label;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontFamily: PTypo.sans,
      fontSize: 12.5,
      fontWeight: PFontWeight.bold,
      color: tokens.fgSecondary,
    ),
  );
}

class _KvCell extends StatelessWidget {
  const _KvCell(this.row, {required this.tokens});
  final (String, String, Color) row;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(row.$1, style: PTypo.micro.copyWith(color: tokens.fgTertiary)),
      const SizedBox(height: 2),
      Text(
        row.$2,
        style: PTypo.bodySm.copyWith(
          color: row.$3,
          fontWeight: PFontWeight.bold,
          fontFeatures: _tnum,
        ),
      ),
    ],
  );
}

// ---- 종목 기본정보 (토스 stocks + price-limits) ------------------------------

/// 시가총액 — en 은 ₩ + 로케일 compact(₩1.2T), ko 는 조/억/만 + 원.
///
/// 축약은 차트 축과 같은 함수 하나다. 손으로 짠 예전 코드는 구간마다 정밀도가
/// 달라(조는 `.0` 을 남겨 `5.0조원`, 억은 정수) 같은 규칙이 아니었고, 1억 밑을
/// 반올림해 5,000만원짜리를 `1억원` 이라고 했다.
String _fmtCapKrw(double v) {
  if (localeIsEn()) return '₩${formatChartAxis(v)}';
  return '${formatChartAxis(v)}원';
}

/// 상장주식수 — 금액은 아니지만 같은 한국어 단위 사다리(만·억)를 쓴다.
///
/// 예전엔 10억 주를 넘으면 소수를 떼고(`60억 주`) 그 밑은 한 자리를 남겨
/// (`5.9억 주`) 같은 칸에서 규칙이 바뀌었다 — 축약 규칙은 하나다(QA #73).
/// 단위(주)는 ko 만 붙인다. en 은 행 라벨이 이미 들고 있다.
String _fmtShares(double n) {
  if (localeIsEn()) return formatChartAxis(n);
  return '${formatChartAxis(n)} 주';
}

class _StockInfoCard extends ConsumerWidget {
  const _StockInfoCard({
    required this.symbol,
    required this.currency,
    required this.info,
    required this.lastPrice,
    required this.fxRate,
  });
  final String symbol;
  final String currency;
  final TossStockInfo? info;
  final double? lastPrice;
  final double? fxRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final info = this.info; // 로컬 바인딩 → 널 승격(field promotion 불가) 위함.
    final isUs = currency == 'USD';
    final isKr = currency == 'KRW';
    final limits = ref.watch(tossPriceLimitsProvider(symbol)).asData?.value;
    final shares = info?.sharesValue ?? 0;
    // 시가총액 = 현재가 × 발행주식수 (USD 는 환율 환산). 시세 없으면 미표시. 웹 미러.
    final last = lastPrice;
    final fx = fxRate;
    final priceInKrw = last == null
        ? null
        : isUs
        ? (fx == null ? null : last * fx)
        : (isKr ? last : null);
    final mcKrw = (priceInKrw != null && shares > 0)
        ? priceInKrw * shares
        : null;
    final upper = limits?.upperValue;
    final lower = limits?.lowerValue;
    final listDate = info?.listDate;

    final rows = <(String, String, Color?)>[
      (
        l.stocksMarket,
        info?.market.isNotEmpty == true
            ? info!.market
            : (isUs ? l.stocksMarketUs : l.stocksMarketKr),
        null,
      ),
      (
        l.stocksInstrumentType,
        info?.isEtf == true ? 'ETF' : l.stocksInstrumentStock,
        null,
      ),
      (
        l.stocksCurrency,
        info?.currency.isNotEmpty == true ? info!.currency : currency,
        null,
      ),
      if (mcKrw != null) (l.stocksMarketCap, _fmtCapKrw(mcKrw), null),
      if (isKr && upper != null)
        (
          l.stocksUpperLimit,
          krwSigned(upper.round(), false, unit: true),
          t.statusDangerFg,
        ),
      if (isKr && lower != null)
        (
          l.stocksLowerLimit,
          krwSigned(lower.round(), false, unit: true),
          t.fgBrand,
        ),
      if (listDate != null && listDate.isNotEmpty)
        (l.stocksListingDate, listDate, null),
      if (shares > 0) (l.stocksSharesOutstanding, _fmtShares(shares), null),
      (
        // 거래정지는 토스 status(분류성 값)가 아니라 KRX 거래정지 플래그로 판정.
        l.stocksTradingStatus,
        info?.koreanMarketDetail?.krxTradingSuspended == true
            ? l.stocksTradingSuspended
            : l.stocksTradingNormal,
        info?.koreanMarketDetail?.krxTradingSuspended == true
            ? t.statusDangerFg
            : t.statusSuccessFg,
      ),
    ];

    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l.stocksBasicInfo, tokens: t),
          const SizedBox(height: PSpace.x4),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: t.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 12.5,
                      color: t.fgTertiary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                        color: rows[i].$3 ?? t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                        fontFeatures: _tnum,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---- 호가창 (토스 orderbook · 실데이터 전용) ----------------------------------

class _OrderBook extends StatelessWidget {
  const _OrderBook({
    required this.currency,
    required this.lastPrice,
    required this.book,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final TossOrderbook book;
  final double changePct;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // asks=낮은가격순 → 상단 표시(높은가격 위) 위해 5개 잘라 역순, bids=높은가격순 그대로.
    final asks = [
      for (final e in book.asks.take(5))
        (p: e.priceValue, q: e.volumeValue.round()),
    ].reversed.toList();
    final bids = [
      for (final e in book.bids.take(5))
        (p: e.priceValue, q: e.volumeValue.round()),
    ];
    var maxQ = 1;
    for (final a in asks) {
      if (a.q > maxQ) maxQ = a.q;
    }
    for (final b in bids) {
      if (b.q > maxQ) maxQ = b.q;
    }
    String fmt(double p) =>
        currency == 'USD' ? '\$${p.toStringAsFixed(2)}' : krw(p.round());

    Widget qtyBar({
      required int q,
      required Color tone,
      required bool alignRight,
    }) {
      final f = (maxQ <= 0 ? 0.0 : q / maxQ).clamp(0.0, 1.0);
      // 바는 항상 중심축(가격) 쪽에 붙어 바깥으로 자란다 — 매수=중심(오른쪽)에서 왼쪽으로,
      // 매도=중심(왼쪽)에서 오른쪽으로. FractionallySizedBox+Stack 은 좌측 고정 버그가 있어 Positioned 로 명시.
      return SizedBox(
        height: 22,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: alignRight ? null : 0,
                right: alignRight ? 0 : null,
                width: c.maxWidth * f,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: chipFill(context, tone, t: 0.13),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Align(
                alignment: alignRight
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: alignRight ? 6 : 0,
                    left: alignRight ? 0 : 6,
                  ),
                  child: Text(
                    krw(q),
                    style: PTypo.micro.copyWith(
                      color: t.fgTertiary,
                      fontFeatures: _tnum,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget row({required double p, required int q, required bool isAsk}) {
      final priceColor = isAsk ? t.fgBrand : t.statusDangerFg;
      return SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(
              child: isAsk
                  ? const SizedBox.shrink()
                  : qtyBar(q: q, tone: t.statusDangerFg, alignRight: true),
            ),
            SizedBox(
              width: 92,
              child: Center(
                child: Text(
                  fmt(p),
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontFeatures: _tnum,
                    fontSize: 12.5,
                    fontWeight: PFontWeight.bold,
                    color: priceColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isAsk
                  ? qtyBar(q: q, tone: t.fgBrand, alignRight: false)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const _OrderBookHead(),
        const SizedBox(height: PSpace.x4),
        for (final a in asks) row(p: a.p, q: a.q, isAsk: true),
        _OrderBookLast(
          currency: currency,
          lastPrice: lastPrice,
          changePct: changePct,
        ),
        for (final b in bids) row(p: b.p, q: b.q, isAsk: false),
      ],
    );
  }
}

/// 호가 테이블 헤더 — 정적 틀이라 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _OrderBookHead extends StatelessWidget {
  const _OrderBookHead();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final style = TextStyle(
      fontFamily: PTypo.sans,
      fontSize: 10.5,
      fontWeight: PFontWeight.semi,
      color: t.fgTertiary,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            l.stocksBidVolume,
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        const SizedBox(width: 92),
        Expanded(child: Text(l.stocksAskVolume, style: style)),
      ],
    );
  }
}

/// 현재가 스트립 — 값이 호가 응답이 아니라 상위에서 이미 받아둔 시세라
/// 호가 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _OrderBookLast extends StatelessWidget {
  const _OrderBookLast({
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final double changePct;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lastPrice != null ? _fmtByCurrency(lastPrice!, currency) : '—',
            style: PTypo.bodySm.copyWith(
              color: _trendColor(t, changePct),
              fontWeight: PFontWeight.bold,
              fontFeatures: _tnum,
            ),
          ),
          const SizedBox(width: 6),
          _PctBadge(pct: changePct, size: 11),
        ],
      ),
    );
  }
}

/// 호가 로딩 스켈레톤 — [_OrderBook] 실렌더 구조를 그대로 따른다.
/// 헤더 행과 현재가 스트립은 실 위젯을 그대로 쓰고, 서버에서 오는 매도/매수
/// 5호가 자리만 placeholder — 행 26 / 잔량 바 22 / 가격 컬럼 92 고정.
class _OrderBookSkeleton extends StatelessWidget {
  const _OrderBookSkeleton({
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final double changePct;

  /// 잔량 바 길이는 실렌더에서 maxQ 대비 비율이라 값을 알 수 없다 — 프레임마다
  /// 흔들리지 않도록 고정 시퀀스로 대체(랜덤 금지). asks 는 위가 고가라 역순 모양.
  static const _askBars = [0.34, 0.52, 0.41, 0.66, 0.47];
  static const _bidBars = [0.58, 0.44, 0.70, 0.38, 0.50];

  @override
  Widget build(BuildContext context) {
    // 실렌더 row(): SizedBox(height: 26) + 가운데 가격 컬럼 92 고정.
    // 잔량 바는 중심축(가격)에 붙어 바깥으로 자라므로 정렬도 매도=왼쪽/매수=오른쪽.
    Widget row(double factor, {required bool isAsk}) {
      // 실렌더 qtyBar 의 높이 22 · radius 4(=PRadius.brSm, PSkeleton 기본값).
      final bar = FractionallySizedBox(
        alignment: isAsk ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: factor,
        child: const PSkeleton(height: 22),
      );
      return SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(child: isAsk ? const SizedBox.shrink() : bar),
            const SizedBox(
              width: 92,
              child: Center(child: PSkeleton.line(width: 56, height: 12)),
            ),
            Expanded(child: isAsk ? bar : const SizedBox.shrink()),
          ],
        ),
      );
    }

    return Column(
      children: [
        const _OrderBookHead(),
        const SizedBox(height: PSpace.x4),
        for (final f in _askBars) row(f, isAsk: true),
        _OrderBookLast(
          currency: currency,
          lastPrice: lastPrice,
          changePct: changePct,
        ),
        for (final f in _bidBars) row(f, isAsk: false),
      ],
    );
  }
}

// ---- 발견(디스커버리) 랭킹 — 토스 rankings 실데이터 (웹 DiscoverPanel 미러) ----

class _RankRow extends ConsumerWidget {
  const _RankRow({
    required this.item,
    required this.index,
    required this.onPick,
  });
  final TossRankingItem item;
  final int index;
  final void Function(String symbol) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    // 국가는 심볼 형태로 판정(알파벳=US), 이름은 랭킹 응답에 없어 토스 종목정보 조회.
    final country = RegExp(r'^[A-Za-z]').hasMatch(item.symbol) ? 'US' : 'KR';
    final name = ref
        .watch(tossStockInfoProvider(item.symbol))
        .asData
        ?.value
        ?.name;
    final last = item.price.lastPriceValue;
    return Row(
      // 행이 자체 좌우 여백을 갖지 않으므로 순위 컬럼과의 간격은 gap 이 맡는다.
      spacing: 14,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '${item.rank}',
            // 순위 숫자도 페이지 여백에서 시작한다(통계 가맹점 순위와 같은 결정).
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontFeatures: _tnum,
              fontSize: 14,
              fontWeight: PFontWeight.bold,
              color: index < 3 ? t.fgBrand : t.fgTertiary,
            ),
          ),
        ),
        Expanded(
          child: _StockRow(
            symbol: item.symbol,
            name: (name != null && name.isNotEmpty) ? name : item.symbol,
            countryCode: country,
            currency: item.currency,
            price: last > 0 ? last : null,
            changePct: item.price.changePct,
            onTap: () => onPick(item.symbol),
          ),
        ),
      ],
    );
  }
}

/// 발견 랭킹 로딩 스켈레톤 — `_RankRow` + `_StockRow` 실렌더 구조 미러.
/// 행 수 10 = 랭킹 API count 기본값(`StocksRepository.getRankings(count: 10)`),
/// 순위 컬럼 22 + gap 14, 행 상하 여백 PSpace.x12, 배지 40 / PRadius.tile(40),
/// 가격 컬럼 minWidth 78 은 전부 실렌더에서 그대로 읽어온 값. 텍스트 폭만 대략치.
class _RankRowsSkeleton extends StatelessWidget {
  const _RankRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 10; i++)
          Row(
            // 순위 컬럼과의 간격은 _RankRow 와 같이 gap 이 맡는다.
            spacing: 14,
            children: [
              const SizedBox(
                width: 22,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PSkeleton.line(width: 14, height: 14),
                ),
              ),
              Expanded(
                child: Padding(
                  // 행 리듬은 _StockRow 의 상하 여백이 만든다(좌우는 페이지가 쥔다).
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
                  child: Row(
                    children: [
                      PSkeleton(
                        width: 40,
                        height: 40,
                        borderRadius: PRadius.tile(40),
                      ),
                      const SizedBox(width: PSpace.x12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 종목명(bodySm) / 심볼(micro) 2줄 · 사이 1.
                            PSkeleton.line(width: 108, height: 14),
                            SizedBox(height: 1),
                            PSkeleton.line(width: 64, height: 11),
                          ],
                        ),
                      ),
                      const SizedBox(width: PSpace.x12),
                      ConstrainedBox(
                        // ConstrainedBox 는 const 생성자가 아니라 안쪽만 const.
                        constraints: const BoxConstraints(minWidth: 78),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 가격 + 등락 배지 2줄 · 사이 1.
                            PSkeleton.line(width: 66, height: 14),
                            SizedBox(height: 1),
                            PSkeleton.line(width: 50, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DiscoverPanel extends ConsumerStatefulWidget {
  const _DiscoverPanel({required this.onPick});
  final void Function(String ticker) onPick;

  @override
  ConsumerState<_DiscoverPanel> createState() => _DiscoverPanelState();
}

class _DiscoverPanelState extends ConsumerState<_DiscoverPanel> {
  String _tab = 'gainers';
  String _market = 'KR';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // TOP_GAINERS/LOSERS 는 realtime 미지원 → 1d, 거래량은 실시간.
    final type = _tab == 'gainers'
        ? 'TOP_GAINERS'
        : (_tab == 'losers' ? 'TOP_LOSERS' : 'MARKET_TRADING_VOLUME');
    final duration = _tab == 'volume' ? 'realtime' : '1d';
    final rankingsAsync = ref.watch(
      tossRankingsProvider('$type|$_market|$duration'),
    );
    final rankings =
        rankingsAsync.asData?.value.rankings ?? const <TossRankingItem>[];

    return Column(
      children: [
        // 랭킹 종류 + 국내/미국 토글 — 좁은 화면에선 줄바꿈 (웹 flexWrap 미러).
        Wrap(
          spacing: PSpace.x8,
          runSpacing: PSpace.x8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            PTabs<String>(
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
              variant: PTabsVariant.container,
              size: PTabsSize.sm,
              items: [
                PTabItem(value: 'gainers', label: l.stocksGainers),
                PTabItem(value: 'losers', label: l.stocksLosers),
                PTabItem(value: 'volume', label: l.stocksVolume),
              ],
            ),
            PTabs<String>(
              value: _market,
              onChanged: (v) => setState(() => _market = v),
              variant: PTabsVariant.container,
              size: PTabsSize.sm,
              items: [
                PTabItem(value: 'KR', label: l.stocksMarketToggleKr),
                PTabItem(value: 'US', label: l.stocksMarketToggleUs),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 카드 다이어트 — 발견 랭킹 리스트도 카드 없이 행 리듬만.
        if (rankingsAsync.isLoading)
          // 문구 로딩을 스켈레톤으로 바꾸면 스크린리더에 남는 안내가 없어진다 —
          // 기존 로딩 문구를 Semantics 라벨로 살려 둔다.
          Semantics(
            label: l.stocksRankingLoading,
            child: const _RankRowsSkeleton(),
          )
        else if (rankings.isEmpty)
          _QuotesEmpty(l.stocksRankingEmpty)
        else
          Column(
            children: [
              for (var i = 0; i < rankings.length; i++)
                _RankRow(item: rankings[i], index: i, onPick: widget.onPick),
            ],
          ),
      ],
    );
  }
}

// ---- 호가 / 체결 탭 카드 (실데이터 전용 · 로딩/빈 상태) -----------------------

typedef _Fill = ({String time, double p, int q, int dir});

/// 라이브 체결 테이프 변환 (토스 trades). dir=직전 체결가 대비 방향. 웹 `liveTradeFills` 미러.
List<_Fill> _liveTradeFills(List<TossTrade>? trades) {
  if (trades == null || trades.isEmpty) return const [];
  final out = <_Fill>[];
  final n = trades.length < 12 ? trades.length : 12;
  for (var i = 0; i < n; i++) {
    final tr = trades[i];
    final p = tr.priceValue;
    final prev = i + 1 < trades.length ? trades[i + 1].priceValue : p;
    final time =
        RegExp(r'(\d{2}:\d{2}:\d{2})').firstMatch(tr.timestamp)?.group(1) ??
        tr.timestamp;
    out.add((
      time: time,
      p: p,
      q: tr.volumeValue.round(),
      dir: p >= prev ? 1 : -1,
    ));
  }
  return out;
}

class _QuotesEmpty extends StatelessWidget {
  const _QuotesEmpty(this.msg);
  final String msg;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x32, horizontal: 12),
      child: Center(
        child: Text(msg, style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
      ),
    );
  }
}

class _QuotesCard extends ConsumerStatefulWidget {
  const _QuotesCard({
    required this.symbol,
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String symbol;
  final String currency;
  final double? lastPrice;
  final double changePct;

  @override
  ConsumerState<_QuotesCard> createState() => _QuotesCardState();
}

class _QuotesCardState extends ConsumerState<_QuotesCard> {
  String _tab = 'book';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final orderbookAsync = ref.watch(tossOrderbookProvider(widget.symbol));
    final tradesAsync = ref.watch(tossTradesProvider(widget.symbol));
    final book = orderbookAsync.asData?.value;
    final hasBook =
        book != null && book.asks.isNotEmpty && book.bids.isNotEmpty;
    final fills = _liveTradeFills(tradesAsync.asData?.value);

    Widget content;
    if (_tab == 'book') {
      if (orderbookAsync.isLoading) {
        content = Semantics(
          label: l.stocksOrderbookLoading,
          child: _OrderBookSkeleton(
            currency: widget.currency,
            lastPrice: widget.lastPrice,
            changePct: widget.changePct,
          ),
        );
      } else if (hasBook) {
        content = _OrderBook(
          currency: widget.currency,
          lastPrice: widget.lastPrice,
          book: book,
          changePct: widget.changePct,
        );
      } else {
        content = _QuotesEmpty(l.stocksOrderbookEmpty);
      }
    } else {
      if (tradesAsync.isLoading) {
        content = Semantics(
          label: l.stocksTradesLoading,
          child: const _TradeTapeSkeleton(),
        );
      } else if (fills.isEmpty) {
        content = _QuotesEmpty(l.stocksTradesEmpty);
      } else {
        content = _TradeTape(currency: widget.currency, fills: fills);
      }
    }

    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PTabs<String>(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            variant: PTabsVariant.container,
            size: PTabsSize.sm,
            expand: true,
            items: [
              PTabItem(value: 'book', label: l.stocksOrderbook),
              PTabItem(value: 'tape', label: l.stocksTrades),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          content,
        ],
      ),
    );
  }
}

// ---- 체결 테이프 (토스 trades · 실데이터 전용) --------------------------------

class _TradeTape extends StatelessWidget {
  const _TradeTape({required this.currency, required this.fills});
  final String currency;
  final List<_Fill> fills;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    String fmt(double p) =>
        currency == 'USD' ? '\$${p.toStringAsFixed(2)}' : krw(p.round());

    return Column(
      children: [
        const _TradeTapeHead(),
        const SizedBox(height: PSpace.x4),
        for (final f in fills)
          SizedBox(
            height: 25,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    f.time,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontFeatures: _tnum,
                      fontSize: 12,
                      color: t.fgTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    fmt(f.p),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontFeatures: _tnum,
                      fontSize: 12,
                      fontWeight: PFontWeight.bold,
                      color: _trendColor(t, f.dir.toDouble()),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    krw(f.q),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontFeatures: _tnum,
                      fontSize: 12,
                      color: t.fgSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 체결 테이블 헤더 — 정적 틀이라 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _TradeTapeHead extends StatelessWidget {
  const _TradeTapeHead();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final head = TextStyle(
      fontFamily: PTypo.sans,
      fontSize: 10.5,
      fontWeight: PFontWeight.semi,
      color: t.fgTertiary,
    );
    return Row(
      children: [
        Expanded(child: Text(l.stocksTradeTime, style: head)),
        Expanded(
          child: Text(
            l.stocksTradePrice,
            textAlign: TextAlign.right,
            style: head,
          ),
        ),
        Expanded(
          child: Text(
            l.stocksTradeVolume,
            textAlign: TextAlign.right,
            style: head,
          ),
        ),
      ],
    );
  }
}

/// 체결 로딩 스켈레톤 — [_TradeTape] 실렌더 구조를 그대로 따른다.
/// 헤더는 실 위젯을 그대로 쓰고 체결 행만 placeholder — `_liveTradeFills` 상한인
/// 12행 · 행 높이 25 · 3등분 컬럼(시간 좌 / 가격 우 / 수량 우) 그대로.
class _TradeTapeSkeleton extends StatelessWidget {
  const _TradeTapeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TradeTapeHead(),
        const SizedBox(height: PSpace.x4),
        for (var i = 0; i < 12; i++)
          const SizedBox(
            height: 25,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PSkeleton.line(width: 52, height: 12),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PSkeleton.line(width: 48, height: 12),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PSkeleton.line(width: 36, height: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---- 일별 시세 표 (토스 candles 1d) ------------------------------------------

class _DailyQuoteTable extends ConsumerWidget {
  const _DailyQuoteTable({required this.symbol, required this.isUs});
  final String symbol;
  final bool isUs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final candlesAsync = ref.watch(
      tossCandlesProvider((symbol: symbol, interval: '1d')),
    );
    String fmt(double v) => isUs ? '\$${v.toStringAsFixed(2)}' : krw(v.round());
    String fmtVol(int v) => krw(v);

    // 최근 9영업일 → 전일대비 등락 산출 → 8행.
    final asc = candlesAsync.asData?.value == null
        ? const <TossCandle>[]
        : ([...candlesAsync.asData!.value!.candles]
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
    final recent = asc.length > 9 ? asc.sublist(asc.length - 9) : asc;
    final rows = <({String date, double close, double chg, int vol})>[];
    for (var i = recent.length - 1; i >= 1; i--) {
      final c = recent[i];
      final prev = recent[i - 1].closeValue;
      final close = c.closeValue;
      final chg = prev > 0 ? (close - prev) / prev * 100 : 0.0;
      final ts = c.timestamp;
      final date = ts.length >= 10
          ? ts.substring(5, 10).replaceAll('-', '.')
          : ts;
      rows.add((
        date: date,
        close: close,
        chg: chg,
        vol: c.volumeValue.round(),
      ));
      if (rows.length >= 8) break;
    }

    Widget headCell(String label, int flex, TextAlign align) => Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: PFontSize.micro,
          fontWeight: PFontWeight.semi,
          color: t.fgTertiary,
        ),
      ),
    );

    Widget cell(
      String text,
      int flex,
      TextAlign align,
      Color color, {
      FontWeight? weight,
    }) => Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontFeatures: _tnum,
          fontSize: 12.5,
          fontWeight: weight ?? PFontWeight.regular,
          color: color,
        ),
      ),
    );

    // 로딩 셀 — 실렌더 `cell` 과 같은 flex/정렬, 높이는 fontSize 12.5 라인 기준.
    // 실렌더 행 높이는 글자 크기가 아니라 라인박스가 정한다 — cell() 은 height 를 안 줘서
    // 테마 bodyMedium(height 1.5)을 상속, 12.5 x 1.5 = 18.75(렌더 19)가 된다.
    // 바 두께(13)를 그대로 쓰면 행마다 6px 씩 짧아 8행이면 48px 이 밀린다.
    // 그래서 자리는 19 로 잡고 그 안에 13 두께 바를 세운다.
    Widget skelCell(double width, int flex, Alignment align) => Expanded(
      flex: flex,
      child: SizedBox(
        height: 19,
        child: Align(
          alignment: align,
          child: PSkeleton.line(width: width, height: 13),
        ),
      ),
    );

    // 표 헤더는 정적 틀 — 로딩·실데이터 두 분기가 같은 것을 쓰도록 한 곳에 둔다.
    // (분기마다 따로 두면 컬럼 라벨·flex 가 바뀔 때 한쪽만 고쳐진다)
    final dailyHead = Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x8),
      child: Row(
        children: [
          headCell(l.stocksDate, 10, TextAlign.left),
          headCell(l.stocksClosePrice, 12, TextAlign.right),
          headCell(l.stocksChangeRate, 10, TextAlign.right),
          headCell(l.stocksVolume, 13, TextAlign.right),
        ],
      ),
    );

    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l.stocksDailyPrices, tokens: t),
          const SizedBox(height: 10),
          if (candlesAsync.isLoading) ...[
            // 헤더 행은 정적 틀 — 로딩에도 실제로 렌더하고 데이터 행만 스켈레톤.
            // 문구 로딩을 걷어낸 대신 Semantics 로 스크린리더 안내를 남긴다.
            Semantics(label: l.stocksDailyPricesLoading, child: dailyHead),
            // 실렌더는 최근 9영업일 → 8행(`rows.length >= 8` break). 행 padding 8 +
            // 상단 borderSubtle 구분선까지 데이터 행과 동일하게 유지.
            for (var i = 0; i < 8; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: t.borderSubtle)),
                ),
                child: Row(
                  children: [
                    skelCell(38, 10, Alignment.centerLeft),
                    skelCell(48, 12, Alignment.centerRight),
                    skelCell(44, 10, Alignment.centerRight),
                    skelCell(64, 13, Alignment.centerRight),
                  ],
                ),
              ),
          ] else if (rows.isEmpty)
            _QuotesEmpty(l.stocksDailyPricesEmpty)
          else ...[
            dailyHead,
            for (final r in rows)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: t.borderSubtle)),
                ),
                child: Row(
                  children: [
                    cell(r.date, 10, TextAlign.left, t.fgSecondary),
                    cell(
                      fmt(r.close),
                      12,
                      TextAlign.right,
                      t.fgPrimary,
                      weight: PFontWeight.semi,
                    ),
                    cell(
                      '${r.chg >= 0 ? '+' : ''}${r.chg.toStringAsFixed(2)}%',
                      10,
                      TextAlign.right,
                      _trendColor(t, r.chg),
                      weight: PFontWeight.bold,
                    ),
                    cell(fmtVol(r.vol), 13, TextAlign.right, t.fgTertiary),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
