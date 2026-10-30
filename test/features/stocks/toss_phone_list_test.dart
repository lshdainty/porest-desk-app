// 토스 폰 목록(I-13 B · C · 7 · 9 · 11 · 12 · 13) — 띠 차례, 금액 줄바꿈, 미국 금액, 지수 이름, 관심 그룹, 실패 한 벌.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/market_state.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

TossHoldingsItem _item(
  String symbol,
  String name,
  String currency,
  String value,
) => TossHoldingsItem(
  symbol: symbol,
  name: name,
  marketCountry: currency == 'USD' ? 'US' : 'KR',
  currency: currency,
  quantity: '3',
  lastPrice: value,
  averagePurchasePrice: value,
  marketValueAmount: value,
  profitLossAmount: '1000',
  profitLossRate: '12.2345',
  dailyProfitLossAmount: '0',
  dailyProfitLossRate: '0',
  purchaseAmount: value,
  commission: '0',
  tax: '0',
);

StockWatchGroup _group(int id, String name, List<String> symbols) =>
    StockWatchGroup(
      rowId: id,
      groupName: name,
      sortOrder: id,
      items: [
        for (final s in symbols)
          WatchItem(
            rowId: id * 1000 + symbols.indexOf(s),
            stockMasterRowId: 1,
            countryCode: 'KR',
            marketCode: 'KOSPI',
            symbol: s,
            nameKr: '종목 $s',
            securityType: 'STOCK',
            currency: 'KRW',
          ),
      ],
    );

final _holdings = TossHoldings(
  totalPurchaseAmount: '1500000000',
  marketValueAmount: '1834567890',
  profitLossAmount: '334567890',
  profitLossRate: '22.31',
  dailyProfitLossAmount: '-12345678',
  dailyProfitLossRate: '-0.67',
  items: [
    _item('A100', '가람전자 아주 긴 종목 이름 우선주 테스트', 'KRW', '8760000'),
    _item('MOA', '모아 테크놀로지스', 'USD', '6185.55'),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 2400),
  double textScale = 1,
  List<StockWatchGroup> groups = const [],
  bool holdingsFail = false,
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (holdingsFail)
          tossHoldingsProvider.overrideWith(
            (ref) async => throw StateError('x'),
          )
        else
          tossHoldingsProvider.overrideWith((ref) async => _holdings),
        tossExchangeRateProvider.overrideWith(
          (ref) async => const TossExchangeRate(rate: '1385.2'),
        ),
        watchGroupsProvider.overrideWith((ref) async => groups),
        tossMarketCalendarKrProvider.overrideWith(
          (ref) async => TossKrMarketCalendar.fromJson(const {}),
        ),
        tossMarketCalendarUsProvider.overrideWith(
          (ref) async => TossUsMarketCalendar.fromJson(const {}),
        ),
        tossIndicatorPricesProvider.overrideWith(
          (ref) async => const [
            TossIndicatorPrice(symbol: 'KOSPI', lastPrice: '2650.5'),
            TossIndicatorPrice(symbol: 'KR3Y', lastPrice: '3.1'),
          ],
        ),
        tossIndicatorClosesProvider.overrideWith(
          (ref, symbol) async => const [100.0, 101.0, 102.0],
        ),
        tossPricesProvider.overrideWith(
          (ref, key) async => [
            for (final s in key.split(',').where((e) => e.isNotEmpty))
              TossPrice(symbol: s, lastPrice: '70000'),
          ],
        ),
        prevCloseProvider.overrideWith((ref, s) async => 69000.0),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 3,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(body: TossStocksView()),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// 줄바꿈 자리(U+2060 · U+200B)를 뺀 글로 찾는다 — ds 가 keep-all 을 위해 글 사이에 끼운다.
String _plain(Text w) => (w.data ?? w.textSpan?.toPlainText() ?? '')
    .replaceAll('\u2060', '')
    .replaceAll('\u200B', '');
Finder _t(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w) == s);

/// Chip Tabs 의 칩 — 글을 ds 가 따로 그린다.
Finder _chip(String s) => find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == 'ChipVisual' && (w as dynamic).label == s,
);
Finder _tc(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w).contains(s));

void main() {
  marketTests();
  testWidgets('띠 차례 — 내 투자 → 시장 → 종목, 띠 사이 8, 지수는 아는 심볼만', (tester) async {
    await _pump(tester);
    final invest = _t('내 투자 평가금액');
    final market = _t('시장');
    final stocks = _t('종목');
    expect(invest, findsOneWidget);
    expect(market, findsOneWidget);
    expect(stocks, findsOneWidget);
    expect(
      tester.getTopLeft(invest).dy < tester.getTopLeft(market).dy &&
          tester.getTopLeft(market).dy < tester.getTopLeft(stocks).dy,
      isTrue,
    );
    final bands = find.byKey(const ValueKey('screen-section'));
    expect(bands, findsNWidgets(2));
    expect(
      tester.getRect(bands.at(1)).top - tester.getRect(bands.at(0)).bottom,
      8,
    );
    expect(_t('코스피'), findsOneWidget);
    expect(_t('코스닥'), findsNothing);
    expect(_t('1,385.20원'), findsOneWidget);
  });

  testWidgets('큰 금액은 쉼표 뒤에서만 줄바꿈(U+200B), Delta 에 + 부호 없음', (tester) async {
    await _pump(tester);
    final stat = tester.widget<Text>(
      find.byKey(const ValueKey('card-stat-value')),
    );
    expect(stat.data, contains('​'));
    expect(stat.semanticsLabel, '1,834,567,890원');
    expect(_tc('+'), findsNothing);
  });

  testWidgets('보유 줄 — 미국 종목은 달러, 원화는 원, 긴 이름은 줄바꿈, 종목 타일 없음', (tester) async {
    await _pump(tester);
    expect(_tc(r'$6,185.55'), findsOneWidget);
    expect(_tc('8,760,000원'), findsWidgets);
    final name = _t('가람전자 아주 긴 종목 이름 우선주 테스트');
    expect(name, findsOneWidget);
    expect(tester.widget<Text>(name).maxLines, isNull);
    expect(_chip('보유'), findsOneWidget);
    expect(_chip('보유 2'), findsNothing, reason: 'Chip Tabs 글에 숫자 없음');
  });

  testWidgets('보유 질의 실패 — 실패 한 벌, 연결 안내 아님', (tester) async {
    await _pump(tester, holdingsFail: true);
    expect(_t('내 투자를 불러오지 못했어요'), findsOneWidget);
    expect(_t('보유 종목을 불러오지 못했어요'), findsOneWidget);
    expect(_t('잠시 뒤 다시 시도해주세요.'), findsNWidgets(2));
    expect(_t('다시 시도'), findsNWidgets(2));
    expect(_tc('연결'), findsNothing);
  });

  testWidgets('관심 — 그룹마다 "{이름} · {n}" 제목 + ⋮ + 맨 끝 "그룹 추가", 빈 그룹 안내', (
    tester,
  ) async {
    await _pump(
      tester,
      groups: [
        _group(1, '반도체', ['A1', 'A2']),
        _group(2, '배당 · 장기 보유 후보 종목 모음 아주 긴 그룹 이름 예시', []),
      ],
    );
    await tester.tap(_chip('관심'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_t('반도체 · 2'), findsOneWidget);
    expect(_t('배당 · 장기 보유 후보 종목 모음 아주 긴 그룹 이름 예시 · 0'), findsOneWidget);
    expect(_t('반도체 더보기'), findsNothing); // 의미 이름은 Semantics
    expect(find.bySemanticsLabel('반도체 더보기'), findsOneWidget);
    expect(_t('아직 담은 종목이 없어요'), findsOneWidget);
    await tester.scrollUntilVisible(
      _t('그룹 추가'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_t('그룹 추가'), findsOneWidget);
  });

  testWidgets('관심에서 보유로 돌아와도 예외가 나지 않는다(묶음이 사라질 때)', (tester) async {
    await _pump(
      tester,
      groups: [
        _group(1, '반도체', ['A1', 'A2']),
      ],
    );
    await tester.tap(_chip('관심'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(_chip('보유'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('관심 그룹 0 — 안내만, "그룹 추가" 줄 없음', (tester) async {
    await _pump(tester);
    await tester.tap(_chip('관심'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_t('관심 종목이 없어요'), findsOneWidget);
    expect(_t('종목을 찾아 ☆ 를 눌러 보세요.'), findsOneWidget);
    expect(_t('그룹 추가'), findsNothing);
  });

  testWidgets('찾는 칸은 단추 — placeholder "종목 검색", 실제 회사 이름 없음', (tester) async {
    await _pump(tester);
    expect(find.bySemanticsLabel('종목 검색'), findsWidgets);
    expect(_t('종목 검색'), findsOneWidget);
    expect(_tc('삼성'), findsNothing);
  });

  testWidgets('글자 200% 에서도 가로 넘침 없음', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}

// ── 장 상태 · 시장 띠 실패 (I-13 9 · 12) ──
void marketTests() {
  testWidgets('장 상태 — 장 전 · 장 중 · 장 끝을 시각으로 가른다(분으로 견줌)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SizedBox(),
      ),
    );
    final l = AppLocalizations.of(tester.element(find.byType(SizedBox)));
    const session = TossMarketSession(
      startTime: '09:00:00',
      endTime: '15:30:00',
    );
    final before = marketStateAt(
      session,
      DateTime.utc(2026, 10, 29, 8, 59).subtract(const Duration(hours: 9)),
      l,
    );
    final during = marketStateAt(
      session,
      DateTime.utc(2026, 10, 29, 13, 0).subtract(const Duration(hours: 9)),
      l,
    );
    final atEnd = marketStateAt(
      session,
      DateTime.utc(2026, 10, 29, 15, 30).subtract(const Duration(hours: 9)),
      l,
    );
    final after = marketStateAt(
      session,
      DateTime.utc(2026, 10, 29, 15, 31).subtract(const Duration(hours: 9)),
      l,
    );
    expect((before.open, before.detail), (false, '개장 오전 9:00'));
    expect(during.open, isTrue);
    expect(during.detail, contains('오후 1:00'));
    expect(atEnd.open, isTrue);
    expect((after.open, after.detail), (false, '장마감'));
    expect(
      marketStateAt(
        null,
        DateTime.utc(2026, 10, 29, 13, 0).subtract(const Duration(hours: 9)),
        l,
      ).detail,
      '휴장',
    );
  });

  testWidgets('시장 질의(지수 · 국내 · 미국)가 모두 실패하면 시장 띠에 실패 한 벌', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tossHoldingsProvider.overrideWith((ref) async => null),
          tossExchangeRateProvider.overrideWith((ref) async => null),
          watchGroupsProvider.overrideWith((ref) async => <StockWatchGroup>[]),
          tossMarketCalendarKrProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
          tossMarketCalendarUsProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
          tossIndicatorPricesProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TossStocksView()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(_t('시장 정보를 불러오지 못했어요'), findsOneWidget);
  });
}
