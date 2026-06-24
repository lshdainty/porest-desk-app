import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_axis.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/card/presentation/card_performance_bar.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_mock.dart';
import 'package:porest_desk_app/features/stocks/domain/stock.dart';
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
    title: _titleFor(asset),
    contentBuilder: (ctx, scrollCtrl) =>
        _DetailBody(asset: asset, scrollController: scrollCtrl),
    footerBuilder: (ctx) => _DetailFooter(asset: asset, onEdit: onEdit),
  );
}

class _DetailFooter extends ConsumerWidget {
  const _DetailFooter({required this.asset, this.onEdit});
  final Asset asset;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    return PViewFooter(
      // 좌측 = 삭제가 아니라 금액 가리기/표시 토글 → leading 슬롯.
      leading: PButton(
        label: masked ? '금액 표시' : '금액 가리기',
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

String _titleFor(Asset a) {
  if (a.assetType == 'CREDIT_CARD' || a.assetType == 'CHECK_CARD') {
    return '카드 상세';
  }
  if (a.assetType == 'INVESTMENT') return '투자 상세';
  return '계좌 상세';
}

enum _Period { p3m, p6m, p1y }

extension on _Period {
  int get weeks => switch (this) {
    _Period.p3m => 12,
    _Period.p6m => 24,
    _Period.p1y => 52,
  };
  String get label => switch (this) {
    _Period.p3m => '3개월',
    _Period.p6m => '6개월',
    _Period.p1y => '1년',
  };
  String get headerLabel => switch (this) {
    _Period.p3m => '12주',
    _Period.p6m => '24주',
    _Period.p1y => '52주',
  };
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.asset, required this.scrollController});
  final Asset asset;
  final ScrollController scrollController;
  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  _Period _period = _Period.p3m;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final asset = widget.asset;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    final meta = AssetTypeMeta.of(asset.assetType);
    final brandFg = resolveChartColor(context, asset.color, fallback: t.fgBrand);

    final isCard =
        asset.assetType == 'CREDIT_CARD' || asset.assetType == 'CHECK_CARD';
    final isInv = asset.assetType == 'INVESTMENT';
    final valueLabel = isCard
        ? '이번 달 결제 예정'
        : isInv
        ? '평가액'
        : '잔액';
    final seriesLabel = isCard
        ? '사용'
        : isInv
        ? '평가액'
        : '잔액';
    final trendTitle =
        '최근 ${_period.headerLabel} ${isCard
            ? '사용 추이'
            : isInv
            ? '평가액 추이'
            : '잔액 추이'}';

    final trendAsync = ref.watch(
      assetBalanceTrendProvider((assetId: asset.rowId, weeks: _period.weeks)),
    );
    // recent tx — web 와 동일 12건.
    final recentAsync = ref.watch(
      expensesByAssetProvider((assetId: asset.rowId, limit: 12)),
    );

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        _HeroCard(
          asset: asset,
          meta: meta,
          brandFg: brandFg,
          valueLabel: valueLabel,
          isCard: isCard,
          masked: masked,
        ),
        const SizedBox(height: PSpace.x16),
        if (isCard) ...[
          CardPerformanceBar(
            assetRowId: asset.rowId,
            yearMonth: _currentYearMonth(),
            masked: masked,
          ),
          const SizedBox(height: PSpace.x16),
        ],
        if (asset.assetType == 'CREDIT_CARD') ...[
          _CardBillingSection(asset: asset, masked: masked),
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
                  PTabItem(value: p, label: p.label),
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
                    ? '최근 거래 (${recentAsync.value!.length})'
                    : '최근 거래',
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
                      '전체 보기',
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
  String? _selSymbol;
  String? _selName;
  bool _busy = false;
  ({String symbol, int quantity})? _linked;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _queryCtrl = TextEditingController()..addListener(() => setState(() {}));
    _qtyCtrl = TextEditingController(
      text: a.tossQuantity != null ? '${a.tossQuantity}' : '',
    );
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
    super.dispose();
  }

  Future<void> _link() async {
    final symbol = _selSymbol;
    final qty = int.tryParse(_qtyCtrl.text.replaceAll(',', '')) ?? 0;
    if (symbol == null || qty <= 0 || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.linkTossSymbol(widget.asset.rowId, symbol, qty);
      ref.invalidate(assetsProvider);
      ref.invalidate(tossValuationMapProvider);
      if (!mounted) return;
      setState(() => _linked = (symbol: symbol, quantity: qty));
      showPSnackBar(context, '토스 시세 연동을 시작했어요',
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '연결 실패: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    if (_busy) return;
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
      showPSnackBar(context, '토스 연결을 해제했어요',
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '해제 실패: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final enabled =
        (features?.hasSecurities ?? false) && (features?.tossConnected ?? false);
    if (!enabled) return const SizedBox.shrink();

    if (_linked != null) {
      final linked = _linked!;
      final name = findStock(linked.symbol)?.name ?? linked.symbol;
      return PCard(
        variant: PCardVariant.bordered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PBadge(label: '토스 연동 중'),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: Text(
                    '$name · ${linked.quantity}주',
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
              '평가액 = 토스 현재가 × ${linked.quantity}주 로 실시간 계산됩니다.',
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
            const SizedBox(height: PSpace.x12),
            PButton(
              label: '연결 해제',
              variant: PButtonVariant.secondary,
              size: PButtonSize.sm,
              loading: _busy,
              onPressed: _busy ? null : _unlink,
            ),
          ],
        ),
      );
    }

    final q = _queryCtrl.text.trim();
    final matches = q.isEmpty
        ? const <Stock>[]
        : kStocks
            .where((s) =>
                s.name.contains(q) ||
                s.ticker.toUpperCase().contains(q.toUpperCase()))
            .take(6)
            .toList();
    final codeFallback = q.isNotEmpty && matches.isEmpty ? q.toUpperCase() : null;
    final qty = int.tryParse(_qtyCtrl.text.replaceAll(',', '')) ?? 0;
    final canLink = _selSymbol != null && qty > 0 && !_busy;

    return PCard(
      variant: PCardVariant.bordered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '토스 시세로 실시간 평가',
            style: PTypo.bodySm
                .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
          ),
          const SizedBox(height: PSpace.x4),
          Text(
            '보유 종목과 수량을 등록하면 토스 현재가 × 수량으로 평가액이 실시간 반영됩니다.',
            style: PTypo.caption.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(height: PSpace.x12),

          // 선택된 종목 (있으면 chip, 없으면 검색)
          if (_selSymbol != null)
            Row(
              children: [
                PChip(
                  label:
                      '${_selName ?? findStock(_selSymbol!)?.name ?? _selSymbol!} (${_selSymbol!})',
                  selected: true,
                  onTap: () => setState(() {
                    _selSymbol = null;
                    _selName = null;
                  }),
                ),
                const SizedBox(width: PSpace.x8),
                Text('변경하려면 탭',
                    style: PTypo.micro.copyWith(color: t.fgTertiary)),
              ],
            )
          else ...[
            PTextInput(
              controller: _queryCtrl,
              placeholder: '종목명·코드 검색 (예: 삼성전자, 005930)',
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
                      label: '「$codeFallback」 코드로 연결',
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
                  placeholder: '보유 수량',
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton(
                label: '연결',
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
    required this.brandFg,
    required this.valueLabel,
    required this.isCard,
    required this.masked,
  });
  final Asset asset;
  final AssetTypeMeta meta;
  final Color brandFg;
  final String valueLabel;
  final bool isCard;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final subtitle = [
      asset.institution,
      meta.label,
      asset.memo,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final absBalance = (asset.balance ?? 0).abs();
    return Container(
      padding: const EdgeInsets.all(PSpace.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brandFg.withValues(alpha: 0.12),
            brandFg.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: brandFg.withValues(alpha: 0.22), width: 1),
        borderRadius: PRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 14),
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
                  text: masked
                      ? '••••••'
                      : '${isCard && absBalance > 0 ? '−' : ''}${krw(absBalance)}',
                  style: PTypo.h1.copyWith(
                    color: isCard ? t.statusDangerFg : t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: -0.6,
                  ),
                ),
                if (!masked)
                  TextSpan(
                    text: '원',
                    style: PTypo.body.copyWith(
                      color: isCard ? t.statusDangerFg : t.fgPrimary,
                      fontWeight: PFontWeight.bold,
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
      return _ChartPlaceholder(text: '표시할 데이터가 없어요', tokens: tokens);
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
                    '${i + 1}주',
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
                  '${_touchedIdx! + 1}주 · ${_fmtWeekStart(list[_touchedIdx!].weekStart)}',
              labelWidth: 40,
              rows: [
                PChartTooltipRowData(
                  color: brandFg,
                  label: seriesLabel,
                  amount: masked
                      ? '••••••'
                      : '${krw(list[_touchedIdx!].balance)}원',
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
      return PCard(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        variant: PCardVariant.bordered,
        child: Column(
          children: [
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
        ),
      );
    }
    if (list.isEmpty) {
      return PCard(
        padding: const EdgeInsets.symmetric(vertical: 24),
        variant: PCardVariant.bordered,
        child: Center(
          child: Text(
            '연결된 거래 내역이 없어요.',
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
          ),
        ),
      );
    }
    return PCard(
      variant: PCardVariant.bordered,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          for (final e in list)
            _ExpenseRow(expense: e, masked: masked, tokens: tokens),
        ],
      ),
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
    final isIncome = expense.expenseType == 'INCOME';
    final color = resolveChartColor(context, expense.categoryColor, fallback: tokens.fgBrand);
    final bg = softBg(context, color);
    final title =
        expense.merchant ??
        expense.description ??
        (expense.categoryName ?? '거래');
    final subParts = [
      expense.categoryName ?? '기타',
      if ((expense.assetName ?? '').isNotEmpty) expense.assetName!,
    ];
    return InkWell(
      onTap: () => showTxDetailDialog(context, expense),
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              masked ? '••••••' : '${krw(expense.signedAmount, sign: true)}원',
              style: PTypo.bodySm.copyWith(
                color: isIncome ? tokens.fgIncome : tokens.fgExpense,
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
class _CardBillingSection extends ConsumerStatefulWidget {
  const _CardBillingSection({required this.asset, required this.masked});
  final Asset asset;
  final bool masked;
  @override
  ConsumerState<_CardBillingSection> createState() =>
      _CardBillingSectionState();
}

class _CardBillingSectionState extends ConsumerState<_CardBillingSection> {
  bool _paying = false;

  /// 결제 전 확인 — web ConfirmDialog 미러 (제목/문구/'결제하기' 동일).
  Future<void> _confirmAndPay(CardBilling b) async {
    final dateSuffix =
        b.nextPaymentDate != null ? ' 결제일은 ${b.nextPaymentDate} 입니다.' : '';
    final ok = await showPConfirmDialog(
      context,
      title: '지금 결제',
      message: '결제 예정액 ${krw(b.upcomingAmount)}원을 지금 결제 처리할까요?$dateSuffix',
      confirmLabel: '결제하기',
    );
    if (!ok || !mounted) return;
    await _pay();
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.payCard(widget.asset.rowId);
      ref
        ..invalidate(cardBillingProvider(widget.asset.rowId))
        ..invalidate(assetsProvider)
        ..invalidate(assetByIdProvider(widget.asset.rowId));
      if (!mounted) return;
      showPSnackBar(context, '결제가 기록되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '결제 실패: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final masked = widget.masked;
    final async = ref.watch(cardBillingProvider(widget.asset.rowId));
    return async.when(
      // 서버 청구정보 로딩 중 — 실제 청구 카드(결제예정 라벨/금액·결제버튼/결제일) 스켈레톤.
      loading: () => PCard(
        variant: PCardVariant.bordered,
        padding: const EdgeInsets.all(PSpace.x16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(children: [
              PSkeleton.line(width: 64, height: 14),
              Spacer(),
              PSkeleton.line(width: 40, height: 11),
            ]),
            SizedBox(height: 10),
            Row(children: [
              PSkeleton.line(width: 112, height: 22),
              Spacer(),
              PSkeleton(width: 88, height: 32, borderRadius: PRadius.brMd),
            ]),
            SizedBox(height: 8),
            PSkeleton.line(width: 96, height: 11),
          ],
        ),
      ),
      error: (e, _) => PCard(
        variant: PCardVariant.bordered,
        padding: const EdgeInsets.all(PSpace.x16),
        child: Text('청구 정보를 불러오지 못했어요',
            style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
      ),
      data: (b) {
        final canPay = b.upcomingAmount > 0 && !_paying;
        return PCard(
          variant: PCardVariant.bordered,
          padding: const EdgeInsets.all(PSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('결제 예정',
                      style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                  const Spacer(),
                  if (b.nextPaymentDate != null)
                    Text(_fmtDate(b.nextPaymentDate!),
                        style: PTypo.caption.copyWith(color: t.fgTertiary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: masked ? '••••••' : krw(b.upcomingAmount),
                          style: PTypo.h2.copyWith(
                            color: b.upcomingAmount > 0
                                ? t.statusDangerFg
                                : t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (!masked)
                          TextSpan(
                            text: '원',
                            style: PTypo.bodySm.copyWith(
                              color: b.upcomingAmount > 0
                                  ? t.statusDangerFg
                                  : t.fgPrimary,
                              fontWeight: PFontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PButton(
                    label: '지금 결제',
                    icon: LucideIcons.wallet,
                    size: PButtonSize.sm,
                    loading: _paying,
                    onPressed: canPay ? () => _confirmAndPay(b) : null,
                  ),
                ],
              ),
              if (b.paymentDay != null) ...[
                const SizedBox(height: 6),
                Text('매월 ${b.paymentDay}일 결제',
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ],
              if (b.history.isNotEmpty) ...[
                const SizedBox(height: PSpace.x12),
                PDivider(),
                const SizedBox(height: PSpace.x8),
                Text('청구 이력',
                    style: PTypo.caption.copyWith(
                        color: t.fgSecondary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: PSpace.x4),
                for (final item in b.history)
                  _BillingHistoryRow(item: item, masked: masked),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BillingHistoryRow extends StatelessWidget {
  const _BillingHistoryRow({required this.item, required this.masked});
  final BillingItem item;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      masked ? '••••••' : '${krw(item.billingAmount)}원',
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtDate(item.periodStart)} ~ ${_fmtDate(item.periodEnd)} · 결제일 ${_fmtDate(item.paymentDate)}',
                  style: PTypo.micro.copyWith(color: t.fgTertiary),
                ),
                if ((item.failureReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.failureReason!,
                      style:
                          PTypo.micro.copyWith(color: t.statusDangerFg)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (status) {
      'COMPLETED' => ('완료', PBadgeVariant.softSuccess),
      'PENDING' => ('대기', PBadgeVariant.softWarning),
      'FAILED' => ('실패', PBadgeVariant.softError),
      'SKIPPED' => ('건너뜀', PBadgeVariant.secondary),
      _ => (status, PBadgeVariant.secondary),
    };
    return PBadge(label: label, variant: variant);
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
