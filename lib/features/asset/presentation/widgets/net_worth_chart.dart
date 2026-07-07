import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_axis.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/widgets/p_chart_tooltip.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';

/// 12개월 순자산 추이 area chart. front `NetWorthChart` 미러.
class NetWorthChart extends ConsumerStatefulWidget {
  const NetWorthChart({super.key, this.height = 140, this.months = 12});

  final double height;
  final int months;

  @override
  ConsumerState<NetWorthChart> createState() => _NetWorthChartState();
}

class _NetWorthChartState extends ConsumerState<NetWorthChart> {
  int? _touchedIdx;
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final height = widget.height;
    final months = widget.months;
    final trendAsync = ref.watch(netWorthTrendProvider(months));
    final masked = ref.watch(settingsProvider).value?.hideAmounts ?? false;
    return SizedBox(
      height: height,
      child: trendAsync.when(
        // 차트 전체 PSkeleton — Hero 카드 안 영역에 fill.
        loading: () =>
            SizedBox.expand(child: PSkeleton(borderRadius: PRadius.brLg)),
        error: (_, _) => Center(
          child: Text(
            l.assetTrendLoadError,
            style: TextStyle(color: t.fgTertiary, fontSize: PFontSize.bodySm),
          ),
        ),
        data: (points) {
          if (points.isEmpty) {
            return Center(
              child: Text(
                l.assetTrendEmpty,
                style: TextStyle(
                  color: t.fgTertiary,
                  fontSize: PFontSize.bodySm,
                ),
              ),
            );
          }
          final spots = <FlSpot>[
            for (int i = 0; i < points.length; i++)
              FlSpot(i.toDouble(), points[i].netWorth.toDouble()),
          ];
          final values = points.map((p) => p.netWorth.toDouble()).toList();
          final dataMax = values.reduce((a, b) => a > b ? a : b);
          final dataMin = values.reduce((a, b) => a < b ? a : b);
          // 웹 Recharts 의 auto-nice 축을 이식 — 0 기준 + 1·2·2.5·5×10ⁿ 눈금.
          // fl_chart 는 auto-nice 가 없어 직접 계산해야 0-base·딱떨어지는 눈금·라벨 겹침해소가 된다.
          final axis = niceAxis(dataMin, dataMax);
          final yMin = axis.min;
          final yMax = axis.max;
          final yInterval = axis.interval;

          final chart = LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: yMin,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: t.borderSubtle,
                  strokeWidth: 1,
                  dashArray: const [3, 3],
                ),
              ),
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
                        style: TextStyle(
                          color: t.fgTertiary,
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
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.round();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      // 격월 표시 (07월 / 09월 / 11월 …)
                      if (points.length > 7 && i % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      final mm = points[i].month.toString().padLeft(2, '0');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$mm월',
                          style: TextStyle(
                            color: t.fgTertiary,
                            fontSize: PFontSize.micro,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
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
                  if (i >= 0 &&
                      i < points.length &&
                      (i != _touchedIdx || pos != _touchPos)) {
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
                  color: t.bgBrand,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 3,
                      color: t.bgBrand,
                      strokeColor: t.bgSurface,
                      strokeWidth: 2,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        t.bgBrand.withValues(alpha: 0.25),
                        t.bgBrand.withValues(alpha: 0.0),
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
              if (_touchedIdx != null &&
                  _touchedIdx! < points.length &&
                  _touchPos != null)
                PChartTooltipLayer(
                  anchor: _touchPos!,
                  child: PChartTooltipBox(
                    title:
                        '${points[_touchedIdx!].month.toString().padLeft(2, '0')}월',
                    labelWidth: 40,
                    rows: [
                      PChartTooltipRowData(
                        color: t.bgBrand,
                        label: l.assetNetWorth,
                        amount: masked
                            ? '••••••'
                            : krwSigned(points[_touchedIdx!].netWorth, false,
                                unit: true),
                        amountColor: points[_touchedIdx!].netWorth < 0
                            ? t.statusDangerFg
                            : t.fgPrimary,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
