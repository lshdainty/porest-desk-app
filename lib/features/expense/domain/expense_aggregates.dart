/// 거래 집계의 **단 하나의 규칙** — 백엔드 `ExpenseAggregates` · 웹 `expense-aggregate.ts` 미러.
///
/// 두 가지를 지켜야 서버 값과 맞는다.
///   1. **아직 오지 않은 건 안 센다.** 반복거래는 미래분을 미리 만들어 두는데, 그걸 더하면
///      통장에 없는 급여가 이번 달 수입으로 잡힌다.
///   2. **환불된 건 안 센다.** 환불은 원거래에 찍는 표식이고, 표식이 찍힌 거래는 삭제와
///      똑같이 빠진다 — 지출 50,000 을 환불하면 그 달 지출에서 50,000 이 사라진다.
///
/// 이 규칙이 화면마다 흩어져 있어서 여러 번 빠뜨렸다 — 예산 이행률, 통계 일별 추이,
/// 캘린더 셀이 각각 다른 시점에 발견됐다. 거래를 합산하는 코드는 여기를 거칠 것.
library;

import 'package:porest_desk_app/features/expense/domain/expense.dart';

/// 아직 오지 않은 거래인가 — 서버도 이 기준으로 오늘까지만 센다.
bool isScheduledTx(String? date) {
  if (date == null) return false;
  final normalized = date.length == 10 ? '${date}T23:59:59' : date;
  return DateTime.parse(normalized).isAfter(DateTime.now());
}

/// 환불된 거래인가 — 원거래에 찍힌 표식 하나로 판정한다.
///
/// 종전엔 "수입 + 원거래 연결" 이었다. 환불이 수입 행을 만들던 모델인데, 그러면
/// 원거래 회차와 환불 날짜 회차에서 카드 청구가 두 번 깎였다.
bool isRefundedTx(Expense e) => e.refundedAt != null;

/// 집계 대상만 남긴다 — 아직 안 온 것과 **환불된 것**을 뺀다.
Iterable<Expense> countableTx(Iterable<Expense> all) =>
    all.where((e) => !isScheduledTx(e.expenseDate) && !isRefundedTx(e));

/// 수입 합계.
int incomeSum(Iterable<Expense> all) => countableTx(all)
    .where((e) => e.expenseType == 'INCOME')
    .fold<int>(0, (s, e) => s + e.amount.abs());

/// 지출 합계.
int expenseSum(Iterable<Expense> all) => countableTx(all)
    .where((e) => e.expenseType == 'EXPENSE')
    .fold<int>(0, (s, e) => s + e.amount.abs());
