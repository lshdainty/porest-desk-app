/// 거래 집계의 **단 하나의 규칙** — 백엔드 `ExpenseAggregates` · 웹 `expense-aggregate.ts` 미러.
///
/// 두 가지를 지켜야 서버 값과 맞는다.
///   1. **아직 오지 않은 건 안 센다.** 반복거래는 미래분을 미리 만들어 두는데, 그걸 더하면
///      통장에 없는 급여가 이번 달 수입으로 잡힌다.
///   2. **환불은 수입이 아니라 지출 상계다.** 지출 50,000 + 환불 3,000 이면 47,000 이다.
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

/// 환불 = 수입으로 기록하되 원거래에 묶인 것. 수입이 아니라 지출을 깎는다.
bool isRefundTx(Expense e) =>
    e.expenseType == 'INCOME' && e.refundOfExpenseRowId != null;

/// 집계 대상만 남긴다.
Iterable<Expense> countableTx(Iterable<Expense> all) =>
    all.where((e) => !isScheduledTx(e.expenseDate));

/// 수입 합계 — 환불 제외.
int incomeSum(Iterable<Expense> all) => countableTx(all)
    .where((e) => e.expenseType == 'INCOME' && !isRefundTx(e))
    .fold<int>(0, (s, e) => s + e.amount.abs());

/// 지출 합계 — 환불이 음수로 상계된다.
int expenseSum(Iterable<Expense> all) => countableTx(all).fold<int>(
      0,
      (s, e) => s +
          (isRefundTx(e)
              ? -e.amount.abs()
              : e.expenseType == 'EXPENSE'
                  ? e.amount.abs()
                  : 0),
    );
