// 자산 편집 진입점이 유형별로 맞는 폼을 여는지 — 카드를 계좌 폼으로 보내던 회귀 방지.
//
// 카드 자산을 계좌 폼에 넣으면 은행 브랜드 목록·계좌번호가 뜨고 카드 상품을 못 바꾼다.
// 게다가 `_SubType` 에 카드 매핑이 없어 저장 시 유형이 바뀔 위험까지 있었다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_edit_dialog.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog_page.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _card = Asset(
  rowId: 7,
  assetName: '신한 Deep Dream',
  assetType: 'CREDIT_CARD',
  balance: 320000,
  institution: '신한카드',
  isIncludedInTotal: 'Y',
  creditLimit: 5000000,
  paymentDay: 14,
  cardCatalog: AssetCardCatalog(
    rowId: 101,
    cardName: '신한 Deep Dream',
    companyName: '신한카드',
  ),
);

const _account = Asset(
  rowId: 8,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

const _emptyPage = CardCatalogPage(
  content: [],
  totalElements: 0,
  totalPages: 0,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: true,
);

/// 시트를 여는 버튼 하나만 있는 최소 앱.
Future<void> _pumpAndOpen(WidgetTester tester, Asset asset) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [_account]),
        cardCatalogPageProvider.overrideWith((ref, key) async => _emptyPage),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetEditForm(ctx, asset),
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

void main() {
  testWidgets('카드 편집은 카드 폼을 연다', (tester) async {
    await tester.pumpAndOpen(_card);

    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l.assetCardEdit), findsOneWidget);
    expect(find.text(l.assetCardType), findsOneWidget);
    expect(find.text(l.assetCardProduct), findsOneWidget);
    // 계좌 폼이 열렸다면 나왔을 것들.
    expect(find.text(l.assetAccountEdit), findsNothing);
    expect(find.text(l.assetInstitutionBrand), findsNothing);
    // 기존 값이 채워져 있어야 한다 — 청구 사이클은 폼 아래쪽이라 스크롤해서 확인.
    expect(find.text('신한 Deep Dream'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('5000000'),
      find.byType(ListView).first,
      const Offset(0, -240),
    );
    expect(find.text('5000000'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text(l.dayN(14)),
      find.byType(ListView).first,
      const Offset(0, -240),
    );
    expect(find.text(l.dayN(14)), findsOneWidget);
  });

  testWidgets('계좌 편집은 그대로 계좌 폼을 연다', (tester) async {
    await tester.pumpAndOpen(_account);

    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l.assetAccountEdit), findsOneWidget);
    expect(find.text(l.assetInstitutionBrand), findsOneWidget);
    expect(find.text(l.assetCardEdit), findsNothing);
  });
}

extension on WidgetTester {
  Future<void> pumpAndOpen(Asset asset) => _pumpAndOpen(this, asset);
}
