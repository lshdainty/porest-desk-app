// 차트 10색(v110)과 옅은 바탕(v111) — 저장된 hex 는 이름표이고 그릴 색은 역할 색이다(01A-001 · 002).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      '${dark ? "다크" : "라이트"} — 저장 hex 가 역할 색(700 · 800-dark)과 옅은 바탕(200 · 300)으로 그려진다',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? GrooTheme.dark() : GrooTheme.light(),
            home: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        );
        final c = dark ? PColors.dark : PColors.light;
        // 저장된 이름표 hex → 역할 색
        expect(resolveChartColor(ctx, '#c73838'), c.chartRed);
        expect(resolveChartColor(ctx, '#2c70bf'), c.chartBlue);
        expect(resolveChartColor(ctx, '#6b7484'), c.chartGray);
        // 옅은 바탕은 불투명 역할 색
        expect(softBg(ctx, resolveChartColor(ctx, '#c73838')), c.chartRedWeak);
        expect(
          softBg(ctx, resolveChartColor(ctx, '#2d8060')),
          c.chartGreenWeak,
        );
        expect(softBg(ctx, resolveChartColor(ctx, '#6b7484')).a, 1.0);
        // 열 가지 모두 짝 표에서 역할 색을 가리킨다
        expect(kChartPairs.length, 10);
        expect(kChartPairs.first.base, PColors.light.chartRed);
        expect(kChartPairs.first.light, PColors.dark.chartRed);
      },
    );
  }
}
