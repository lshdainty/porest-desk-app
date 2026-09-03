// 통계 추이 차트 Y축 눈금 표기 — 웹 `formatChartAmount` 와 같은 글자인지.
//
// 축약 함수가 둘인 건 의도다. `formatChartAxis` 는 1만~10만을 소수 한 자리로 내고
// (QA #38 — 도넛 중앙처럼 숫자 하나만 보는 자리), 추이 축은 눈금이 촘촘해 정수 만이다.
// 웹도 같은 이유로 `formatChartAxis` / `formatChartAmount` 를 나눠 뒀다.
//
// 갈려 있던 건 **천단위 콤마**였다 — 웹은 `1,000만`·`8,000`, 앱은 `1000만`·`8000`.
// 같은 축을 두 플랫폼이 다른 글자로 그리고 있었다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/features/stats/presentation/stats_screen.dart';

/// 오늘(이번 달 안) 지출 한 건. 기본 기간이 이번 달이라 추이 축의 최대값이 된다.
Expense _todayExpense(int amount) {
  final n = DateTime.now();
  return Expense(
    rowId: 1,
    expenseType: 'EXPENSE',
    amount: amount,
    expenseDate:
        '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}T09:00:00',
  );
}

/// 통계 화면을 띄우고 '추이' 탭으로 넘긴다.
Future<void> _pumpTrend(WidgetTester tester, int expenseAmount) async {
  // 폭을 조금 넉넉히 준다 — 390 에서는 옆 '비교' 탭의 지표 Row 가 큰 금액에서
  // 넘쳐(pre-existing) 축 라벨과 무관한 오버플로 예외가 테스트를 깬다.
  tester.view.physicalSize = const Size(480 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => const []),
        rangeExpensesProvider.overrideWith(
          (ref, key) async => [_todayExpense(expenseAmount)],
        ),
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
            totalExpense: expenseAmount,
          ),
        ),
        heatmapProvider.overrideWith(
          (ref, range) async => const <HeatmapCell>[],
        ),
        merchantSummaryProvider.overrideWith(
          (ref, range) async => const <MerchantSummary>[],
        ),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const StatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // 카테고리 → 추이
  await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('만 단위 눈금에 천단위 콤마가 붙는다 — 웹 `1,000만` 과 같은 글자', (tester) async {
    // 12,340,000 → nice ceil 5틱: 0 / 500만 / 1,000만 / 1,500만 / 2,000만
    await _pumpTrend(tester, 12340000);

    expect(find.text('1,000만'), findsWidgets);
    expect(find.text('1000만'), findsNothing);
    // 1만~10만 소수 한 자리는 축약 함수가 다른 자리(도넛 중앙) 규칙이다 — 축은 정수 만.
    expect(find.text('500만'), findsWidgets);
  });

  testWidgets('1만 아래 눈금에도 콤마가 붙는다 — 웹 `8,000` 과 같은 글자', (tester) async {
    // 8,000 → nice ceil 5틱: 0 / 2,000 / 4,000 / 6,000 / 8,000
    await _pumpTrend(tester, 8000);

    expect(find.text('8,000'), findsWidgets);
    expect(find.text('8000'), findsNothing);
    expect(find.text('2,000'), findsWidgets);
  });
}
