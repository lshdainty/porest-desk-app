// PLineChart `dots` 선택 인자(I-05 57 — 순자산 추이): 데이터 점마다 늘 찍는 점, 지름 6 · 계열 색 · 테두리 없음.
// 기본(인자 없음)은 p_chart_spec_test 가 스펙대로 잰다 — 점이 없다.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_cartesian.dart';

Widget _host(Widget child, {Brightness mode = Brightness.light}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 330, child: child),
    ),
  ),
);

PLineChart _chart({bool dots = false, bool area = true}) => PLineChart(
  label: '추이',
  height: 140,
  categories: const ['7월', '8월', '9월'],
  area: area,
  dots: dots,
  series: const [
    PChartSeries(
      key: 'n',
      label: '순자산',
      color: PChartColor.blue,
      values: [100, -50, 300],
    ),
  ],
);

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    final c = mode == Brightness.dark ? PColors.dark : PColors.light;
    group('PLineChart dots — $mode', () {
      testWidgets('기본은 점이 없고 dots 를 켜면 점마다 지름 6 계열 색 · 테두리 0', (tester) async {
        await tester.pumpWidget(_host(_chart(), mode: mode));
        await tester.pump(const Duration(seconds: 1));
        var bar = tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .first;
        expect(bar.dotData.show, isFalse);

        await tester.pumpWidget(
          _host(_chart(dots: true, area: false), mode: mode),
        );
        await tester.pump(const Duration(seconds: 1));
        bar = tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .first;
        expect(bar.dotData.show, isTrue);
        expect(bar.belowBarData.show, isFalse, reason: '영역 채움 없음');
        final painter =
            bar.dotData.getDotPainter(bar.spots.first, 0, bar, 0)
                as FlDotCirclePainter;
        expect(painter.radius, kChartPointRadius);
        expect(painter.radius * 2, 6);
        expect(painter.color, c.chartBlue);
        expect(painter.strokeWidth, 0);
      });
    });
  }
}
