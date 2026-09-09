import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/core/sync/stats_freshness.dart';
import 'package:porest_desk_app/core/update/app_update.dart';

/// 거래(expense) 변경 후 파급되는 provider 일괄 무효화.
///
/// 거래 하나가 바뀌면 화면 여러 곳의 숫자가 함께 달라진다. 자산 잔액은 백엔드가
/// 거래 history 로 계산하고, 통계·요약·예산·홈 위젯은 그 거래를 다시 집계한다.
///
/// 여기 든 provider 는 **autoDispose 가 아니다.** 게다가 홈·가계부·통계는 탭
/// 셸(`IndexedStack`)에 계속 mount 되어 dispose 되지도 않는다 — 한 번 읽힌 값은
/// 여기서 비우지 않는 한 앱을 끌 때까지 그대로다. 탭을 오가거나 화면을 다시 열어도
/// 갱신되지 않고, 당겨서 새로고침해야만 풀린다.
///
/// **화면이 실제로 읽는 것만 넣는다.** 아무도 안 읽는 provider 를 끼워 두면 목록만
/// 길어지고 "갱신하고 있다" 는 착시가 생겨, 정작 빠진 것을 못 찾는다.
///
/// family provider 는 base 를 넘기면 모든 인스턴스가 무효화된다.
void invalidateAfterExpenseChange(WidgetRef ref) {
  // 자산 — 잔액·순자산은 거래 이력에서 계산된다.
  ref.invalidate(assetsProvider);
  ref.invalidate(assetSummaryProvider);
  ref.invalidate(netWorthTrendProvider);
  ref.invalidate(assetByIdProvider);
  ref.invalidate(expensesByAssetProvider);
  ref.invalidate(assetBalanceTrendProvider);
  ref.invalidate(assetTransfersProvider);
  ref.invalidate(assetPeriodExpensesProvider);

  // 홈 — 이번 달 지출·예산·위젯이 전부 이 거래를 센다.
  // 홈 합계는 `요약 ?? 목록합` 순서라, 옛 요약이 살아 있으면 새 목록으로 폴백조차
  // 하지 않는다. 요약을 비우지 않으면 "오늘 목록만 바뀌는" 비대칭이 남는다.
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(monthBudgetsProvider);

  // 통계 — 통계 화면이 읽는 넷. rangeSummary 는 홈 합계도 같이 읽는다.
  ref.invalidate(rangeSummaryProvider);
  ref.invalidate(rangeExpensesProvider);
  ref.invalidate(heatmapProvider);
  ref.invalidate(merchantSummaryProvider);
  ref.invalidate(merchantMonthExpensesProvider);

  // 예산·카드 실적도 그 달 지출을 다시 센다.
  ref.invalidate(budgetComplianceProvider);
  ref.invalidate(cardPerformanceProvider);

  // 월별 거래 목록(`monthExpensesProvider`)은 부르는 쪽이 바뀐 달만 짚어 비운다 —
  // 여기서 base 로 밀면 안 본 달까지 전부 다시 받는다.
}

/// 자산(계좌·카드·투자) 생성·수정·삭제 후 무효화.
///
/// 자산 목록만 비우면 순자산·추이·청구·실적이 옛 값으로 남는다. 전부 별도 조회이고,
/// 셸에 상주하는 화면이 읽으므로 스스로 다시 받지 않는다.
///
/// 거래는 건드리지 않는다 — 자산을 고쳐도 그 자산에 달린 거래 자체는 그대로다.
/// 거래까지 바뀌는 경로(카드 결제·이체 삭제 등)는 [invalidateAfterExpenseChange] 를 쓴다.
void invalidateAfterAssetChange(WidgetRef ref) {
  ref.invalidate(assetsProvider);
  ref.invalidate(assetSummaryProvider);
  ref.invalidate(netWorthTrendProvider);
  ref.invalidate(assetByIdProvider);
  ref.invalidate(cardBillingProvider);
  ref.invalidate(cardPerformanceProvider);
}

/// keepAlive(앱 세션 캐시) provider 일괄 무효화.
///
/// 이 provider 들은 `ref.keepAlive()` 로 앱 세션 내내 캐시되어 자동 refetch 되지
/// 않는다. 다른 클라이언트(웹 등)에서 변경된 내용을 따라잡기 위해 앱이
/// 포그라운드로 복귀할 때 한 번에 무효화한다(다음 watch 시 refetch).
/// family provider 는 base 를 넘기면 모든 인스턴스가 무효화된다.
void invalidateKeepAliveProviders(WidgetRef ref) {
  ref.invalidate(categoriesProvider);
  ref.invalidate(eventLabelsProvider);
  ref.invalidate(userCalendarListProvider);
  ref.invalidate(cardBenefitMappingsProvider);
  ref.invalidate(assetsProvider);
  ref.invalidate(netWorthTrendProvider);
  ref.invalidate(todoTagListProvider);
  ref.invalidate(memoTagListProvider);
  ref.invalidate(budgetComplianceProvider);
  // 세션 내내 남는 조회들 — keepAlive 는 아니지만 autoDispose 도 아니라
  // 한 번 읽으면 그대로 굳는다. 다른 기기에서 바뀐 값을 여기서 함께 따라잡는다.
  ref.invalidate(dashboardLayoutProvider);
  ref.invalidate(budgetAlertThresholdProvider);
  // 탭 6화면이 IndexedStack 에 상주해 dispose 되지 않는다 — 화면이 그리는 원본을
  // 여기서 같이 비워야 웹에서 고친 값이 복귀 후에 보인다. 한 곳이라도 빠뜨리면
  // 그 숫자만 앱을 다시 켤 때까지 옛 값으로 남는다.
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(assetSummaryProvider);
  ref.invalidate(rangeSummaryProvider);
  ref.invalidate(monthExpensesProvider);
  ref.invalidate(monthBudgetsProvider);
  ref.invalidate(monthEventsProvider);
  // 새 버전 확인도 여기 태운다 — 예전엔 앱을 켤 때 한 번뿐이라, 오래 띄워 둔 앱은
  // 새 버전이 나와도 끌 때까지 몰랐다. version.json 은 1KB 정적 파일에 5초 타임아웃이라
  // resume 마다 한 번 더 물어봐도 부담이 없다.
  ref.invalidate(updateStatusProvider);
}

/// 셸(IndexedStack) 화면 진입 갱신.
///
/// `/expense`·`/assets`·`/budget`·`/calendar` 등은 셸에 계속 mount 되어
/// `initState` 가 재실행되지 않으므로, 라우트가 바뀔 때 진입하는 경로가 watch 하는
/// keepAlive provider 만 골라 무효화한다(다른 탭은 건드리지 않아 불필요한 refetch 방지).
///
/// `/stats` 만 시각을 본다 — [_invalidateStaleStats] 참고.
void invalidateKeepAliveForRoute(WidgetRef ref, String path) {
  switch (path) {
    case '/home':
      ref.invalidate(categoriesProvider);
    case '/expense':
      ref.invalidate(categoriesProvider);
      ref.invalidate(assetsProvider);
    case '/assets':
      ref.invalidate(assetsProvider);
      ref.invalidate(netWorthTrendProvider);
      // 자산 화면 저축 목표 조회 섹션 — 셸 상주 watch 로 dispose 안 되므로 진입 시 갱신.
      ref.invalidate(savingGoalListProvider);
    case '/stats':
      ref.invalidate(categoriesProvider);
      _invalidateStaleStats(ref);
    case '/budget':
      ref.invalidate(budgetComplianceProvider);
    case '/calendar':
      ref.invalidate(userCalendarListProvider);
      ref.invalidate(eventLabelsProvider);
  }
}

/// 통계 4종 — 마지막으로 **받아 온 지** 60초가 지났을 때만 다시 받는다.
///
/// 통계 provider 는 autoDispose 가 아니고 통계 탭도 셸에 상주해 dispose 되지
/// 않는다. 그래서 진입할 때 비우지 않으면 다른 기기에서 넣은 값이 당겨서
/// 새로고침하거나 앱을 다시 켜기 전에는 안 보인다. 반대로 들어올 때마다 비우면
/// 탭을 한 번 왕복하는 것만으로 조회 넷이 새로 나간다.
///
/// 그래서 웹 react-query 의 `staleTime: 60_000` 과 **같은 규칙**을 쓴다. 기준은
/// **마지막 성공 조회 시각**(`StatsFreshness`)이지 마지막 무효화 시각이 아니다 —
/// 무효화는 아무도 그 provider 를 안 보고 있으면 조회로 이어지지 않으므로,
/// 비운 시각을 기준으로 삼으면 실제로는 한 번도 안 받은 채 시계만 돈다.
///
/// 60초 안이면 **아무것도 하지 않는다**(요청 0회). 한 번도 안 받았으면 비운다 —
/// 안 읽힌 provider 를 비우는 것은 no-op 이다.
///
/// 타이머·폴링은 없다. 화면에 들어오는 이 순간에만 비교한다. 거래를 바꿨을 때의
/// 무효화([invalidateAfterExpenseChange])는 시간과 무관하게 즉시 비운다.
void _invalidateStaleStats(WidgetRef ref) {
  final now = ref.read(statsClockProvider)();
  if (!ref.read(statsFreshnessProvider).isStaleAt(now)) return;
  ref.invalidate(rangeSummaryProvider);
  ref.invalidate(rangeExpensesProvider);
  ref.invalidate(heatmapProvider);
  ref.invalidate(merchantSummaryProvider);
}
