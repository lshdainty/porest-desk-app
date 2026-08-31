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
import 'package:porest_desk_app/core/update/app_update.dart';

/// 거래(expense) 변경 후 파급되는 provider 일괄 무효화.
///
/// 거래 하나가 바뀌면 화면 여러 곳의 숫자가 함께 달라진다. 자산 잔액은 백엔드가
/// 거래 history 로 계산하고, 통계·추이·요약은 그 거래를 집계해 만들며, 캘린더
/// 일정이나 할일에 걸린 거래 목록도 같은 원본을 본다.
///
/// 예전엔 자산 쪽 다섯만 무효화해서, 거래를 고쳐도 **통계·캘린더·할일 화면은 옛
/// 숫자를 그대로 들고 있었다**. 이 provider 들은 autoDispose 가 아니라 한 번 읽으면
/// 앱을 끌 때까지 남는다 — 화면을 다시 열어도 갱신되지 않는다.
///
/// family provider 는 base 를 넘기면 모든 인스턴스가 무효화된다.
void invalidateAfterExpenseChange(WidgetRef ref) {
  // 자산 — 잔액은 거래 이력에서 계산된다.
  ref.invalidate(assetsProvider);
  ref.invalidate(netWorthTrendProvider);
  ref.invalidate(assetByIdProvider);
  ref.invalidate(expensesByAssetProvider);
  ref.invalidate(expensesByAssetIdProvider);
  ref.invalidate(assetBalanceTrendProvider);
  ref.invalidate(assetTransfersProvider);
  ref.invalidate(assetPeriodExpensesProvider);

  // 통계 — 전부 거래를 집계해 만든다.
  ref.invalidate(dailySummaryProvider);
  ref.invalidate(monthlyTrendProvider);
  ref.invalidate(assetExpenseSummaryProvider);
  ref.invalidate(merchantMonthExpensesProvider);

  // 예산·카드 실적도 그 달 지출을 다시 센다.
  ref.invalidate(budgetComplianceProvider);
  ref.invalidate(cardPerformanceProvider);

  // 캘린더 일정·할일 연결 거래는 넣지 않는다 — 모바일 레이아웃이 바뀌며 그 화면이
  // 사라져 지금은 아무도 읽지 않는다(별도 정리 예정).
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
  ref.invalidate(memoFolderListProvider);
  ref.invalidate(budgetComplianceProvider);
  // 세션 내내 남는 조회들 — keepAlive 는 아니지만 autoDispose 도 아니라
  // 한 번 읽으면 그대로 굳는다. 다른 기기에서 바뀐 값을 여기서 함께 따라잡는다.
  ref.invalidate(dashboardLayoutProvider);
  ref.invalidate(todoStatsProvider);
  ref.invalidate(memoFolderTreeProvider);
  ref.invalidate(calendarAggregateProvider);
  ref.invalidate(groupEventsProvider);
  ref.invalidate(budgetAlertThresholdProvider);
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
    case '/budget':
      ref.invalidate(budgetComplianceProvider);
    case '/calendar':
      ref.invalidate(userCalendarListProvider);
      ref.invalidate(eventLabelsProvider);
  }
}
