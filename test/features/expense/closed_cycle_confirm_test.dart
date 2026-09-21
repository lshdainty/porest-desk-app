// 결제가 끝난 회차 — 확인창 **한 문구**와 결과 토스트가 화면에 실제로 뜨는가(D1·D4·D16).
//
// 예전엔 서버에 "얼마가 돌아오나" 를 미리 물어 다섯 갈래 문장을 골랐다(3초 제한·실패
// 폴백·예고 금액 비교). 닫힌 회차는 이제 기록만 바뀌므로 묻지 않는다. 여기서 잠그는 것은
//   ① 스와이프·상세의 삭제 확인창이 같은 한 문구를 붙인다 — 열린 회차엔 안 붙인다
//   ② 미리 낸 돈이 계좌로 돌아왔으면 사후 토스트로 알린다(스와이프 삭제 포함)
//   ③ 환불 확인창: 금액 단위 · 닫힌 회차 한 문구 · 환불일은 거래일~오늘
//   ④ 환불 취소: 옛 환급 이체가 묶인 거래만 "환급된 금액도 되돌아가요"
//   ⑤ 새 저장: 닫힌 회차로 가면 한 번 묻고, 물러나면 아무것도 안 보낸다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/data/expense_repository.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/expense_actions.dart';
import 'package:porest_desk_app/features/expense/presentation/refund_confirm_dialog.dart';
import 'package:porest_desk_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/features/expense_split/data/expense_split_repository.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_swipe_actions.dart';

const _closedLine = '이미 결제가 끝난 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요.';

/// 결제일 12일 카드 — 8월분(9/12 결제)까지 닫혔다.
const _card = Asset(
  rowId: 9,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 12,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);

const _category = ExpenseCategory(
  rowId: 11,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

/// 닫힌 회차(8월)의 카드 지출.
const _closed = Expense(
  rowId: 77,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 40000,
  merchant: '버스',
  expenseDate: '2026-08-20T10:00:00',
);

/// 열린 회차(9월)의 카드 지출.
final _open = _closed.copyWith(rowId: 78, expenseDate: '2026-09-10T10:00:00');

/// 부른 경로·인자를 잡고 정해 둔 응답을 돌려주는 가짜 레포지토리.
class _FakeRepo extends ExpenseRepository {
  _FakeRepo({this.refundedOnDelete, this.refundedOnRefund})
    : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  final int? refundedOnDelete;
  final int? refundedOnRefund;
  final deleted = <int>[];
  final created = <Map<String, Object?>>[];
  String? refundedAt;

  @override
  Future<int?> delete(int id) async {
    deleted.add(id);
    return refundedOnDelete;
  }

  @override
  Future<Expense> refund(int id, {String? refundedAt}) async {
    this.refundedAt = refundedAt;
    return _closed.copyWith(
      refundedAt: refundedAt,
      refundedAmount: refundedOnRefund,
    );
  }

  @override
  Future<Expense> create({
    required int categoryRowId,
    int? assetRowId,
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
  }) async {
    created.add({
      'assetRowId': assetRowId,
      'amount': amount,
      'expenseDate': expenseDate,
    });
    return _closed;
  }

  @override
  Future<Expense> update({
    required int id,
    required int categoryRowId,
    Patch<int> assetRowId = const Patch.keep(),
    required String expenseType,
    required int amount,
    required String expenseDate,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    Patch<int> installmentMonths = const Patch.keep(),
    Patch<double> originalAmount = const Patch.keep(),
    Patch<String> originalCurrency = const Patch.keep(),
    Patch<double> exchangeRate = const Patch.keep(),
    List<SplitInput>? splits,
  }) async => _open.copyWith(refundedAmount: 30000);
}

Future<void> _pumpApp(
  WidgetTester tester,
  Widget home, {
  required _FakeRepo repo,
}) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        assetsProvider.overrideWith((ref) async => const [_card]),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        merchantMonthExpensesProvider.overrideWith(
          (ref, key) async => const [],
        ),
        hideCardProvider.overrideWith((ref, card) => false),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: SlidableAutoCloseBehavior(child: home)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 토스트가 스스로 닫히게 둔다 — 남은 타이머가 있으면 테스트가 끝나며 실패한다.
Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}

/// 스와이프 액션만 단 행 하나 — 가계부 목록과 같은 조립(`expenseActions.swipeActions`).
Widget _swipeRow(Expense e) => Consumer(
  builder: (ctx, ref, _) => PSwipeActions(
    groupTag: 'test',
    actions: expenseActions.swipeActions(ctx, ref, e, asset: _card),
    child: const SizedBox(
      height: 64,
      width: double.infinity,
      child: Text('거래 행'),
    ),
  ),
);

Future<void> _swipeDelete(WidgetTester tester) async {
  await tester.drag(find.text('거래 행'), const Offset(-300, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('삭제'));
  await tester.pumpAndSettle();
}

Widget _opener(void Function(BuildContext) open) => Builder(
  builder: (ctx) =>
      TextButton(onPressed: () => open(ctx), child: const Text('open')),
);

void main() {
  group('스와이프 삭제', () {
    testWidgets('닫힌 회차 카드 거래는 확인창에 한 문구가 붙는다', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(tester, _swipeRow(_closed), repo: repo);

      await _swipeDelete(tester);

      expect(find.textContaining('"버스" 거래를 삭제할까요?'), findsOneWidget);
      expect(find.textContaining(_closedLine), findsOneWidget);
    });

    testWidgets('열린 회차는 문구가 없다', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(tester, _swipeRow(_open), repo: repo);

      await _swipeDelete(tester);

      expect(find.textContaining('"버스" 거래를 삭제할까요?'), findsOneWidget);
      expect(find.textContaining(_closedLine), findsNothing);
      expect(find.textContaining('환급'), findsNothing, reason: '예고 문구는 걷었다');
    });

    testWidgets('미리 낸 돈이 돌아오면 지운 뒤 토스트로 알린다(D4)', (tester) async {
      final repo = _FakeRepo(refundedOnDelete: 30000);
      await _pumpApp(tester, _swipeRow(_open), repo: repo);

      await _swipeDelete(tester);
      // 확인창의 [삭제] — 트레이는 닫혔으니 남은 '삭제' 는 확인 버튼이다.
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      expect(repo.deleted, [78]);
      expect(find.text('미리 낸 돈 중 30,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });

    testWidgets('돌려준 돈이 없으면 토스트도 없다', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(tester, _swipeRow(_open), repo: repo);

      await _swipeDelete(tester);
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      expect(repo.deleted, [78]);
      expect(find.textContaining('계좌로 돌아왔어요'), findsNothing);
    });
  });

  group('상세 삭제', () {
    testWidgets('스와이프와 같은 문구 — 닫힌 회차 한 줄', (tester) async {
      final repo = _FakeRepo(refundedOnDelete: 12000);
      await _pumpApp(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _closed)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.textContaining(_closedLine), findsOneWidget);

      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.deleted, [77]);
      expect(find.text('미리 낸 돈 중 12,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });
  });

  group('환불 확인창', () {
    testWidgets('금액에 단위가 붙고, 닫힌 회차면 한 문구를 말한다', (tester) async {
      await _pumpApp(
        tester,
        _opener(
          (ctx) => showRefundConfirmDialog(ctx, expense: _closed, asset: _card),
        ),
        repo: _FakeRepo(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('40,000원을 현대카드(으)로'), findsOneWidget);
      expect(find.text(_closedLine), findsOneWidget);
    });

    testWidgets('열린 회차 + 결제계좌 없는 카드는 그 안내만', (tester) async {
      await _pumpApp(
        tester,
        _opener(
          (ctx) => showRefundConfirmDialog(
            ctx,
            expense: _open,
            asset: _card.copyWith(paymentAssetRowId: null),
          ),
        ),
        repo: _FakeRepo(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(_closedLine), findsNothing);
      expect(find.text('결제계좌가 없어 카드 잔액만 정리돼요.'), findsOneWidget);
    });

    testWidgets('환불일은 거래일부터 오늘까지만 고를 수 있다(D16)', (tester) async {
      await _pumpApp(
        tester,
        _opener(
          (ctx) => showRefundConfirmDialog(ctx, expense: _closed, asset: _card),
        ),
        repo: _FakeRepo(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final input = tester.widget<PDateInput>(find.byType(PDateInput));
      final now = DateTime.now();
      expect(input.firstDate, DateTime(2026, 8, 20));
      expect(input.lastDate, DateTime(now.year, now.month, now.day));
      expect(input.value, DateTime(now.year, now.month, now.day));
    });

    test('범위는 날짜만 본다 — 거래 시각 때문에 당일이 빠지지 않는다', () {
      final r = refundDateRange(
        _closed.copyWith(expenseDate: '2026-09-21T23:59:00'),
        now: DateTime(2026, 9, 21, 8),
      );
      expect(r.first, DateTime(2026, 9, 21));
      expect(r.last, DateTime(2026, 9, 21));
    });

    test('아직 오지 않은 거래면 범위가 뒤집히지 않게 오늘로 좁힌다', () {
      final r = refundDateRange(
        _closed.copyWith(expenseDate: '2026-10-01T09:00:00'),
        now: DateTime(2026, 9, 21, 8),
      );
      expect(r.first, DateTime(2026, 9, 21));
      expect(r.last, DateTime(2026, 9, 21));
    });

    testWidgets('환불해서 미리 낸 돈이 돌아오면 토스트로 알린다(D4)', (tester) async {
      final repo = _FakeRepo(refundedOnRefund: 8000);
      await _pumpApp(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _open)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('환불'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('환불 처리').last);
      await tester.pumpAndSettle();

      expect(repo.refundedAt, endsWith('T12:00:00'));
      expect(find.text('미리 낸 돈 중 8,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });
  });

  group('환불 취소', () {
    Future<void> openCancel(WidgetTester tester, Expense e) async {
      await _pumpApp(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, e)),
        repo: _FakeRepo(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('환불 취소'));
      await tester.pumpAndSettle();
    }

    testWidgets('옛 환급 이체가 묶인 거래만 "환급된 금액도 되돌아가요"', (tester) async {
      await openCancel(
        tester,
        _closed.copyWith(
          refundedAt: '2026-09-15T12:00:00',
          refundTransferRowId: 501,
        ),
      );

      expect(find.textContaining('환급된 금액도 되돌아가요'), findsOneWidget);
      expect(
        find.textContaining(_closedLine),
        findsNothing,
        reason: '그 이체는 통장에서 다시 빠진다 — "잔액 그대로" 는 거짓이 된다',
      );
    });

    testWidgets('표식만 풀리는 닫힌 회차 거래는 기록만 바뀐다고 말한다', (tester) async {
      await openCancel(
        tester,
        _closed.copyWith(refundedAt: '2026-09-15T12:00:00'),
      );

      expect(find.textContaining('환급된 금액도 되돌아가요'), findsNothing);
      expect(find.textContaining('이 거래가 합계에 다시 들어가요.'), findsOneWidget);
      expect(find.textContaining(_closedLine), findsOneWidget);
    });
  });

  group('새 저장', () {
    Future<_FakeRepo> openAndFill(WidgetTester tester, String date) async {
      final repo = _FakeRepo();
      await _pumpApp(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, defaultDate: date)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '13000');
      await tester.pump();
      await tester.tap(find.text('식비').last);
      await tester.pumpAndSettle();
      // 계좌·카드 선택 — '선택 안 함' 이 둘(결제 수단·자산)이라 마지막 것이 자산이다.
      await tester.tap(find.text('선택 안 함').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('현대카드').last);
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('닫힌 회차 날짜면 한 번 묻고, 물러나면 보내지 않는다', (tester) async {
      final repo = await openAndFill(tester, '2026-08-20');

      await tester.tap(find.text('추가').last);
      await tester.pumpAndSettle();
      expect(find.text('저장할까요?'), findsOneWidget);
      expect(find.text(_closedLine), findsOneWidget);

      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      expect(repo.created, isEmpty);

      await tester.tap(find.text('추가').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();
      expect(repo.created.single['assetRowId'], 9);
    });

    testWidgets('열린 회차는 묻지 않고 저장한다', (tester) async {
      final repo = await openAndFill(tester, '2026-09-10');

      await tester.tap(find.text('추가').last);
      await tester.pumpAndSettle();

      expect(find.text('저장할까요?'), findsNothing);
      expect(repo.created, hasLength(1));
    });
  });

  group('편집 저장', () {
    testWidgets('미리 낸 돈이 돌아오면 저장 뒤 토스트로 알린다(D4)', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, edit: _open)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();

      expect(find.text('미리 낸 돈 중 30,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });
  });
}
