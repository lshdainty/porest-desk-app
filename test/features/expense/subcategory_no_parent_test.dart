// 하위 카테고리 칸에는 상위 자신이 없다(QA 30 13).
//
// 이 칸은 하위가 있는 상위를 골랐을 때만 뜨는데 첫 칸이 "식비 (상위)" 였다. 하위가 있는 상위에는
// 서버가 거래(EXP_009)·반복·프리셋(NOT_LEAF)을 안 받아서, 고르면 저장에서 막혔다. 웹과 같이 걷는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/data/expense_repository.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/features/sms/data/sms_repository.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _parent = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);
const _lunch = ExpenseCategory(
  rowId: 2,
  categoryName: '점심',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  parentRowId: 1,
);
const _dinner = ExpenseCategory(
  rowId: 3,
  categoryName: '저녁',
  expenseType: 'EXPENSE',
  sortOrder: 1,
  parentRowId: 1,
);

void main() {
  testWidgets('거래 추가 — 하위 칸에 "식비 (상위)" 가 없다', (tester) async {
    tester.view.physicalSize = const Size(1500, 2600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
          categoriesProvider.overrideWith(
            (ref) async => [_parent, _lunch, _dinner],
          ),
          assetsProvider.overrideWith((ref) async => []),
          presetListProvider.overrideWith((ref) async => []),
          expenseRepositoryProvider.overrideWith(
            (ref) async => ExpenseRepository(Dio()),
          ),
          smsRepositoryProvider.overrideWith(
            (ref) async => SmsRepository(Dio()),
          ),
        ],
        child: MaterialApp(
          theme: PorestTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showAddTxSheet(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final l = await AppLocalizations.delegate.load(const Locale('ko'));

    // 상위를 누르면 첫 하위(점심)가 골라지고 하위 칸이 뜬다 — 그 칸을 펼친다.
    await tester.tap(find.text('식비').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('점심').last);
    await tester.pumpAndSettle();

    expect(find.text('저녁'), findsWidgets, reason: '하위 목록이 안 펼쳐졌다');
    expect(find.text(l.expTopCategorySuffix('식비')), findsNothing);
  });
}
