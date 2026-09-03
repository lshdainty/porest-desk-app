// 반복 거래 요약 카드의 금액 부호 — QA #69(홈 밖에 남아 있던 `-0`·ASCII 하이픈).
//
// 홈(`dashboard_amount_sign_test.dart`)과 **같은 규칙**이다. 규칙은 이제 한 곳에
// 있다 — `core/format/krw.dart` 의 `minusOf`(웹 `shared/lib/porest/format.ts` 미러).
//   0   → 부호 없음  (반복 거래가 하나도 없을 때 `-0` 이 뜨던 자리)
//   양수 → U+2212 `−`
//
// 수입 쪽도 같은 규칙이다(`plusOf`) — 지출만 고쳐 두는 바람에 매월 고정 수입은
// `+0` 으로 남아 있었다. 같은 카드 안에서 한쪽은 `0`, 한쪽은 `+0` 이었다.
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 띄워 글자를 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/recurring/application/recurring_providers.dart';
import 'package:porest_desk_app/features/recurring/domain/recurring_transaction.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_screen.dart';

/// 매월 고정 지출로 잡히는 한 건 — 활성 · MONTHLY · EXPENSE.
RecurringTransaction _monthlyExpense(int amount) => RecurringTransaction(
  rowId: 1,
  expenseType: 'EXPENSE',
  amount: amount,
  frequency: 'MONTHLY',
  isActive: 'Y',
);

/// 매월 고정 수입으로 잡히는 한 건 — 활성 · MONTHLY · INCOME.
RecurringTransaction _monthlyIncome(int amount) => RecurringTransaction(
  rowId: 2,
  expenseType: 'INCOME',
  amount: amount,
  frequency: 'MONTHLY',
  isActive: 'Y',
);

Future<void> _pumpRecurring(
  WidgetTester tester,
  List<RecurringTransaction> items,
) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recurringListProvider.overrideWith((ref) async => items),
        categoriesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const RecurringScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('반복 거래가 없으면 매월 고정 지출이 `-0` 이 아니라 `0` 이다', (tester) async {
    await _pumpRecurring(tester, const []);

    // 옛 코드는 `sign: '-'` 를 무조건 붙여 `-0` 을 냈다.
    expect(find.text('-0'), findsNothing);
    expect(find.text('−0'), findsNothing);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('고정 지출이 있으면 U+2212 로 찍는다 — ASCII 하이픈이 아니다', (tester) async {
    await _pumpRecurring(tester, [_monthlyExpense(51750)]);

    // 요약 카드와 목록 행 — 한 화면 안 두 자리가 같은 기호를 쓴다
    // (QA #22 는 한 카드에서 `−`/`-` 가 섞여 tabular 정렬이 어긋난 걸 잡았다).
    expect(find.text('−51,750'), findsNWidgets(2));
    expect(find.text('-51,750'), findsNothing);
  });

  testWidgets('반복 수입이 없으면 매월 고정 수입이 `+0` 이 아니라 `0` 이다', (tester) async {
    // 지출만 있는(= 수입이 없는) 계정. 카드 왼쪽 지출은 `−51,750`, 오른쪽 수입은
    // 0 인데 옛 코드는 `sign: '+'` 를 무조건 붙여 `+0` 을 냈다.
    await _pumpRecurring(tester, [_monthlyExpense(51750)]);

    expect(find.text('+0'), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('고정 수입이 있으면 `+` 를 붙인다', (tester) async {
    await _pumpRecurring(tester, [_monthlyIncome(990000)]);

    // 요약 카드 + 목록 행. 0 일 때만 부호를 떼는 것이지 부호 자체가 사라지면 안 된다.
    expect(find.text('+990,000'), findsNWidgets(2));
  });

  testWidgets('금액이 0 인 반복 거래는 행에도 부호가 없다', (tester) async {
    // `amount` 는 모델 기본값이 0 이라 서버가 안 주면 그대로 0 으로 온다.
    await _pumpRecurring(tester, [_monthlyIncome(0), _monthlyExpense(0)]);

    expect(find.text('+0'), findsNothing);
    expect(find.text('−0'), findsNothing);
    expect(find.text('-0'), findsNothing);
  });
}
