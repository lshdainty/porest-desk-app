// I-31 별건 — 잔액 추이 세로축 폭은 가장 긴 눈금 글자("−5,000만")를 재서 잡는다.
// 고정 폭 52 일 때는 360 폭 · 글자 200% 에서 왼쪽 끝이 잘려 `−2,500만` 이 `2,500만` 으로 읽혔다
// (chart.md:46 "세로축의 폭은 가장 긴 글자('−3,000만')가 잘리지 않게" · 결함 D6).
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';

const _loan = Asset(
  rowId: 10,
  assetName: '전세자금대출',
  assetType: 'LOAN',
  balance: -85000000,
);

const _trend = [
  AssetBalancePoint(weekStart: '2026-09-07', balance: -82000000),
  AssetBalancePoint(weekStart: '2026-09-14', balance: -83000000),
  AssetBalancePoint(weekStart: '2026-09-21', balance: -84000000),
  AssetBalancePoint(weekStart: '2026-09-28', balance: -85000000),
];

Future<LineChart> _open(WidgetTester tester, double scale) async {
  tester.view.physicalSize = const Size(720, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [_loan]),
        assetBalanceTrendProvider.overrideWith((ref, key) async => _trend),
        assetTransfersProvider.overrideWith(
          (ref, key) async => const <AssetTransfer>[],
        ),
        expensesByAssetProvider.overrideWith((ref, key) async => const []),
        assetPeriodExpensesProvider.overrideWith((ref, key) async => const []),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetDetailRich(ctx, _loan),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tester.widget<LineChart>(find.byType(LineChart));
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('세로축 폭이 가장 긴 눈금 글자(−1억 · −7,500만 …)보다 넓다 — 글자 x$scale', (
      tester,
    ) async {
      final chart = await _open(tester, scale);
      final reserved =
          chart.data.titlesData.leftTitles.sideTitles.reservedSize ?? 0;
      final style = PTypo.micro.copyWith(fontSize: PFontSize.micro);
      var widest = 0.0;
      for (final v in [-100000000.0, -75000000.0, -50000000.0, -25000000.0]) {
        widest =
            widest <
                measureText(
                  formatChartAxis(v),
                  style,
                  scaler: TextScaler.linear(scale),
                )
            ? measureText(
                formatChartAxis(v),
                style,
                scaler: TextScaler.linear(scale),
              )
            : widest;
      }
      // 눈금 글자 + 오른쪽 여백 6
      expect(reserved, greaterThanOrEqualTo(widest + 6));
      // 눈금 글자에 U+2212 가 그대로 있다(잘려 양수로 읽히지 않는다)
      expect(find.text('−2,500만'), findsOneWidget);
    });
  }

  test('chartAxisWidth — 가장 긴 글자(부호 포함) + 여백', () {
    const style = TextStyle(fontSize: 12);
    final wide = measureText('−5,000만', style);
    final w = chartAxisWidth(['0', '−5,000만', '−1억'], style);
    expect(w, wide + kChartTickMargin);
    expect(chartAxisWidth(const [], style), kChartTickMargin);
    expect(
      chartAxisWidth(['−5,000만'], style, scaler: const TextScaler.linear(2)),
      greaterThan(w),
    );
  });
}
