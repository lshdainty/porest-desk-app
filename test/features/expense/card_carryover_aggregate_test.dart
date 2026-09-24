// 카드 이월 거래는 **가계부 합계에서만** 빠진다(D4 후속 결정, 2026-09-18).
//
// 카드를 만들 때 적은 "이전 미결제 사용액" 은 앱을 쓰기 전에 이미 쓴 돈이다. 그걸 지출
// 합계에 세면 카드를 등록한 달만 몇십만 원이 솟는다 — 그 달에 쓴 돈이 아니다.
//
// 반대로 카드 쪽에서는 빼면 안 된다. 그 거래가 곧 카드의 미결제 잔액이고 첫 회차 청구라,
// 빼는 순간 D4("잔액 = 거래 합")가 풀린다. 그래서 규칙이 둘이고, 같은 목록을 넣어 나란히 본다.
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_aggregates.dart';

Expense tx({
  int rowId = 1,
  int amount = 12000,
  String? autoSource,
  String type = 'EXPENSE',
}) => Expense(
  rowId: rowId,
  expenseType: type,
  amount: amount,
  expenseDate: '2026-09-10T12:00:00',
  autoSource: autoSource,
);

void main() {
  final plain = tx();
  final carryover = tx(rowId: 2, amount: 300000, autoSource: 'CARD_CARRYOVER');

  test('가계부 합계에는 이월 30만이 없다 — 등록한 달의 지출이 아니다', () {
    expect(expenseSum([plain, carryover]), 12000);
    expect(countableTx([plain, carryover]).map((e) => e.rowId), [1]);
  });

  test('카드 쪽 합계에는 그대로 있다 — 빼면 잔액 = 거래 합이 풀린다', () {
    expect(cardExpenseSum([plain, carryover]), 312000);
    expect(cardCountableTx([plain, carryover]).map((e) => e.rowId), [1, 2]);
  });

  test('다른 시스템 거래는 가계부에도 남는다 — 이월만 빼는 규칙이다', () {
    // 자동 생성 전부를 빼면 매도 실현손익·이체 이자가 합계에서 사라진다.
    final realized = tx(rowId: 3, amount: 5000, autoSource: 'TRADE_REALIZED');
    expect(expenseSum([realized]), 5000);
    expect(isCardCarryoverTx(realized), isFalse);
  });

  test('판정은 autoSource 하나다', () {
    expect(isCardCarryoverTx(carryover), isTrue);
    expect(isCardCarryoverTx(plain), isFalse);
  });

  // 결제일 전에 등록하며 따로 적은 지난달 청구분(2026-09-22)도 등록 전에 쓴 돈이다.
  test('결제 대기 청구분도 같은 이월이다 — 가계부에서 빠지고 카드에는 남는다', () {
    final due = tx(rowId: 4, amount: 120000, autoSource: 'CARD_CARRYOVER_DUE');
    expect(isCardCarryoverTx(due), isTrue);
    expect(expenseSum([plain, due]), 12000);
    expect(cardExpenseSum([plain, due]), 132000);
  });
}
