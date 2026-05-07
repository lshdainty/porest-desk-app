import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/radius.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/settings/settings_notifier.dart';
import '../../application/asset_providers.dart';

/// 12개월 순자산 추이 area chart. front `NetWorthChart` 미러.
class NetWorthChart extends ConsumerWidget {
  const NetWorthChart({super.key, this.height = 140, this.months = 12});

  final double height;
  final int months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final trendAsync = ref.watch(netWorthTrendProvider(months));
    final masked =
        ref.watch(settingsProvider).value?.hideAmounts ?? false;
    return SizedBox(
      height: height,
      child: trendAsync.when(
        loading: () => Center(
          child: Text(
            '불러오는 중…',
            style: TextStyle(color: t.fgTertiary, fontSize: PFontSize.bodySm),
          ),
        ),
        error: (_, __) => Center(
          child: Text(
            '추이 데이터를 불러오지 못했어요',
            style: TextStyle(color: t.fgTertiary, fontSize: PFontSize.bodySm),
          ),
        ),
        data: (points) {
          if (points.isEmpty) {
            return Center(
              child: Text(
                '추이 데이터가 없어요',
                style: TextStyle(color: t.fgTertiary, fontSize: PFontSize.bodySm),
              ),
            );
          }
          final spots = <FlSpot>[
            for (int i = 0; i < points.length; i++)
              FlSpot(i.toDouble(), points[i].netWorth.toDouble()),
          ];
          final values = points.map((p) => p.netWorth.toDouble()).toList();
          final maxV = values.reduce((a, b) => a > b ? a : b);
          final minV = values.reduce((a, b) => a < b ? a : b);
          final pad = ((maxV - minV).abs() * 0.12).clamp(1.0, double.infinity);
          final yMin = minV - pad;
          final yMax = maxV + pad;

          return LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: yMin,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ((yMax - yMin) / 4).abs().clamp(1.0, double.infinity),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: t.borderSubtle,
                  strokeWidth: 1,
                  dashArray: const [3, 3],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: ((yMax - yMin) / 4).abs().clamp(1.0, double.infinity),
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        masked ? '•••' : _fmtAxis(v),
                        style: TextStyle(color: t.fgTertiary, fontSize: PFontSize.micro),
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
                      if (i < 0 || i >= points.length) return const SizedBox.shrink();
                      // 격월 표시 (07월 / 09월 / 11월 …)
                      if (points.length > 7 && i % 2 != 0) return const SizedBox.shrink();
                      final mm = points[i].month.split('-').last;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${mm}월',
                          style: TextStyle(color: t.fgTertiary, fontSize: PFontSize.micro),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => t.bgSurface,
                  tooltipBorder: BorderSide(color: t.borderSubtle),
                  tooltipBorderRadius: PRadius.brTile,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${points[s.x.toInt()].month}\n${masked ? '•••' : _fmtFull(s.y)}',
                        TextStyle(color: t.fgPrimary, fontSize: PFontSize.caption, fontWeight: PFontWeight.bold),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: PorestPalette.mossy500,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3,
                      color: PorestPalette.mossy500,
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
                        PorestPalette.mossy500.withValues(alpha: 0.25),
                        PorestPalette.mossy500.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _fmtAxis(double v) {
  final n = v.abs();
  if (n >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
  if (n >= 10000) return '${(v / 10000).round()}만';
  return v.round().toString();
}

String _fmtFull(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  final neg = s.startsWith('-');
  final body = neg ? s.substring(1) : s;
  for (int i = 0; i < body.length; i++) {
    if (i > 0 && (body.length - i) % 3 == 0) buf.write(',');
    buf.write(body[i]);
  }
  return '${neg ? '-' : ''}${buf.toString()}원';
}
