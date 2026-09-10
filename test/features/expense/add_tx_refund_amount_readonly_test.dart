// 환불 행은 **금액을 못 고친다** — 환불은 만들고 취소하는 것이지 고치는 게 아니다.
//
// 환불 행은 평범한 수입 행(`INCOME` + 원거래 연결)이라 가계부 목록에 섞이고, 거기서
// **표준 수정 경로**에 그대로 걸린다. 그래서 금액칸이 열려 있었다. 서버(#330)는 상한
// 초과만 400 으로 막으므로 **상한 안에서는 자유롭게 고쳐진다** — 12,000원 지출에 달린
// 3,000원 환불을 9,000원으로 바꿔도 통과하고, 그 순간 원거래의 지출 상계액이 조용히
// 달라진다. 금액이 틀렸으면 **환불을 지우고 다시 넣는다**(삭제는 그대로 열려 있다).
//
// 여기서 고정하는 것.
//   ① 환불 행을 편집하면 금액칸이 잠기고 **왜 잠겼는지**가 보인다
//   ② **평범한 수입 행은 그대로 열린다** — 판정이 `INCOME` 하나로 넓어지면
//      월급·이자까지 못 고친다(과잉 차단)
//   ③ **환불이 달린 원거래**도 그대로 열린다 — 환불과 이어진 행이라고 잠기면 안 된다
//   ④ **새 환불을 만드는 모드는 금액을 친다** — 얼마를 돌려받았는지 쓰는 자리다.
//      #342 의 상한(남은 환불 가능액)은 그대로 산다
//   ⑤ 환불 행의 **메모·날짜는 여전히 고칠 수 있다** — 잠그는 건 금액 하나다
//
// 판정은 집계와 같은 규칙(`isRefundTx`)이다 — 여기서 조건을 다시 쓰면 상계에 드는
// 행과 잠기는 행이 갈린다.
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) "무엇이 잠기고 무엇이 열리는가" 를
// 위젯 테스트로 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_aggregates.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/features/expense_split/domain/expense_split.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';

const _expenseCategory = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _incomeCategory = ExpenseCategory(
  rowId: 9,
  categoryName: '환불금',
  expenseType: 'INCOME',
  sortOrder: 0,
  icon: 'undo-2',
  color: '#2f9e6e',
);

/// 원거래 — 12,000원 지출에 3,000원이 환불돼 있다.
const _original = Expense(
  rowId: 77,
  categoryRowId: 5,
  expenseType: 'EXPENSE',
  amount: 12000,
  refundCount: 1,
  refundedAmount: 3000,
  expenseDate: '2026-09-01T12:00:00',
  merchant: '스타벅스',
);

/// 그 환불 행 — 수입인데 원거래에 묶여 있다. 목록에선 평범한 수입처럼 보인다.
const _refundRow = Expense(
  rowId: 78,
  categoryRowId: 9,
  expenseType: 'INCOME',
  amount: 3000,
  refundOfExpenseRowId: 77,
  expenseDate: '2026-09-02T12:00:00',
  merchant: '스타벅스',
  description: '일부 환불',
);

/// 평범한 수입 행 — 원거래 연결이 없다(월급·이자가 여기다).
const _plainIncome = Expense(
  rowId: 79,
  categoryRowId: 9,
  expenseType: 'INCOME',
  amount: 3000,
  expenseDate: '2026-09-02T12:00:00',
  merchant: '회사',
);

/// 금액칸 — 이 시트에서 `hintText: '0'` 인 칸은 금액뿐이다(수수료·이자는 이체 전용).
Finder get _amountField => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == '0',
);

Finder _memoField(AppLocalizations l) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == l.expMemoPlaceholder,
);

String _amountText(WidgetTester tester) =>
    tester.widget<TextField>(_amountField).controller!.text;

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<AppLocalizations> _open(
  WidgetTester tester,
  void Function(BuildContext ctx) show,
) async {
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith(
          (ref) async => [_expenseCategory, _incomeCategory],
        ),
        assetsProvider.overrideWith((ref) async => []),
        presetListProvider.overrideWith((ref) async => []),
        // 편집 모드는 기존 분할을 적재한다 — 실제 provider 는 dio 를 타므로 비운다.
        expenseSplitsProvider.overrideWith(
          (ref, id) async => const <ExpenseSplit>[],
        ),
        // 실제 provider 는 `/me/preferences` 를 탄다 — 값만 흘려보낸다.
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => show(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('ko'));
}

void main() {
  group('환불 판정은 집계와 같은 규칙이다', () {
    test('수입 + 원거래 연결이 환불이다', () {
      expect(isRefundTx(_refundRow), isTrue);
      expect(isRefundTx(_plainIncome), isFalse, reason: '연결 없는 수입은 그냥 수입이다');
      expect(isRefundTx(_original), isFalse, reason: '환불이 달린 지출은 원거래다');
    });
  });

  testWidgets('환불 행을 편집하면 금액칸이 잠기고 이유가 보인다', (tester) async {
    final l = await _open(
      tester,
      (ctx) => showAddTxSheet(ctx, edit: _refundRow),
    );

    expect(
      tester.widget<TextField>(_amountField).enabled,
      isFalse,
      reason: '상한 안에서 고쳐지면 원거래의 지출 상계액이 조용히 달라진다',
    );
    expect(_amountText(tester), '3000', reason: '못 고칠 뿐, 얼마인지는 보여야 한다');
    // 잠긴 칸만 보여 주면 고장으로 보인다 — 대신 할 일까지 말해 준다.
    expect(find.text(l.expRefundAmountLocked), findsOneWidget);
  });

  testWidgets('평범한 수입 행은 금액칸이 그대로 열린다', (tester) async {
    // 판정이 `INCOME` 하나로 넓어지면 월급·이자까지 못 고친다.
    final l = await _open(
      tester,
      (ctx) => showAddTxSheet(ctx, edit: _plainIncome),
    );

    expect(tester.widget<TextField>(_amountField).enabled, isTrue);
    expect(find.text(l.expRefundAmountLocked), findsNothing);

    await tester.enterText(_amountField, '5000');
    await tester.pumpAndSettle();
    expect(_amountText(tester), '5000', reason: '환불이 아닌 수입은 금액을 고칠 수 있어야 한다');
  });

  testWidgets('환불이 달린 원거래도 금액칸이 열린다', (tester) async {
    // 환불과 이어져 있을 뿐 원거래는 원거래다 — 여기가 잠기면 오타 하나를 못 고친다.
    final l = await _open(
      tester,
      (ctx) => showAddTxSheet(ctx, edit: _original),
    );

    expect(tester.widget<TextField>(_amountField).enabled, isTrue);
    expect(find.text(l.expRefundAmountLocked), findsNothing);
  });

  testWidgets('새 환불을 만드는 모드는 금액을 칠 수 있다 — #342 상한은 그대로', (tester) async {
    // **편집 모드와 반대편이다.** 얼마를 돌려받았는지 쓰는 자리라 금액이 열려야 한다.
    final l = await _open(
      tester,
      (ctx) => showAddTxSheet(ctx, refundOf: _original),
    );

    expect(tester.widget<TextField>(_amountField).enabled, isTrue);
    expect(find.text(l.expRefundAmountLocked), findsNothing);
    // 남은 환불 가능액(12,000 − 3,000)으로 열리고 그 상한이 그대로 산다.
    expect(_amountText(tester), '9000');
    expect(find.text(l.expRefundCapLeft('3,000', '9,000')), findsOneWidget);

    await tester.enterText(_amountField, '4000');
    await tester.pumpAndSettle();
    expect(_amountText(tester), '4000', reason: '부분 환불은 금액을 낮춰 칠 수 있어야 한다');

    await tester.enterText(_amountField, '9001');
    await tester.pumpAndSettle();
    expect(
      _amountText(tester),
      '4000',
      reason: '#342 상한은 그대로다 — 남은 금액을 넘으면 안 찍힌다',
    );
  });

  testWidgets('환불 행의 메모·날짜는 여전히 고칠 수 있다', (tester) async {
    // 잠그는 건 금액 하나다. 분류를 못 고치게 하면 잘못 꽂힌 카테고리를 영원히 못 옮긴다.
    final l = await _open(
      tester,
      (ctx) => showAddTxSheet(ctx, edit: _refundRow),
    );

    expect(tester.widget<TextField>(_memoField(l)).enabled, isTrue);
    await tester.enterText(_memoField(l), '카드 취소분');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_memoField(l)).controller!.text, '카드 취소분');

    expect(
      tester.widget<PDateInput>(find.byType(PDateInput)).enabled,
      isTrue,
      reason: '환불 날짜는 손으로 적는 값이다 — 잘못 찍은 날짜를 못 고치면 안 된다',
    );

    // 금액이 잠겼다고 저장이 죽으면 메모·날짜 수정 자체가 막힌다.
    expect(
      tester.widget<PButton>(_submitButton(l.actionSave)).onPressed,
      isNotNull,
    );
  });
}
