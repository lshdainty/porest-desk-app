// 이체 칸 공용 위젯 — 시트·반복 설정·프리셋 폼이 이 하나를 쓴다.
//
// 어제(#366)까지 같은 칸을 세 화면이 각자 그렸다. 규칙(`transfer_rules.dart`)만
// 공유해서 반은 맞고 반은 틀렸다 — 셀렉트 위젯도, 로딩 표시도, 수수료 상한도 달랐다.
// 화면이 갈리면 "어떤 계좌를 고를 수 있나 · 이자 칸이 언제 뜨나" 가 조용히 갈리고,
// 갈리는 순간 사용자는 시트에서 만든 이체를 반복으로는 못 만든다.
//
// 그래서 세 화면 대신 **이 위젯 하나**를 잰다. 세 화면의 저장 payload 테스트
// (`preset_transfer_payload_test` · `recurring_transfer_payload_test`)는 그대로 둔다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/transfer_account_fields.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';

const _bank = Asset(
  rowId: 1,
  assetName: 'QA예금',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(
  rowId: 2,
  assetName: 'QA적금',
  assetType: 'SAVINGS',
  institution: '신한',
);
const _loan = Asset(
  rowId: 3,
  assetName: 'QA대출',
  assetType: 'LOAN',
  institution: '신한',
);
const _check = Asset(
  rowId: 4,
  assetName: 'QA체크',
  assetType: 'CHECK_CARD',
  institution: '신한',
);
const _credit = Asset(
  rowId: 5,
  assetName: 'QA신용',
  assetType: 'CREDIT_CARD',
  institution: '신한',
);

Future<void> _pump(
  WidgetTester tester, {
  int? fromAssetRowId,
  int? toAssetRowId,
  int? amountForHint,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransferAccountFields(
              assets: const AsyncValue.data([
                _bank,
                _savings,
                _loan,
                _check,
                _credit,
              ]),
              fromAssetRowId: fromAssetRowId,
              toAssetRowId: toAssetRowId,
              feeController: TextEditingController(),
              interestController: TextEditingController(text: '20000'),
              amountForHint: amountForHint,
              onFromChanged: (_) {},
              onToChanged: (_) {},
              labelBuilder: (text) => Text(text),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSelect(WidgetTester tester, int index) async {
  await tester.tap(find.byType(PSelect<int>).at(index));
  await tester.pumpAndSettle();
}

/// 열린 메뉴 **안의** 항목만 본다. 전역 `find.text` 는 셀렉트 트리거에 그려진
/// "고른 값" 까지 잡아서, 보내는 계좌가 받는 목록에서 빠졌는지 가릴 수 없다.
Finder _menuOption(String label) =>
    find.descendant(of: find.byType(ListView), matching: find.text(label));

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('카드는 어느 쪽에도 후보로 안 뜬다', (tester) async {
    await _pump(tester);
    await _openSelect(tester, 0);

    expect(_menuOption('신한 · QA예금'), findsOneWidget);
    expect(_menuOption('신한 · QA적금'), findsOneWidget);
    expect(_menuOption('신한 · QA대출'), findsOneWidget);
    expect(_menuOption('신한 · QA체크'), findsNothing);
    expect(_menuOption('신한 · QA신용'), findsNothing);
  });

  testWidgets('받는 계좌 후보에서 보내는 계좌가 빠진다', (tester) async {
    await _pump(tester, fromAssetRowId: 1);
    await _openSelect(tester, 1);

    expect(_menuOption('신한 · QA예금'), findsNothing);
    expect(_menuOption('신한 · QA적금'), findsOneWidget);
  });

  testWidgets('받는 계좌가 대출이면 이자 칸이 뜬다', (tester) async {
    await _pump(tester, fromAssetRowId: 1, toAssetRowId: 3);

    expect(find.text(l.expInterest), findsOneWidget);
  });

  testWidgets('받는 계좌가 대출이 아니면 이자 칸이 없다', (tester) async {
    await _pump(tester, fromAssetRowId: 1, toAssetRowId: 2);

    expect(find.text(l.expInterest), findsNothing);
  });

  testWidgets('금액이 없으면 이자 안내를 쪼개지 않는다 — 프리셋은 금액이 없는 게 정상', (tester) async {
    await _pump(tester, fromAssetRowId: 1, toAssetRowId: 3);

    expect(find.text(l.expInterestHint), findsOneWidget);
  });

  testWidgets('금액이 있으면 원금·이자로 쪼개 보여 준다', (tester) async {
    await _pump(
      tester,
      fromAssetRowId: 1,
      toAssetRowId: 3,
      amountForHint: 100000,
    );

    expect(find.text(l.expInterestHint), findsNothing);
    expect(find.text(l.expInterestSplit('80,000', '20,000')), findsOneWidget);
  });
}
