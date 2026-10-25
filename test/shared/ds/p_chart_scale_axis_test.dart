// 통계 큰 글자 · 많은 칸에서 드러난 차트 두 결함(I-08 34 · 36).
// ① 막대 차트 가로축 글은 칸마다 불려 겹쳤다 — 간격 칸만 그린다. ② 열지도 줄 높이가 글자 배율을 안 따라 200% 에서 시간대 라벨이 넘쳤다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 312, child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('막대 차트 가로축 글은 겹치지 않게 간격 칸만 그린다(31칸)', (tester) async {
    await tester.pumpWidget(
      _host(
        PBarChart(
          label: '일별',
          height: 180,
          categories: [for (var i = 1; i <= 31; i++) '10/$i'],
          series: [
            PChartSeries(
              key: 's',
              label: '값',
              color: PChartColor.blue,
              values: [for (var i = 1; i <= 31; i++) i * 1000.0],
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final shown = [
      for (var i = 1; i <= 31; i++)
        if (find.text('10/$i').evaluate().isNotEmpty) i,
    ];
    expect(shown.length, lessThan(12), reason: '31칸 글을 다 그리면 겹친다');
    expect(shown.first, 1);
    // 이웃한 두 글이 붙어 있지 않다
    for (var k = 1; k < shown.length; k++) {
      expect(shown[k] - shown[k - 1], greaterThanOrEqualTo(2));
    }
  });

  testWidgets('열지도 — 글자 200% 에서 시간대 라벨이 줄 밖으로 넘치지 않는다', (tester) async {
    await tester.pumpWidget(
      _host(
        PHeatmap(
          label: '열지도',
          rows: const [
            PHeatmapRow(key: 'a', label: '아침', sub: '06~10시'),
            PHeatmapRow(key: 'b', label: '점심', sub: '10~14시'),
          ],
          columns: [
            for (final d in ['월', '화', '수', '목', '금', '토', '일'])
              PHeatmapColumn(key: d, label: d),
          ],
          values: [
            for (var r = 0; r < 2; r++)
              [for (var c = 0; c < 7; c++) (r + c + 1) * 1000.0],
          ],
        ),
        scale: 2,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
