import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 60초 규칙에 든 조회들 — [QueryFreshness] 의 **칸 이름**이다.
///
/// 시각을 남기는 쪽(provider 본문)과 판정하는 쪽([QueryFreshness.isStaleAt])이
/// 같은 칸을 가리켜야 하므로 문자열이 아니라 enum 으로 둔다. 새 조회를 이 규칙에
/// 넣을 때는 **셋을 한 세트로** 한다.
///
/// 1. 여기에 값을 하나 더한다
/// 2. 그 provider 본문에서 **자기 값으로** [QueryFreshnessRef.markQueryFetched] 를 부른다
/// 3. `keep_alive_refresh.dart` 의 `_invalidateQuery` 에 provider 를 잇고,
///    그 조회를 읽는 **탭의 목록**(`tabQueries`)에 값을 넣는다
///
/// 3 번의 앞쪽(`_invalidateQuery`)은 빠뜨릴 수 없다 — enum 을 다 덮지 않는 switch 는
/// 컴파일이 안 된다. 2 번과 목록 쪽은 컴파일러가 못 잡으므로
/// `test/core/sync/tab_stale_60s_test.dart` 가 탭마다 왕복시켜 잡는다.
///
/// ## 서버에서 받아 오는 것만 넣는다
///
/// 금액 가리기(`hideCardProvider`·`maskFlagsProvider`)나 공휴일 표시
/// (`holidayVisibleProvider`)처럼 **사용자가 켜 둔 토글**은 여기 오면 안 된다.
/// 그건 조회가 아니라 화면 상태라, 비우는 순간 사용자가 켜 둔 것이 기본값으로
/// 돌아간다 — 탭을 왕복할 때마다 가려 둔 금액이 드러난다.
enum ServerQuery {
  /// 카테고리 목록 (`categoriesProvider`) — 홈·가계부·통계·예산이 함께 읽는다.
  categories,

  /// 월간 거래 목록 (`monthExpensesProvider`) — 홈·가계부.
  monthExpenses,

  /// 기간 거래 목록 (`rangeExpensesProvider`) — 통계 추이 차트.
  rangeExpenses,

  /// **거래 상세** dialog 의 "이전 거래" (`merchantMonthExpensesProvider`).
  /// 통계 화면은 이걸 읽지 않는다 — 칸을 나눈 이유가 이 하나다.
  merchantMonthExpenses,

  /// 이체 목록 (`assetTransfersProvider`) — 가계부가 거래 목록과 합쳐 그린다.
  assetTransfers,

  /// 자산 목록 (`assetsProvider`) — 자산 화면·가계부 필터 칩.
  assets,

  /// 자산 요약 (`assetSummaryProvider`) — 홈 순자산 카드·자산 화면 상단.
  assetSummary,

  /// 순자산 추이 (`netWorthTrendProvider`) — 자산 화면 차트.
  netWorthTrend,

  /// 저축 목표 목록 (`savingGoalListProvider`) — 자산 화면 섹션.
  savingGoalList,

  /// 홈 통합 요약 (`dashboardSummaryProvider`).
  dashboardSummary,

  /// 월 예산 (`monthBudgetsProvider`) — 홈 예산 카드·예산 화면.
  monthBudgets,

  /// 예산 경고 임계값 (`budgetAlertThresholdProvider`) — 홈·예산 게이지.
  budgetAlertThreshold,

  /// 예산 준수율 (`budgetComplianceProvider`) — 예산 화면 추이.
  budgetCompliance,

  /// 기간 요약 (`rangeSummaryProvider`) — 통계 도넛·하이라이트, 홈·예산 합계.
  rangeSummary,

  /// 히트맵 (`heatmapProvider`) — 통계 화면.
  heatmap,

  /// 가맹점 순위 (`merchantSummaryProvider`) — 통계 화면.
  merchantSummary,

  /// 월 일정 (`monthEventsProvider`) — 캘린더 그리드.
  monthEvents,

  /// 사용자 캘린더 목록 (`userCalendarListProvider`) — 캘린더 표시 토글의 원본.
  userCalendarList,

  /// 일정 라벨 (`eventLabelsProvider`) — 일정 등록·수정 dialog.
  eventLabels,

  /// 공휴일 (`holidayListProvider`) — 캘린더 그리드 라벨.
  holidayList,
}

/// 60초 규칙이 붙은 조회들의 **마지막 성공 조회 시각** — [ServerQuery] 마다 한 칸.
///
/// 탭 6화면은 셸(`IndexedStack`)에 상주하고 provider 도 대부분 autoDispose 가
/// 아니라, 진입할 때 비우지 않으면 다른 기기에서 넣은 값이 안 보인다. 그렇다고
/// 들어올 때마다 비우면 탭을 두 번 왕복하는 것만으로 화면이 읽는 조회가 통째로
/// 다시 나간다.
///
/// 그래서 웹(react-query `staleTime` 60초)과 **같은 규칙**을 쓴다 — 마지막으로
/// 받아 온 지 60초가 지났을 때만 다시 받는다. 기준은 "마지막으로 **비운** 시각"
/// 이 아니라 **"마지막으로 값을 받아 온 시각"** 이다. 무효화는 아무도 그 provider 를
/// 보고 있지 않으면 조회로 이어지지 않으므로, 비운 시각을 기준으로 삼으면 한 번도
/// 받지 않은 채 60초가 흘러가 버린다.
///
/// 시각은 **provider 가 값을 만들어 낸 직후**에만 찍는다(실패하면 안 찍는다).
/// 타이머·폴링은 없다 — 화면에 들어올 때와 앱이 포그라운드로 돌아올 때
/// [isStaleAt] 으로 비교만 한다.
///
/// ## 왜 provider 마다 칸을 나눴나
///
/// 처음엔 "가장 최근 조회 시각" 한 칸이었다. 근거는 **이 조회들이 함께 움직인다**
/// 는 것 — 통계 화면 하나가 넷을 한 번에 읽으므로, 누가 시각을 남겨도 나머지가
/// 방금 받은 상태였다.
///
/// [ServerQuery.merchantMonthExpenses] 가 같은 규칙에 들어오면서(QA #158) 그
/// 전제가 깨졌다. **그 조회를 읽는 건 통계 화면이 아니라 거래 상세**다. 칸이
/// 하나면 거래 상세를 여는 것만으로 통계 넷의 시계까지 밀린다.
///
/// ```
/// 0초   통계 진입      → 4종 조회 · 시각 = 0
/// 30초  거래 상세 열기 → merchantMonthExpenses 조회 · 한 칸이면 시각이 30 으로 밀린다
/// 70초  통계 진입      → 70-30 = 40 < 60 → 통계 넷은 70초째 옛 값을 그대로 쓴다
/// ```
///
/// 규칙이 여섯 탭으로 넓어진 지금은 그 전제가 아예 성립하지 않는다. 탭마다 읽는
/// 것이 다르고 겹치는 것도 일부뿐이라, 칸을 공유하면 **남의 탭에 들어갔다 온 것만으로
/// 내 탭이 새 값을 못 받는다.** 그래서 각 조회가 **자기 마지막 성공 조회**만 기준으로
/// 삼는다. 남의 조회는 내 시계를 밀지 못하고, 밀어 주지도 못한다.
///
/// 나눈 대가는 **키를 빠뜨릴 수 있다**는 것이다. 비우는 자리와 시각을 남기는 자리가
/// 같은 [ServerQuery] 를 써야 한다 — 비우기만 하면 스스로 받은 직후에도 stale 로
/// 읽혀 진입마다 조회가 한 번 더 나가고, 시각만 남기면 영원히 안 비워진다.
/// (칸이 하나였을 때는 시각을 안 남겨도 남이 대신 밀어 줘서 티가 안 났다. 지금은
/// 그 provider 만 조용히 어긋난다.)
///
/// 칸은 provider 단위이고 family 인자 단위가 아니다 — 무효화도 base 로 하므로
/// 결이 같다. 아직 한 번도 안 받은 조회는 맵에 없는데, 안 읽힌 provider 를 비우는
/// 것은 no-op 이라 그대로 두어도 손해가 없다.
class QueryFreshness {
  /// 웹 `staleTime` 과 같은 값.
  static const Duration ttl = Duration(seconds: 60);

  /// 조회별 마지막 성공 조회 시각. 한 번도 받은 적이 없으면 칸이 없다.
  final Map<ServerQuery, DateTime> _lastFetchedAt = <ServerQuery, DateTime>{};

  /// [query] provider 가 값을 만들어 냈다. 뒤로 가는 시계(수동 변경·DST)에도
  /// 기준이 미래에 박히지 않도록 **더 최근 것만** 남긴다.
  void markFetched(ServerQuery query, DateTime at) {
    final prev = _lastFetchedAt[query];
    if (prev == null || at.isAfter(prev)) _lastFetchedAt[query] = at;
  }

  /// [now] 기준으로 [query] 를 다시 받아야 하는가.
  ///
  /// 한 번도 안 받았으면 `true` — 비워도 no-op 이니 그냥 비운다.
  /// 경계는 웹 react-query 와 같게 **`>=`** 다(정확히 60초면 stale).
  bool isStaleAt(ServerQuery query, DateTime now) {
    final last = _lastFetchedAt[query];
    if (last == null) return true;
    return now.difference(last) >= ttl;
  }
}

/// 앱 세션 동안 유지되는 맵 — 화면을 다시 그릴 일이 없어 알림도 필요 없다.
/// (`Notifier` 로 두면 provider 가 값을 만드는 도중 상태를 바꾸게 되어 되레 위험하다.)
final queryFreshnessProvider = Provider<QueryFreshness>(
  (ref) => QueryFreshness(),
);

/// 시계 — 테스트가 진짜 60초를 기다리지 않도록 갈아 끼운다.
final freshnessClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

extension QueryFreshnessRef on Ref {
  /// [query] provider 가 값을 **성공적으로** 만든 직후, **자기 키로** 호출한다.
  /// (`await` 뒤에 두어야 실패한 조회가 시각을 갱신하지 않는다.)
  ///
  /// 키를 남의 것으로 주면 두 조회가 서로의 시계를 밀어 칸을 나눈 의미가 없어진다.
  void markQueryFetched(ServerQuery query) => read(
    queryFreshnessProvider,
  ).markFetched(query, read(freshnessClockProvider)());
}
