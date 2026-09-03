// 홈 금액 부호 — QA #1(음수 0) · QA #22(하이픈 ↔ U+2212 혼용) 의 앱판.
//
// 웹 `shared/lib/porest/format.ts` 의 `minusOf` 와 **같은 규칙**이어야 한다.
//   0   → 부호 없음  (빈 계정에서 `−0원` 이 뜨던 자리)
//   양수 → U+2212 `−`
//   음수 → `+`       (선결제 카드가 부채를 깎아 `totalDebt < 0` 이 되는 경우)
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 직접 띄워 글자를 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:porest_desk_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';

/// 이번 달 1일 (`_DashboardScreenState._ymdStart` 와 같은 규칙).
String _monthStart() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-01';
}

Future<void> _pumpHome(
  WidgetTester tester, {
  int totalAssets = 0,
  int totalDebt = 0,
  int income = 0,
  int expense = 0,
  List<Expense> todayTx = const [],
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final start = _monthStart();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetSummaryProvider.overrideWith(
          (ref, key) async =>
              AssetSummary(totalAssets: totalAssets, totalDebt: totalDebt),
        ),
        // 이번 달만 값을 준다 — 지난달(전월 대비 %)은 0 으로 둔다.
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
            totalIncome: range.startDate == start ? income : 0,
            totalExpense: range.startDate == start ? expense : 0,
          ),
        ),
        monthExpensesProvider.overrideWith((ref, key) async => todayTx),
        categoriesProvider.overrideWith((ref) async => const []),
        monthBudgetsProvider.overrideWith((ref, key) async => const []),
        budgetAlertThresholdProvider.overrideWith((ref) async => 85),
        dashboardSummaryProvider.overrideWith(
          (ref) async => DashboardSummary.fromJson(const <String, dynamic>{}),
        ),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(body: DashboardScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('빈 계정 — 총 부채·지출이 `−0` 이 아니라 `0` 이다', (tester) async {
    await _pumpHome(tester);

    // 옛 코드는 `sign: '-'` 를 무조건 붙여 `-0` 을 냈다.
    expect(find.text('-0'), findsNothing);
    expect(find.text('−0'), findsNothing);
    // 총자산·총부채·지출 모두 부호 없는 '0'.
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('부채가 있으면 U+2212 로 찍는다 — ASCII 하이픈이 아니다', (tester) async {
    await _pumpHome(tester, totalAssets: 1000000, totalDebt: 356800);

    expect(find.text('−356,800'), findsOneWidget);
    expect(find.text('-356,800'), findsNothing);
  });

  testWidgets('선결제로 총 부채가 음수면 부호를 겹치지 않고 `+` 로 뒤집는다', (tester) async {
    // desk-back #305 이후 `totalDebt = −Σ부채군` 이라 선결제한 카드가 부채를 깎는다.
    await _pumpHome(tester, totalAssets: 1000000, totalDebt: -356800);

    expect(find.text('+356,800'), findsOneWidget);
    // 옛 코드는 부호 글자와 값의 부호가 겹쳐 `--356,800` 을 냈다.
    expect(find.text('--356,800'), findsNothing);
    expect(find.text('−-356,800'), findsNothing);
  });

  testWidgets('이번 달 지출도 같은 규칙 — 값이 있으면 U+2212', (tester) async {
    await _pumpHome(tester, income: 2000000, expense: 123456);

    expect(find.text('−123,456'), findsOneWidget);
    expect(find.text('-123,456'), findsNothing);
    // 수입은 웹과 같이 늘 `+`.
    expect(find.text('+2,000,000'), findsOneWidget);
  });

  testWidgets('오늘 쓴 돈 합계도 U+2212 로 찍는다', (tester) async {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}T09:00:00';
    await _pumpHome(
      tester,
      todayTx: [
        Expense(
          rowId: 1,
          expenseType: 'EXPENSE',
          amount: 7560,
          expenseDate: today,
        ),
      ],
    );

    // 카드 헤더 합계와 행 금액 — 같은 카드 안 두 자리가 같은 기호를 쓴다
    // (QA #22 는 한 카드에서 `−`/`-` 가 섞여 정렬이 어긋난 걸 잡았다).
    expect(find.text('−7,560원'), findsNWidgets(2));
    expect(find.text('-7,560원'), findsNothing);
  });
}
