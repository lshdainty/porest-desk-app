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
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/holding_format.dart';
import 'package:porest_desk_app/features/asset/presentation/include_in_total_card.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/stocks/application/live_prices.dart';

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

/// 편집 중 보유 1행 — 도메인 값 + 리스트가 바뀌어도 유지되는 위젯 key.
/// 이름 인라인 수정·행 삭제에도 입력 State 가 엉키지 않게 한다 (front `EditHolding.key` 미러).
typedef _EditRow = ({String key, AssetHolding holding});

int _editRowSeq = 0;
String _nextRowKey() => 'eh-${++_editRowSeq}';

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
  late final TextEditingController _nameCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _cashCtrl;

  late String _brand;
  late bool _includeInTotal;
  late List<_EditRow> _rows;
  bool _submitting = false;
  // 종목 검색 디바운스 — 키 입력마다 서버 요청이 나가지 않게 300ms 지연.
  Timer? _searchDebounce;
  String _debouncedStockQuery = '';

  bool get _isEdit => widget.edit != null;

  Iterable<AssetHolding> get _holdings => _rows.map((r) => r.holding);

  /// 검색 q 매칭된 카테고리별 entries (증권사·가상자산거래소만).
  List<MapEntry<BankCategory, List<BankEntry>>> get _filteredByCategory {
    final q = _norm(_queryCtrl.text.trim());
    final result = <MapEntry<BankCategory, List<BankEntry>>>[];
    for (final cat in investCategories) {
      final all = bankEntriesByCategory[cat] ?? const <BankEntry>[];
      final list = all
          .where((e) => _matchesQuery(e, q))
          .toList(growable: false);
      if (list.isEmpty) continue;
      result.add(MapEntry(cat, list));
    }
    // bankCategoryOrder 순서 보장.
    result.sort(
      (a, b) => bankCategoryOrder
          .indexOf(a.key)
          .compareTo(bankCategoryOrder.indexOf(b.key)),
    );
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

  BankEntry get _selectedEntry => _investBrands.firstWhere(
    (e) => e.name == _brand,
    orElse: () => _investBrands.first,
  );

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _brand = e?.institution != null && e!.institution!.isNotEmpty
        ? _investBrands
              .firstWhere(
                (b) =>
                    b.name == e.institution ||
                    b.aliases.contains(e.institution),
                orElse: () => _investBrands.first,
              )
              .name
        : _investBrands.first.name;
    _queryCtrl = TextEditingController()..addListener(_onChanged);
    _stockQueryCtrl = TextEditingController()
      ..addListener(_onStockQueryChanged);
    // 별칭 — 사용자가 지은 이름을 보존한다. 저장 때 기관명으로 덮으면
    // "금 현물" 같은 이름이 "NH투자" 로 사라진다(웹 AssetEditDialog 미러).
    _nameCtrl = TextEditingController(text: e?.assetName ?? '');
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    // 예수금 — 보유가 없을 때만 쓰인다(전량 매도 대금 등).
    _cashCtrl = TextEditingController(
      text: (e?.cashBalance ?? e?.balance ?? 0).toString(),
    );
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    // 기존 보유 복사. 레거시 단일 연동(tossSymbol/tossQuantity)은 보유 1건으로 이관.
    _rows = e == null
        ? []
        : e.holdings.isNotEmpty
        ? [for (final h in e.holdings) (key: _nextRowKey(), holding: h)]
        : (e.tossSymbol?.isNotEmpty ?? false) && e.tossQuantity != null
        ? [
            (
              key: _nextRowKey(),
              holding: AssetHolding(
                linked: true,
                marketCode: e.marketCode,
                tossSymbol: e.tossSymbol,
                quantity: e.tossQuantity?.toString(),
              ),
            ),
          ]
        : [];
    widget.controller.onSubmit = _submit;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.setCanSubmit(true),
    );
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
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
    _nameCtrl.dispose();
    _memoCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  // ── 보유 종목 상태 조작 ────────────────────────────────────────
  void _addLinked(StockMasterItem s) {
    // 시세 게이트 OFF(비구독·토스 미연결)면 연동해도 평가액을 못 구하므로 수동 항목으로 추가
    // — 사용자가 평가액을 직접 입력해 합계에 반영(사용자 결정).
    if (!_liveEnabled) {
      _addManual(s.nameKr);
      return;
    }
    setState(() {
      _rows = [
        ..._rows,
        (
          key: _nextRowKey(),
          holding: AssetHolding(
            linked: true,
            // 검색 결과가 시장을 알고 있다 — 여기서 안 담으면 서버는 심볼로 되짚어야 하고,
            // 여러 시장에 걸리는 티커(SPY·IVV 등)는 확정하지 못한다.
            marketCode: s.marketCode,
            tossSymbol: s.symbol,
            quantity: '1',
            holdingName: s.nameKr, // 표시용 — 직렬화 시 linked 는 심볼·수량만 전송.
            sortOrder: _rows.length,
          ),
        ),
      ];
      _stockQueryCtrl.clear();
      _debouncedStockQuery = '';
    });
  }

  void _addManual(String name) {
    setState(() {
      _rows = [
        ..._rows,
        (
          key: _nextRowKey(),
          holding: AssetHolding(
            holdingType: _manualHoldingType,
            holdingName: name,
            holdingValue: 0,
            sortOrder: _rows.length,
          ),
        ),
      ];
      _stockQueryCtrl.clear();
      _debouncedStockQuery = '';
    });
  }

  /// 금·코인은 검색 대상이 아니다(토스·마스터 모두 미제공) — 빈 행으로만 담는다.
  /// 기관이 보유 유형을 정한다 — 증권사에서 코인을, 금거래소에서 주식을 담을 일은 없다.
  /// 모르는 기관(구버전 데이터·직접 입력)이면 종전대로 셋 다 열어 둔다.
  String? get _brandHoldingType {
    for (final e in bankEntries) {
      if (e.name == _brand) return categoryHoldingType[e.category];
    }
    return null;
  }

  bool get _allowStock =>
      _brandHoldingType == null || _brandHoldingType == 'STOCK';

  /// 손으로 추가하는 보유의 유형.
  ///
  /// 기관이 정해져 있으면 그 카테고리를 따른다(상품거래소=금, 코인거래소=코인).
  /// 기관을 안 골랐으면 **이미 담아 둔 보유**를 본다 — 금만 있는 자산에 항목을
  /// 추가했는데 주식으로 저장되면 단위가 "주" 로 나오고 유형 분리가 무의미해진다.
  /// 둘 다 단서가 없을 때만 주식이다.
  AssetHoldingType get _manualHoldingType {
    switch (_brandHoldingType) {
      case 'GOLD':
        return AssetHoldingType.gold;
      case 'CRYPTO':
        return AssetHoldingType.crypto;
      case 'STOCK':
        return AssetHoldingType.stock;
      default:
        final types = _rows.map((r) => r.holding.holdingType).toSet();
        return types.length == 1 ? types.first : AssetHoldingType.stock;
    }
  }

  List<AssetHoldingType> get _manualAddTypes {
    switch (_brandHoldingType) {
      case 'GOLD':
        return const [AssetHoldingType.gold];
      case 'CRYPTO':
        return const [AssetHoldingType.crypto];
      case 'STOCK':
        return const [];
      default:
        return const [AssetHoldingType.gold, AssetHoldingType.crypto];
    }
  }

  void _addTyped(AssetHoldingType type) {
    setState(() {
      _rows = [
        ..._rows,
        (
          key: _nextRowKey(),
          holding: AssetHolding(
            holdingType: type,
            holdingName: '',
            holdingValue: 0,
            sortOrder: _rows.length,
          ),
        ),
      ];
    });
  }

  void _updateRow(String key, AssetHolding next) {
    setState(() {
      _rows = [
        for (final r in _rows)
          if (r.key == key) (key: r.key, holding: next) else r,
      ];
    });
  }

  void _removeRow(String key) {
    setState(() {
      _rows = [
        for (final r in _rows)
          if (r.key != key) r,
      ];
    });
  }

  /// 시세 연동 가능 여부 — 증권 구독 + 토스 연결 둘 다여야 실시간 평가가 가능하다.
  bool get _liveEnabled {
    final features = ref.read(myFeaturesProvider).asData?.value;
    return (features?.hasSecurities ?? false) &&
        (features?.hasBrokerConnection ?? false);
  }

  /// 연동 심볼 1주 KRW 환산가 맵 — 게이트 OFF·시세 미확보 심볼은 null.
  ///
  /// 환산 규칙은 [livePricesProvider] 한 곳에 있다 — 자산 목록·상세와 같은 걸 써야
  /// 한 화면에서 총액과 종목별 금액이 어긋나지 않는다(실제로 어긋난 적이 있다).
  Map<String, double?> _unitKrwMap() {
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final gate =
        (features?.hasSecurities ?? false) &&
        (features?.hasBrokerConnection ?? false);
    final symbols = {
      for (final h in _holdings)
        if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) h.tossSymbol!,
    }.toList()..sort();
    if (!gate || symbols.isEmpty) return const {};
    final live = ref
        .watch(livePricesProvider(livePricesKey(symbols)))
        .asData
        ?.value;
    if (live == null) return const {};
    return {for (final s in symbols) s: live.unitKrw(s)};
  }

  /// 보유 합계(KRW) — manual 합 + 시세 확보된 linked 합.
  /// **미리보기 표시 전용** — 저장되는 평가액은 서버가 BigDecimal 로 산정한다.
  int _totalOf(Map<String, double?> unitMap, Iterable<AssetHolding> holdings) {
    var total = 0.0;
    for (final h in holdings) {
      if (h.linked) {
        final unit = unitMap[h.tossSymbol];
        if (unit != null) total += unit * h.quantityValue;
      } else {
        total += (h.holdingValue ?? 0).toDouble();
      }
    }
    return total.round();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final brand = _brand;
    // 별칭이 있으면 그것이 자산명이다 — 비웠을 때만 웹과 같은 fallback 을 쓴다.
    final resolvedName = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : '$brand 투자';
    final memo = _memoCtrl.text.trim();
    // 추가만 하고 이름을 안 채운 미연동 행은 버린다 — 이름 빈 미연동은 서버가 400 으로 막는다.
    final filled = [
      for (final h in _holdings)
        if (h.linked || (h.holdingName?.trim().isNotEmpty ?? false)) h,
    ];
    final holdings = [
      for (int i = 0; i < filled.length; i++) filled[i].copyWith(sortOrder: i),
    ];
    // 평가액은 **서버가** 시세×수량을 BigDecimal 로 산정한다 — 클라이언트 계산값은 보내지 않는다.
    // 보유가 없으면 남는 건 예수금뿐이라 입력값을 보낸다 — 0 으로 밀면 전량 매도 대금이 사라진다.
    final int? balance = holdings.isEmpty
        ? (int.tryParse(_cashCtrl.text.replaceAll(',', '')) ?? 0)
        : null;

    _setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          assetName: resolvedName,
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
          assetName: resolvedName,
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
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final unitMap = _unitKrwMap();
    final total = _totalOf(unitMap, _holdings);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
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
            Text(
              l.assetBrokerExchange,
              style: PTypo.caption.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.medium,
              ),
            ),
            const Spacer(),
            Text(
              l.assetTotalEntries(_investEntriesCount),
              style: PTypo.micro.copyWith(color: t.fgTertiary),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        PSearchField(controller: _queryCtrl, hint: l.assetInvestSearchHint),
        const SizedBox(height: PSpace.x8),
        _BrandPicker(
          categories: _filteredByCategory,
          selectedName: _brand,
          onPick: (name) => setState(() => _brand = name),
        ),
        const SizedBox(height: PSpace.x20),

        // 별칭 ────────────────────────────────
        Text(
          l.assetProductName,
          style: PTypo.caption.copyWith(
            color: t.fgPrimary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _nameCtrl,
          placeholder: l.assetProductPlaceholder,
        ),
        const SizedBox(height: PSpace.x20),

        // 보유 종목 ────────────────────────
        Row(
          children: [
            Text(
              l.assetHoldings,
              style: PTypo.caption.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.medium,
              ),
            ),
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
        if (_allowStock) ...[
          const SizedBox(height: PSpace.x8),
          PSearchField(
            controller: _stockQueryCtrl,
            hint: l.assetHoldingSearchHint,
          ),
        ],
        if (_allowStock && _debouncedStockQuery.isNotEmpty) ...[
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
        // 금·코인은 검색으로 담을 수 없다(시세·마스터 미제공) — 빈 행 추가 버튼으로만.
        // 기관이 유형을 정하므로 증권사면 아무것도 안 뜬다(주식은 위 검색으로 담는다).
        if (_manualAddTypes.isNotEmpty) ...[
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              for (final type in _manualAddTypes) ...[
                if (type != _manualAddTypes.first) const SizedBox(width: 6),
                PButton(
                  label: type == AssetHoldingType.gold
                      ? l.assetHoldingAddGold
                      : l.assetHoldingAddCrypto,
                  icon: LucideIcons.plus,
                  variant: PButtonVariant.outline,
                  size: PButtonSize.sm,
                  onPressed: () => _addTyped(type),
                ),
              ],
            ],
          ),
        ],
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: PSpace.x12,
              horizontal: 2,
            ),
            child: Text(
              _allowStock
                  ? l.assetHoldingsEmptyEdit
                  : l.assetHoldingsEmptyManual,
              style: PTypo.caption.copyWith(color: t.fgTertiary, height: 1.5),
            ),
          )
        else
          // 유형별 섹션 — 해당 유형이 없으면 섹션 자체를 그리지 않는다.
          for (final type in AssetHoldingType.values)
            if (_rows.any((r) => r.holding.holdingType == type))
              _HoldingTypeSection(
                // 다른 유형 섹션이 사라져도 이 섹션의 행 State(입력 중 값)가 유지되도록.
                key: ValueKey(type),
                type: type,
                rows: [
                  for (final r in _rows)
                    if (r.holding.holdingType == type) r,
                ],
                unitMap: unitMap,
                onChanged: _updateRow,
                onRemove: _removeRow,
              ),

        // 예수금 ──────────────────────────────
        // 보유가 없을 때만 노출한다. 보유가 있으면 평가금액은 서버가 시세로 산정하고
        // 예수금은 입금·매도로만 움직여야 해서, 여기서 총액을 적으면 이중 계상된다.
        if (_rows.isEmpty) ...[
          const SizedBox(height: PSpace.x20),
          Text(
            l.assetCashBalance,
            style: PTypo.caption.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _cashCtrl,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            placeholder: '0',
          ),
          const SizedBox(height: 6),
          Text(
            l.assetCashBalanceHint,
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
        ],

        // 메모 (선택) ────────────────────────
        const SizedBox(height: PSpace.x20),
        Text(
          l.assetMemoOptional,
          style: PTypo.caption.copyWith(
            color: t.fgPrimary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: PSpace.x8),
        PTextInput(controller: _memoCtrl, placeholder: l.assetMemoPlaceholder),

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
                    strokeWidth: 2,
                    color: t.fgTertiary,
                  ),
                ),
              ),
            )
          else
            for (final s in items)
              InkWell(
                onTap: () => onPickLinked(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x12,
                    vertical: 10,
                  ),
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
                                  FontFeature.tabularFigures(),
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
                horizontal: PSpace.x12,
                vertical: 10,
              ),
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

/// 유형별 보유 섹션 — 라벨 + 그 유형의 행 목록.
/// 라벨과 목록은 한 묶음이라 유형이 하나뿐이어도 어떤 단위인지 드러난다.
class _HoldingTypeSection extends StatelessWidget {
  const _HoldingTypeSection({
    super.key,
    required this.type,
    required this.rows,
    required this.unitMap,
    required this.onChanged,
    required this.onRemove,
  });
  final AssetHoldingType type;
  final List<_EditRow> rows;
  final Map<String, double?> unitMap;
  final void Function(String key, AssetHolding next) onChanged;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: PSpace.x12, bottom: 2),
          child: Text(
            holdingTypeLabel(l, type),
            style: PTypo.micro.copyWith(
              color: t.fgTertiary,
              fontWeight: PFontWeight.bold,
            ),
          ),
        ),
        for (int i = 0; i < rows.length; i++)
          _HoldingEditRow(
            key: ValueKey(rows[i].key),
            holding: rows[i].holding,
            first: i == 0,
            unitKrw: rows[i].holding.linked
                ? unitMap[rows[i].holding.tossSymbol]
                : null,
            onChanged: (next) => onChanged(rows[i].key, next),
            onRemove: () => onRemove(rows[i].key),
          ),
      ],
    );
  }
}

/// 보유 종목 편집 1행 — 연동: 이름·배지 + 수량 + 평가액(시세 계산) /
/// 미연동: 이름 입력 + 수량(선택) + 평가액 입력. 우측 삭제.
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
  late final TextEditingController _qtyCtrl;
  // 미연동 전용 — 이름·평가액 직접 입력.
  late final TextEditingController _nameCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    final h = widget.holding;
    // 입력 중 '3.' 같은 중간 상태는 controller 가 들고 있으므로 모델에서 되쓰지 않는다.
    // 수량은 이미 문자열이라 그대로 띄운다 — 숫자를 거치면 소수 표기가 흔들린다.
    _qtyCtrl = TextEditingController(text: h.quantity ?? '');
    _nameCtrl = TextEditingController(text: h.holdingName ?? '');
    _valueCtrl = TextEditingController(text: '${h.holdingValue ?? 0}');
    // 매수원가 — 비어 있으면 안 보내고 서버가 기존 값을 잇는다.
    _costCtrl = TextEditingController(
      text: h.totalCost != null && h.totalCost! > 0 ? '${h.totalCost}' : '',
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _onQtyChanged(String v) =>
      widget.onChanged(widget.holding.copyWith(quantity: holdingQtyText(v)));

  void _onValueChanged(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    widget.onChanged(widget.holding.copyWith(holdingValue: n));
  }

  void _onCostChanged(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    widget.onChanged(widget.holding.copyWith(totalCost: n));
  }

  void _onNameChanged(String v) =>
      widget.onChanged(widget.holding.copyWith(holdingName: v));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final h = widget.holding;
    final name = (h.holdingName?.isNotEmpty ?? false)
        ? h.holdingName!
        : (h.tossSymbol ?? '');
    final value = widget.unitKrw != null
        ? (widget.unitKrw! * h.quantityValue).round()
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: widget.first
            ? null
            : Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          if (h.linked)
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
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
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.unitKrw != null
                        ? l.assetHoldingLinkedSub(
                            '${krw(widget.unitKrw!.round())}원',
                          )
                        : l.assetHoldingLinkedBadge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.micro.copyWith(
                      color: t.fgTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  _CostField(
                    controller: _costCtrl,
                    onChanged: _onCostChanged,
                    quantity: h.quantityValue,
                  ),
                ],
              ),
            )
          else
            // 미연동은 이름도 고칠 수 있어야 한다 — 금·코인은 검색으로 이름을 받지 못한다.
            Expanded(
              child: PTextInput(
                controller: _nameCtrl,
                placeholder: l.assetHoldingNamePlaceholder,
                onChanged: _onNameChanged,
              ),
            ),
          const SizedBox(width: PSpace.x8),
          // 수량 — 연동은 필수(시세×수량), 미연동은 선택. 소수 허용(0.05 BTC·3.75g).
          SizedBox(
            width: 64,
            child: PTextInput(
              controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [HoldingQtyInputFormatter()],
              textAlign: TextAlign.right,
              onChanged: _onQtyChanged,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            holdingUnitLabel(l, h.holdingType),
            style: PTypo.caption.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(width: PSpace.x8),
          // 평가액 — 연동은 시세로 계산(읽기 전용), 미연동은 직접 입력.
          if (h.linked)
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
            )
          else
            SizedBox(
              width: 100,
              child: PTextInput(
                controller: _valueCtrl,
                numbersOnly: true,
                textAlign: TextAlign.right,
                onChanged: _onValueChanged,
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
/// 매수원가 입력 — 실현손익의 기준.
///
/// 매수·매도로 쌓이지만, 앱을 쓰기 전부터 갖고 있던 보유는 여기서 적어 넣어야
/// 손익이 맞는다. 비워 두면 서버가 같은 종목의 기존 원가를 잇는다.
class _CostField extends StatelessWidget {
  const _CostField({
    required this.controller,
    required this.onChanged,
    required this.quantity,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double quantity;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final cost =
        int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final avg = (cost > 0 && quantity > 0) ? (cost / quantity).round() : null;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            l.holdingTotalCost,
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 104,
            height: 30,
            child: PTextInput(
              controller: controller,
              keyboardType: TextInputType.number,
              placeholder: '0',
              textAlign: TextAlign.right,
              onChanged: onChanged,
            ),
          ),
          if (avg != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l.holdingAvgPriceInline('${krw(avg)}원'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.micro.copyWith(color: t.fgTertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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

  /// 카테고리 라벨 — enum 의 한글 label 은 데이터 원문이고, 화면은 로케일을 따른다
  /// (영어 사용자에게 '시중은행' 이 그대로 나오면 안 된다). web 동일.
  static String _label(AppLocalizations l, BankCategory c) => switch (c) {
    BankCategory.retailBank => l.assetCategoryCommercialBank,
    BankCategory.internetBank => l.assetCategoryInternetBank,
    BankCategory.regionalBank => l.assetCategoryLocalBank,
    BankCategory.specialBank => l.assetCategorySpecialBank,
    BankCategory.savingsInstitution => l.assetCategorySavingsInstitution,
    BankCategory.foreignBank => l.assetCategoryForeignBank,
    BankCategory.other => l.assetCategoryOther,
    BankCategory.brokerage => l.assetCategoryBrokerage,
    BankCategory.commodityExchange => l.assetCategoryCommodityExchange,
    BankCategory.cryptoExchange => l.assetCategoryCryptoExchange,
  };

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
