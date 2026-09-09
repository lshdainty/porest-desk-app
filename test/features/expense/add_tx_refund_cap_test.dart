// 환불 금액 상한 — **원거래 금액이 아니라 "원거래 금액 − 이미 환불된 금액"** (QA #152).
//
// 환불 시트는 연결 아이디만 싣고 금액엔 상한이 없었다. 12,000원 지출에 7,000원을
// 환불해 두고 다시 12,000원을 넣으면 환불 합계가 원거래를 넘어, 통계 상계가
// 원거래보다 커져 **지출이 수입으로 뒤집힌다.**
//
// 서버도 막지만(같은 묶음의 desk-back PR) 그건 저장을 누른 뒤다. 폼이 먼저 잠가야
// 사용자가 실패를 보고 나서 알지 않는다 — 금액칸에 이미 있는 상한 처리
// (`p_text_input_amount` 의 `amountMax` → `AmountLimitFormatter`)를 그대로 쓴다.
//
// 여기서 고정하는 것.
//   ① 남은 환불 가능액 계산 — 이미 환불된 만큼 깎이고, 음수로는 안 내려간다
//   ② 상한을 넘는 값은 **타이핑 자체가 안 된다**(거래 100억 상한과 같은 방식)
//   ③ **경계** — 정확히 남은 금액은 통과한다
//   ④ 이미 일부 환불된 거래는 **남은 금액으로 열린다** — 원거래 금액으로 열면
//      그대로 저장만 눌러도 넘는다(포매터는 타이핑만 막는다)
//   ⑤ 다 환불된 거래는 칸이 잠기고 저장이 막힌다
//   ⑥ 프리셋처럼 칸에 값을 **직접 꽂는** 경로로 넘어온 초과값은 저장이 막힌다
//   ⑦ 종류를 지출로 바꾸면 상한이 풀린다 — 원거래 연결도 그때는 안 실린다
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) "무엇이 보이고 무엇이 안 찍히는가" 를
// 위젯 테스트로 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/features/preset/domain/expense_template.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _expenseCategory = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

/// 환불은 수입으로 들어간다 — 고를 카테고리가 있어야 저장 가능 판정이 산다.
const _incomeCategory = ExpenseCategory(
  rowId: 9,
  categoryName: '환불금',
  expenseType: 'INCOME',
  sortOrder: 0,
  icon: 'undo-2',
  color: '#2f9e6e',
);

/// 환불할 원거래 — [refunded] 만큼은 이미 돌려받았다.
Expense _original({required int amount, int refunded = 0}) => Expense(
  rowId: 77,
  categoryRowId: _expenseCategory.rowId,
  expenseType: 'EXPENSE',
  amount: amount,
  refundCount: refunded > 0 ? 1 : 0,
  refundedAmount: refunded,
  expenseDate: '2026-09-01T12:00:00',
  merchant: '스타벅스',
);

/// 금액을 고정으로 들고 오는 수입 프리셋 — 칩을 누르면 금액칸에 **직접** 꽂힌다.
ExpenseTemplate _incomePreset(int amount) => ExpenseTemplate(
  rowId: 1,
  templateName: '환불분',
  expenseType: 'INCOME',
  categoryRowId: _incomeCategory.rowId,
  amount: amount,
  lockAmount: 'Y',
);

/// 금액칸 — 이 시트에서 `hintText: '0'` 인 칸은 금액뿐이다(수수료·이자는 이체 전용).
Finder get _amountField => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == '0',
);

String _amountText(WidgetTester tester) =>
    tester.widget<TextField>(_amountField).controller!.text;

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<AppLocalizations> _openRefund(
  WidgetTester tester,
  Expense original, {
  List<ExpenseTemplate> presets = const [],
}) async {
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
        presetListProvider.overrideWith((ref) async => presets),
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
              onPressed: () => showAddTxSheet(ctx, refundOf: original),
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
  group('남은 환불 가능액', () {
    test('금액 − 이미 환불된 금액이다', () {
      expect(_original(amount: 12000).refundableAmount, 12000);
      expect(_original(amount: 12000, refunded: 5000).refundableAmount, 7000);
      expect(_original(amount: 12000, refunded: 12000).refundableAmount, 0);
    });

    test('음수로는 안 내려간다 — 상한이 없던 시절의 초과 환불이 남아 있다', () {
      expect(_original(amount: 12000, refunded: 15000).refundableAmount, 0);
    });
  });

  testWidgets('환불이 없던 거래는 원거래 금액이 상한이다', (tester) async {
    final l = await _openRefund(tester, _original(amount: 12000));

    expect(_amountText(tester), '12000', reason: '원거래 금액으로 연다');
    expect(find.text(l.expRefundCap('12,000')), findsOneWidget);

    // 1원만 넘겨도 안 찍힌다 — 자릿수가 아니라 값으로 막는다.
    await tester.enterText(_amountField, '12001');
    await tester.pumpAndSettle();
    expect(_amountText(tester), '12000');

    // 자릿수를 늘려 붙여넣어도 마찬가지.
    await tester.enterText(_amountField, '99999999');
    await tester.pumpAndSettle();
    expect(_amountText(tester), '12000');
  });

  testWidgets('이미 일부 환불된 거래는 남은 금액이 상한이다 — 그 값으로 열린다', (tester) async {
    final l = await _openRefund(
      tester,
      _original(amount: 12000, refunded: 5000),
    );

    expect(
      _amountText(tester),
      '7000',
      reason: '원거래 금액(12,000)으로 열면 그대로 저장만 눌러도 합계가 원거래를 넘는다',
    );
    expect(find.text(l.expRefundCapLeft('5,000', '7,000')), findsOneWidget);

    await tester.enterText(_amountField, '12000');
    await tester.pumpAndSettle();
    expect(_amountText(tester), '7000', reason: '원거래 금액이라도 남은 금액을 넘으면 안 찍힌다');
  });

  testWidgets('정확히 남은 금액은 통과한다 (경계)', (tester) async {
    await _openRefund(tester, _original(amount: 12000, refunded: 5000));

    // 아래에서 올라와도 상한 정각은 그대로 들어간다.
    await tester.enterText(_amountField, '1000');
    await tester.pumpAndSettle();
    expect(_amountText(tester), '1000');

    await tester.enterText(_amountField, '7000');
    await tester.pumpAndSettle();
    expect(_amountText(tester), '7000');
    expect(
      tester.widget<PButton>(_submitButton('추가')).onPressed,
      isNotNull,
      reason: '상한 정각은 저장까지 열려 있어야 한다',
    );
  });

  testWidgets('원거래를 다 환불했으면 금액칸이 잠기고 저장이 막힌다', (tester) async {
    final l = await _openRefund(
      tester,
      _original(amount: 12000, refunded: 12000),
    );

    expect(find.text(l.expRefundCapUsedUp), findsOneWidget);
    expect(
      tester.widget<TextField>(_amountField).enabled,
      isFalse,
      reason: '상한 0 이면 한 글자도 안 찍힌다 — 살아 있는 칸으로 두면 고장으로 보인다',
    );
    expect(tester.widget<PButton>(_submitButton('추가')).onPressed, isNull);
  });

  testWidgets('프리셋이 상한을 넘긴 금액을 꽂으면 저장이 막힌다', (tester) async {
    // 포매터는 **타이핑만** 막는다. 프리셋 적용과 외화 환산은 금액칸에 값을 직접
    // 꽂으므로 그 경로로 들어온 초과값은 저장 직전 판정에서만 걸린다.
    final l = await _openRefund(
      tester,
      _original(amount: 12000, refunded: 5000),
      presets: [_incomePreset(50000)],
    );

    await tester.tap(find.text('환불분'));
    await tester.pumpAndSettle();

    expect(_amountText(tester), '50000', reason: '프리셋은 포매터를 안 거친다');
    expect(
      tester.widget<PButton>(_submitButton('추가')).onPressed,
      isNull,
      reason: '남은 7,000원을 넘겼다 — 400 을 받기 전에 여기서 막는다',
    );
    // 저장이 왜 죽었는지 같은 한 줄이 말해 준다.
    expect(find.text(l.expRefundCapLeft('5,000', '7,000')), findsOneWidget);
  });

  testWidgets('종류를 지출로 바꾸면 상한이 풀린다 — 원거래 연결도 그때는 안 실린다', (tester) async {
    final l = await _openRefund(
      tester,
      _original(amount: 12000, refunded: 5000),
    );
    expect(find.text(l.expRefundCapLeft('5,000', '7,000')), findsOneWidget);

    await tester.tap(find.text(l.expTypeExpense));
    await tester.pumpAndSettle();

    expect(find.text(l.expRefundCapLeft('5,000', '7,000')), findsNothing);
    await tester.enterText(_amountField, '50000');
    await tester.pumpAndSettle();
    expect(
      _amountText(tester),
      '50000',
      reason: '환불로 안 나가는 입력에 원거래 금액이 묶이면 안 된다',
    );
  });
}
