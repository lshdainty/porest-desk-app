import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/radius.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/format/krw.dart';
import '../../../../core/settings/settings_notifier.dart';
import '../../../../shared/widgets/p_skeleton.dart';
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
    final masked = ref.watch(settingsProvider).value?.hideAmounts ?? false;
    return SizedBox(
      height: height,
      child: trendAsync.when(
        // 차트 전체 PSkeleton — Hero 카드 안 영역에 fill.
        loading: () =>
            SizedBox.expand(child: PSkeleton(borderRadius: PRadius.brLg)),
        error: (_, _) => Center(
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
                horizontalInterval: ((yMax - yMin) / 4).abs().clamp(
                  1.0,
                  double.infinity,
                ),
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
                    interval: ((yMax - yMin) / 4).abs().clamp(
                      1.0,
                      double.infinity,
                    ),
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
                      if (i < 0 || i >= points.length)
                        return const SizedBox.shrink();
                      // 격월 표시 (07월 / 09월 / 11월 …)
                      if (points.length > 7 && i % 2 != 0)
                        return const SizedBox.shrink();
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
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => t.bgSurface,
                  tooltipBorder: BorderSide(color: t.borderSubtle),
                  tooltipBorderRadius: PRadius.brLg,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  getTooltipItems: (spots) => [
                    for (int i = 0; i < spots.length; i++)
                      if (i == 0)
                        LineTooltipItem(
                          '',
                          const TextStyle(),
                          textAlign: TextAlign.left,
                          children: [
                            TextSpan(
                              text: () {
                                final ix = spots[i].x.toInt();
                                if (ix < 0 || ix >= points.length) return '\n';
                                return '${points[ix].month.toString().padLeft(2, '0')}월\n';
                              }(),
                              style: PTypo.micro.copyWith(
                                color: t.fgTertiary,
                                fontWeight: PFontWeight.semi,
                                height: 1.6,
                              ),
                            ),
                            TextSpan(
                              text: '●  ',
                              style: TextStyle(
                                color: t.bgBrand,
                                fontSize: PFontSize.caption,
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: '순자산  ',
                              style: PTypo.caption.copyWith(
                                color: t.fgSecondary,
                              ),
                            ),
                            TextSpan(
                              text: masked ? '••••••' : _fmtFull(spots[i].y),
                              style: PTypo.bodySm.copyWith(
                                color: spots[i].y < 0
                                    ? t.statusDangerFg
                                    : t.fgPrimary,
                                fontWeight: PFontWeight.bold,
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
        },
      ),
    );
  }
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
