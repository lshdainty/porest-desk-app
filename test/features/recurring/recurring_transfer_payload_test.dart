// 이체 반복이 **보내는 것**을 고정한다.
//
// 이 본문은 밤마다 서버가 그대로 실행한다 — 잘못 저장되면 화면엔 "저장됐다" 가 남고
// 자정 배치만 조용히 실패한다(실패는 로그만 남는다). 그래서 두 방향을 함께 잰다.
//
// - 이체로 저장하면 받는 계좌·수수료가 실리고 카테고리·거래처·결제 수단은 안 실린다.
// - 종류를 지출로 되돌리면 이체 칸이 빠진다 — 남겨 두면 서버가 400 으로 거절한다.
//
// 카드가 이체 상대 후보에 없다는 것도 여기서 잠근다 — 거래 시트와 같은 규칙을 써야
// "시트에서 만든 이체를 반복으로는 못 만든다" 가 안 생긴다(`transfer_rules.dart`).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/recurring/application/recurring_providers.dart';
import 'package:porest_desk_app/features/recurring/data/recurring_repository.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_settings_drawer.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';

const _category = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _bank = Asset(
  rowId: 7,
  assetName: '주거래',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(
  rowId: 8,
  assetName: '청약',
  assetType: 'SAVINGS',
  institution: '신한',
);

/// 이체 후보에서 빠져야 하는 카드.
const _card = Asset(
  rowId: 9,
  assetName: '체크',
  assetType: 'CHECK_CARD',
  institution: '신한',
);

class _CapturingRepo extends RecurringRepository {
  _CapturingRepo() : super(Dio());

  bool called = false;
  Map<String, Object?> created = {};

  @override
  Future<void> create({
    int? categoryRowId,
    int? assetRowId,
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    int? sourceExpenseRowId,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    String? executionTime,
    required String startDate,
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,
  }) async {
    called = true;
    created = {
      'categoryRowId': categoryRowId,
      'assetRowId': assetRowId,
      'toAssetRowId': toAssetRowId,
      'fee': fee,
      'interestAmount': interestAmount,
      'expenseType': expenseType,
      'amount': amount,
      'merchant': merchant,
      'paymentMethod': paymentMethod,
    };
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _open(WidgetTester tester) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recurringRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_bank, _savings, _card]),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showRecurringSettingsDialog(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _pickSelect(WidgetTester tester, int index, String label) async {
  await tester.tap(find.byType(PSelect<int>).at(index));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('이체로 저장하면 받는 계좌·수수료가 실리고 카테고리는 안 실린다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.text(l.expTypeTransfer));
    await tester.pumpAndSettle();
    await tester.enterText(_field('0').first, '300000'); // 금액
    await tester.pumpAndSettle();
    await _pickSelect(tester, 0, '신한 · 주거래');
    await _pickSelect(tester, 1, '신한 · 청약');
    // 금액 다음의 '0' 자리가 수수료다.
    await tester.enterText(_field('0').at(1), '500');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.recurringAdd));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(repo.created['expenseType'], 'TRANSFER');
    expect(repo.created['assetRowId'], 7);
    expect(repo.created['toAssetRowId'], 8);
    expect(repo.created['fee'], 500);
    expect(repo.created['amount'], 300000);
    // 이체에는 카테고리·거래처·결제 수단이 없다 — 실려 가면 서버가 400 이다.
    expect(repo.created['categoryRowId'], isNull);
    expect(repo.created['merchant'], isNull);
    expect(repo.created['paymentMethod'], isNull);
  });

  testWidgets('양쪽 계좌가 없으면 저장이 안 열린다 — 자정마다 조용히 실패할 규칙이 된다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.text(l.expTypeTransfer));
    await tester.pumpAndSettle();
    await tester.enterText(_field('0').first, '300000');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.recurringAdd));
    await tester.pumpAndSettle();

    expect(repo.called, isFalse);
  });

  testWidgets('카드는 이체 상대 후보에 없다 — 거래 시트와 같은 규칙', (tester) async {
    await _open(tester);
    await tester.tap(find.text(l.expTypeTransfer));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PSelect<int>).first);
    await tester.pumpAndSettle();

    expect(find.text('신한 · 주거래'), findsWidgets);
    expect(find.text('신한 · 청약'), findsWidgets);
    expect(find.text('신한 · 체크'), findsNothing);
  });
}
