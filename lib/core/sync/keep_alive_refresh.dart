import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';

/// 거래(expense) 변경 후 자산 관련 provider 무효화.
///
/// 거래는 자산 잔액에 영향을 주므로(백엔드가 잔액을 거래 history 로 계산) 거래
/// 생성/수정/삭제/이체 시 자산 잔액·추이·자산별 거래내역을 무효화한다.
/// family provider 는 base 를 넘기면 모든 인스턴스가 무효화된다.
void invalidateAssetsAfterExpense(WidgetRef ref) {
  ref.invalidate(assetsProvider);
  ref.invalidate(netWorthTrendProvider);
  ref.invalidate(assetByIdProvider);
  ref.invalidate(expensesByAssetProvider);
  ref.invalidate(expensesByAssetIdProvider);
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
