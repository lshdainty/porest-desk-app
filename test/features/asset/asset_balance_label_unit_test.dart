// 잔액·한도 라벨이 **고른 통화**를 따른다 (QA 12차 결정 ③).
//
// 통화를 USD 로 골라도 라벨은 `잔액 (원)` 이었다. 한 폼 안에서 이미 갈려 있었다 —
// 통화 칸은 `$ USD` 라고 적혀 있는데 바로 위 칸은 `(원)` 이다.
//
// 표기 규칙은 `currencyUnit` 한 곳이고 웹도 같은 규칙을 쓴다(desk-front #369).
// 그쪽 규칙은 `test/core/format/currency_unit_test.dart` 가 잠근다 — 여기서는
// **폼이 그 단위를 실제로 라벨에 넣는가**만 본다.
//
// 한도 라벨도 같이 옮겼다. 지시에 적힌 건 잔액이지만, 한도는 사용액과 **견주는**
// 값이라 단위가 갈리면 `현재 사용액 ($)` 옆에 `신용한도 (원)` 이 선다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/account_add_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/card_add_dialog.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog_page.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';

const _krwAccount = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  currency: 'KRW',
  institution: '국민은행',
  isIncludedInTotal: 'Y',
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
  Locale locale = const Locale('ko'),
}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // 라벨 글자는 AppLocalizations, 단위는 `Intl.defaultLocale` 을 본다 — 실제 앱은
  // `SettingsNotifier.setLocale` 이 둘을 함께 배선하므로 여기서도 같이 맞춘다.
  Intl.defaultLocale = locale.languageCode;
  addTearDown(() => Intl.defaultLocale = 'ko');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => const [_krwAccount]),
        assetRepositoryProvider.overrideWith(
          (ref) async => AssetRepository(Dio()),
        ),
        cardCatalogPageProvider.overrideWith((ref, key) async => _catalog),
        myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
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

/// 통화 select 를 펼쳐 코드를 고른다 — 두 폼 다 `PSelect<String>` 은 통화 하나뿐이다.
Future<void> _pickCurrency(WidgetTester tester, String label) async {
  await tester.tap(find.byType(PSelect<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('계좌 — 원화면 `잔액 (원)`, USD 면 `잔액 (\$)`', (tester) async {
    await _host(tester, showAccountAddDialog);
    expect(find.text('잔액 (원)'), findsOneWidget);

    await _pickCurrency(tester, '\$ USD');

    expect(find.text('잔액 (\$)'), findsOneWidget);
    expect(
      find.text('잔액 (원)'),
      findsNothing,
      reason: '통화 칸은 USD 인데 바로 위 라벨이 (원) 이면 라벨이 값을 속인다',
    );
  });

  testWidgets('계좌 — 마이너스통장은 사용액·한도가 같은 단위다', (tester) async {
    await _host(tester, showAccountAddDialog);
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.text(l.assetSubtypeOverdraft));
    await tester.pumpAndSettle();
    await _pickCurrency(tester, '€ EUR');

    expect(find.text('사용 중인 금액 (€)'), findsOneWidget);
    expect(
      find.text('마이너스 한도 (€, 선택)'),
      findsOneWidget,
      reason: '한도는 사용액과 견주는 값이다 — 단위가 갈리면 무엇과 견줬는지 못 읽는다',
    );
  });

  testWidgets('계좌 — 대출도 고른 통화를 따른다', (tester) async {
    await _host(tester, showAccountAddDialog);
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.text(l.assetTypeLoan));
    await tester.pumpAndSettle();
    await _pickCurrency(tester, '¥ JPY');

    expect(find.text('남은 대출 금액 (¥)'), findsOneWidget);
  });

  testWidgets('카드 — 사용액·신용한도가 같은 단위다', (tester) async {
    await _host(tester, showCardAddDialog);
    expect(find.text('현재 사용액 (원)'), findsOneWidget);
    expect(find.text('신용한도 (원, 선택)'), findsOneWidget);

    await _pickCurrency(tester, '\$ USD');

    expect(find.text('현재 사용액 (\$)'), findsOneWidget);
    expect(find.text('신용한도 (\$, 선택)'), findsOneWidget);
  });

  testWidgets('영어 화면의 원화는 `₩` 다 — 이 레포가 이미 쓰는 규칙이다', (tester) async {
    // `krwSigned(unit: true)` 가 ko `10,000원` · en `₩10,000` 인 것과 같은 갈래다.
    // `Balance (원)` 은 영어 화면에서는 남의 글자다.
    await _host(tester, showAccountAddDialog, locale: const Locale('en'));

    expect(find.text('Balance (₩)'), findsOneWidget);

    await _pickCurrency(tester, '\$ USD');
    expect(find.text('Balance (\$)'), findsOneWidget);
  });
}
