import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_axis.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/stocks/data/krx_stock_master.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_mock.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/asset/domain/card_billing.dart';
import 'package:porest_desk_app/shared/widgets/p_chart_tooltip.dart';
import 'package:porest_desk_app/features/asset/domain/asset_type_meta.dart';
import 'package:porest_desk_app/features/asset/presentation/widgets/asset_logo.dart';

/// 자산 상세 — front `AssetDetailDialog` 모바일 미러.
///
/// 공통 `showPSheet` 사용. 구성 (web 동일):
/// - Hero 카드 (브랜드 그라디언트 + 아이콘 + 이름 + 잔액)
/// - 12/24/52주 잔액 추이 + 3개월/6개월/1년 segmented
/// - 최근 거래 12건 + "전체 보기 →"
/// - 푸터: 금액 가리기 / 편집 / 확인 (본문 끝에 함께 스크롤)
void showAssetDetailRich(
  BuildContext context,
  Asset asset, {
  VoidCallback? onEdit,
}) {
  showPSheet<void>(
    context,
    title: _titleFor(AppLocalizations.of(context), asset),
    contentBuilder: (ctx, scrollCtrl) =>
        _DetailBody(asset: asset, scrollController: scrollCtrl, onEdit: onEdit),
    footerBuilder: (ctx) => _DetailFooter(asset: asset, onEdit: onEdit),
  );
}

class _DetailFooter extends ConsumerWidget {
  const _DetailFooter({required this.asset, this.onEdit});
  final Asset asset;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    return PViewFooter(
      // 좌측 = 삭제가 아니라 금액 가리기/표시 토글 → leading 슬롯.
      leading: PButton(
        label: masked ? l.assetShowAmount : l.assetHideAmount,
        icon: masked ? LucideIcons.eye : LucideIcons.eyeOff,
        variant: PButtonVariant.ghost,
        flush: PButtonFlush.left,
        onPressed: () => toggleHideAmountsWithUnlock(context, ref),
      ),
      onEdit: () {
        Navigator.of(context).pop();
        if (onEdit != null) {
          onEdit!();
        } else {
          context.push('/account-card-manage');
        }
      },
      onConfirm: () => Navigator.of(context).pop(),
    );
  }
}

String _titleFor(AppLocalizations l, Asset a) {
  if (a.assetType == 'CREDIT_CARD' || a.assetType == 'CHECK_CARD') {
    return l.assetCardDetail;
  }
  if (a.assetType == 'INVESTMENT') return l.assetInvestDetail;
  return l.assetAccountDetail;
}

enum _Period { p3m, p6m, p1y }

extension on _Period {
  int get weeks => switch (this) {
    _Period.p3m => 12,
    _Period.p6m => 24,
    _Period.p1y => 52,
  };
  String label(AppLocalizations l) => switch (this) {
    _Period.p3m => l.assetPeriod3m,
    _Period.p6m => l.assetPeriod6m,
    _Period.p1y => l.assetPeriod1y,
  };
  String headerLabel(AppLocalizations l) => l.assetWeeksCount(weeks);
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.asset,
    required this.scrollController,
    this.onEdit,
  });
  final Asset asset;
  final ScrollController scrollController;
  final VoidCallback? onEdit;
  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  _Period _period = _Period.p3m;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final asset = widget.asset;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    final meta = AssetTypeMeta.of(asset.assetType);
    final brandFg = resolveChartColor(context, asset.color, fallback: t.fgBrand);

    final isCard =
        asset.assetType == 'CREDIT_CARD' || asset.assetType == 'CHECK_CARD';
    final isInv = asset.assetType == 'INVESTMENT';
    final valueLabel = isCard
        ? l.assetValueLabelCard
        : isInv
        ? l.assetValuationShort
        : l.expSummaryBalance;
    final seriesLabel = isCard
        ? l.assetSeriesUsage
        : isInv
        ? l.assetValuationShort
        : l.expSummaryBalance;
    final trendTitle = l.assetTrendRecent(
      _period.headerLabel(l),
      isCard
          ? l.assetTrendKindUsage
          : isInv
              ? l.assetTrendKindValuation
              : l.assetTrendKindBalance,
    );

    final trendAsync = ref.watch(
      assetBalanceTrendProvider((assetId: asset.rowId, weeks: _period.weeks)),
    );
    // recent tx — web 와 동일 12건.
    final recentAsync = ref.watch(
      expensesByAssetProvider((assetId: asset.rowId, limit: 12)),
    );
    // CREDIT_CARD 는 신판 카드 상세 본문(_CardDetailBody) — 회차 히어로가 금액 담당.
    final isCredit = asset.assetType == 'CREDIT_CARD';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        _HeroCard(
          asset: asset,
          meta: meta,
          valueLabel: valueLabel,
          isCard: isCard,
          masked: masked,
          nameRowOnly: isCredit,
        ),
        if (isCredit) ...[
          _CardDetailBody(
            asset: asset,
            masked: masked,
            recentAsync: recentAsync,
            onEdit: widget.onEdit,
          ),
        ] else ...[
        const SizedBox(height: PSpace.x16),
        // 체크카드 — 실적 배지만(청구 회차 없음, design 신판)
        if (isCard) ...[
          _CardPerfBadge(assetRowId: asset.rowId, masked: masked),
          const SizedBox(height: PSpace.x16),
        ],
        if (isInv) ...[
          _TossLinkSection(asset: asset),
          const SizedBox(height: PSpace.x16),
        ],

        // Trend header
        Row(
          children: [
            Expanded(
              child: Text(
                trendTitle,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PTabs<_Period>(
              value: _period,
              size: PTabsSize.sm,
              items: [
                for (final p in _Period.values)
                  PTabItem(value: p, label: p.label(l)),
              ],
              onChanged: (p) => setState(() => _period = p),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        SizedBox(
          height: 160,
          child: _BalanceTrendChart(
            async: trendAsync,
            tokens: t,
            brandFg: brandFg,
            seriesLabel: seriesLabel,
            masked: masked,
          ),
        ),
        const SizedBox(height: PSpace.x20),

        // Recent tx
        Row(
          children: [
            Expanded(
              child: Text(
                (recentAsync.value?.isNotEmpty ?? false)
                    ? l.assetRecentTxCount(recentAsync.value!.length)
                    : l.dashRecent,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
            ),
            InkWell(
              borderRadius: PRadius.brSm,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/expense?assetId=${asset.rowId}');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.assetViewAll,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgSecondary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 12,
                      color: t.fgSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        _RecentExpenses(async: recentAsync, masked: masked, tokens: t),
        ],
      ],
    );
  }
}

/// 투자 자산 ↔ 토스 종목 연결 섹션 (프로(SECURITIES)+토스 연결 사용자에게만 노출).
/// 종목 + 보유수량을 등록하면 토스 현재가 × 수량으로 평가액이 실시간 계산된다.
/// 토스 계좌 보유분과 무관 — 시세만 빌려 타 증권사 보유 주식도 평가.
class _TossLinkSection extends ConsumerStatefulWidget {
  const _TossLinkSection({required this.asset});
  final Asset asset;

  @override
  ConsumerState<_TossLinkSection> createState() => _TossLinkSectionState();
}

class _TossLinkSectionState extends ConsumerState<_TossLinkSection> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _editQtyCtrl;
  String? _selSymbol;
  String? _selName;
  bool _busy = false;
  bool _editingQty = false;
  ({String symbol, int quantity})? _linked;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _queryCtrl = TextEditingController()..addListener(() => setState(() {}));
    _qtyCtrl = TextEditingController(
      text: a.tossQuantity != null ? '${a.tossQuantity}' : '',
    );
    _editQtyCtrl = TextEditingController();
    _selSymbol = a.tossSymbol;
    if (a.tossSymbol != null) _selName = findStock(a.tossSymbol!)?.name;
    if (a.tossSymbol != null && a.tossQuantity != null) {
      _linked = (symbol: a.tossSymbol!, quantity: a.tossQuantity!);
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _qtyCtrl.dispose();
    _editQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final symbol = _selSymbol;
    final qty = int.tryParse(_qtyCtrl.text.replaceAll(',', '')) ?? 0;
    if (symbol == null || qty <= 0 || _busy) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.linkTossSymbol(widget.asset.rowId, symbol, qty);
      ref.invalidate(assetsProvider);
      ref.invalidate(tossValuationMapProvider);
      if (!mounted) return;
      setState(() => _linked = (symbol: symbol, quantity: qty));
      showPSnackBar(context, l.assetTossLinkStarted,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetLinkFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.unlinkTossSymbol(widget.asset.rowId);
      ref.invalidate(assetsProvider);
      ref.invalidate(tossValuationMapProvider);
      if (!mounted) return;
      setState(() {
        _linked = null;
        _selSymbol = null;
        _selName = null;
        _qtyCtrl.clear();
        _queryCtrl.clear();
      });
      showPSnackBar(context, l.assetTossUnlinked,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetUnlinkFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 보유 수량만 수정 — 같은 종목코드로 재연결(백엔드가 수량 갱신 + 평가액 스냅샷 재적재).
  Future<void> _saveQty() async {
    final linked = _linked;
    final qty = int.tryParse(_editQtyCtrl.text.replaceAll(',', '')) ?? 0;
    if (linked == null || qty <= 0 || _busy) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.linkTossSymbol(widget.asset.rowId, linked.symbol, qty);
      ref.invalidate(assetsProvider);
      ref.invalidate(tossValuationMapProvider);
      if (!mounted) return;
      setState(() {
        _linked = (symbol: linked.symbol, quantity: qty);
        _editingQty = false;
      });
      showPSnackBar(context, l.assetQtyUpdated,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetUpdateFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 종목코드 → 이름 (KRX 마스터 우선, 해외 등은 kStocks 폴백).
  String? _nameOf(KrxStockMaster? master, String ticker) =>
      master?.byTicker(ticker)?.name ?? findStock(ticker)?.name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final enabled =
        (features?.hasSecurities ?? false) && (features?.tossConnected ?? false);
    if (!enabled) return const SizedBox.shrink();

    // KRX 종목 마스터(이름↔코드). 로딩 중이면 null → kStocks 폴백.
    final master = ref.watch(krxStockMasterProvider).asData?.value;

    if (_linked != null) {
      final linked = _linked!;
      final name = _nameOf(master, linked.symbol) ?? linked.symbol;
      return PCard(
        variant: PCardVariant.bordered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PBadge(label: l.assetTossLinked),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: Text(
                    '$name · ${l.assetSharesCount(linked.quantity)}',
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PSpace.x8),
            Text(
              l.assetTossValuationFormula(linked.quantity),
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
            const SizedBox(height: PSpace.x12),
            if (_editingQty) ...[
              PTextInput(
                controller: _editQtyCtrl,
                keyboardType: TextInputType.number,
                placeholder: l.assetHoldingQty,
              ),
              const SizedBox(height: PSpace.x8),
              Row(
                children: [
                  PButton(
                    label: l.actionSave,
                    size: PButtonSize.sm,
                    loading: _busy,
                    onPressed: _busy ? null : _saveQty,
                  ),
                  const SizedBox(width: PSpace.x8),
                  PButton(
                    label: l.actionCancel,
                    variant: PButtonVariant.secondary,
                    size: PButtonSize.sm,
                    onPressed:
                        _busy ? null : () => setState(() => _editingQty = false),
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  PButton(
                    label: l.assetEditQty,
                    size: PButtonSize.sm,
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _editQtyCtrl.text = '${linked.quantity}';
                            _editingQty = true;
                          }),
                  ),
                  const SizedBox(width: PSpace.x8),
                  PButton(
                    label: l.assetUnlink,
                    variant: PButtonVariant.secondary,
                    size: PButtonSize.sm,
                    loading: _busy,
                    onPressed: _busy ? null : _unlink,
                  ),
                ],
              ),
          ],
        ),
      );
    }

    final q = _queryCtrl.text.trim();
    // KRX 마스터(이름→코드) 우선 검색 + 해외 등 kStocks 보강(마스터엔 국내만 있음).
    final matches = <({String ticker, String name})>[];
    if (q.isNotEmpty) {
      for (final s in master?.search(q, limit: 8) ?? const []) {
        matches.add((ticker: s.ticker, name: s.name));
      }
      for (final s in kStocks) {
        if (matches.length >= 8) break;
        if (matches.any((m) => m.ticker == s.ticker)) continue;
        if (s.name.contains(q) || s.ticker.toUpperCase().contains(q.toUpperCase())) {
          matches.add((ticker: s.ticker, name: s.name));
        }
      }
    }
    final codeFallback = q.isNotEmpty && matches.isEmpty ? q.toUpperCase() : null;
    final qty = int.tryParse(_qtyCtrl.text.replaceAll(',', '')) ?? 0;
    final canLink = _selSymbol != null && qty > 0 && !_busy;

    return PCard(
      variant: PCardVariant.bordered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.assetTossRealtimeTitle,
            style: PTypo.bodySm
                .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
          ),
          const SizedBox(height: PSpace.x4),
          Text(
            l.assetTossRealtimeDesc,
            style: PTypo.caption.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(height: PSpace.x12),

          // 선택된 종목 (있으면 chip, 없으면 검색)
          if (_selSymbol != null)
            Row(
              children: [
                PChip(
                  label:
                      '${_selName ?? _nameOf(master, _selSymbol!) ?? _selSymbol!} (${_selSymbol!})',
                  selected: true,
                  onTap: () => setState(() {
                    _selSymbol = null;
                    _selName = null;
                  }),
                ),
                const SizedBox(width: PSpace.x8),
                Text(l.assetTapToChange,
                    style: PTypo.micro.copyWith(color: t.fgTertiary)),
              ],
            )
          else ...[
            PTextInput(
              controller: _queryCtrl,
              placeholder: l.assetStockSearchHint,
            ),
            if (matches.isNotEmpty || codeFallback != null) ...[
              const SizedBox(height: PSpace.x8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in matches)
                    PChip(
                      label: '${s.name} (${s.ticker})',
                      selected: false,
                      onTap: () => setState(() {
                        _selSymbol = s.ticker;
                        _selName = s.name;
                        _queryCtrl.clear();
                      }),
                    ),
                  if (codeFallback != null)
                    PChip(
                      label: l.assetLinkByCode(codeFallback),
                      selected: false,
                      onTap: () => setState(() {
                        _selSymbol = codeFallback;
                        _selName = null;
                        _queryCtrl.clear();
                      }),
                    ),
                ],
              ),
            ],
          ],

          const SizedBox(height: PSpace.x12),
          Row(
            children: [
              Expanded(
                child: PTextInput(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  placeholder: l.assetHoldingQty,
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton(
                label: l.assetLink,
                size: PButtonSize.sm,
                loading: _busy,
                onPressed: canLink ? _link : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.asset,
    required this.meta,
    required this.valueLabel,
    required this.isCard,
    required this.masked,
    this.nameRowOnly = false,
  });
  final Asset asset;
  final AssetTypeMeta meta;
  final String valueLabel;
  final bool isCard;
  final bool masked;

  /// 신용카드 — 이름 행만(구분선·잔액 생략, 회차 히어로가 금액 담당).
  final bool nameRowOnly;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final subtitle = [
      asset.institution,
      assetTypeLabel(l, asset.assetType),
      asset.memo,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final absBalance = (asset.balance ?? 0).abs();
    // 플랫 히어로(design 신판) — 그라데이션 카드 제거, 이름 행 아래 구분선만.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 14),
          margin: EdgeInsets.only(bottom: nameRowOnly ? 0 : 14),
          decoration: nameRowOnly
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.borderSubtle)),
                ),
          child: Row(
            children: [
              // web hero 정합 — 타입 글리프 대신 AssetLogo 모노그램 (icon 제거 마이그 잔재 정리)
              AssetLogo(asset: asset, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.assetName,
                      style: PTypo.h3.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!nameRowOnly) ...[
        Text(
          valueLabel,
          style: PTypo.micro.copyWith(
            color: t.fgTertiary,
            fontWeight: PFontWeight.semi,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        // 큰 금액 — 숫자/원 분리해서 원 폰트만 작게.
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                // 카드도 부호 없이 중립색 — 결제 예정 금액 표기(사용자 결정)
                text: masked ? '••••••' : krw(absBalance),
                style: PTypo.h1.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.6,
                ),
              ),
              if (!masked)
                TextSpan(
                  text: wonUnit(),
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        ],
      ],
    );
  }
}

class _BalanceTrendChart extends StatefulWidget {
  const _BalanceTrendChart({
    required this.async,
    required this.tokens,
    required this.brandFg,
    required this.seriesLabel,
    required this.masked,
  });
  final AsyncValue<List<AssetBalancePoint>> async;
  final PorestTokens tokens;
  final Color brandFg;
  final String seriesLabel;
  final bool masked;

  @override
  State<_BalanceTrendChart> createState() => _BalanceTrendChartState();
}

class _BalanceTrendChartState extends State<_BalanceTrendChart> {
  int? _touchedIdx;
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = widget.tokens;
    final brandFg = widget.brandFg;
    final seriesLabel = widget.seriesLabel;
    final masked = widget.masked;
    final list = widget.async.value ?? const <AssetBalancePoint>[];
    if (widget.async.isLoading && list.isEmpty) {
      // 차트 영역 전체 PSkeleton — 부모 SizedBox(height:160) 의 영역에 fill.
      return SizedBox.expand(child: PSkeleton(borderRadius: PRadius.brLg));
    }
    if (list.isEmpty) {
      return _ChartPlaceholder(
          text: AppLocalizations.of(context).assetChartNoData, tokens: tokens);
    }
    final n = list.length;
    final spots = [
      for (int i = 0; i < n; i++)
        FlSpot(i.toDouble(), list[i].balance.toDouble()),
    ];
    // Y축: 웹 Recharts auto-nice 와 동일한 0기준 nice 눈금 (공유 niceAxis).
    // 대출 등 음수 잔액이면 0 아래로도 nice 확장 → 눈금이 딱 떨어지고 겹치지 않음.
    final values = list.map((p) => p.balance.toDouble()).toList(growable: false);
    final maxRaw = values.reduce((a, b) => a > b ? a : b);
    final minRaw = values.reduce((a, b) => a < b ? a : b);
    final yAxis = niceAxis(minRaw, maxRaw);
    final yMin = yAxis.min;
    final yMax = yAxis.max;
    final yInterval = yAxis.interval;
    final xInterval = (n / 6).clamp(1.0, double.infinity);

    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tokens.borderSubtle,
            strokeWidth: 1,
            dashArray: const [3, 3],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: yInterval,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  masked ? '••••' : formatChartAxis(v),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: PTypo.micro.copyWith(
                    color: tokens.fgTertiary,
                    fontSize: PFontSize.micro,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: xInterval,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= n) return const SizedBox.shrink();
                // 너무 빽빽하면 균등 stride 만 표시.
                final stride = (n / 6).ceil();
                if (n > 12 && stride > 1 && i % stride != 0 && i != n - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.weekN(i + 1),
                    style: PTypo.micro.copyWith(
                      color: tokens.fgTertiary,
                      fontSize: PFontSize.micro,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent ||
                event is FlPanEndEvent ||
                event is FlPanCancelEvent ||
                event is FlLongPressEnd ||
                event is FlPointerExitEvent) {
              if (_touchedIdx != null) {
                setState(() => _touchedIdx = null);
              }
              return;
            }
            final touched = response?.lineBarSpots;
            if (touched == null || touched.isEmpty) {
              if (_touchedIdx != null) {
                setState(() => _touchedIdx = null);
              }
              return;
            }
            final i = touched.first.x.toInt();
            final pos = event.localPosition;
            if (i >= 0 && i < list.length && (i != _touchedIdx || pos != _touchPos)) {
              setState(() {
                _touchedIdx = i;
                if (pos != null) _touchPos = pos;
              });
            }
          },
          // 기본 RichText 툴팁 OFF — web 라운드 사각 인디케이터 정합을 위해
          // Stack 위 PChartTooltipBox 로 직접 렌더 (아래 Positioned).
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipBorder: BorderSide.none,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 0,
            getTooltipItems: (touched) =>
                List<LineTooltipItem?>.filled(touched.length, null),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: brandFg,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: brandFg,
                strokeColor: tokens.bgSurface,
                strokeWidth: 1.5,
              ),
            ),
            // web recharts 정합 — fill 은 차트 바닥이 아니라 0 기준선을 향해 채움.
            // 양수 구간은 라인 아래(belowBarData), 음수 구간은 라인 위(aboveBarData)로
            // cutOffY=0 에서 잘라 채운다 (카드 사용 추이처럼 전부 음수면 위쪽 fill).
            belowBarData: BarAreaData(
              show: true,
              applyCutOffY: true,
              cutOffY: 0,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  brandFg.withValues(alpha: 0.28),
                  brandFg.withValues(alpha: 0),
                ],
              ),
            ),
            aboveBarData: BarAreaData(
              show: true,
              applyCutOffY: true,
              cutOffY: 0,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  brandFg.withValues(alpha: 0.28),
                  brandFg.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        chart,
        if (_touchedIdx != null && _touchedIdx! < list.length && _touchPos != null)
          PChartTooltipLayer(
            anchor: _touchPos!,
            child: PChartTooltipBox(
              // web BalanceTooltip 정합 — 'N주 · MM-DD'
              title:
                  '${l.weekN(_touchedIdx! + 1)} · ${_fmtWeekStart(list[_touchedIdx!].weekStart)}',
              labelWidth: 40,
              rows: [
                PChartTooltipRowData(
                  color: brandFg,
                  label: seriesLabel,
                  amount: masked
                      ? '••••••'
                      : krwSigned(list[_touchedIdx!].balance, false, unit: true),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 'YYYY-MM-DD' → 'MM-DD' (web weekStart.slice(5) 정합).
String _fmtWeekStart(String iso) => iso.length >= 10 ? iso.substring(5) : iso;

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.text, required this.tokens});
  final String text;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSunken,
        borderRadius: PRadius.brLg,
      ),
      alignment: Alignment.center,
      child: Text(text, style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses({
    required this.async,
    required this.masked,
    required this.tokens,
  });
  final AsyncValue<List<Expense>> async;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <Expense>[];
    if (async.isLoading && list.isEmpty) {
      // 서버 거래내역 로딩 중 — 실제 _ExpenseRow(아이콘 36 + 2줄 + 금액) 그대로 스켈레톤.
      return Column(
        children: [
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  PSkeleton(width: 36, height: 36, borderRadius: PRadius.tile(36)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PSkeleton.line(width: 120, height: 14),
                        SizedBox(height: 4),
                        PSkeleton.line(width: 80, height: 11),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const PSkeleton.line(width: 56, height: 14),
                ],
              ),
            ),
        ],
      );
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            AppLocalizations.of(context).assetNoLinkedTx,
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
          ),
        ),
      );
    }

    // 가계부 메인 리스트 미러 — 카드 제거, 날짜 그룹 헤더(웹 DateGroupHeader
    // 정합: 날짜 primary/bold + 요일 tertiary + 우측 일 지출/수입 합계) + 플랫 행.
    final dayGroups = <String, List<Expense>>{};
    for (final e in list) {
      dayGroups.putIfAbsent(e.expenseDateOnly ?? '', () => <Expense>[]).add(e);
    }
    final entries = dayGroups.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var gi = 0; gi < entries.length; gi++) ...[
          // 헤더-행 간격은 행 자체 pt 12(웹 LedgerRow py-3)가 담당 — bottom 0.
          Padding(
            padding: EdgeInsets.only(top: gi == 0 ? 0 : PSpace.x16),
            child: _DayGroupHeader(
              dayKey: entries[gi].key,
              items: entries[gi].value,
              masked: masked,
              tokens: tokens,
            ),
          ),
          for (final e in entries[gi].value)
            _ExpenseRow(expense: e, masked: masked, tokens: tokens),
        ],
      ],
    );
  }
}

/// 날짜 그룹 헤더 — 웹 DateGroupHeader 미러 ("7월 8일" + "수" + 일 합계).
class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({
    required this.dayKey,
    required this.items,
    required this.masked,
    required this.tokens,
  });
  final String dayKey;
  final List<Expense> items;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(dayKey);
    final label = d == null ? null : formatDay(d);
    final dayExpense = items
        .where((e) => e.expenseType == 'EXPENSE')
        .fold<int>(0, (s, e) => s + e.amount.abs());
    final dayIncome = items
        .where((e) => e.expenseType == 'INCOME')
        .fold<int>(0, (s, e) => s + e.amount.abs());
    return Row(
      children: [
        Text(
          label?.md ?? dayKey,
          style: PTypo.bodySm.copyWith(
            color: tokens.fgPrimary,
            fontWeight: PFontWeight.bold,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: PSpace.x8),
          Text(
            label.dow,
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
          ),
        ],
        const Spacer(),
        if (dayExpense > 0)
          Text(
            krwSigned(dayExpense, masked, sign: '−', unit: true),
            style: PTypo.caption.copyWith(
              color: tokens.fgExpense,
              fontWeight: PFontWeight.semi,
            ),
          ),
        if (dayIncome > 0) ...[
          if (dayExpense > 0) const SizedBox(width: PSpace.x8),
          Text(
            krwSigned(dayIncome, masked, sign: '+', unit: true),
            style: PTypo.caption.copyWith(
              color: tokens.fgIncome,
              fontWeight: PFontWeight.semi,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.masked,
    required this.tokens,
  });
  final Expense expense;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = resolveChartColor(context, expense.categoryColor, fallback: tokens.fgBrand);
    final bg = softBg(context, color);
    final title =
        expense.merchant ??
        expense.description ??
        (expense.categoryName ?? l.assetTxFallback);
    final subParts = [
      expense.categoryName ?? l.assetCategoryOther,
      if ((expense.assetName ?? '').isNotEmpty) expense.assetName!,
    ];
    return InkWell(
      onTap: () => showTxDetailDialog(context, expense),
      borderRadius: PRadius.brMd,
      child: Padding(
        // 웹 LedgerRow 정합 — py-3(12), 좌우 0(헤더와 좌측 라인 일치).
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.tile(36)),
              alignment: Alignment.center,
              child: Icon(
                lucideByName(expense.categoryIcon),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.bodySm.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              masked
                  ? '••••••'
                  : krwSigned(expense.signedAmount, false,
                      sign: expense.signedAmount > 0 ? '+' : '', unit: true),
              style: PTypo.bodySm.copyWith(
                color: tokens.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 신용카드 청구 사이클 — 결제예정액·예정일 + '지금 결제' + 청구이력.
/// GET /asset/{id}/billing 사용. '지금 결제' 후 billing/assets invalidate.
/// chart green 시멘틱(실적 달성) — 다크 light variant 스왑(웹 --color-cat-green 미러).
Color _chartGreenOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6BCB86) // chart-green-light
        : const Color(0xFF2D8060); // chart-green

/// 결제 회차(청구월) 항목 — 예정 1건 + 과거 결제 완료(COMPLETED) 이력.
class _CardStatement {
  const _CardStatement({
    required this.label,
    required this.scheduled,
    required this.amount,
    required this.paymentDate,
    this.periodStart,
    this.periodEnd,
  });
  final String label;
  final bool scheduled;
  final int amount;
  final String paymentDate;
  final String? periodStart;
  final String? periodEnd;
}

/// 카드 월 실적 배지 — design 신판(달성/잔여 요약, 웹 CardPerfBadge 미러).
/// 달성: cat-green 10% tint / 미달: sunken. 실적 무관 카드면 숨김.
class _CardPerfBadge extends ConsumerWidget {
  const _CardPerfBadge({required this.assetRowId, required this.masked});
  final int assetRowId;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final async = ref.watch(cardPerformanceProvider(
        (assetRowId: assetRowId, yearMonth: _currentYearMonth())));
    final p = async.value;
    if (async.isLoading && p == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: t.bgSunken,
          borderRadius: PRadius.brLg,
        ),
        child: const Row(
          children: [
            PSkeleton(width: 30, height: 30, borderRadius: PRadius.brFull),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PSkeleton.line(width: 130, height: 13),
                  SizedBox(height: 4),
                  PSkeleton.line(width: 160, height: 11),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (p == null || !p.isRequired || p.requiredAmount == null) {
      return const SizedBox.shrink();
    }
    final done = p.isAchieved;
    final green = _chartGreenOf(context);
    final pct = (p.achievementRate.clamp(0, 1.5) * 100).truncate();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: done
            ? Color.alphaBlend(green.withValues(alpha: 0.10), t.bgSurface)
            : t.bgSunken,
        borderRadius: PRadius.brLg,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: t.bgSurface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(
              done ? LucideIcons.check : LucideIcons.target,
              size: 15,
              color: done ? green : t.fgSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  done
                      ? l.assetPerfDone
                      : l.assetPerfRemain(
                          krwSigned(p.remainingAmount ?? 0, masked, unit: true)),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  masked
                      ? '•••••• · $pct%'
                      : '${krw(p.currentAmount)} / ${krw(p.requiredAmount!)}${wonUnit()} · $pct%',
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 상세 본문 — design card-detail.jsx 신판(현대카드 결제정보 패턴, 웹 CardDetailBody
/// 미러). 회차 히어로(기간 선택 시트) / 결제일·이용 기간 행 / 액션 2타일 /
/// 한도 사용 게이지·실적 배지 / 이용 내역(정렬 칩 + 날짜 그룹). CREDIT_CARD 전용.
class _CardDetailBody extends ConsumerStatefulWidget {
  const _CardDetailBody({
    required this.asset,
    required this.masked,
    required this.recentAsync,
    this.onEdit,
  });
  final Asset asset;
  final bool masked;
  final AsyncValue<List<Expense>> recentAsync;
  final VoidCallback? onEdit;

  @override
  ConsumerState<_CardDetailBody> createState() => _CardDetailBodyState();
}

enum _UsageSort { recent, amount, category }

class _CardDetailBodyState extends ConsumerState<_CardDetailBody> {
  int _stIdx = 0;
  _UsageSort _sort = _UsageSort.recent;
  bool _paying = false;

  List<_CardStatement> _statements(CardBilling? b) {
    final out = <_CardStatement>[];
    if (b?.nextPaymentDate != null) {
      final d = DateTime.tryParse(b!.nextPaymentDate!);
      out.add(_CardStatement(
        label: d != null ? formatDay(d).md : b.nextPaymentDate!,
        scheduled: true,
        amount: b.upcomingAmount,
        paymentDate: b.nextPaymentDate!,
        periodStart: b.upcomingPeriodStart,
        periodEnd: b.upcomingPeriodEnd,
      ));
    }
    for (final h in b?.history ?? const <BillingItem>[]) {
      if (h.status != 'COMPLETED') continue;
      final d = DateTime.tryParse(h.paymentDate);
      out.add(_CardStatement(
        label: d != null ? formatDay(d).md : h.paymentDate,
        scheduled: false,
        amount: h.billingAmount,
        paymentDate: h.paymentDate,
        periodStart: h.periodStart,
        periodEnd: h.periodEnd,
      ));
    }
    return out;
  }

  Future<void> _confirmAndPay(CardBilling b) async {
    final l = AppLocalizations.of(context);
    final dateSuffix = b.nextPaymentDate != null
        ? l.assetPayConfirmDateSuffix(b.nextPaymentDate!)
        : '';
    final ok = await showPConfirmDialog(
      context,
      title: l.assetPayNow,
      message: '${l.assetPayConfirmMessage(krw(b.upcomingAmount))}$dateSuffix',
      confirmLabel: l.assetPayAction,
    );
    if (!ok || !mounted) return;
    await _pay();
  }

  Future<void> _pay() async {
    if (_paying) return;
    final l = AppLocalizations.of(context);
    setState(() => _paying = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.payCard(widget.asset.rowId);
      ref
        ..invalidate(cardBillingProvider(widget.asset.rowId))
        ..invalidate(assetsProvider)
        ..invalidate(assetByIdProvider(widget.asset.rowId));
      if (!mounted) return;
      showPSnackBar(context, l.assetPaymentRecorded,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetPayFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _goEdit() {
    Navigator.of(context).pop();
    if (widget.onEdit != null) {
      widget.onEdit!();
    } else {
      context.push('/account-card-manage');
    }
  }

  void _openPeriodPicker(List<_CardStatement> stmts) {
    final byYear = <String, List<(int, _CardStatement)>>{};
    for (var i = 0; i < stmts.length; i++) {
      byYear.putIfAbsent(stmts[i].paymentDate.substring(0, 4), () => []).add((i, stmts[i]));
    }
    showPSheet<void>(
      context,
      title: AppLocalizations.of(context).assetPeriodPick,
      shrinkWrap: true,
      contentBuilder: (ctx, _) {
        final t = ctx.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in byYear.entries)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: PFontSize.bodyMd,
                            fontWeight: PFontWeight.bold,
                            color: t.fgPrimary,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var ri = 0; ri < entry.value.length; ri++)
                            InkWell(
                              onTap: () {
                                // showPSheet 는 root navigator — rootNavigator pop 필수.
                                Navigator.of(context, rootNavigator: true).pop();
                                setState(() => _stIdx = entry.value[ri].$1);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 15),
                                decoration: ri == 0
                                    ? null
                                    : BoxDecoration(
                                        border: Border(
                                            top: BorderSide(
                                                color: t.borderSubtle)),
                                      ),
                                child: Row(
                                  children: [
                                    Text(
                                      entry.value[ri].$2.scheduled
                                          ? '${entry.value[ri].$2.label} (${AppLocalizations.of(ctx).assetScheduledTag})'
                                          : entry.value[ri].$2.label,
                                      style: TextStyle(
                                        fontFamily: PTypo.sans,
                                        fontSize: PFontSize.bodyMd,
                                        fontWeight: entry.value[ri].$1 == _stIdx
                                            ? PFontWeight.bold
                                            : PFontWeight.medium,
                                        color: t.fgPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      widget.masked
                                          ? '••••••'
                                          : krwSigned(entry.value[ri].$2.amount,
                                              false, unit: true),
                                      style: PTypo.bodySm
                                          .copyWith(color: t.fgTertiary),
                                    ),
                                    if (entry.value[ri].$1 == _stIdx) ...[
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.check,
                                          size: 16, color: t.fgBrand),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final masked = widget.masked;
    final asset = widget.asset;
    final billingAsync = ref.watch(cardBillingProvider(asset.rowId));
    final b = billingAsync.value;
    final stmts = _statements(b);
    final st = stmts.isEmpty ? null : stmts[_stIdx.clamp(0, stmts.length - 1)];

    final limit = asset.creditLimit ?? 0;
    final used = (asset.balance ?? 0).abs();
    final limitPct =
        limit > 0 ? ((used / limit) * 100).round().clamp(0, 100) : 0;
    final limitWarn = limitPct >= 80;
    final paymentDay = b?.paymentDay ?? asset.paymentDay;
    final canPay = (b?.upcomingAmount ?? 0) > 0 && !_paying;
    final periodText = st?.periodStart != null && st?.periodEnd != null
        ? '${_fmtDate(st!.periodStart!)} ~ ${_fmtDate(st.periodEnd!)}'
        : null;

    if (billingAsync.isLoading && b == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(2, 2, 2, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSkeleton.line(width: 130, height: 20),
            SizedBox(height: 12),
            PSkeleton.line(width: 180, height: 32),
            SizedBox(height: 16),
            PSkeleton.line(width: double.infinity, height: 48),
          ],
        ),
      );
    }

    final green = _chartGreenOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 결제 예정 히어로 — 회차 선택
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: PRadius.brMd,
                onTap: stmts.isEmpty ? null : () => _openPeriodPicker(stmts),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      st?.label ?? '—',
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.h3,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.4,
                        color: t.fgPrimary,
                      ),
                    ),
                    if (st?.scheduled ?? false) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: t.borderDefault),
                          borderRadius: PRadius.brFull,
                        ),
                        child: Text(
                          l.assetScheduledTag,
                          style: PTypo.micro.copyWith(
                            color: t.fgSecondary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 7),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: t.bgSunken,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.chevronDown,
                          size: 14, color: t.fgSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: masked ? '••••••' : krw(st?.amount ?? 0),
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.displayMd,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.96,
                        color: t.fgPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!masked)
                      TextSpan(
                        text: wonUnit(),
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.h3,
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              if (st != null && !st.scheduled) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.check, size: 13, color: green),
                    const SizedBox(width: 4),
                    Text(
                      l.assetPaidDone,
                      style: PTypo.caption.copyWith(
                        color: green,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // 결제일 · 카드 이용 기간
        if (paymentDay != null)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  child: Text(
                    l.assetPaymentDay,
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                  ),
                ),
                Text(
                  l.assetMonthlyPaymentDay(paymentDay),
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const Spacer(),
                if (periodText != null)
                  Text(
                    l.assetUsagePeriod(periodText),
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
              ],
            ),
          ),

        // 빠른 액션
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: _CardActionTile(
                  icon: LucideIcons.zap,
                  label: l.assetPayNow,
                  enabled: canPay,
                  onTap: b == null ? null : () => _confirmAndPay(b),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardActionTile(
                  icon: LucideIcons.slidersHorizontal,
                  label: l.assetLimitSettings,
                  onTap: _goEdit,
                ),
              ),
            ],
          ),
        ),

        // 한도 사용 · 실적
        if (limit > 0)
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l.assetLimitUsage,
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l.assetLimitPctUsed(limitPct),
                      style: PTypo.bodySm.copyWith(
                        color: limitWarn ? chartRedOf(context) : t.fgBrand,
                        fontWeight: PFontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 11, bottom: 7),
                  child: ClipRRect(
                    borderRadius: PRadius.brFull,
                    child: SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(color: t.bgSunken),
                          FractionallySizedBox(
                            widthFactor: limitPct / 100,
                            child: Container(
                              color: limitWarn
                                  ? chartRedOf(context)
                                  : t.bgBrandSolid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      masked
                          ? '••••••'
                          : l.assetLimitOf(krw(used), '${krw(limit)}${wonUnit()}'),
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                    const Spacer(),
                    Text(
                      masked
                          ? '••••••'
                          : l.assetLimitRemain(krwSigned(
                              (limit - used).clamp(0, limit), false,
                              unit: true)),
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: PRadius.brFull,
                    onTap: _goEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: t.borderDefault),
                        borderRadius: PRadius.brFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.pencil,
                              size: 12, color: t.fgPrimary),
                          const SizedBox(width: 5),
                          Text(
                            l.assetLimitEdit,
                            style: PTypo.caption.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _CardPerfBadge(assetRowId: asset.rowId, masked: masked),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _CardPerfBadge(assetRowId: asset.rowId, masked: masked),
          ),

        // 이용 내역 — 정렬 칩 + 리스트
        Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l.assetUsageHistory,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  if ((widget.recentAsync.value?.length ?? 0) > 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      '${widget.recentAsync.value!.length}',
                      style: PTypo.body.copyWith(
                        color: t.fgBrand,
                        fontWeight: PFontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  const Spacer(),
                  InkWell(
                    borderRadius: PRadius.brSm,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/expense?assetId=${asset.rowId}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.assetViewAll,
                            style: PTypo.bodySm.copyWith(
                              color: t.fgSecondary,
                              fontWeight: PFontWeight.semi,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(LucideIcons.chevronRight,
                              size: 12, color: t.fgSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 2),
                child: Row(
                  children: [
                    for (final o in _UsageSort.values) ...[
                      if (o != _UsageSort.values.first)
                        const SizedBox(width: 7),
                      _UsageSortChip(
                        label: switch (o) {
                          _UsageSort.recent => l.assetSortRecent,
                          _UsageSort.amount => l.assetSortAmount,
                          _UsageSort.category => l.assetSortCategory,
                        },
                        selected: _sort == o,
                        onTap: () => setState(() => _sort = o),
                      ),
                    ],
                  ],
                ),
              ),
              if (_sort == _UsageSort.recent)
                _RecentExpenses(
                    async: widget.recentAsync, masked: masked, tokens: t)
              else
                Builder(builder: (context) {
                  final list = [...(widget.recentAsync.value ?? const <Expense>[])];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          l.assetNoUsage,
                          style:
                              PTypo.bodySm.copyWith(color: t.fgTertiary),
                        ),
                      ),
                    );
                  }
                  if (_sort == _UsageSort.amount) {
                    list.sort(
                        (a, b) => b.amount.abs().compareTo(a.amount.abs()));
                  } else {
                    list.sort((a, b) => (a.categoryName ?? '')
                        .compareTo(b.categoryName ?? ''));
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        for (final e in list)
                          _ExpenseRow(
                              expense: e, masked: masked, tokens: t),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// 빠른 액션 타일 — sunken 박스 + 아이콘 30 박스(surface) + 라벨(design cdt-action).
class _CardActionTile extends StatelessWidget {
  const _CardActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        borderRadius: PRadius.brLg,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: t.bgSurface,
                  borderRadius: PRadius.brMd,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: t.fgSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.caption.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이용 내역 정렬 칩 — sunken / 선택 시 brand 채움(design cdt-chip, 웹 정합).
class _UsageSortChip extends StatelessWidget {
  const _UsageSortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      borderRadius: PRadius.brFull,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.bgBrandSolid : t.bgSunken,
          borderRadius: PRadius.brFull,
        ),
        child: Text(
          label,
          style: PTypo.caption.copyWith(
            color: selected ? t.fgOnBrand : t.fgSecondary,
            fontWeight: selected ? PFontWeight.bold : PFontWeight.semi,
          ),
        ),
      ),
    );
  }
}

/// 'yyyy-MM-dd' → 'M.d' 표기.
String _fmtDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || d == null) return iso;
  return '$m.$d';
}

/// stats 차트와 동일한 만/억 단위 — 한글 단위가 KRW 와 어울리고
/// '4.3M'/'-40.4M' 보다 짧게 표현돼 reservedSize 안에 안전히 들어간다.

String _currentYearMonth() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}';
}
