// 거래·자산을 바꾼 뒤 화면이 실제로 다시 그려지는지 — QA #135~#139 · #151.
//
// 이 앱의 provider 는 `userPreferences` 를 빼면 전부 비-autoDispose 이고, 탭 6화면은
// `IndexedStack` 에 상주해 dispose 조차 되지 않는다. 그래서 무효화 묶음에서 빠진
// provider 는 **앱을 다시 켤 때까지 옛 값**이다 — 탭을 오가도, 화면을 다시 열어도
// 안 바뀌고 당겨서 새로고침해야만 풀린다. 목록에서 한 줄이 빠지는 것이 곧 버그다.
//
// 두 가지를 잠근다.
//  1. 무효화하면 홈이 **새 숫자를 그린다** — 그리고 무효화 전에는 안 그린다.
//  2. 무효화 묶음이 화면이 읽는 provider 를 하나도 빠뜨리지 않는다(refetch 횟수).
//
// 화면이 안 읽는 provider 를 목록에 넣어도 이 테스트는 통과한다. 그건 의도한 것이다 —
// 여기서 막는 건 "빠뜨림" 이고, "죽은 것 끼워 넣기" 는 QA #151 이 grep 으로 잡는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/domain/card_billing.dart';
import 'package:porest_desk_app/features/asset/domain/net_worth_point.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';
import 'package:porest_desk_app/features/budget/domain/budget_compliance.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_performance.dart';
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

/// 트리 안에서 `WidgetRef` 를 꺼내 온다 — 무효화 함수는 `WidgetRef` 를 받는다.
class _RefProbe extends ConsumerWidget {
  const _RefProbe({required this.onRef, required this.child});
  final void Function(WidgetRef) onRef;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onRef(ref);
    return child;
  }
}

void main() {
  // ─── 1. 홈이 새 숫자를 그린다 ────────────────────────────────
  testWidgets('거래 무효화 뒤 홈의 이번 달 지출·총 부채가 새 값으로 바뀐다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final start = _monthStart();
    // 서버가 들고 있는 값 — 거래를 저장하면 이 숫자가 달라진다.
    var serverExpense = 222222;
    var serverDebt = 111111;
    WidgetRef? captured;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetSummaryProvider.overrideWith(
            (ref, key) async => AssetSummary(totalDebt: serverDebt),
          ),
          rangeSummaryProvider.overrideWith(
            (ref, range) async => RangeSummary(
              startDate: range.startDate,
              endDate: range.endDate,
              // 이번 달만 값을 준다 — 지난달(전월 대비)은 0.
              totalExpense: range.startDate == start ? serverExpense : 0,
            ),
          ),
          monthExpensesProvider.overrideWith((ref, key) async => const []),
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
          home: Scaffold(
            body: _RefProbe(
              onRef: (r) => captured = r,
              child: const DashboardScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('−222,222'), findsOneWidget);
    expect(find.text('−111,111'), findsOneWidget);

    // 서버 값이 바뀌었다(= 거래를 저장했다). 무효화하지 않으면 홈은 못 본다 —
    // 이 provider 들은 autoDispose 도 아니고 홈은 셸에 상주해 dispose 되지도 않는다.
    serverExpense = 444444;
    serverDebt = 333333;
    await tester.pumpAndSettle();
    expect(
      find.text('−222,222'),
      findsOneWidget,
      reason: '무효화 없이 바뀌면 이 테스트가 아무것도 안 지킨다',
    );
    expect(find.text('−444,444'), findsNothing);

    invalidateAfterExpenseChange(captured!);
    await tester.pumpAndSettle();

    expect(
      find.text('−444,444'),
      findsOneWidget,
      reason: 'rangeSummary 가 묶음에서 빠졌다',
    );
    expect(
      find.text('−333,333'),
      findsOneWidget,
      reason: 'assetSummary 가 묶음에서 빠졌다',
    );
    expect(find.text('−222,222'), findsNothing);
    expect(find.text('−111,111'), findsNothing);
  });

  // ─── 2. 묶음이 화면이 읽는 provider 를 다 비운다 ─────────────
  testWidgets('invalidateAfterExpenseChange — 홈·통계·예산이 읽는 것을 전부 다시 받는다', (
    tester,
  ) async {
    final counts = <String, int>{};
    final ref = await _pumpProbe(tester, counts);

    // 전부 한 번씩 읽혔다 — 안 읽힌 게 있으면 아래 검사가 의미를 잃는다.
    for (final k in _expenseKeys) {
      expect(counts[k], 1, reason: '$k 를 프로브가 watch 하지 않았다');
    }

    invalidateAfterExpenseChange(ref);
    await tester.pumpAndSettle();

    for (final k in _expenseKeys) {
      expect(
        counts[k],
        2,
        reason: '$k 가 invalidateAfterExpenseChange 에 없다 — 그 화면은 앱을 끌 때까지 옛 값이다',
      );
    }
  });

  testWidgets('invalidateAfterAssetChange — 순자산·추이·청구·실적까지 다시 받는다', (
    tester,
  ) async {
    final counts = <String, int>{};
    final ref = await _pumpProbe(tester, counts);

    invalidateAfterAssetChange(ref);
    await tester.pumpAndSettle();

    for (final k in _assetKeys) {
      expect(
        counts[k],
        2,
        reason: '$k 가 invalidateAfterAssetChange 에 없다 — 자산을 고쳐도 옛 값이 남는다',
      );
    }
    // 자산 변경은 거래를 건드리지 않는다 — 가계부 목록까지 밀지는 않는다.
    expect(counts['rangeExpenses'], 1);
  });
}

// ─── 프로브 ───────────────────────────────────────────────────

const _rangeKey = (startDate: '2026-09-01', endDate: '2026-09-30');
const _monthKey = (year: 2026, month: 9);
const _cardKey = (assetRowId: 1, yearMonth: '2026-09');

const _expenseKeys = <String>[
  'assets',
  'assetSummary',
  'netWorthTrend',
  'dashboardSummary',
  'monthBudgets',
  'rangeSummary',
  'rangeExpenses',
  'heatmap',
  'merchantSummary',
  'budgetCompliance',
  'cardPerformance',
];

const _assetKeys = <String>[
  'assets',
  'assetSummary',
  'netWorthTrend',
  'cardBilling',
  'cardPerformance',
];

/// 모든 대상 provider 를 "읽을 때마다 세는" 가짜로 바꿔 물리고, 트리의 `WidgetRef` 를 준다.
///
/// `overrides` 의 원소 타입(`Override`)은 flutter_riverpod 이 export 하지 않아
/// 목록만 따로 반환할 수 없다 — 그래서 pump 까지 여기서 한다.
Future<WidgetRef> _pumpProbe(
  WidgetTester tester,
  Map<String, int> counts,
) async {
  void bump(String k) => counts[k] = (counts[k] ?? 0) + 1;
  WidgetRef? captured;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async {
          bump('assets');
          return const <Asset>[];
        }),
        assetSummaryProvider.overrideWith((ref, key) async {
          bump('assetSummary');
          return const AssetSummary();
        }),
        netWorthTrendProvider.overrideWith((ref, months) async {
          bump('netWorthTrend');
          return const <NetWorthPoint>[];
        }),
        cardBillingProvider.overrideWith((ref, id) async {
          bump('cardBilling');
          return CardBilling(cardAssetRowId: id, upcomingAmount: 0);
        }),
        dashboardSummaryProvider.overrideWith((ref) async {
          bump('dashboardSummary');
          return DashboardSummary.fromJson(const <String, dynamic>{});
        }),
        monthBudgetsProvider.overrideWith((ref, key) async {
          bump('monthBudgets');
          return const <Budget>[];
        }),
        budgetComplianceProvider.overrideWith((ref, months) async {
          bump('budgetCompliance');
          return const <BudgetComplianceMonth>[];
        }),
        rangeSummaryProvider.overrideWith((ref, range) async {
          bump('rangeSummary');
          return RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
          );
        }),
        rangeExpensesProvider.overrideWith((ref, key) async {
          bump('rangeExpenses');
          return const <Expense>[];
        }),
        heatmapProvider.overrideWith((ref, range) async {
          bump('heatmap');
          return const <HeatmapCell>[];
        }),
        merchantSummaryProvider.overrideWith((ref, range) async {
          bump('merchantSummary');
          return const <MerchantSummary>[];
        }),
        cardPerformanceProvider.overrideWith((ref, key) async {
          bump('cardPerformance');
          return CardPerformance(
            assetRowId: key.assetRowId,
            yearMonth: key.yearMonth,
            isRequired: false,
            currentAmount: 0,
            achievementRate: 0,
            isAchieved: false,
          );
        }),
      ],
      child: MaterialApp(
        home: _RefProbe(onRef: (r) => captured = r, child: const _WatchAll()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured!;
}

/// 화면들이 읽는 자리를 대신한다 — watch 하지 않으면 invalidate 해도 refetch 되지 않는다.
class _WatchAll extends ConsumerWidget {
  const _WatchAll();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(assetsProvider);
    ref.watch(assetSummaryProvider((year: 2026, month: 9)));
    ref.watch(netWorthTrendProvider(12));
    ref.watch(cardBillingProvider(1));
    ref.watch(dashboardSummaryProvider);
    ref.watch(monthBudgetsProvider(_monthKey));
    ref.watch(budgetComplianceProvider(6));
    ref.watch(rangeSummaryProvider(_rangeKey));
    ref.watch(rangeExpensesProvider(_rangeKey));
    ref.watch(heatmapProvider(_rangeKey));
    ref.watch(
      merchantSummaryProvider((
        startDate: _rangeKey.startDate,
        endDate: _rangeKey.endDate,
      )),
    );
    ref.watch(cardPerformanceProvider(_cardKey));
    return const SizedBox.shrink();
  }
}
