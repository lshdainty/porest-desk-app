// 여섯 탭은 "1분 지났으면" 다시 받는다 (웹 `staleTime: 60_000` 과 같은 규칙).
//
// 탭 6화면은 셸(`IndexedStack`)에 상주해 dispose 되지 않고, 화면이 읽는 provider 도
// 대부분 autoDispose 가 아니다. 그래서 진입할 때 비우지 않으면 **다른 기기에서 넣은
// 값이 페이지 이동만으로는 안 보였다** — 당겨서 새로고침하거나 앱을 다시 켜야 했다.
// 그렇다고 들어올 때마다 비우면 탭을 한 번 왕복하는 것만으로 그 화면의 조회가 통째로
// 다시 나가고, 카드들이 스켈레톤으로 껌뻑인다.
//
// 기준은 **마지막 성공 조회 시각**이지 마지막 무효화 시각이 아니다.
//
// 시각 칸은 **provider 마다 따로**다(`ServerQuery`). 탭마다 읽는 것이 다르고 겹치는
// 것도 일부뿐이라, 칸을 공유하면 남의 탭에 들렀다 온 것만으로 내 탭이 새 값을 못 받는다
// (아래 "칸은 서로 밀지 않는다" 두 테스트가 그 두 방향을 각각 잠근다).
//
// 이 시계를 보는 자리는 둘이다 — 탭 **진입**(`invalidateKeepAliveForRoute`)과
// **포그라운드 복귀**(`invalidateKeepAliveProviders`). 둘은 **같은 함수·같은 목록**을
// 쓴다. 목록이 두 벌로 갈리면 "합계만 새 값이고 나머지는 옛 값" 인 화면이 된다.
//
// 여기서 보는 건 "무효화 한 줄이 있다" 가 아니라 **리포지토리가 실제로 몇 번
// 불렸는가** 다. 시각은 주입한 가짜 시계로 민다 — 진짜 60초를 기다리지 않는다.
//
// 프로브(`_AllTabsProbe`)는 **`tabQueries` 에 든 조회를 전부** watch 한다. 그래서
// 목록에 조회를 더하면서 프로브를 안 고치면 "프로브가 watch 하지 않았다" 로 먼저
// 깨진다 — 테스트가 목록을 따라온다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/auth_repository.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/core/sync/query_freshness.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/asset/domain/net_worth_point.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/data/budget_repository.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';
import 'package:porest_desk_app/features/budget/domain/budget_compliance.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/data/calendar_repository.dart';
import 'package:porest_desk_app/features/calendar/data/holiday_repository.dart';
import 'package:porest_desk_app/features/calendar/data/user_calendar_repository.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/event_label.dart';
import 'package:porest_desk_app/features/calendar/domain/holiday.dart';
import 'package:porest_desk_app/features/calendar/domain/user_calendar.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/features/dashboard/data/dashboard_repository.dart';
import 'package:porest_desk_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/data/expense_repository.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/data/stats_repository.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';

// ─── 프로브가 읽는 인자 ────────────────────────────────────────
// `monthExpenses`(월 전체)와 `rangeExpenses`(임의 기간)는 리포지토리 메서드가
// 같다(`list`). 기간을 겹치지 않게 잡아 둘을 구분해 센다.
const _month = (year: 2026, month: 9);
const _monthStart = '2026-09-01';
const _monthEnd = '2026-09-30';
const _range = (startDate: '2026-09-05', endDate: '2026-09-25');
const _merchantRange = (startDate: '2026-09-05', endDate: '2026-09-25');
const _merchantMonth = (merchant: '이마트', year: 2026, month: 9);
const _holidayRange = (startDate: '2026-09-01', endDate: '2026-09-30');
const _summaryKey = (year: 2026, month: 9);

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

/// 금액 가리기를 켜 둔 카드 — 탭을 아무리 왕복해도 안 풀려야 한다.
const _maskedCard = 'home.netWorth';

/// 60초 규칙에 든 조회 전부 — 세는 키는 [ServerQuery] 이름 그대로다.
final _allKeys = ServerQuery.values.map((q) => q.name).toList();

/// 그 탭에 들어갔을 때 다시 받아야 하는 것 — **제품 코드의 목록**을 그대로 읽는다.
List<String> _keysOf(String route) =>
    tabQueries[route]!.map((q) => q.name).toList();

void main() {
  // ─── 탭 핑퐁이 조용하다 ─────────────────────────────────────
  testWidgets('60초 안에 여섯 탭을 왕복해도 요청이 한 건도 안 나간다', (tester) async {
    final h = await _pump(tester);

    for (final k in _allKeys) {
      expect(h.counts[k], 1, reason: '$k 를 프로브가 watch 하지 않았다');
    }

    h.clock.advance(const Duration(seconds: 59));
    // 홈 → 가계부 → 자산 → 통계 → 예산 → 캘린더 → 홈. 두 바퀴 돈다.
    for (var lap = 0; lap < 2; lap++) {
      for (final route in tabQueries.keys) {
        invalidateKeepAliveForRoute(h.ref, route);
        await tester.pumpAndSettle();
      }
    }

    for (final k in _allKeys) {
      expect(
        h.counts[k],
        1,
        reason: '$k — 59초밖에 안 지났는데 다시 받았다. 탭을 왕복할 때마다 요청이 나간다',
      );
    }
  });

  // ─── 60초가 지나면 그 탭 것만 ───────────────────────────────
  for (final route in tabQueries.keys) {
    testWidgets('$route — 60초가 지나 들어가면 이 탭이 읽는 것만 다시 받는다', (tester) async {
      final h = await _pump(tester);
      final mine = _keysOf(route);

      h.clock.advance(const Duration(seconds: 61));
      invalidateKeepAliveForRoute(h.ref, route);
      await tester.pumpAndSettle();

      for (final k in _allKeys) {
        final want = mine.contains(k) ? 2 : 1;
        expect(
          h.counts[k],
          want,
          reason: mine.contains(k)
              ? '$k 가 $route 진입 갱신에서 빠졌다 — 다른 기기에서 넣은 값이 안 보인다'
              : '$k 는 $route 가 읽지 않는다 — 남의 탭 조회까지 밀었다',
        );
      }

      // 다시 받았으니 기준 시각도 그때로 옮겨간다 — 59초 뒤 재진입은 조용하다.
      // (`markQueryFetched` 를 빠뜨린 조회는 여기서 3 이 되어 잡힌다.)
      h.clock.advance(const Duration(seconds: 59));
      invalidateKeepAliveForRoute(h.ref, route);
      await tester.pumpAndSettle();

      for (final k in mine) {
        expect(
          h.counts[k],
          2,
          reason:
              '$k — 방금 받아 온 시각을 안 남겼다. 비우는 목록에만 들어가 있어, 받은 직후에도 '
              'stale 로 읽혀 $route 에 들어갈 때마다 조회가 한 번 더 나간다',
        );
      }
    });
  }

  testWidgets('경계는 웹 staleTime 과 같다 — 정확히 60초면 다시 받는다', (tester) async {
    final h = await _pump(tester);

    h.clock.advance(const Duration(seconds: 60));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _keysOf('/stats')) {
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
    h.ref.invalidate(categoriesProvider);
    await tester.pumpAndSettle();
    for (final k in _keysOf('/stats')) {
      expect(h.counts[k], 2, reason: '$k — 당겨서 새로고침이 재조회로 안 이어졌다');
    }

    // 처음 조회로부터 80초, 그러나 마지막 조회로부터는 30초다.
    h.clock.advance(const Duration(seconds: 30));
    invalidateKeepAliveForRoute(h.ref, '/stats');
    await tester.pumpAndSettle();

    for (final k in _keysOf('/stats')) {
      expect(
        h.counts[k],
        2,
        reason: '$k — 기준이 "마지막 무효화" 가 되어 30초 전에 받은 값을 또 받았다',
      );
    }
  });

  // ─── 로컬 UI 상태는 목록에 없다 ─────────────────────────────
  testWidgets('금액 가리기·공휴일 표시는 탭을 왕복해도 안 풀린다', (tester) async {
    final h = await _pump(tester, watchLocalState: true);

    // 사용자가 켜 둔 상태: 순자산 금액은 가려져 있고, 공휴일 표시는 꺼 뒀다.
    h.ref.read(holidayVisibleProvider.notifier).toggle();
    await tester.pumpAndSettle();
    expect(h.masked.last, isTrue, reason: '시나리오 전제 — 금액 가리기가 켜져 있어야 한다');
    expect(h.holidayVisible.last, isFalse, reason: '시나리오 전제 — 공휴일 표시를 꺼야 한다');
    h.masked.clear();
    h.holidayVisible.clear();
    // 지금 화면이 들고 있는 설정 **그 객체**. 무효화되면 build 가 다시 돌아 다른
    // 객체가 되므로, 값이 같아도 여기서 잡힌다.
    final settingsBefore = h.ref.read(settingsProvider).value;
    expect(settingsBefore, isNotNull, reason: '시나리오 전제 — 설정이 로드돼 있어야 한다');

    // 60초를 훌쩍 넘겨 여섯 탭을 두 바퀴 돌고, 앱을 접었다 켜기까지 한다.
    h.clock.advance(const Duration(seconds: 600));
    for (var lap = 0; lap < 2; lap++) {
      for (final route in tabQueries.keys) {
        invalidateKeepAliveForRoute(h.ref, route);
        await tester.pumpAndSettle();
      }
    }
    invalidateKeepAliveProviders(h.ref);
    await tester.pumpAndSettle();

    // 서버 조회는 낡았으니 다시 받는 게 맞다 — 시나리오가 성립했는지부터 본다.
    expect(
      h.counts['categories'],
      greaterThan(1),
      reason: '시나리오 전제 — 10분이 지났으면 서버 조회는 다시 나갔어야 한다',
    );
    // 그동안 화면이 본 값에 `false` 가 한 번이라도 섞이면 금액이 드러난 것이다.
    // 가리기 값은 기기에 저장돼 있어 다시 읽어도 같은 값으로 돌아온다 — 그렇게
    // 티가 안 나는 경우까지 잡으려고 바로 아래에서 **객체 동일성**도 본다.
    expect(
      h.masked,
      isNot(contains(false)),
      reason:
          '금액 가리기가 풀렸다. `hideCardProvider`(=`settingsProvider`)는 서버 조회가 아니라 '
          '사용자가 켜 둔 토글이라 목록에 넣으면 안 된다 — 비우는 순간 다시 읽어 올 때까지 '
          '금액이 그대로 드러난다',
    );
    expect(
      identical(h.ref.read(settingsProvider).value, settingsBefore),
      isTrue,
      reason:
          '표시 설정(`settingsProvider`)이 다시 만들어졌다 — 목록에 들어갔다는 뜻이다. '
          '가리기 값은 기기에 저장돼 있어 곧 같은 값으로 돌아오지만, 저장하지 않는 화면 '
          '상태는 그대로 날아간다',
    );
    expect(
      h.holidayVisible,
      isNot(contains(true)),
      reason: '공휴일 표시가 저절로 켜졌다 — `holidayVisibleProvider` 는 화면 상태지 조회가 아니다',
    );
    expect(h.ref.read(hideCardProvider(_maskedCard)), isTrue);
    expect(h.ref.read(holidayVisibleProvider), isFalse);
  });

  // ─── 내가 바꾼 것은 시간과 무관하게 즉시 ────────────────────
  testWidgets('거래 변경 무효화는 시간과 무관하게 즉시 비운다', (tester) async {
    final h = await _pump(tester);

    // 1초밖에 안 지났다 — 60초 규칙에 걸리면 안 된다.
    h.clock.advance(const Duration(seconds: 1));
    invalidateAfterExpenseChange(h.ref);
    await tester.pumpAndSettle();

    for (final k in [
      ..._statsScreenKeys,
      'merchantMonthExpenses',
      'assets',
      'assetSummary',
      'netWorthTrend',
      'dashboardSummary',
      'monthBudgets',
      'budgetCompliance',
    ]) {
      expect(h.counts[k], 2, reason: '$k — 이 기기에서 거래를 바꿨는데 60초를 기다리게 됐다');
    }
  });

  // ─── 포그라운드 복귀 — 진입과 같은 시계, 같은 목록 ─────────────
  testWidgets('포그라운드 복귀 — 1분 넘게 나갔다 오면 여섯 탭 것을 함께 다시 받는다', (tester) async {
    final h = await _pump(tester);

    // 탭을 켜 둔 채 앱을 접었다 켠 자리다 — 라우트가 안 바뀌므로 진입 갱신은
    // 돌지 않는다. 여기서 빠진 조회는 탭을 떠났다 돌아오기 전까지 옛 값이다.
    h.clock.advance(const Duration(seconds: 61));
    invalidateKeepAliveProviders(h.ref);
    await tester.pumpAndSettle();

    for (final k in _allKeys) {
      expect(
        h.counts[k],
        2,
        reason:
            '$k — 복귀 묶음이 안 비웠다. 목록이 진입과 갈리면 합계만 새 값이고 나머지는 옛 값인 '
            '화면이 된다 — 어느 설계도 아닌 상태다',
      );
    }

    // 복귀에서 받아 온 시각이 곧 기준이다 — 이어서 탭에 들어가도 조용하다.
    // (복귀와 진입이 서로 다른 시계를 보면 여기서 조회가 한 번 더 나간다.)
    h.clock.advance(const Duration(seconds: 1));
    for (final route in tabQueries.keys) {
      invalidateKeepAliveForRoute(h.ref, route);
      await tester.pumpAndSettle();
    }

    for (final k in _allKeys) {
      expect(h.counts[k], 2, reason: '$k — 1초 전에 복귀가 받아 온 값을 진입이 또 받았다');
    }
  });

  testWidgets('포그라운드 복귀 — 잠깐 나갔다 오면 전부 조용하다', (tester) async {
    final h = await _pump(tester);

    // 홈 버튼을 눌렀다 30초 만에 돌아왔다. 낡음은 흘러간 시간의 함수라 30초짜리
    // 외출은 아무것도 낡게 만들지 않는다.
    h.clock.advance(const Duration(seconds: 30));
    invalidateKeepAliveProviders(h.ref);
    await tester.pumpAndSettle();

    for (final k in _allKeys) {
      expect(
        h.counts[k],
        1,
        reason:
            '$k — 복귀가 시계를 무시하고 비웠다. 잠깐 나갔다 올 때마다 보고 있던 화면이 '
            '스켈레톤으로 껌뻑인다',
      );
    }

    // 조용한 게 "복귀에선 안 받는다" 는 뜻은 아니다 — 60초를 넘기면 다 같이 받는다.
    h.clock.advance(const Duration(seconds: 31));
    invalidateKeepAliveProviders(h.ref);
    await tester.pumpAndSettle();

    for (final k in _allKeys) {
      expect(h.counts[k], 2, reason: '$k — 61초 만에 돌아왔는데 다시 안 받았다');
    }
  });

  // ─── 칸은 서로 밀지 않는다 — provider 마다 따로 판정한다 ───────
  testWidgets('거래 상세를 열어도 통계 4종의 시계는 안 밀린다 — 70초 뒤 진입에서 다시 받는다', (
    tester,
  ) async {
    // 칸이 하나였을 때 이렇게 깨졌다:
    //   0초  통계 진입      → 4종 조회 · 시각 = 0
    //   30초 거래 상세 열기 → merchantMonthExpenses 조회 · 한 칸이면 시각이 30 으로 밀린다
    //   70초 통계 진입      → 70-30 = 40 < 60 → 통계 넷이 70초째 옛 값을 그대로 쓴다
    // 거래 상세는 자주 여는 화면이라, 통계 탭이 다른 기기의 변경을 못 따라잡는 창이 그만큼 넓어진다.
    final detailOpen = ValueNotifier(false);
    addTearDown(detailOpen.dispose);
    final h = await _pump(tester, txDetail: detailOpen);

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

    // 70초: 통계 진입. 통계 넷은 마지막 조회로부터 70초다.
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
    // 이어서 가계부(거래 상세가 열리는 탭)로 가도 40초 전에 받은 것은 그대로다.
    invalidateKeepAliveForRoute(h.ref, '/expense');
    await tester.pumpAndSettle();
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

    // 62초: 가계부 진입. 통계 넷은 1초 전에 받았고, merchantMonthExpenses 는 62초 전이다.
    h.clock.advance(const Duration(seconds: 1));
    invalidateKeepAliveForRoute(h.ref, '/expense');
    await tester.pumpAndSettle();

    for (final k in _statsScreenKeys) {
      expect(h.counts[k], 2, reason: '$k — 1초 전에 받은 값을 또 받았다');
    }
    expect(
      h.counts['merchantMonthExpenses'],
      2,
      reason:
          'merchantMonthExpenses — 62초째 낡았는데 안 비웠다. 남이 방금 받았다고 이것까지 '
          '건너뛰면 거래 상세가 다른 기기의 거래를 못 따라잡는다',
    );
  });

  // ─── 목록과 키가 어긋나지 않는다 ────────────────────────────
  test('모든 ServerQuery 는 어느 탭 목록에든 들어 있다', () {
    final listed = tabQueries.values.expand((qs) => qs).toSet();
    expect(
      ServerQuery.values.toSet().difference(listed),
      isEmpty,
      reason:
          '어느 탭에도 안 실린 키가 있다. 시각만 남고 아무도 안 비우니 그 조회는 앱을 다시 '
          '켤 때까지 옛 값이다 — 키를 지우거나, 그 조회를 읽는 탭의 목록에 넣어라',
    );
    expect(
      tabQueries.keys.toSet(),
      {'/home', '/expense', '/assets', '/stats', '/budget', '/calendar'},
      reason: '셸 탭 경로가 바뀌었다 — 라우터와 목록이 어긋나면 그 탭은 영원히 옛 값이다',
    );
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
  Future<List<ExpenseCategory>> categories() async {
    _bump('categories');
    return const <ExpenseCategory>[];
  }

  @override
  Future<List<Expense>> list({
    String? startDate,
    String? endDate,
    int? categoryId,
    int? assetId,
    String? expenseType,
  }) async {
    // 월 전체냐 임의 기간이냐로 가른다 — 화면이 부르는 provider 가 다르다.
    _bump(
      startDate == _monthStart && endDate == _monthEnd
          ? 'monthExpenses'
          : 'rangeExpenses',
    );
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

class _CountingAssetRepo extends AssetRepository {
  _CountingAssetRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<List<Asset>> list() async {
    _bump('assets');
    return const <Asset>[];
  }

  @override
  Future<AssetSummary> summary({int? year, int? month}) async {
    _bump('assetSummary');
    return const AssetSummary();
  }

  @override
  Future<List<NetWorthPoint>> netWorthTrend({int months = 12}) async {
    _bump('netWorthTrend');
    return const <NetWorthPoint>[];
  }

  @override
  Future<List<AssetTransfer>> listTransfers({
    String? startDate,
    String? endDate,
  }) async {
    _bump('assetTransfers');
    return const <AssetTransfer>[];
  }
}

class _CountingBudgetRepo extends BudgetRepository {
  _CountingBudgetRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<List<Budget>> list({int? year, int? month}) async {
    _bump('monthBudgets');
    return const <Budget>[];
  }

  @override
  Future<List<BudgetComplianceMonth>> compliance({int months = 6}) async {
    _bump('budgetCompliance');
    return const <BudgetComplianceMonth>[];
  }
}

class _CountingAuthRepo extends AuthRepository {
  _CountingAuthRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<int?> getBudgetAlertThreshold() async {
    _bump('budgetAlertThreshold');
    return 85;
  }
}

class _CountingDashboardRepo extends DashboardRepository {
  _CountingDashboardRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<DashboardSummary> summary() async {
    _bump('dashboardSummary');
    return DashboardSummary.fromJson(const <String, dynamic>{});
  }
}

class _CountingCalendarRepo extends CalendarRepository {
  _CountingCalendarRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<List<CalendarEvent>> events({
    required String startDate,
    required String endDate,
  }) async {
    _bump('monthEvents');
    return const <CalendarEvent>[];
  }

  @override
  Future<List<EventLabel>> labels() async {
    _bump('eventLabels');
    return const <EventLabel>[];
  }
}

class _CountingUserCalendarRepo extends UserCalendarRepository {
  _CountingUserCalendarRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<List<UserCalendar>> list() async {
    _bump('userCalendarList');
    return const <UserCalendar>[];
  }
}

class _CountingHolidayRepo extends HolidayRepository {
  _CountingHolidayRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<List<Holiday>> list({
    required String startDate,
    required String endDate,
  }) async {
    _bump('holidayList');
    return const <Holiday>[];
  }
}

class _CountingSavingGoalRepo extends SavingGoalRepository {
  _CountingSavingGoalRepo(this._bump) : super(Dio());
  final void Function(String) _bump;

  @override
  Future<List<SavingGoal>> list() async {
    _bump('savingGoalList');
    return const <SavingGoal>[];
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

/// 여섯 탭이 읽는 조회를 **하나씩 전부** watch 한다 — watch 하지 않으면 무효화해도
/// 재조회가 없어서, 목록에서 빠진 것과 구분이 안 된다.
///
/// 실제 앱에서는 탭마다 자기 것만 읽지만, 여기서 한꺼번에 보는 이유는 **남의 탭
/// 조회까지 밀지 않는지**를 같은 자리에서 재기 위해서다.
class _AllTabsProbe extends ConsumerWidget {
  const _AllTabsProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoriesProvider);
    ref.watch(monthExpensesProvider(_month));
    ref.watch(rangeExpensesProvider(_range));
    ref.watch(merchantMonthExpensesProvider(_merchantMonth));
    ref.watch(assetTransfersProvider(_range));
    ref.watch(assetsProvider);
    ref.watch(assetSummaryProvider(_summaryKey));
    ref.watch(netWorthTrendProvider(12));
    ref.watch(savingGoalListProvider);
    ref.watch(dashboardSummaryProvider);
    ref.watch(monthBudgetsProvider(_month));
    ref.watch(budgetAlertThresholdProvider);
    ref.watch(budgetComplianceProvider(6));
    ref.watch(rangeSummaryProvider(_range));
    ref.watch(heatmapProvider(_range));
    ref.watch(merchantSummaryProvider(_merchantRange));
    ref.watch(monthEventsProvider(_month));
    ref.watch(userCalendarListProvider);
    ref.watch(eventLabelsProvider);
    ref.watch(holidayListProvider(_holidayRange));
    return const SizedBox.shrink();
  }
}

/// 거래 상세 dialog 의 "이전 거래" — **열려 있는 동안만** watch 한다.
/// 통계 화면과 다른 화면이라는 것이 시각 칸을 나눈 이유다.
class _WatchOtherMerchantMonth extends ConsumerWidget {
  const _WatchOtherMerchantMonth();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(merchantMonthExpensesProvider(_otherMerchantMonth));
    return const SizedBox.shrink();
  }
}

/// 사용자가 켜 둔 화면 상태 — 서버 조회가 아니다. 프레임마다 값을 적어 둔다.
class _WatchLocalState extends ConsumerWidget {
  const _WatchLocalState({required this.masked, required this.holidayVisible});
  final List<bool> masked;
  final List<bool> holidayVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    masked.add(ref.watch(hideCardProvider(_maskedCard)));
    holidayVisible.add(ref.watch(holidayVisibleProvider));
    return const SizedBox.shrink();
  }
}

typedef _Harness = ({
  Map<String, int> counts,
  _FakeClock clock,
  WidgetRef ref,
  List<bool> masked,
  List<bool> holidayVisible,
});

/// 리포지토리만 가짜로 바꾼다 — provider 본문은 진짜가 돌아야 "값을 만든 시각"이
/// [QueryFreshness] 에 남는 배선까지 함께 잠긴다.
Future<_Harness> _pump(
  WidgetTester tester, {
  ValueNotifier<bool>? txDetail,
  bool watchLocalState = false,
}) async {
  final counts = <String, int>{};
  final clock = _FakeClock();
  final masked = <bool>[];
  final holidayVisible = <bool>[];
  void bump(String k) => counts[k] = (counts[k] ?? 0) + 1;
  WidgetRef? captured;

  SharedPreferences.setMockInitialValues({
    PrefsKeys.hideCards: <String>[_maskedCard],
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        freshnessClockProvider.overrideWith(
          (ref) =>
              () => clock.now,
        ),
        statsRepositoryProvider.overrideWith(
          (ref) async => _CountingStatsRepo(bump),
        ),
        expenseRepositoryProvider.overrideWith(
          (ref) async => _CountingExpenseRepo(bump),
        ),
        assetRepositoryProvider.overrideWith(
          (ref) async => _CountingAssetRepo(bump),
        ),
        budgetRepositoryProvider.overrideWith(
          (ref) async => _CountingBudgetRepo(bump),
        ),
        authRepositoryProvider.overrideWith(
          (ref) async => _CountingAuthRepo(bump),
        ),
        dashboardRepositoryProvider.overrideWith(
          (ref) async => _CountingDashboardRepo(bump),
        ),
        calendarRepositoryProvider.overrideWith(
          (ref) async => _CountingCalendarRepo(bump),
        ),
        userCalendarRepositoryProvider.overrideWith(
          (ref) async => _CountingUserCalendarRepo(bump),
        ),
        holidayRepositoryProvider.overrideWith(
          (ref) async => _CountingHolidayRepo(bump),
        ),
        savingGoalRepositoryProvider.overrideWith(
          (ref) async => _CountingSavingGoalRepo(bump),
        ),
      ],
      child: MaterialApp(
        home: _RefProbe(
          onRef: (r) => captured = r,
          child: Column(
            children: [
              const _AllTabsProbe(),
              if (watchLocalState)
                _WatchLocalState(
                  masked: masked,
                  holidayVisible: holidayVisible,
                ),
              if (txDetail != null)
                ValueListenableBuilder<bool>(
                  valueListenable: txDetail,
                  builder: (context, isOpen, _) => isOpen
                      ? const _WatchOtherMerchantMonth()
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    counts: counts,
    clock: clock,
    ref: captured!,
    masked: masked,
    holidayVisible: holidayVisible,
  );
}
