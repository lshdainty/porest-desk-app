import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/hide_amounts_unlock_dialog.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_segmented_control.dart';
import '../../card/presentation/card_performance_bar.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/presentation/tx_detail_dialog.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';
import '../domain/asset_transfer.dart';
import '../domain/asset_type_meta.dart';
import 'asset_edit_dialog.dart';

/// 자산 상세 — front `AssetDetailDialog` 모바일 미러.
///
/// 공통 `showPSheet` 사용. 구성 (web 동일):
/// - Hero 카드 (브랜드 그라디언트 + 아이콘 + 이름 + 잔액)
/// - 12/24/52주 잔액 추이 + 3개월/6개월/1년 segmented
/// - 최근 거래 12건 + "전체 보기 →"
/// - 푸터: 금액 가리기 / 편집 / 확인 (본문 끝에 함께 스크롤)
void showAssetDetailRich(BuildContext context, Asset asset) {
  showPSheet<void>(
    context,
    title: _titleFor(asset),
    contentBuilder: (ctx, scrollCtrl) => _DetailBody(
      asset: asset,
      scrollController: scrollCtrl,
    ),
    footerBuilder: (ctx) => _DetailFooter(asset: asset),
  );
}

class _DetailFooter extends ConsumerWidget {
  const _DetailFooter({required this.asset});
  final Asset asset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final masked = settings.hideAmounts;
    return Row(
      children: [
        PButton(
          label: masked ? '금액 표시' : '금액 가리기',
          icon: masked ? LucideIcons.eye : LucideIcons.eyeOff,
          variant: PButtonVariant.ghost,
          size: PButtonSize.sm,
          onPressed: () => toggleHideAmountsWithUnlock(context, ref),
        ),
        const Spacer(),
        PButton(
          label: '편집',
          icon: LucideIcons.pencil,
          variant: PButtonVariant.ghost,
          size: PButtonSize.sm,
          onPressed: () {
            Navigator.of(context).pop();
            showAssetEditForm(context, asset);
          },
        ),
        const SizedBox(width: PSpace.x4),
        PButton(
          label: '확인',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
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
    final brandFg = parseColor(asset.color, fallback: t.fgBrand);

    final isCard =
        asset.assetType == 'CREDIT_CARD' || asset.assetType == 'CHECK_CARD';
    final isInv = asset.assetType == 'INVESTMENT';
    final valueLabel = isCard ? '이번 달 결제 예정' : isInv ? '평가액' : '잔액';
    final seriesLabel = isCard ? '사용' : isInv ? '평가액' : '잔액';
    final trendTitle =
        '최근 ${_period.headerLabel} ${isCard ? '사용 추이' : isInv ? '평가액 추이' : '잔액 추이'}';

    final trendAsync = ref.watch(assetBalanceTrendProvider(
        (assetId: asset.rowId, weeks: _period.weeks)));
    // recent tx — web 와 동일 12건.
    final recentAsync =
        ref.watch(expensesByAssetProvider((assetId: asset.rowId, limit: 12)));

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
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
                    PSegmentedControl<_Period>(
                      value: _period,
                      size: PSegmentSize.sm,
                      elevated: true,
                      items: [
                        for (final p in _Period.values)
                          PSegmentItem(p, p.label),
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
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(
                            '/expense?assetId=${asset.rowId}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('전체 보기',
                                style: PTypo.bodySm.copyWith(
                                  color: t.fgSecondary,
                                  fontWeight: PFontWeight.semi,
                                )),
                            const SizedBox(width: 2),
                            Icon(LucideIcons.chevronRight,
                                size: 12, color: t.fgSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                _RecentExpenses(
                    async: recentAsync, masked: masked, tokens: t),
      ],
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
      padding: const EdgeInsets.all(20),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: brandFg,
                  borderRadius: PRadius.brLg,
                ),
                alignment: Alignment.center,
                child: Icon(meta.icon, size: 22, color: t.fgOnBrand),
              ),
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
                      Text(subtitle,
                          style:
                              PTypo.bodySm.copyWith(color: t.fgTertiary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
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
                      ? '•••'
                      : '${isCard && absBalance > 0 ? '−' : ''}${krw(absBalance)}',
                  style: PTypo.h1.copyWith(
                    color: isCard ? t.statusDangerFg : t.fgPrimary,
                    fontWeight: PFontWeight.heavy,
                    letterSpacing: -0.6,
                    fontFamily: 'monospace',
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

class _BalanceTrendChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final list = async.value ?? const <AssetBalancePoint>[];
    if (async.isLoading && list.isEmpty) {
      return _ChartPlaceholder(text: '불러오는 중…', tokens: tokens);
    }
    if (list.isEmpty) {
      return _ChartPlaceholder(text: '표시할 데이터가 없어요', tokens: tokens);
    }
    final n = list.length;
    final spots = [
      for (int i = 0; i < n; i++)
        FlSpot(i.toDouble(), list[i].balance.toDouble()),
    ];
    // 데이터 실제 min/max — 첫 값으로 시작해서 양쪽 비교 (하드코딩 0 사용 X).
    final values = list.map((p) => p.balance).toList(growable: false);
    final maxRaw =
        values.fold<int>(values.first, (m, v) => v > m ? v : m).toDouble();
    final minRaw =
        values.fold<int>(values.first, (m, v) => v < m ? v : m).toDouble();

    // 모두 양수면 yMin 을 0 으로 클램프 (음수 영역 표시 방지 — web recharts 동작).
    // pad 는 시각 여유.
    final span = (maxRaw - minRaw).abs();
    final pad = (span * 0.12).clamp(1.0, double.infinity);
    final allNonNeg = minRaw >= 0;
    final yMin = allNonNeg ? 0.0 : minRaw - pad;
    final yMax = maxRaw + pad;
    // 라벨은 최대 4개. fl_chart interval 은 데이터 거리 기반.
    final yInterval = ((yMax - yMin) / 3).clamp(1.0, double.infinity);
    final xInterval = (n / 6).clamp(1.0, double.infinity);

    return LineChart(
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
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: yInterval,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  masked ? '•••' : _fmtAxisNum(v),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: PTypo.micro.copyWith(
                      color: tokens.fgTertiary,
                      fontSize: PFontSize.micro),
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
                  child: Text('${i + 1}주',
                      style: PTypo.micro.copyWith(
                          color: tokens.fgTertiary,
                          fontSize: PFontSize.micro)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tokens.bgSurface,
            tooltipBorder: BorderSide(color: tokens.borderSubtle),
            tooltipBorderRadius: PRadius.brLg,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            getTooltipItems: (spots) => [
              for (int i = 0; i < spots.length; i++)
                if (i == 0)
                  LineTooltipItem(
                    '',
                    const TextStyle(),
                    textAlign: TextAlign.left,
                    children: [
                      TextSpan(
                        text: '${spots[i].x.toInt() + 1}주\n',
                        style: PTypo.micro.copyWith(
                            color: tokens.fgTertiary,
                            fontWeight: PFontWeight.semi,
                            height: 1.6),
                      ),
                      TextSpan(
                        text: '●  ',
                        style: TextStyle(
                          color: brandFg,
                          fontSize: PFontSize.caption,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: '$seriesLabel  ',
                        style:
                            PTypo.caption.copyWith(color: tokens.fgSecondary),
                      ),
                      TextSpan(
                        text: masked ? '•••' : '${krw(spots[i].y.round())}원',
                        style: PTypo.bodySm.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  )
                else
                  null,
            ],
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
            belowBarData: BarAreaData(
              show: true,
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
  }
}

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
      child: Text(text,
          style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses(
      {required this.async, required this.masked, required this.tokens});
  final AsyncValue<List<Expense>> async;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <Expense>[];
    if (async.isLoading && list.isEmpty) {
      return PCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        variant: PCardVariant.bordered,
        child: const Center(child: PCircularProgressIndicator()),
      );
    }
    if (list.isEmpty) {
      return PCard(
        padding: const EdgeInsets.symmetric(vertical: 24),
        variant: PCardVariant.bordered,
        child: Center(
          child: Text('연결된 거래 내역이 없어요.',
              style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
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
    final color = parseColor(expense.categoryColor, fallback: tokens.fgBrand);
    final bg = softBg(color);
    final title = expense.merchant ??
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
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(lucideByName(expense.categoryIcon),
                  size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: PFontWeight.semi,
                      )),
                  const SizedBox(height: 2),
                  Text(subParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.caption
                          .copyWith(color: tokens.fgTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              masked
                  ? '•••'
                  : '${krw(expense.signedAmount, sign: true)}원',
              style: PTypo.bodySm.copyWith(
                color: isIncome ? tokens.fgIncome : tokens.fgExpense,
                fontWeight: PFontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// stats 차트와 동일한 만/억 단위 — 한글 단위가 KRW 와 어울리고
/// '4.3M'/'-40.4M' 보다 짧게 표현돼 reservedSize 안에 안전히 들어간다.
String _fmtAxisNum(double v) {
  final n = v.abs();
  String body;
  if (n >= 100000000) {
    body = '${(n / 100000000).toStringAsFixed(1)}억';
  } else if (n >= 10000) {
    body = '${(n / 10000).round()}만';
  } else {
    body = n.toStringAsFixed(0);
  }
  return v < 0 ? '−$body' : body;
}

String _currentYearMonth() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}';
}
