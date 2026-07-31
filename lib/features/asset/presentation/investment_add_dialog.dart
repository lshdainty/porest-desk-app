import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/brand/bank_colors.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/include_in_total_card.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';

/// 투자 추가/편집 다이얼로그 — design `AssetEditDialog`(group='invest', tossapi5) 미러.
///
/// 계좌 다이얼로그와 동일한 패턴 (showModalBottomSheet + DraggableScrollableSheet).
/// 구성: 증권사·거래소 chip picker + **보유 종목 편집**(연동: 종목 검색→현재가×수량 /
/// 직접: 이름+평가액) + 메모 + 합계 포함 토글. 저장 시 holdings 전체 교체.
void showInvestmentAddDialog(BuildContext context) {
  _open(context, edit: null);
}

void showInvestmentEditDialog(BuildContext context, Asset asset) {
  _open(context, edit: asset);
}

void _open(BuildContext context, {required Asset? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.assetInvestAdd : l.assetInvestEdit,
    contentBuilder: (ctx, scrollCtrl) => _InvestmentAddBody(
      edit: edit,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit != null ? l.actionSave : l.calAdd,
    ),
  ).whenComplete(controller.dispose);
}

/// 투자에 노출되는 브랜드만 평탄화 (증권사 + 가상자산거래소).
List<BankEntry> get _investBrands => [
      for (final cat in investCategories) ...?bankEntriesByCategory[cat],
    ];

class _InvestmentAddBody extends ConsumerStatefulWidget {
  const _InvestmentAddBody({
    required this.edit,
    required this.scrollController,
    required this.controller,
  });
  final Asset? edit;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_InvestmentAddBody> createState() => _InvestmentAddBodyState();
}

class _InvestmentAddBodyState extends ConsumerState<_InvestmentAddBody> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _stockQueryCtrl;
  late final TextEditingController _memoCtrl;

  late String _brand;
  late bool _includeInTotal;
  late List<AssetHolding> _holdings;
  bool _submitting = false;
  bool _deleting = false;
  // 종목 검색 디바운스 — 키 입력마다 서버 요청이 나가지 않게 300ms 지연.
  Timer? _searchDebounce;
  String _debouncedStockQuery = '';

  bool get _isEdit => widget.edit != null;

  /// 검색 q 매칭된 카테고리별 entries (증권사·가상자산거래소만).
  List<MapEntry<BankCategory, List<BankEntry>>> get _filteredByCategory {
    final q = _norm(_queryCtrl.text.trim());
    final result = <MapEntry<BankCategory, List<BankEntry>>>[];
    for (final cat in investCategories) {
      final all = bankEntriesByCategory[cat] ?? const <BankEntry>[];
      final list =
          all.where((e) => _matchesQuery(e, q)).toList(growable: false);
      if (list.isEmpty) continue;
      result.add(MapEntry(cat, list));
    }
    // bankCategoryOrder 순서 보장.
    result.sort((a, b) => bankCategoryOrder
        .indexOf(a.key)
        .compareTo(bankCategoryOrder.indexOf(b.key)));
    return result;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  static bool _matchesQuery(BankEntry e, String needle) {
    if (needle.isEmpty) return true;
    if (_norm(e.name).contains(needle)) return true;
    return e.aliases.any((a) => _norm(a).contains(needle));
  }

  int get _investEntriesCount => _investBrands.length;

  BankEntry get _selectedEntry => _investBrands
      .firstWhere((e) => e.name == _brand, orElse: () => _investBrands.first);

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _brand = e?.institution != null && e!.institution!.isNotEmpty
        ? _investBrands
            .firstWhere(
              (b) =>
                  b.name == e.institution || b.aliases.contains(e.institution),
              orElse: () => _investBrands.first,
            )
            .name
        : _investBrands.first.name;
    _queryCtrl = TextEditingController()..addListener(_onChanged);
    _stockQueryCtrl = TextEditingController()..addListener(_onStockQueryChanged);
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    // 기존 보유 복사. 레거시 단일 연동(tossSymbol/tossQuantity)은 보유 1건으로 이관.
    _holdings = e == null
        ? []
        : e.holdings.isNotEmpty
            ? List.of(e.holdings)
            : (e.tossSymbol?.isNotEmpty ?? false) && e.tossQuantity != null
                ? [
                    AssetHolding(
                      linked: true,
                      tossSymbol: e.tossSymbol,
                      quantity: e.tossQuantity,
                    ),
                  ]
                : [];
    widget.controller.onSubmit = _submit;
    if (widget.edit != null) widget.controller.onDelete = _delete;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.controller.setCanSubmit(true));
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v || _deleting);
  }

  void _setDeleting(bool v) {
    setState(() => _deleting = v);
    widget.controller.setSubmitting(v || _submitting);
  }

  void _onChanged() => setState(() {});

  void _onStockQueryChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _debouncedStockQuery = _stockQueryCtrl.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _queryCtrl.dispose();
    _stockQueryCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  // ── 보유 종목 상태 조작 ────────────────────────────────────────
  void _addLinked(StockMasterItem s) {
    setState(() {
      _holdings = [
        ..._holdings,
        AssetHolding(
          linked: true,
          tossSymbol: s.symbol,
          quantity: 1,
          holdingName: s.nameKr, // 표시용 — 직렬화 시 linked 는 심볼·수량만 전송.
          sortOrder: _holdings.length,
        ),
      ];
      _stockQueryCtrl.clear();
      _debouncedStockQuery = '';
    });
  }

  void _addManual(String name) {
    setState(() {
      _holdings = [
        ..._holdings,
        AssetHolding(
          holdingName: name,
          holdingValue: 0,
          sortOrder: _holdings.length,
        ),
      ];
      _stockQueryCtrl.clear();
      _debouncedStockQuery = '';
    });
  }

  void _updateHolding(int index, AssetHolding next) {
    setState(() {
      _holdings = [
        for (int i = 0; i < _holdings.length; i++)
          i == index ? next : _holdings[i],
      ];
    });
  }

  void _removeHolding(int index) {
    setState(() {
      _holdings = [
        for (int i = 0; i < _holdings.length; i++)
          if (i != index) _holdings[i],
      ];
    });
  }

  /// 연동 심볼 1주 KRW 환산가 맵 — 게이트 OFF·시세 미확보 심볼은 null.
  Map<String, double?> _unitKrwMap() {
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final gate = (features?.hasSecurities ?? false) &&
        (features?.tossConnected ?? false);
    final symbols = {
      for (final h in _holdings)
        if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) h.tossSymbol!,
    }.toList()
      ..sort();
    if (!gate || symbols.isEmpty) return const {};
    final prices = ref
            .watch(tossPricesProvider(symbols.join(',')))
            .asData
            ?.value ??
        const <TossPrice>[];
    final bySymbol = {for (final p in prices) p.symbol: p};
    final hasForeign = prices.any((p) {
      final cur = p.currency;
      return cur != null && cur.isNotEmpty && cur.toUpperCase() != 'KRW';
    });
    final fx = hasForeign
        ? ref.watch(tossExchangeRateProvider).asData?.value?.rateValue ?? 0.0
        : 0.0;
    return {
      for (final s in symbols)
        s: () {
          final p = bySymbol[s];
          if (p == null) return null;
          final cur = p.currency;
          final foreign =
              cur != null && cur.isNotEmpty && cur.toUpperCase() != 'KRW';
          if (foreign) return fx > 0 ? p.priceValue * fx : null;
          return p.priceValue;
        }(),
    };
  }

  /// 보유 합계(KRW) — manual 합 + 시세 확보된 linked 합.
  int _totalOf(Map<String, double?> unitMap) {
    var total = 0.0;
    for (final h in _holdings) {
      if (h.linked) {
        final unit = unitMap[h.tossSymbol];
        if (unit != null) total += unit * (h.quantity ?? 0);
      } else {
        total += (h.holdingValue ?? 0).toDouble();
      }
    }
    return total.round();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final brand = _brand;
    final memo = _memoCtrl.text.trim();
    final holdings = [
      for (int i = 0; i < _holdings.length; i++)
        _holdings[i].copyWith(sortOrder: i),
    ];
    final balance = _totalOf(_unitKrwMap());

    _setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          // design 정합 — 투자 자산명은 증권사·거래소명.
          assetName: brand,
          assetType: 'INVESTMENT',
          balance: balance,
          currency: 'KRW',
          institution: brand,
          memo: memo.isEmpty ? null : memo,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          holdings: holdings,
        );
      } else {
        await repo.create(
          assetName: brand,
          assetType: 'INVESTMENT',
          balance: balance,
          currency: 'KRW',
          institution: brand,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          holdings: holdings,
        );
      }
      ref.invalidate(assetsProvider);
      ref.invalidate(investmentValuationMapProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, _isEdit ? l.assetInvestUpdated : l.assetInvestAdded,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetActionFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    if (_deleting || widget.edit == null) return;
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.assetInvestDelete,
      message: l.assetInvestDeleteConfirm,
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setDeleting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(assetsProvider);
      ref.invalidate(investmentValuationMapProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, l.assetInvestDeleted,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetDeleteFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setDeleting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final unitMap = _unitKrwMap();
    final total = _totalOf(unitMap);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        _PreviewTile(
          entry: _selectedEntry,
          holdingsCount: _holdings.length,
          total: total,
        ),
        const SizedBox(height: PSpace.x20),

        // 증권사·거래소 ──────────────────────
        Row(
          children: [
            Text(l.assetBrokerExchange,
                style: PTypo.caption.copyWith(
                    color: t.fgPrimary, fontWeight: PFontWeight.medium)),
            const Spacer(),
            Text(l.assetTotalEntries(_investEntriesCount),
                style: PTypo.micro.copyWith(color: t.fgTertiary)),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        PSearchField(
          controller: _queryCtrl,
          hint: l.assetInvestSearchHint,
        ),
        const SizedBox(height: PSpace.x8),
        _BrandPicker(
          categories: _filteredByCategory,
          selectedName: _brand,
          onPick: (name) => setState(() => _brand = name),
        ),
        const SizedBox(height: PSpace.x20),

        // 보유 종목 ────────────────────────
        Row(
          children: [
            Text(l.assetHoldings,
                style: PTypo.caption.copyWith(
                    color: t.fgPrimary, fontWeight: PFontWeight.medium)),
            const Spacer(),
            Text(
              l.assetHoldingsSummary(_holdings.length, krw(total)),
              style: PTypo.micro.copyWith(
                color: t.fgTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        PSearchField(
          controller: _stockQueryCtrl,
          hint: l.assetHoldingSearchHint,
        ),
        if (_debouncedStockQuery.isNotEmpty) ...[
          const SizedBox(height: PSpace.x8),
          _StockSearchResults(
            query: _debouncedStockQuery,
            excludeSymbols: {
              for (final h in _holdings)
                if (h.linked && (h.tossSymbol?.isNotEmpty ?? false))
                  h.tossSymbol!,
            },
            onPickLinked: _addLinked,
            onAddManual: _addManual,
          ),
        ],
        if (_holdings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: PSpace.x12, horizontal: 2),
            child: Text(
              l.assetHoldingsEmptyEdit,
              style: PTypo.caption.copyWith(color: t.fgTertiary, height: 1.5),
            ),
          )
        else
          for (int i = 0; i < _holdings.length; i++)
            _HoldingEditRow(
              key: ValueKey('holding-$i-${_holdings[i].tossSymbol ?? _holdings[i].holdingName}'),
              holding: _holdings[i],
              first: i == 0,
              unitKrw: _holdings[i].linked
                  ? unitMap[_holdings[i].tossSymbol]
                  : null,
              onChanged: (next) => _updateHolding(i, next),
              onRemove: () => _removeHolding(i),
            ),

        // 메모 (선택) ────────────────────────
        const SizedBox(height: PSpace.x20),
        Text(l.assetMemoOptional,
            style: PTypo.caption.copyWith(
                color: t.fgPrimary, fontWeight: PFontWeight.medium)),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _memoCtrl,
          placeholder: l.assetMemoPlaceholder,
        ),

        // 전체 자산 합계 포함 토글 ──────────────
        const SizedBox(height: PSpace.x20),
        IncludeInTotalCard(
          value: _includeInTotal,
          onChanged: (v) => setState(() => _includeInTotal = v),
        ),
      ],
    );
  }
}

/// 종목 검색 결과 — 서버 stock_master 검색. 탭 → 연동 보유 추가(수량 1),
/// 하단 "직접 추가" → 이름만으로 manual 보유 추가 (design pk-pop 미러).
class _StockSearchResults extends ConsumerWidget {
  const _StockSearchResults({
    required this.query,
    required this.excludeSymbols,
    required this.onPickLinked,
    required this.onAddManual,
  });
  final String query;
  final Set<String> excludeSymbols;
  final ValueChanged<StockMasterItem> onPickLinked;
  final ValueChanged<String> onAddManual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final async = ref.watch(stockSearchProvider(query));
    final items = (async.asData?.value ?? const <StockMasterItem>[])
        .where((s) => !excludeSymbols.contains(s.symbol))
        .take(6)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderSubtle),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (async.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: t.fgTertiary),
                ),
              ),
            )
          else
            for (final s in items)
              InkWell(
                onTap: () => onPickLinked(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PSpace.x12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.nameKr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PTypo.bodySm.copyWith(
                                color: t.fgPrimary,
                                fontWeight: PFontWeight.semi,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${s.symbol} · ${s.marketCode}',
                              style: PTypo.micro.copyWith(
                                color: t.fgTertiary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.plus, size: 15, color: t.fgBrand),
                    ],
                  ),
                ),
              ),
          // 직접 추가 — 검색 결과 유무와 무관하게 항상 제공(design).
          InkWell(
            onTap: () => onAddManual(query),
            child: Container(
              decoration: BoxDecoration(
                border: (async.isLoading || items.isNotEmpty)
                    ? Border(top: BorderSide(color: t.borderSubtle))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: PSpace.x12, vertical: 10),
              child: Row(
                children: [
                  Icon(LucideIcons.plus, size: 14, color: t.fgBrand),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.assetHoldingAddManual(query),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.caption.copyWith(
                        color: t.fgBrand,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
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

/// 보유 종목 편집 1행 — linked: 수량 입력(주) / manual: 평가액 입력. 우측 평가액·삭제.
class _HoldingEditRow extends StatefulWidget {
  const _HoldingEditRow({
    super.key,
    required this.holding,
    required this.first,
    required this.unitKrw,
    required this.onChanged,
    required this.onRemove,
  });
  final AssetHolding holding;
  final bool first;
  final double? unitKrw; // 연동 1주 KRW 환산가 (미확보 시 null)
  final ValueChanged<AssetHolding> onChanged;
  final VoidCallback onRemove;

  @override
  State<_HoldingEditRow> createState() => _HoldingEditRowState();
}

class _HoldingEditRowState extends State<_HoldingEditRow> {
  late final TextEditingController _numCtrl;

  @override
  void initState() {
    super.initState();
    final h = widget.holding;
    _numCtrl = TextEditingController(
      text: h.linked ? '${h.quantity ?? 0}' : '${h.holdingValue ?? 0}',
    );
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  void _onNumChanged(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final h = widget.holding;
    widget.onChanged(
      h.linked ? h.copyWith(quantity: n) : h.copyWith(holdingValue: n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final h = widget.holding;
    final name = (h.holdingName?.isNotEmpty ?? false)
        ? h.holdingName!
        : (h.tossSymbol ?? '');
    final value = h.linked
        ? (widget.unitKrw != null
            ? (widget.unitKrw! * (h.quantity ?? 0)).round()
            : null)
        : (h.holdingValue ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border:
            widget.first ? null : Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                    ),
                    if (h.linked) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: t.bgBrandSubtle,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l.assetHoldingLinkedBadge,
                          style: PTypo.micro.copyWith(
                            color: t.fgBrandStrong,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  h.linked
                      ? (widget.unitKrw != null
                          ? l.assetHoldingLinkedSub(
                              '${krw(widget.unitKrw!.round())}원')
                          : l.assetHoldingLinkedBadge)
                      : l.assetHoldingManualSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.micro.copyWith(
                    color: t.fgTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          // 수량(연동) / 평가액(직접) 입력
          SizedBox(
            width: h.linked ? 64 : 104,
            child: PTextInput(
              controller: _numCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: _onNumChanged,
            ),
          ),
          if (h.linked) ...[
            const SizedBox(width: 4),
            Text(l.assetSharesUnit,
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
          ],
          const SizedBox(width: PSpace.x8),
          SizedBox(
            width: 84,
            child: Text(
              value != null ? '${krw(value)}원' : '—',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PTypo.caption.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          PButton.icon(
            icon: LucideIcons.trash2,
            size: PButtonSize.sm,
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

/// 미리보기 타일 — 브랜드 컬러 박스 + 브랜드명 / "보유 N종목 · 합계원" (design Preview).
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.entry,
    required this.holdingsCount,
    required this.total,
  });
  final BankEntry entry;
  final int holdingsCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final letter = entry.name.isEmpty ? '?' : entry.name.characters.first;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: entry.color.bg,
            borderRadius: PRadius.brMd,
          ),
          child: Text(
            letter,
            style: TextStyle(
              color: entry.color.fg,
              fontWeight: PFontWeight.bold,
              fontSize: PFontSize.body,
            ),
          ),
        ),
        const SizedBox(width: PSpace.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.body.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.assetHoldingsSummary(holdingsCount, krw(total)),
                style: PTypo.caption.copyWith(
                  color: t.fgTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 카테고리별 브랜드 chip 그리드 — maxHeight 260 + 자체 스크롤 (web 동일).
class _BrandPicker extends StatelessWidget {
  const _BrandPicker({
    required this.categories,
    required this.selectedName,
    required this.onPick,
  });
  final List<MapEntry<BankCategory, List<BankEntry>>> categories;
  final String selectedName;
  final ValueChanged<String> onPick;

  /// 카테고리 라벨 — 가상자산 → 가상자산거래소 (web 동일).
  static String _label(AppLocalizations l, BankCategory c) =>
      c == BankCategory.cryptoExchange ? l.assetCryptoExchange : c.label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final box = BoxDecoration(
      color: t.bgSurface,
      borderRadius: PRadius.brMd,
      border: Border.all(color: t.borderSubtle),
    );
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: box,
        child: Center(
          child: Text(
            l.assetNoSearchResults,
            style: PTypo.caption.copyWith(color: t.fgTertiary),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      decoration: box,
      constraints: const BoxConstraints(maxHeight: 260),
      clipBehavior: Clip.hardEdge,
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _label(l, categories[i].key),
                    style: PTypo.micro.copyWith(
                      color: t.fgTertiary,
                      fontWeight: PFontWeight.semi,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in categories[i].value)
                      PChip(
                        label: e.name,
                        selected: e.name == selectedName,
                        onTap: () => onPick(e.name),
                        color: e.color.bg,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
