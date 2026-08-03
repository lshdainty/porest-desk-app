// 자산을 안 고르고도 거래를 저장할 수 있어야 한다 — 웹과 같은 규칙.
//
// 자산까지 관리하지 않고 가계부로만 쓰는 사용자가 있다. 앱만 자산을 강제하면
// 그 사용법이 아예 막히고, 같은 계정인데 웹에서 넣은 거래는 되고 앱에선 안 되는
// 상태가 된다. 백엔드도 asset_row_id 를 nullable 로 받는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _category = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _account = Asset(
  rowId: 10,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

Future<AppLocalizations> _open(WidgetTester tester) async {
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_account]),
        presetListProvider.overrideWith((ref) async => []),
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
  return AppLocalizations.delegate.load(const Locale('ko'));
}

/// 저장 버튼 — onPressed 가 null 이면 잠긴 상태.
bool _submitEnabled(WidgetTester tester, String label) {
  final btn = tester.widget<PButton>(
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).first,
  );
  return btn.onPressed != null;
}

void main() {
  testWidgets('금액 + 카테고리만 채우면 자산 없이도 저장할 수 있다', (tester) async {
    final l = await _open(tester);

    // 아무것도 안 채운 상태에선 잠겨 있어야 한다.
    expect(_submitEnabled(tester, l.expAddShort), isFalse);

    await tester.enterText(find.byType(TextField).first, '12000');
    await tester.pump();

    // 카테고리 선택 — 자산은 일부러 건드리지 않는다.
    await tester.tap(find.text(l.expCategory).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('식비').last);
    await tester.pumpAndSettle();

    expect(_submitEnabled(tester, l.expAddShort), isTrue);
  });
}
