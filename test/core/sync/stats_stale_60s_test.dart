// 통계 탭은 "1분 지났으면" 다시 받는다 (결정 1).
//
// 통계 provider 다섯(`rangeSummary`·`rangeExpenses`·`heatmap`·`merchantSummary`·
// `merchantMonthExpenses`)은
// autoDispose 가 아니고, 통계 탭도 셸(`IndexedStack`)에 상주해 dispose 되지 않는다.
// 그래서 진입할 때 비우지 않으면 **다른 기기에서 넣은 값이 페이지 이동만으로는
// 안 보였다** — 당겨서 새로고침하거나 앱을 다시 켜야 했다. 그렇다고 들어올 때마다
// 비우면 탭을 한 번 왕복하는 것만으로 조회 넷이 새로 나간다.
//
// 그래서 웹 react-query 의 `staleTime: 60_000` 과 같은 규칙을 쓴다. 기준은
// **마지막 성공 조회 시각**이지 마지막 무효화 시각이 아니다.
//
// 시각 칸은 **provider 마다 따로**다(`StatsQuery`). 처음엔 한 칸이었는데,
// `merchantMonthExpenses` 를 읽는 곳이 통계 화면이 아니라 **거래 상세**라서
// 거래 상세를 여는 것만으로 통계 넷의 시계가 밀렸다 — 아래 "칸은 서로 밀지 않는다"
// 두 테스트가 그 두 방향을 각각 잠근다.
//
// 여기서 보는 건 "무효화 한 줄이 있다" 가 아니라 **리포지토리가 실제로 몇 번
// 불렸는가** 다. 시각은 주입한 가짜 시계로 민다 — 진짜 60초를 기다리지 않는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/core/sync/stats_freshness.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/data/expense_repository.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/data/stats_repository.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';

const _range = (startDate: '2026-09-01', endDate: '2026-09-30');
const _merchantRange = (startDate: '2026-09-01', endDate: '2026-09-30');
const _merchantMonth = (merchant: '이마트', year: 2026, month: 9);

/// 거래 상세를 **다른 가맹점**으로 여는 자리 — family 인스턴스가 새로 생겨
/// 조회가 한 번 더 나가고, `merchantMonthExpenses` 칸의 시각이 그때로 밀린다.
const _otherMerchantMonth = (merchant: '스타벅스', year: 2026, month: 9);

/// **통계 화면**이 읽는 넷 — 거래 상세를 열어도 이 시계는 안 밀려야 한다.
const _statsScreenKeys = <String>[
  'rangeSummary',
  'rangeExpenses',
  'heatmap',
  'merchantSummary',
];

/// 60초 규칙에 든 5종의 조회 횟수 — 진입 갱신이 **재조회로 이어졌는지** 보는 자다.
///
/// `merchantMonthExpenses`(TX 상세 "이전 거래")는 QA #158 에서 같은 기준에
/// 들어왔다. 비우는 자리(`_invalidateStaleStats`)와 시각을 남기는
/// 자리(`ref.markStatsFetched(StatsQuery.…)`)에 **같은 키로 둘 다** 있어야 기준이
/// 맞는다 — 아래 테스트들이 방향별로 한쪽씩 잠근다.
const _statsKeys = <String>[..._statsScreenKeys, 'merchantMonthExpenses'];

void main() {
  testWidgets('60초 안에 다시 들어가면 통계 5종을 다시 받지 않는다', (tester) async {
    final h = await _pump(tester);

    for (final k in _statsKeys) {
      expect(h.counts[k], 1, reason: '$k 를 프로브가 watch 하지 않았다');
    }

    h.clock.advance(const Duration(seconds: 59));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _statsKeys) {
      expect(
        h.counts[k],
        1,
        reason: '$k — 59초밖에 안 지났는데 다시 받았다. 탭을 왕복할 때마다 조회가 나간다',
      );
    }
  });

  testWidgets('60초가 지나 들어가면 통계 5종을 각각 다시 받는다', (tester) async {
    final h = await _pump(tester);

    h.clock.advance(const Duration(seconds: 61));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _statsKeys) {
      expect(h.counts[k], 2, reason: '$k 가 진입 갱신에서 빠졌다 — 다른 기기에서 넣은 값이 안 보인다');
    }

    // 다시 받았으니 기준 시각도 그때로 옮겨간다 — 59초 뒤 재진입은 조용하다.
    h.clock.advance(const Duration(seconds: 59));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _statsKeys) {
      expect(h.counts[k], 2, reason: '$k — 기준이 마지막 조회 시각으로 안 옮겨갔다');
    }
  });

  testWidgets('경계는 웹 staleTime 과 같다 — 정확히 60초면 다시 받는다', (tester) async {
    final h = await _pump(tester);

    h.clock.advance(const Duration(seconds: 60));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _statsKeys) {
      expect(
        h.counts[k],
        2,
        reason: '$k — react-query 는 정확히 staleTime 이면 stale 이다',
      );
    }
  });

  testWidgets('기준은 마지막 성공 조회 시각이다 — 방금 당겨서 새로고침했으면 진입해도 안 받는다', (tester) async {
    final h = await _pump(tester);

    // 50초 뒤 사용자가 당겨서 새로고침한다 — 진입 갱신을 거치지 않는 경로다.
    h.clock.advance(const Duration(seconds: 50));
    h.ref.invalidate(rangeSummaryProvider);
    h.ref.invalidate(rangeExpensesProvider);
    h.ref.invalidate(heatmapProvider);
    h.ref.invalidate(merchantSummaryProvider);
    h.ref.invalidate(merchantMonthExpensesProvider);
    await tester.pumpAndSettle();
    for (final k in _statsKeys) {
      expect(h.counts[k], 2, reason: '$k — 당겨서 새로고침이 재조회로 안 이어졌다');
    }

    // 처음 조회로부터 80초, 그러나 마지막 조회로부터는 30초다.
    h.clock.advance(const Duration(seconds: 30));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _statsKeys) {
      expect(
        h.counts[k],
        2,
        reason: '$k — 기준이 "마지막 무효화" 가 되어 30초 전에 받은 값을 또 받았다',
      );
    }
  });

  // ─── 시각을 남기는 자리 — 비우는 목록과 같아야 한다 ───────────
  testWidgets('가맹점·달 거래도 받아 온 시각을 남긴다 — 30초 뒤 통계 진입은 조용하다', (tester) async {
    // TX 상세 "이전 거래" 만 열어 본 상태 — 통계 4종은 아직 한 번도 안 받았다.
    // 그래서 기준 시각은 이 provider 가 남긴 것 하나뿐이다.
    final h = await _pump(tester, watch: const _WatchMerchantMonthOnly());

    expect(
      h.counts['merchantMonthExpenses'],
      1,
      reason: 'merchantMonthExpenses 를 프로브가 watch 하지 않았다',
    );

    h.clock.advance(const Duration(seconds: 30));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    expect(
      h.counts['merchantMonthExpenses'],
      1,
      reason:
          'merchantMonthExpenses 가 시각을 안 남겼다 — 비우는 목록에만 들어가 있어, 방금 받은 값도 '
          'stale 로 읽혀 통계 탭에 들어갈 때마다 조회가 한 번 더 나간다',
    );
  });

  // ─── 칸은 서로 밀지 않는다 — provider 마다 따로 판정한다 ───────
  testWidgets('거래 상세를 열어도 통계 4종의 시계는 안 밀린다 — 70초 뒤 진입에서 다시 받는다', (
    tester,
  ) async {
    // 칸이 하나였을 때 이렇게 깨졌다:
    //   0초  통계 진입      → 5종 조회 · 시각 = 0
    //   30초 거래 상세 열기 → merchantMonthExpenses 조회 · 한 칸이면 시각이 30 으로 밀린다
    //   70초 통계 진입      → 70-30 = 40 < 60 → 통계 넷이 70초째 옛 값을 그대로 쓴다
    // 거래 상세는 자주 여는 화면이라, 통계 탭이 다른 기기의 변경을 못 따라잡는 창이 그만큼 넓어진다.
    final detailOpen = ValueNotifier(false);
    addTearDown(detailOpen.dispose);
    final h = await _pump(tester, watch: _StatsWithTxDetail(detailOpen));

    for (final k in _statsKeys) {
      expect(h.counts[k], 1, reason: '$k 를 프로브가 watch 하지 않았다');
    }

    // 30초: 거래 상세를 다른 가맹점으로 연다 — 이 조회만 나간다.
    h.clock.advance(const Duration(seconds: 30));
    detailOpen.value = true;
    await tester.pumpAndSettle();

    expect(
      h.counts['merchantMonthExpenses'],
      2,
      reason: '거래 상세를 열었는데 merchantMonthExpenses 조회가 안 나갔다 — 시나리오가 성립하지 않는다',
    );
    for (final k in _statsScreenKeys) {
      expect(h.counts[k], 1, reason: '$k — 거래 상세를 여는 것이 통계 조회를 부르진 않는다');
    }

    // 70초: 통계 진입. 통계 넷은 마지막 조회로부터 70초, merchantMonthExpenses 는 40초.
    h.clock.advance(const Duration(seconds: 40));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _statsScreenKeys) {
      expect(
        h.counts[k],
        2,
        reason:
            '$k — 거래 상세를 여는 것만으로 통계 시계가 밀렸다. 시각 칸을 하나로 공유하면 '
            '거래 상세를 열 때마다 통계 탭이 다른 기기의 변경을 못 따라잡는 창이 넓어진다',
      );
    }
    expect(
      h.counts['merchantMonthExpenses'],
      2,
      reason:
          'merchantMonthExpenses — 40초 전에 받았는데 다시 받았다. "하나라도 낡았으면 다 비운다" 가 '
          '되면 안 된다(자기 시각을 지킨다)',
    );
  });

  testWidgets('거꾸로도 각자다 — 낡은 가맹점·달 거래만 비우고 방금 받은 통계 4종은 그대로 둔다', (
    tester,
  ) async {
    final h = await _pump(tester);

    // 61초 뒤 통계 화면에서 당겨서 새로고침 — 통계 넷만 다시 받는다.
    h.clock.advance(const Duration(seconds: 61));
    h.ref.invalidate(rangeSummaryProvider);
    h.ref.invalidate(rangeExpensesProvider);
    h.ref.invalidate(heatmapProvider);
    h.ref.invalidate(merchantSummaryProvider);
    await tester.pumpAndSettle();
    for (final k in _statsScreenKeys) {
      expect(h.counts[k], 2, reason: '$k — 당겨서 새로고침이 재조회로 안 이어졌다');
    }

    // 62초: 통계 진입. 통계 넷은 1초 전에 받았고, merchantMonthExpenses 는 62초 전이다.
    h.clock.advance(const Duration(seconds: 1));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _statsScreenKeys) {
      expect(h.counts[k], 2, reason: '$k — 1초 전에 받은 값을 또 받았다');
    }
    expect(
      h.counts['merchantMonthExpenses'],
      2,
      reason:
          'merchantMonthExpenses — 62초째 낡았는데 안 비웠다. 통계 넷이 방금 받았다고 이것까지 '
          '건너뛰면 거래 상세가 다른 기기의 거래를 못 따라잡는다',
    );
  });

  testWidgets('거래 변경 무효화는 시간과 무관하게 즉시 비운다', (tester) async {
    final h = await _pump(tester);

    // 1초밖에 안 지났다 — 60초 규칙에 걸리면 안 된다.
    h.clock.advance(const Duration(seconds: 1));
    invalidateAfterExpenseChange(h.ref);
    await tester.pumpAndSettle();

    for (final k in _statsKeys) {
      expect(h.counts[k], 2, reason: '$k — 이 기기에서 거래를 바꿨는데 60초를 기다리게 됐다');
    }
  });
}

// ─── 프로브 ───────────────────────────────────────────────────

class _FakeClock {
  DateTime now = DateTime(2026, 9, 9, 12);
  void advance(Duration d) => now = now.add(d);
}

class _CountingStatsRepo extends StatsRepository {
  _CountingStatsRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<RangeSummary> range({
    required String startDate,
    required String endDate,
  }) async {
    _bump('rangeSummary');
    return RangeSummary(startDate: startDate, endDate: endDate);
  }

  @override
  Future<List<HeatmapCell>> heatmap({
    required String startDate,
    required String endDate,
  }) async {
    _bump('heatmap');
    return const <HeatmapCell>[];
  }

  @override
  Future<List<MerchantSummary>> byMerchant({
    String? startDate,
    String? endDate,
  }) async {
    _bump('merchantSummary');
    return const <MerchantSummary>[];
  }
}

class _CountingExpenseRepo extends ExpenseRepository {
  _CountingExpenseRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<List<Expense>> list({
    String? startDate,
    String? endDate,
    int? categoryId,
    int? assetId,
    String? expenseType,
  }) async {
    _bump('rangeExpenses');
    return const <Expense>[];
  }

  @override
  Future<List<Expense>> search({
    int? categoryId,
    int? assetId,
    String? expenseType,
    String? keyword,
    String? merchant,
    int? minAmount,
    int? maxAmount,
    String? startDate,
    String? endDate,
  }) async {
    _bump('merchantMonthExpenses');
    // provider 가 결과를 그 자리에서 정렬한다 — const 목록을 주면 sort 가 던진다.
    return <Expense>[];
  }
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

/// 60초 규칙이 미는 다섯을 읽는 자리를 대신한다(통계 화면 넷 + TX 상세 "이전 거래")
/// — watch 하지 않으면 무효화해도 재조회가 없다.
class _WatchStats extends ConsumerWidget {
  const _WatchStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(rangeSummaryProvider(_range));
    ref.watch(rangeExpensesProvider(_range));
    ref.watch(heatmapProvider(_range));
    ref.watch(merchantSummaryProvider(_merchantRange));
    ref.watch(merchantMonthExpensesProvider(_merchantMonth));
    return const SizedBox.shrink();
  }
}

/// 거래 상세 dialog 의 "이전 거래" — **열려 있는 동안만** watch 한다.
/// 통계 화면 넷과 다른 화면이라는 것이 시각 칸을 나눈 이유다.
class _WatchOtherMerchantMonth extends ConsumerWidget {
  const _WatchOtherMerchantMonth();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(merchantMonthExpensesProvider(_otherMerchantMonth));
    return const SizedBox.shrink();
  }
}

/// 통계 화면(다섯을 읽는 자리) + 여닫을 수 있는 거래 상세.
class _StatsWithTxDetail extends StatelessWidget {
  const _StatsWithTxDetail(this.detailOpen);
  final ValueNotifier<bool> detailOpen;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _WatchStats(),
      ValueListenableBuilder<bool>(
        valueListenable: detailOpen,
        builder: (context, isOpen, _) =>
            isOpen ? const _WatchOtherMerchantMonth() : const SizedBox.shrink(),
      ),
    ],
  );
}

/// TX 상세 "이전 거래" 만 열어 본 상태 — 통계 4종은 아직 아무도 안 읽었다.
class _WatchMerchantMonthOnly extends ConsumerWidget {
  const _WatchMerchantMonthOnly();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(merchantMonthExpensesProvider(_merchantMonth));
    return const SizedBox.shrink();
  }
}

typedef _Harness = ({Map<String, int> counts, _FakeClock clock, WidgetRef ref});

/// 리포지토리만 가짜로 바꾼다 — provider 본문은 진짜가 돌아야 "값을 만든 시각"이
/// [StatsFreshness] 에 남는 배선까지 함께 잠긴다.
Future<_Harness> _pump(
  WidgetTester tester, {
  Widget watch = const _WatchStats(),
}) async {
  final counts = <String, int>{};
  final clock = _FakeClock();
  void bump(String k) => counts[k] = (counts[k] ?? 0) + 1;
  WidgetRef? captured;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        statsClockProvider.overrideWith(
          (ref) =>
              () => clock.now,
        ),
        statsRepositoryProvider.overrideWith(
          (ref) async => _CountingStatsRepo(bump),
        ),
        expenseRepositoryProvider.overrideWith(
          (ref) async => _CountingExpenseRepo(bump),
        ),
      ],
      child: MaterialApp(
        home: _RefProbe(onRef: (r) => captured = r, child: watch),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (counts: counts, clock: clock, ref: captured!);
}
