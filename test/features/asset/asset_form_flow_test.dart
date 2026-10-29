// 자산 추가 · 수정 폼의 단계(I-17 5 ~ 11) — 1단계 종류 고르기 → 같은 시트의 2단계, ← 와 "작성한 내용이 사라져요", 수정의 종류 칸,
// 종류마다 칸 차례, 체크 줄 둘, 금액 칸 쉼표, 고르기 시트 연결, 보유 종목 줄.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/select_box/p_select_box.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

const _bank = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: 'KB국민',
  isIncludedInTotal: 'Y',
);

const _credit = Asset(
  rowId: 7,
  assetName: '숲빛 생활 카드',
  assetType: 'CREDIT_CARD',
  balance: -500000,
  institution: '숲길카드',
  isIncludedInTotal: 'Y',
  creditLimit: 200000000,
  paymentDay: 14,
  carryoverAmount: 9000,
  cardClosedThrough: '2026-08-31',
  cardCatalog: AssetCardCatalog(
    rowId: 101,
    cardName: '숲길 카드',
    companyName: '숲길카드',
  ),
);

const _invest = Asset(
  rowId: 12,
  assetName: '연금저축',
  assetType: 'INVESTMENT',
  balance: 5000000,
  institution: '삼성증권',
  isIncludedInTotal: 'Y',
  holdings: [
    AssetHolding(holdingName: '내 금 보유분', holdingType: AssetHoldingType.gold),
  ],
);

const _catalog = CardCatalogPage(
  content: [
    CardCatalogSummary(
      rowId: 101,
      cardName: 'QA 신용카드',
      cardType: 'CREDIT',
      company: CardCompany(rowId: 1, name: '국민카드'),
    ),
  ],
  totalElements: 1,
  totalPages: 1,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: false,
);

Future<void> _host(
  WidgetTester tester,
  void Function(BuildContext ctx) open, {
  List<Asset> assets = const [_bank],
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        assetRepositoryProvider.overrideWith(
          (ref) async => AssetRepository(Dio()),
        ),
        cardCatalogPageProvider.overrideWith((ref, key) async => _catalog),
        myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
        stockSearchProvider.overrideWith(
          (ref, q) async => const <StockMasterItem>[],
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => open(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 시트 머리 제목.
String _title(WidgetTester tester) => plainOf(
  tester
      .widget<Text>(find.byKey(const ValueKey('p-bottom-sheet-title')).last)
      .data!,
);

/// 지금 보이는 Field 라벨을 위에서 아래로.
List<String> _labels(WidgetTester tester) => [
  for (final e in find.byType(PField).evaluate())
    if ((e.widget as PField).label != null)
      plainOf((e.widget as PField).label!),
];

Finder get _sheets => find.byKey(const ValueKey('p-bottom-sheet-root'));

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('1단계 — 무엇을 추가할까요?', () {
    testWidgets('묶음 셋에 상자 아홉, 처음엔 아무것도 안 골라져 있다', (tester) async {
      await _host(tester, showAssetAddFlow);
      expect(_title(tester), l.assetFormFirstTitle);
      for (final t in [
        l.assetCatAccount,
        l.assetGroupCard,
        l.assetGroupInvestment,
      ]) {
        expect(findPlain(t), findsWidgets);
      }
      expect(find.byType(PRadioSelectBox<AssetKind>), findsNWidgets(9));
      for (final k in AssetKind.values) {
        expect(findPlain(k.label(l)), findsWidgets, reason: k.name);
      }
      expect(l.assetSubtypeOverdraft, '마이너스 통장');
      final groups = tester.widgetList<PRadioSelectBoxGroup<AssetKind>>(
        find.byType(PRadioSelectBoxGroup<AssetKind>),
      );
      expect(groups.every((g) => g.value == null && g.columns == 2), isTrue);
    });

    testWidgets('안 고르고 [다음] → 묶음 아래 오류 글, 버튼은 켜져 있다 · 상자만 눌러서는 안 넘어간다', (
      tester,
    ) async {
      await _host(tester, showAssetAddFlow);
      await tester.tap(buttonLabeled(l.actionNext));
      await tester.pumpAndSettle();
      expect(findRichPlain(l.assetFormPickKindError), findsOneWidget);
      expect(_title(tester), l.assetFormFirstTitle);

      await tester.tap(findPlain(l.assetTypeCreditCard).first);
      await tester.pumpAndSettle();
      expect(_title(tester), l.assetFormFirstTitle, reason: '반영은 [다음] 이다');
      expect(findRichPlain(l.assetFormPickKindError), findsNothing);
    });

    testWidgets('[다음] → 같은 시트의 2단계(시트는 하나), 제목은 "{종류} 추가"', (tester) async {
      await _host(tester, showAssetAddFlow);
      await tester.tap(findPlain(l.assetTypeCreditCard).first);
      await tester.pumpAndSettle();
      await tester.tap(buttonLabeled(l.actionNext));
      await tester.pumpAndSettle();
      expect(_title(tester), l.assetFormTitleAdd(l.assetTypeCreditCard));
      expect(_sheets, findsOneWidget, reason: '단계가 바뀌어도 표면은 하나다');
      expect(buttonLabeled(l.calAdd), findsOneWidget);
    });
  });

  group('← 와 닫기', () {
    Future<void> toCredit(WidgetTester tester) async {
      await tester.tap(findPlain(l.assetTypeCreditCard).first);
      await tester.pumpAndSettle();
      await tester.tap(buttonLabeled(l.actionNext));
      await tester.pumpAndSettle();
    }

    testWidgets('← 는 1단계로, 고른 종류는 골라진 채', (tester) async {
      await _host(tester, showAssetAddFlow);
      await toCredit(tester);
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back')));
      await tester.pumpAndSettle();
      expect(_title(tester), l.assetFormFirstTitle);
      final groups = tester.widgetList<PRadioSelectBoxGroup<AssetKind>>(
        find.byType(PRadioSelectBoxGroup<AssetKind>),
      );
      expect(groups.every((g) => g.value == AssetKind.credit), isTrue);
    });

    testWidgets('쓴 값이 있으면 ← 가 먼저 묻는다 — 계속 작성하면 그대로, 나가면 버린다', (tester) async {
      await _host(tester, showAssetAddFlow);
      await toCredit(tester);
      await typeInto(tester, l.assetNickname, '내 카드');
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back')));
      await tester.pumpAndSettle();
      expect(findPlain(l.sheetLeaveTitle), findsOneWidget);

      await tester.tap(findPlain(l.sheetLeaveStay));
      await tester.pumpAndSettle();
      expect(_title(tester), l.assetFormTitleAdd(l.assetTypeCreditCard));
      expect(textOf(tester, l.assetNickname), '내 카드');

      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back')));
      await tester.pumpAndSettle();
      await tester.tap(findPlain(l.sheetLeaveLeave));
      await tester.pumpAndSettle();
      expect(_title(tester), l.assetFormFirstTitle);
    });

    testWidgets('값을 안 쓰면 ← 가 묻지 않는다', (tester) async {
      await _host(tester, showAssetAddFlow);
      await toCredit(tester);
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back')));
      await tester.pumpAndSettle();
      expect(findPlain(l.sheetLeaveTitle), findsNothing);
      expect(_title(tester), l.assetFormFirstTitle);
    });

    testWidgets('수정에는 ← 도 1단계도 없다 · 제목은 "{종류} 수정"', (tester) async {
      await _host(tester, (c) => showAssetEditForm(c, _bank));
      expect(find.byKey(const ValueKey('p-bottom-sheet-back')), findsNothing);
      expect(_title(tester), l.assetFormTitleEdit(l.assetTypeBankAccount));
    });

    testWidgets('바깥을 눌러도 안 닫히고, 바뀐 값이 있으면 닫기 전에 묻는다', (tester) async {
      await _host(tester, (c) => showAssetKindForm(c, AssetKind.cash));
      await tester.tapAt(const Offset(180, 20));
      await tester.pumpAndSettle();
      expect(_sheets, findsOneWidget);

      await typeInto(tester, l.assetNickname, '비상금');
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
      await tester.pumpAndSettle();
      expect(findPlain(l.sheetLeaveTitle), findsOneWidget);
      await tester.tap(findPlain(l.sheetLeaveLeave));
      await tester.pumpAndSettle();
      expect(_sheets, findsNothing);
    });
  });

  group('수정의 종류 칸', () {
    testWidgets('계좌는 Select 여섯 · 카드는 칩 둘 · 투자는 칸이 없다', (tester) async {
      await _host(tester, (c) => showAssetEditForm(c, _bank));
      expect(fieldWithLabel(l.assetFormKindLabel), findsOneWidget);
      expect(find.byType(PRadioSelectBox<AssetKind>), findsNothing);
    });

    testWidgets('카드 종류를 바꿔도 고른 상품이 남고, 체크카드로 바뀌면 결제일 칸이 사라진다', (tester) async {
      await _host(
        tester,
        (c) => showAssetEditForm(c, _credit),
        assets: const [_bank, _credit],
      );
      expect(fieldWithLabel(l.assetPaymentDayLabel), findsOneWidget);
      await tester.tap(findPlain(l.assetTypeCheckCard));
      await tester.pumpAndSettle();
      expect(_title(tester), l.assetFormTitleEdit(l.assetTypeCheckCard));
      expect(fieldWithLabel(l.assetPaymentDayLabel), findsNothing);
      expect(findPlain('숲길 카드'), findsWidgets);
    });

    testWidgets('투자 수정에는 종류 칸이 없다', (tester) async {
      await _host(
        tester,
        (c) => showAssetEditForm(c, _invest),
        assets: const [_bank, _invest],
      );
      expect(fieldWithLabel(l.assetFormKindLabel), findsNothing);
    });
  });

  group('종류마다 칸 차례(I-17 11)', () {
    Future<List<String>> labelsOf(WidgetTester tester, AssetKind kind) async {
      await _host(tester, (c) => showAssetKindForm(c, kind));
      return _labels(tester);
    }

    testWidgets('입출금 · 예금 · 적금 · 현금 · 대출', (tester) async {
      expect(await labelsOf(tester, AssetKind.checking), [
        l.assetInstitutionBrand,
        l.assetNickname,
        l.assetMemo,
        l.assetBalanceLabel,
        l.assetCurrency,
      ]);
    });

    testWidgets('마이너스 통장은 금액 → 약정 한도', (tester) async {
      expect(await labelsOf(tester, AssetKind.overdraft), [
        l.assetInstitutionBrand,
        l.assetNickname,
        l.assetMemo,
        l.assetOverdraftUsedLabel,
        l.assetOverdraftLimitLabel,
        l.assetCurrency,
      ]);
    });

    testWidgets('신용카드', (tester) async {
      expect(await labelsOf(tester, AssetKind.credit), [
        l.assetCardProduct,
        l.assetNickname,
        l.assetCreditLimitLabel,
        l.assetPaymentDayLabel,
        l.assetCurrentUsage,
        l.assetCurrency,
        l.assetPaymentAccountLabel,
      ]);
    });

    testWidgets('체크카드는 잔액이 없다', (tester) async {
      expect(await labelsOf(tester, AssetKind.check), [
        l.assetCardProduct,
        l.assetNickname,
        l.assetCurrency,
        l.assetLinkedAccountLabel,
      ]);
    });

    testWidgets('투자', (tester) async {
      expect(await labelsOf(tester, AssetKind.investment), [
        l.assetBrokerExchange,
        l.assetNickname,
        l.assetHoldings,
        l.assetCashBalance,
        l.assetCurrency,
        l.assetMemo,
      ]);
    });

    testWidgets('체크 줄 둘 — 스위치는 하나도 없다', (tester) async {
      await _host(tester, (c) => showAssetKindForm(c, AssetKind.checking));
      expect(find.byType(PListCheckItem), findsNWidgets(2));
      expect(find.byType(PSwitchmark), findsNothing);
      expect(findPlain(l.assetHideThisAmount), findsOneWidget);
      expect(findPlain(l.assetIncludeInTotal), findsOneWidget);
    });
  });

  group('금액 칸', () {
    testWidgets('쓰는 동안 쉼표가 찍히고 신용한도도 쉼표로 열린다', (tester) async {
      await _host(
        tester,
        (c) => showAssetEditForm(c, _credit),
        assets: const [_bank, _credit],
      );
      expect(textOf(tester, l.assetCreditLimitLabel), '200,000,000');
      await typeInto(tester, l.assetCurrentUsage, '1234567');
      expect(textOf(tester, l.assetCurrentUsage), '1,234,567');
    });

    testWidgets('한도를 넘으면 안내 한 줄(오류 아님)이 서고 저장은 막지 않는다', (tester) async {
      await _host(
        tester,
        (c) => showAssetEditForm(c, _credit),
        assets: const [_bank, _credit],
      );
      await typeInto(tester, l.assetCurrentUsage, '300000000');
      expect(findRichPlain('한도보다'), findsOneWidget);
      expect(buttonLabeled(l.actionSave), findsOneWidget);
    });
  });

  group('고르기 시트 연결', () {
    testWidgets('기관 칸은 Input Button — 시트에서 고르면 값이 칸에 들어간다', (tester) async {
      await _host(tester, (c) => showAssetKindForm(c, AssetKind.checking));
      await pickCardProduct(tester, l.assetInstitutionBrand, 'KB국민');
      expect(find.byType(PField), findsWidgets);
      expect(findPlain('KB국민'), findsWidgets);
      // 시트가 닫혔다
      expect(findPlain(l.assetPickInstitutionTitle), findsNothing);
    });

    testWidgets('카드 상품을 고르면 칸에 이름이 들어가고 별칭 자리 글이 된다', (tester) async {
      await _host(tester, (c) => showAssetKindForm(c, AssetKind.credit));
      await pickCardProduct(tester, l.assetCardProduct, 'QA 신용카드');
      expect(findPlain('QA 신용카드'), findsWidgets);
    });
  });

  group('보유 종목', () {
    testWidgets('직접 추가하면 줄이 생기고 합계 칸이 평가액으로 바뀐다 · 지우면 사라진다', (tester) async {
      await _host(tester, (c) => showAssetKindForm(c, AssetKind.investment));
      expect(fieldWithLabel(l.assetCashBalance), findsOneWidget);
      await tester.tap(buttonLabeled(l.assetAddStock));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '가나 전자');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(findPlain(l.assetHoldingAddManual('가나 전자')));
      await tester.pumpAndSettle();

      // 보유 줄이 생겼다 — 이름 칸 · 수량 · 평가액 · 매수원가
      expect(fieldWithLabel(l.assetHoldingQuantity), findsOneWidget);
      expect(fieldWithLabel(l.holdingTotalCost), findsOneWidget);
      expect(fieldWithLabel(l.assetCashBalance), findsNothing);
      expect(fieldWithLabel(l.assetHoldingValueLabel), findsWidgets);

      await tester.tap(find.bySemanticsLabel(l.assetHoldingRemoveOf('가나 전자')));
      await tester.pumpAndSettle();
      expect(fieldWithLabel(l.assetHoldingQuantity), findsNothing);
      expect(fieldWithLabel(l.assetCashBalance), findsOneWidget);
    });

    testWidgets('금 · 코인 추가 단추는 증권사가 아닐 때만 — 증권사면 종목 추가만', (tester) async {
      await _host(tester, (c) => showAssetKindForm(c, AssetKind.investment));
      // 첫 기관(증권사)이 기본이라 금 · 코인 단추가 없다
      expect(buttonLabeled(l.assetHoldingAddGold), findsNothing);
      expect(buttonLabeled(l.assetAddStock), findsOneWidget);
    });
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      '360 폭 글자 ${(scale * 100).toInt()}% 에서 넘침 없이 그려진다 — 종류 고르기와 신용카드',
      (tester) async {
        await _host(tester, showAssetAddFlow, scale: scale);
        expect(tester.takeException(), isNull);
        await tester.tap(findPlain(l.assetTypeCreditCard).first);
        await tester.pumpAndSettle();
        await tester.tap(buttonLabeled(l.actionNext));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final sheet = tester.getRect(_sheets);
        expect(sheet.left, 0);
        expect(sheet.right, 360);
      },
    );
  }
}
