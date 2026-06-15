import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';

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
  ref.invalidate(todoProjectListProvider);
  ref.invalidate(todoTagListProvider);
  ref.invalidate(memoFolderListProvider);
  ref.invalidate(budgetComplianceProvider);
}
