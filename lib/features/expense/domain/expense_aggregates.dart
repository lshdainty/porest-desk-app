/// 거래 집계의 **단 하나의 규칙** — 백엔드 `ExpenseAggregates` · 웹 `expense-aggregate.ts` 미러.
///
/// 두 가지를 지켜야 서버 값과 맞는다.
///   1. **아직 오지 않은 건 안 센다.** 반복거래는 미래분을 미리 만들어 두는데, 그걸 더하면
///      통장에 없는 급여가 이번 달 수입으로 잡힌다.
///   2. **환불된 건 안 센다.** 환불은 원거래에 찍는 표식이고, 표식이 찍힌 거래는 삭제와
///      똑같이 빠진다 — 지출 50,000 을 환불하면 그 달 지출에서 50,000 이 사라진다.
///   3. **카드 이월은 안 센다.** 카드를 만들 때 적은 "이전 미결제 사용액"(D4)은 앱을 쓰기
///      전에 이미 쓴 돈이라 등록한 달의 지출이 아니다.
///
/// 여기 있는 합계는 전부 **가계부 숫자**다. 카드 청구·한도 사용은 서버가 내려 주고 그쪽은
/// 이월을 포함한다 — 빼면 "잔액 = 거래 합"(D4)이 풀린다.
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

/// 카드 이월 거래인가 — 카드를 만들 때 적은 "이전 미결제 사용액"(D4).
///
/// 등록 전에 이미 쓴 돈이라 그 달의 지출이 아니다. 목록에는 보이고(자동 생성이라 수정·삭제는
/// 잠겨 있다) 합계에서만 빠진다.
bool isCardCarryoverTx(Expense e) => e.autoSource == 'CARD_CARRYOVER';

/// 집계 대상만 남긴다 — 아직 안 온 것 · **환불된 것** · **카드 이월**을 뺀다.
Iterable<Expense> countableTx(Iterable<Expense> all) => all.where(
  (e) =>
      !isScheduledTx(e.expenseDate) &&
      !isRefundedTx(e) &&
      !isCardCarryoverTx(e),
);

/// 수입 합계.
int incomeSum(Iterable<Expense> all) => countableTx(all)
    .where((e) => e.expenseType == 'INCOME')
    .fold<int>(0, (s, e) => s + e.amount.abs());

/// 지출 합계.
int expenseSum(Iterable<Expense> all) => countableTx(all)
    .where((e) => e.expenseType == 'EXPENSE')
    .fold<int>(0, (s, e) => s + e.amount.abs());

/// 카드 쪽 합계 대상 — 이월을 **포함**한다.
///
/// 자산 상세의 이용 내역이 쓴다. 그 화면은 "이 카드로 쓴 것" 을 보여 주는 자리라, 목록에
/// 이월 거래가 있는데 그날 합계에서만 빠지면 같은 화면 안에서 숫자가 안 맞는다.
/// 가계부 쪽은 [countableTx] 다.
Iterable<Expense> cardCountableTx(Iterable<Expense> all) =>
    all.where((e) => !isScheduledTx(e.expenseDate) && !isRefundedTx(e));

/// 카드 쪽 수입 합계 — 이월 포함.
int cardIncomeSum(Iterable<Expense> all) => cardCountableTx(all)
    .where((e) => e.expenseType == 'INCOME')
    .fold<int>(0, (s, e) => s + e.amount.abs());

/// 카드 쪽 지출 합계 — 이월 포함.
int cardExpenseSum(Iterable<Expense> all) => cardCountableTx(all)
    .where((e) => e.expenseType == 'EXPENSE')
    .fold<int>(0, (s, e) => s + e.amount.abs());
