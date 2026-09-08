// 결제 문자 초안에서 지출/수입 토글을 잠근다 (A1-③).
//
// 이 초안의 저장은 `/import/sms/commit` 으로 간다. 그 계약엔 `expenseType` 이 없고
// 서버가 `ExpenseType.EXPENSE` 를 박아 넣는다(`SmsImportServiceImpl`). 그래서 종전엔
// 토글을 수입으로 바꿔 저장해도 **지출로 남았다** — 환불·입금 문자가 지출로 잡혀
// 이번 달 지출이 부풀고 그 돈은 수입에 안 잡혔다. 화면만 수입이라 말한 셈이다.
//
// 못 지키는 약속은 안 하는 게 낫다. 이 초안은 원래부터 "카드 결제라 유형·결제수단은
// 고정" 이고(시트 initState 주석), 편집 모드는 종전부터 같은 방식으로 잠겨 있었다.
//
// 여기서 고정하는 것은 둘이다.
//   ① 문자 초안에서 '수입' 을 눌러도 종류가 안 바뀐다
//   ② 일반 추가에서는 여전히 바뀐다 — 잠금이 문자 초안 밖으로 새면 앱을 못 쓴다
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
import 'package:porest_desk_app/features/sms/data/sms_repository.dart';
import 'package:porest_desk_app/features/sms/domain/sms_draft.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _expenseCategory = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _incomeCategory = ExpenseCategory(
  rowId: 6,
  categoryName: '급여',
  expenseType: 'INCOME',
  sortOrder: 0,
  icon: 'wallet',
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

/// 승인 문자 하나 — 파서가 알아본 상태.
const _draft = SmsDraft(
  text: '[Web발신] 국민카드 승인 12,000원 스타벅스',
  parsed: SmsParseResult(
    matched: true,
    confidence: 'HIGH',
    cancel: false,
    amount: 12000,
    merchant: '스타벅스',
    assetRemembered: true,
    assetCandidates: [],
  ),
);

Future<AppLocalizations> _open(WidgetTester tester, {SmsDraft? draft}) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith(
          (ref) async => [_expenseCategory, _incomeCategory],
        ),
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
              onPressed: () => showAddTxSheet(ctx, smsDraft: draft),
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
  // 종류가 바뀌면 이 라벨이 '수입처' 로 바뀐다 — 화면에서 종류를 읽는 자리다.
  testWidgets('문자 초안에서 수입을 눌러도 지출 그대로다', (tester) async {
    final l = await _open(tester, draft: _draft);

    expect(find.text(l.expPayee), findsOneWidget);
    await tester.tap(find.text(l.expTypeIncome));
    await tester.pumpAndSettle();

    expect(
      find.text(l.expIncomeSource),
      findsNothing,
      reason: '문자 저장 경로는 지출로만 남는다 — 화면이 수입이라 말하면 거짓말이다',
    );
    expect(find.text(l.expPayee), findsOneWidget);
  });

  testWidgets('문자 초안에는 이체 선택지가 아예 없다', (tester) async {
    final l = await _open(tester, draft: _draft);
    expect(find.text(l.expTypeTransfer), findsNothing);
  });

  // 반대편 — 잠금이 문자 초안 밖으로 새면 일반 가계부 입력이 망가진다.
  testWidgets('일반 추가에서는 수입으로 바뀐다', (tester) async {
    final l = await _open(tester);

    expect(find.text(l.expPayee), findsOneWidget);
    await tester.tap(find.text(l.expTypeIncome));
    await tester.pumpAndSettle();

    expect(find.text(l.expIncomeSource), findsOneWidget);
    expect(find.text(l.expPayee), findsNothing);
  });
}
