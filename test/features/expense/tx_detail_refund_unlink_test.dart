// 환불 취소 — 거래 상세에서 원거래와의 연결만 끊는다 (QA 12차 D3).
//
// 편집 저장으로는 못 끊는다. 편집 시트에 환불 연결 칸이 없어 저장 본문에서 그 키를
// 통째로 빼기 때문이다 — 안 그러면 메모만 고쳐도 연결이 끊겨 원거래의 지출 상계가
// 사라진다(QA #108). 그래서 "끊어라" 를 보낼 자리가 아예 없었고, 잘못 묶인 환불은
// 지우고 다시 넣는 수밖에 없었다.
//
// 여기서 고정하는 것은 셋이다.
//   ① 버튼은 **환불 거래일 때만** 보인다 — 수입이면서 원거래에 묶인 거래
//   ② 누르면 확인을 받는다. 취소하면 아무것도 안 나간다
//   ③ 확인하면 본문에 `refundOfExpenseRowId` 가 **명시적 null 로** 실리고,
//      **다른 키는 안 실린다** — 서버가 안 온 칸을 그대로 두므로(QA #96) 화면이
//      들고 있던 옛 금액·카테고리를 다시 실으면 그 사이 바뀐 값을 덮는다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/data/expense_repository.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 환불 거래 — 수입으로 기록하되 원거래(77)에 묶여 있다.
const _refundTx = Expense(
  rowId: 42,
  expenseType: 'INCOME',
  amount: 3000,
  categoryRowId: 5,
  categoryName: '환불',
  expenseDate: '2026-09-08T12:00:00',
  refundOfExpenseRowId: 77,
);

/// 서버가 연결을 끊고 돌려주는 모습 — 같은 거래인데 원거래 연결만 없다.
const _unlinkedJson = {
  'rowId': 42,
  'expenseType': 'INCOME',
  'amount': 3000,
  'categoryRowId': 5,
  'categoryName': '환불',
  'expenseDate': '2026-09-08T12:00:00',
  'refundOfExpenseRowId': null,
};

/// 요청 바디를 잡아 두고 [_unlinkedJson] 을 돌려주는 Dio.
(Dio, List<Map<String, dynamic>> captured) _capturingDio() {
  final captured = <Map<String, dynamic>>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add((options.data as Map).cast<String, dynamic>());
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': _unlinkedJson,
            },
          ),
        );
      },
    ),
  );
  return (dio, captured);
}

Future<AppLocalizations> _open(
  WidgetTester tester,
  Expense expense,
  Dio dio,
) async {
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith(
          (ref) async => ExpenseRepository(dio),
        ),
        categoriesProvider.overrideWith((ref) async => []),
        assetsProvider.overrideWith((ref) async => []),
        expenseSplitsProvider(expense.rowId).overrideWith((ref) async => []),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showTxDetailDialog(ctx, expense),
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

/// 확인창의 버튼 — 시트 버튼·확인창 제목과 문구가 겹쳐서 두 번 좁힌다.
Finder _dialogButton(String label) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(PButton, label),
);

void main() {
  testWidgets('환불 거래에는 환불 취소 버튼이 보인다', (tester) async {
    final (dio, _) = _capturingDio();
    final l = await _open(tester, _refundTx, dio);

    expect(find.text(l.expRefundOfLinked), findsOneWidget);
    expect(find.text(l.expRefundUnlink), findsOneWidget);
  });

  testWidgets('원거래에 안 묶인 수입에는 안 보인다', (tester) async {
    final (dio, _) = _capturingDio();
    // 같은 수입인데 연결만 없다 — 이게 없으면 "수입이면 다 보인다" 가 통과한다.
    final l = await _open(
      tester,
      _refundTx.copyWith(refundOfExpenseRowId: null),
      dio,
    );

    expect(find.text(l.expRefundOfLinked), findsNothing);
    expect(find.text(l.expRefundUnlink), findsNothing);
  });

  testWidgets('지출에 연결이 남아 있어도 안 보인다', (tester) async {
    final (dio, _) = _capturingDio();
    // 환불은 수입일 때만 상계를 만든다 — 지출에 붙은 연결은 환불이 아니다.
    // 이게 없으면 "연결만 있으면 보인다" 가 통과한다.
    final l = await _open(
      tester,
      _refundTx.copyWith(expenseType: 'EXPENSE'),
      dio,
    );

    expect(find.text(l.expRefundOfLinked), findsNothing);
    expect(find.text(l.expRefundUnlink), findsNothing);
  });

  testWidgets('확인하면 refundOfExpenseRowId 만 명시적 null 로 실린다', (tester) async {
    final (dio, captured) = _capturingDio();
    final l = await _open(tester, _refundTx, dio);

    await tester.tap(find.text(l.expRefundUnlink));
    await tester.pumpAndSettle();
    // 곧바로 나가지 않는다 — 되돌릴 칸이 없어 확인을 받는다.
    expect(captured, isEmpty);
    expect(find.text(l.expRefundUnlinkConfirm), findsOneWidget);

    await tester.tap(_dialogButton(l.expRefundUnlink));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    final body = captured.single;
    expect(
      body.containsKey('refundOfExpenseRowId'),
      isTrue,
      reason: '키가 빠지면 서버가 옛 연결을 지킨다',
    );
    expect(body['refundOfExpenseRowId'], isNull, reason: 'null 이어야 끊긴다');
    expect(body.keys, [
      'refundOfExpenseRowId',
    ], reason: '다른 칸을 실으면 화면이 들고 있던 옛 값이 그 사이 바뀐 값을 덮는다');

    // 끊긴 결과가 그 자리에서 보인다 — 배너가 사라진다.
    expect(find.text(l.expRefundOfLinked), findsNothing);
  });

  testWidgets('확인창에서 취소하면 아무것도 안 나간다', (tester) async {
    final (dio, captured) = _capturingDio();
    final l = await _open(tester, _refundTx, dio);

    await tester.tap(find.text(l.expRefundUnlink));
    await tester.pumpAndSettle();
    await tester.tap(_dialogButton(l.actionCancel));
    await tester.pumpAndSettle();

    expect(captured, isEmpty);
    expect(find.text(l.expRefundOfLinked), findsOneWidget);
  });
}
