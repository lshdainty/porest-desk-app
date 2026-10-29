// 고르기 시트 셋(I-17 18 ~ 20) — 기관 · 카드 상품 · 종목 추가. 검색칸 초점 · 거르기 · 고르면 닫힘 · 서버 검색 300ms 한 번 ·
// 단종 스위치 · 0건 · 실패 · 라디오 없는 종목 줄.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/card_product_picker.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/institution_picker.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/stock_add_picker.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/p_searchable_list.dart';

import '../../support/plain_text.dart';

CardCatalogPage _page(List<CardCatalogSummary> content) => CardCatalogPage(
  content: content,
  totalElements: content.length,
  totalPages: 1,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: content.isEmpty,
);

const _stocks = [
  StockMasterItem(
    countryCode: 'KR',
    marketCode: 'KOSPI',
    symbol: '000001',
    nameKr: '가나 전자',
    securityType: 'STOCK',
    currency: 'KRW',
  ),
  StockMasterItem(
    countryCode: 'KR',
    marketCode: 'KOSPI',
    symbol: '000002',
    nameKr: '가나 화학',
    securityType: 'STOCK',
    currency: 'KRW',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open, {
  List<Override> overrides = const [],
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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
            builder: (ctx) =>
                TextButton(onPressed: () => open(ctx), child: const Text('열기')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findPlain('열기'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('기관 고르기', () {
    testWidgets('분류 머리 + 줄, 별칭으로 걸러지고 고르면 이름이 돌아오고 닫힌다', (tester) async {
      String? picked;
      await _pump(tester, (ctx) async {
        picked = await showInstitutionPicker(
          ctx,
          invest: false,
          current: 'KB국민',
        );
      });
      expect(findPlain(l.assetPickInstitutionTitle), findsOneWidget);
      expect(findPlain(l.assetCategoryCommercialBank), findsOneWidget);
      // 증권사는 이 시트에 없다
      expect(findPlain(l.assetCategoryBrokerage), findsNothing);
      // 별칭 · 공백 · 대소문자를 무시해 찾는다
      await tester.enterText(find.byType(TextField), ' 국 민 ');
      await tester.pumpAndSettle();
      expect(findPlain('KB국민'), findsWidgets);
      await tester.tap(findPlain('KB국민').first);
      await tester.pumpAndSettle();
      expect(picked, 'KB국민');
      expect(findPlain(l.assetPickInstitutionTitle), findsNothing);
    });

    testWidgets('0건은 검색어를 넣은 글, 투자는 증권사 · 거래소만', (tester) async {
      await _pump(
        tester,
        (ctx) => showInstitutionPicker(
          ctx,
          invest: true,
          current: null,
        ).then((_) {}),
      );
      expect(findPlain(l.assetPickBrokerTitle), findsOneWidget);
      expect(findPlain(l.assetCategoryBrokerage), findsOneWidget);
      expect(findPlain(l.assetCategoryCommercialBank), findsNothing);
      await tester.enterText(find.byType(TextField), '없는기관');
      await tester.pumpAndSettle();
      expect(findPlain(l.assetSearchEmpty('없는기관')), findsOneWidget);
    });
  });

  group('카드 상품 고르기', () {
    const normal = CardCatalogSummary(
      rowId: 1,
      cardName: '윤슬 포인트 아주 긴 이름의 프리미엄 카드 에디션',
      cardType: 'CREDIT',
      company: CardCompany(name: '숲빛카드'),
      isDiscontinued: 'N',
      annualFee: CardAnnualFee(amount: 12000),
    );
    const old = CardCatalogSummary(
      rowId: 2,
      cardName: '옛 카드',
      cardType: 'CREDIT',
      company: CardCompany(name: '숲빛카드'),
      isDiscontinued: 'Y',
    );

    testWidgets('단종 스위치가 목록을 바꾸고 단종 줄에 배지가 붙는다 · 고르면 상품이 돌아온다', (tester) async {
      final asked = <CardSearchKey>[];
      CardCatalogSummary? picked;
      await _pump(
        tester,
        (ctx) async {
          picked = await showCardProductPicker(
            ctx,
            cardType: 'CREDIT',
            currentRowId: null,
          );
        },
        overrides: [
          cardCatalogPageProvider.overrideWith((ref, key) async {
            asked.add(key);
            return _page(
              key.includeDiscontinued == true ? [normal, old] : [normal],
            );
          }),
        ],
      );
      expect(findPlain(l.assetPickCardTitle), findsOneWidget);
      expect(findPlain(normal.cardName), findsOneWidget);
      expect(findPlain(old.cardName), findsNothing);
      expect(findPlain(l.assetDiscontinued), findsNothing);
      // 요청은 시트를 열 때 한 번
      expect(asked.length, 1);
      expect(asked.single.cardType, 'CREDIT');

      await tester.tap(findPlain(l.assetIncludeDiscontinued));
      await tester.pumpAndSettle();
      expect(findPlain(old.cardName), findsOneWidget);
      expect(findPlain(l.assetDiscontinued), findsOneWidget);

      await tester.tap(findPlain(old.cardName));
      await tester.pumpAndSettle();
      expect(picked?.rowId, 2);
    });

    testWidgets('서버 검색은 마지막 입력 뒤 300ms 에 한 번이다', (tester) async {
      final asked = <String?>[];
      await _pump(
        tester,
        (ctx) => showCardProductPicker(
          ctx,
          cardType: 'CHECK',
          currentRowId: null,
        ).then((_) {}),
        overrides: [
          cardCatalogPageProvider.overrideWith((ref, key) async {
            asked.add(key.keyword);
            return _page([normal]);
          }),
        ],
      );
      asked.clear();
      final field = find.byType(TextField);
      await tester.enterText(field, '윤');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, '윤슬');
      await tester.pump(const Duration(milliseconds: 200));
      expect(asked, isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(asked, ['윤슬']);
    });

    testWidgets('0건 · 실패는 따로, 실패는 다시 시도가 있다', (tester) async {
      var fail = true;
      await _pump(
        tester,
        (ctx) => showCardProductPicker(
          ctx,
          cardType: 'CREDIT',
          currentRowId: null,
        ).then((_) {}),
        overrides: [
          cardCatalogPageProvider.overrideWith((ref, key) async {
            if (fail) throw Exception('x');
            return _page(const []);
          }),
        ],
      );
      expect(findPlain(l.assetSearchFailed), findsOneWidget);
      fail = false;
      await tester.tap(findPlain(l.actionRetry));
      await tester.pumpAndSettle();
      expect(findPlain(l.assetSearchFailed), findsNothing);
      expect(findPlain(l.assetCardEmptyHint), findsOneWidget);
    });
  });

  group('종목 추가', () {
    testWidgets('검색이 실패하면 0건 안내가 아니라 실패 갈래와 다시 시도가 뜬다', (tester) async {
      var fail = true;
      await _pump(
        tester,
        (ctx) => showStockAddPicker(ctx, excludeSymbols: const {}).then((_) {}),
        overrides: [
          stockSearchProvider.overrideWith((ref, q) async {
            if (q.isEmpty) return [];
            if (fail) throw Exception('x');
            return _stocks;
          }),
        ],
      );
      await tester.enterText(find.byType(TextField), '가나');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(findPlain(l.assetSearchFailed), findsOneWidget);
      expect(findPlain(l.assetSearchEmpty('가나')), findsNothing);
      fail = false;
      await tester.tap(findPlain(l.actionRetry));
      await tester.pumpAndSettle();
      expect(findPlain(l.assetSearchFailed), findsNothing);
      expect(find.byType(PSearchableListItem), findsWidgets);
    });

    testWidgets('받는 동안은 스켈레톤 다섯 줄이다', (tester) async {
      final gate = Completer<List<StockMasterItem>>();
      await _pump(
        tester,
        (ctx) => showStockAddPicker(ctx, excludeSymbols: const {}).then((_) {}),
        overrides: [
          stockSearchProvider.overrideWith(
            (ref, q) =>
                q.isEmpty ? Future.value(<StockMasterItem>[]) : gate.future,
          ),
        ],
      );
      await tester.enterText(find.byType(TextField), '가나');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      final skeleton = tester.widget<PSearchableListSkeleton>(
        find.byType(PSearchableListSkeleton),
      );
      expect(skeleton.rows, 5);
      gate.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('시트는 내용만큼 서고(90% 가 아니다) 결과가 늘면 높이 한도까지 큰다', (tester) async {
      await _pump(
        tester,
        (ctx) => showStockAddPicker(ctx, excludeSymbols: const {}).then((_) {}),
        overrides: [
          stockSearchProvider.overrideWith(
            (ref, q) async => q.isEmpty ? [] : _stocks,
          ),
        ],
      );
      final sheetKey = find.byKey(const ValueKey('p-bottom-sheet-root'));
      final before = tester.getRect(sheetKey).height;
      expect(before, lessThan(760 * 0.5), reason: '검색칸만 있을 때는 내용만큼이다');
      await tester.enterText(find.byType(TextField), '가나');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      final after = tester.getRect(sheetKey).height;
      expect(after, greaterThan(before));
      expect(after, lessThanOrEqualTo(760 * 0.9 + 0.5));
    });

    testWidgets('검색어가 없으면 줄이 없고, 있으면 종목 줄 + 맨 아래 직접 추가 줄', (tester) async {
      StockPick? picked;
      await _pump(
        tester,
        (ctx) async {
          picked = await showStockAddPicker(ctx, excludeSymbols: {'000002'});
        },
        overrides: [
          stockSearchProvider.overrideWith(
            (ref, q) async => q.isEmpty ? [] : _stocks,
          ),
        ],
      );
      expect(findPlain(l.assetAddStock), findsOneWidget);
      expect(find.byType(PSearchableListItem), findsNothing);
      await tester.enterText(find.byType(TextField), '가나');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      // 담은 연동 종목(000002)은 빠진다
      expect(findPlain('가나 전자'), findsOneWidget);
      expect(findPlain('가나 화학'), findsNothing);
      expect(findPlain(l.assetHoldingAddManual('가나')), findsOneWidget);
      await tester.tap(findPlain('가나 전자'));
      await tester.pumpAndSettle();
      expect(picked?.found?.symbol, '000001');
    });

    testWidgets('0건이면 안내가 먼저, 직접 추가 줄은 늘 맨 아래', (tester) async {
      await _pump(
        tester,
        (ctx) => showStockAddPicker(ctx, excludeSymbols: {}).then((_) {}),
        overrides: [
          stockSearchProvider.overrideWith((ref, q) async => const []),
        ],
      );
      await tester.enterText(find.byType(TextField).last, '없는종목');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      final empty = tester.getRect(findPlain(l.assetSearchEmpty('없는종목')));
      final manual = tester.getRect(findPlain(l.assetHoldingAddManual('없는종목')));
      expect(empty.bottom, lessThanOrEqualTo(manual.top));
    });

    testWidgets('직접 추가 줄은 검색어 그대로 돌려준다', (tester) async {
      StockPick? picked;
      await _pump(
        tester,
        (ctx) async {
          picked = await showStockAddPicker(ctx, excludeSymbols: {});
        },
        overrides: [
          stockSearchProvider.overrideWith((ref, q) async => const []),
        ],
      );
      await tester.enterText(find.byType(TextField), '내 금 보유분');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(findPlain(l.assetHoldingAddManual('내 금 보유분')));
      await tester.pumpAndSettle();
      expect(picked?.manualName, '내 금 보유분');
    });
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('기관 시트가 360 폭 글자 ${scale * 100}% 에서 넘치지 않는다', (tester) async {
      await _pump(
        tester,
        (ctx) => showInstitutionPicker(
          ctx,
          invest: false,
          current: null,
        ).then((_) {}),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      final sheet = tester.getRect(
        find.byKey(const ValueKey('p-bottom-sheet-root')),
      );
      expect(sheet.left, 0);
      expect(sheet.right, 360);
      expect(sheet.height, lessThanOrEqualTo(760 * 0.9 + 0.5));
    });
  }

  // bottom-sheet.md — 길어질 수 있는 목록은 늘 끝 흐림을 건다(위 20 · 아래 80). 검색칸은 목록 밖이라 흐리지 않는다.
  group('끝 흐림', () {
    Finder fogInResults() => find.descendant(
      of: find.byType(PSearchableListResults),
      matching: find.byType(PScrollFogMask),
    );

    testWidgets('기관 시트의 결과 목록에 끝 흐림이 걸리고 검색칸에는 안 걸린다', (tester) async {
      await _pump(
        tester,
        (ctx) => showInstitutionPicker(
          ctx,
          invest: false,
          current: null,
        ).then((_) {}),
      );
      expect(fogInResults(), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(PScrollFogMask),
        ),
        findsNothing,
      );
      final mask = tester.widget<PScrollFogMask>(fogInResults());
      expect(mask.start, 20);
      expect(mask.end, 80);
    });

    testWidgets('카드 상품 시트의 결과 목록에도 걸린다', (tester) async {
      await _pump(
        tester,
        (ctx) => showCardProductPicker(
          ctx,
          cardType: 'CREDIT',
          currentRowId: null,
        ).then((_) {}),
        overrides: [
          cardCatalogPageProvider.overrideWith(
            (ref, key) async => _page([
              const CardCatalogSummary(
                rowId: 1,
                cardName: '예시 카드',
                cardType: 'CREDIT',
                company: CardCompany(name: '숲빛카드'),
                isDiscontinued: 'N',
              ),
            ]),
          ),
        ],
      );
      expect(fogInResults(), findsOneWidget);
    });

    testWidgets('종목 시트는 결과가 나오면 걸린다', (tester) async {
      await _pump(
        tester,
        (ctx) => showStockAddPicker(ctx, excludeSymbols: const {}).then((_) {}),
        overrides: [
          stockSearchProvider.overrideWith(
            (ref, q) async => q.isEmpty ? [] : _stocks,
          ),
        ],
      );
      await tester.enterText(find.byType(TextField), '가나');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(fogInResults(), findsOneWidget);
    });
  });
}
