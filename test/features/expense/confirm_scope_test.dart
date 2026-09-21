// 확인창은 돈과 기록이 갈리는 자리에만(Q1) — 사용자 결정 2026-09-21. 웹도 같은
// 규칙이다.
//
// Q1 저장 확인창
//   - 잠긴 거래(결제 끝남)의 편집 저장 — 묻지 않고 한 번에 저장한다(카테고리·가맹점·
//     메모만 바뀐다)
//   - 열린 회차 거래를 닫힌 회차 날짜로 옮기는 편집 저장 — 묻는다
//   - 열린 회차 거래를 열린 회차 안에서 고치는 저장 — 묻지 않는다
//   - 닫힌 회차로 들어가는 새 저장 — 묻는다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/features/expense_split/data/expense_split_repository.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

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

/// 열린 회차(9월)의 카드 지출 — 잠기지 않았다.
const _open = Expense(
  rowId: 78,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 40000,
  merchant: '버스',
  paymentMethod: 'CARD',
  expenseDate: '2026-09-10T10:00:00',
);

/// 닫힌 회차(8월)의 카드 지출 — 서버가 잠갔다.
final _locked = _open.copyWith(
  rowId: 77,
  expenseDate: '2026-08-20T10:00:00',
  moneyLocked: true,
);

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  final updates = <String>[];
  final creates = <String>[];

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
  }) async {
    updates.add(expenseDate);
    return _open;
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
    creates.add(expenseDate);
    return _open;
  }
}

Future<_FakeRepo> _pump(WidgetTester tester, Widget home) async {
  final repo = _FakeRepo();
  tester.view.physicalSize = const Size(1500, 3000);
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
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Widget _opener(void Function(BuildContext) open) => Builder(
  builder: (ctx) =>
      TextButton(onPressed: () => open(ctx), child: const Text('open')),
);

/// 컨트롤러 글자로 찾는 입력칸 — 가맹점·날짜 칸.
Finder _fieldWith(String text) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller?.text == text);

Finder _submit(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

void main() {
  group('Q1 편집 저장 — 확인창은 돈과 기록이 갈리는 자리에만', () {
    Future<_FakeRepo> openEdit(WidgetTester tester, Expense e) async {
      final repo = await _pump(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, edit: e)),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('잠긴 거래는 묻지 않고 저장 한 번', (tester) async {
      final repo = await openEdit(tester, _locked);

      await tester.enterText(_fieldWith('버스'), '시내버스');
      await tester.pump();
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(find.text(_closedLine), findsNothing);
      expect(repo.updates, hasLength(1));
    });

    testWidgets('열린 회차 거래를 닫힌 회차 날짜로 옮기면 묻는다', (tester) async {
      final repo = await openEdit(tester, _open);

      await tester.enterText(_fieldWith('2026-09-10'), '2026-08-20');
      await tester.pump();
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(find.text(_closedLine), findsOneWidget);
      expect(repo.updates, isEmpty, reason: '확인 전에는 보내지 않는다');

      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();
      expect(repo.updates.single, startsWith('2026-08-20'));
    });

    testWidgets('열린 회차 안에서 고치면 묻지 않는다', (tester) async {
      final repo = await openEdit(tester, _open);

      await tester.enterText(_fieldWith('2026-09-10'), '2026-09-15');
      await tester.pump();
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(find.text(_closedLine), findsNothing);
      expect(repo.updates.single, startsWith('2026-09-15'));
    });

    testWidgets('닫힌 회차로 들어가는 새 저장은 묻는다', (tester) async {
      final repo = await _pump(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, defaultDate: '2026-08-20')),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '13000');
      await tester.pump();
      await tester.tap(find.text('식비').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택 안 함').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('현대카드').last);
      await tester.pumpAndSettle();

      await tester.tap(_submit('추가'));
      await tester.pumpAndSettle();

      expect(find.text(_closedLine), findsOneWidget);
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();
      expect(repo.creates, hasLength(1));
    });
  });
}
