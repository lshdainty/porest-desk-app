// 나무 폰 화면(I-13 13-3) — 토스와 같은 띠 틀, 국내 · 해외 한 목록, 상세 · 포트폴리오 페이지, 관심 시세 호출.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/securities_repository.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stock_pages.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

NamuHoldingItem _item(
  String symbol,
  String name,
  String eval, {
  String pnl = '1000',
  String qty = '3',
  String price = '70000',
}) => NamuHoldingItem(
  symbol: symbol,
  name: name,
  quantity: qty,
  avgPrice: '60000',
  currentPrice: price,
  evalAmount: eval,
  profitLoss: pnl,
);

NamuHoldings _h(String cur, List<NamuHoldingItem> items) => NamuHoldings(
  accountNo: 'a',
  currency: cur,
  totalEvalAmount: '0',
  totalProfitLoss: '0',
  profitRate: '0',
  items: items,
);

final _krw = _h('KRW', [
  _item('A900001', '가람전자 아주 긴 종목 이름 우선주 테스트', '1834567890', pnl: '300000000'),
  _item('A900002', '숲길증권', '8760000'),
]);
final _usd = _h('USD', [
  _item('MOA', '모아 테크놀로지스', '6185.55', pnl: '685.55', price: '412.37'),
]);

StockWatchGroup _group(int id, String name, List<String> symbols) =>
    StockWatchGroup(
      rowId: id,
      groupName: name,
      sortOrder: id,
      items: [
        for (final (i, s) in symbols.indexed)
          WatchItem(
            rowId: id * 100 + i,
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

String _plain(Text w) => (w.data ?? w.textSpan?.toPlainText() ?? '')
    .replaceAll('⁠', '')
    .replaceAll('​', '');
Finder _t(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w) == s);
Finder _tc(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w).contains(s));
Finder _chip(String s) => find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == 'ChipVisual' && (w as dynamic).label == s,
);

final quotesAsked = <String>[];

Future<void> _pump(
  WidgetTester tester, {
  Widget home = const Scaffold(body: NamuStocksView()),
  Size size = const Size(360, 2400),
  double textScale = 1,
  NamuHoldings? krw,
  NamuHoldings? usd,
  bool krwFail = false,
  bool usdFail = false,
  double? fx = 1385.2,
  List<StockWatchGroup> groups = const [],
}) async {
  quotesAsked.clear();
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        namuHoldingsProvider.overrideWith((ref, c) async {
          final fail = c == 'KRW' ? krwFail : usdFail;
          if (fail) throw StateError('x');
          return c == 'KRW' ? (krw ?? _krw) : (usd ?? _usd);
        }),
        securitiesExchangeRateProvider.overrideWith((ref) async => fx),
        watchGroupsProvider.overrideWith((ref) async => groups),
        namuQuotesProvider.overrideWith((ref, key) async {
          quotesAsked.add(key);
          return [
            for (final s in key.split(',').where((e) => e.isNotEmpty))
              BrokerQuote(
                symbol: s,
                price: 70000,
                currency: 'KRW',
                previousClose: 69000,
              ),
          ];
        }),
        securitiesDailyCandlesProvider.overrideWith(
          (ref, s) async => TossCandlePage(
            candles: [
              for (var d = 20; d <= 28; d++)
                TossCandle(
                  timestamp: '2026-10-${d}T00:00:00+09:00',
                  openPrice: '1',
                  highPrice: '1',
                  lowPrice: '1',
                  closePrice: '${70000 + d * 100}',
                  volume: '1000',
                ),
            ],
          ),
        ),
        stockSearchProvider.overrideWith(
          (ref, q) async => const [
            StockMasterItem(
              countryCode: 'KR',
              marketCode: 'KOSPI',
              symbol: 'A900001',
              nameKr: '가람전자 아주 긴 종목 이름 우선주 테스트',
              securityType: 'STOCK',
              currency: 'KRW',
            ),
          ],
        ),
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
          child: home,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('띠 차례 — 내 투자 → 시장 → 종목, 띠 사이 8, 시장 띠는 환율 줄만', (tester) async {
    await _pump(tester);
    final invest = _t('원화 환산 합계');
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
    expect(_t('환율(USD)'), findsOneWidget);
    expect(_t('1,385.20원'), findsOneWidget);
    // 나무에 없는 것은 그리지 않는다 — 지수 · 장 상태 · 발견
    expect(_t('코스피'), findsNothing);
    expect(_tc('장마감'), findsNothing);
    expect(_chip('발견'), findsNothing);
    expect(_chip('보유'), findsOneWidget);
    expect(_chip('관심'), findsOneWidget);
    expect(_tc('토스'), findsNothing);
    expect(_t('나무증권 Open API · 시세 지연 표시'), findsOneWidget);
  });

  testWidgets('틈 — 내 투자 ↔ 시장 8, 시장 ↔ 종목 띠 8 (T3 · T4, 나무도 같다 T8)', (
    tester,
  ) async {
    await _pump(tester);
    final bands = find.byKey(const ValueKey('screen-section'));
    final marketBottom = tester.getRect(bands.at(1)).bottom;
    // 종목 띠는 제목 위 여백 24 가 띠 안이다 — 제목 글 위쪽에서 24 를 뺀 자리가 띠의 위
    final stocksTop = tester.getTopLeft(_t('종목')).dy - 24;
    expect(stocksTop - marketBottom, 8);
  });

  testWidgets('섞이면 원화 환산 합계 + 환율 적용 글, 국내 · 해외 줄과 "국내 2 · 해외 1"', (
    tester,
  ) async {
    await _pump(tester);
    final stat = tester.widget<Text>(
      find.byKey(const ValueKey('card-stat-value')),
    );
    // 1,834,567,890 + 8,760,000 + 6185.55 × 1385.2 = 1,851,895,… 원 (쉼표 뒤 줄바꿈 U+200B)
    expect(stat.data, contains('​'));
    expect(stat.semanticsLabel, startsWith('≈ 1,85'));
    expect(_t('환율 1,385 적용'), findsOneWidget);
    expect(_tc('+'), findsNothing, reason: 'Delta 에 + 부호 없음');
    expect(_t('국내 평가금액'), findsOneWidget);
    expect(_t('해외 평가금액'), findsOneWidget);
    expect(_t('국내 2 · 해외 1'), findsOneWidget);
    expect(_t('포트폴리오 구성'), findsOneWidget);
    // 나무 잔고에는 일간 손익이 없다
    expect(_t('일간 손익'), findsNothing);
  });

  testWidgets('환율이 없으면 시장 띠도 합계도 없고 통화별로만 — 정확한 값만 보인다', (tester) async {
    await _pump(tester, fx: null);
    expect(_t('시장'), findsNothing);
    expect(_t('원화 환산 합계'), findsNothing);
    expect(_t('국내 평가금액'), findsWidgets);
    expect(find.byKey(const ValueKey('screen-section')), findsNWidgets(1));
  });

  testWidgets('한 통화뿐이면 그 통화 지표 + Delta, 거르기 Segmented 없음', (tester) async {
    await _pump(tester, usd: _h('USD', const []));
    expect(_t('국내 평가금액'), findsOneWidget);
    expect(_t('해외 평가금액'), findsNothing);
    expect(_t('매입금액보다'), findsOneWidget);
    expect(_t('전체'), findsNothing);
    expect(_t('3개'), findsNothing);
    expect(_t('2개'), findsOneWidget);
  });

  testWidgets('보유 줄 — 미국은 달러, 원화는 원, 긴 이름 줄바꿈, 타일 없음, Chip 글에 숫자 없음', (
    tester,
  ) async {
    await _pump(tester);
    expect(_tc(r'$6,185.55'), findsWidgets);
    expect(_tc('8,760,000원'), findsWidgets);
    final name = _t('가람전자 아주 긴 종목 이름 우선주 테스트');
    expect(name, findsOneWidget);
    expect(tester.widget<Text>(name).maxLines, isNull);
    expect(_chip('보유 3'), findsNothing);
  });

  testWidgets('거르기 — 섞였을 때만 전체 · 국내 · 해외, 해외를 고르면 달러 줄만', (tester) async {
    await _pump(tester);
    expect(_t('전체'), findsOneWidget);
    await tester.tap(_t('해외'));
    await tester.pump();
    expect(_t('모아 테크놀로지스'), findsOneWidget);
    expect(_t('숲길증권'), findsNothing);
    await tester.tap(_t('국내'));
    await tester.pump();
    expect(_t('모아 테크놀로지스'), findsNothing);
    expect(_t('숲길증권'), findsOneWidget);
  });

  testWidgets('둘 다 실패 — 실패 한 벌(설명은 계좌 안내), 연결 안내 아님', (tester) async {
    await _pump(tester, krwFail: true, usdFail: true);
    expect(_t('내 투자를 불러오지 못했어요'), findsOneWidget);
    expect(_t('보유 종목을 불러오지 못했어요'), findsOneWidget);
    expect(_t('계좌가 없거나 조회 권한이 없을 수 있어요.'), findsNWidgets(2));
    expect(_tc('연결'), findsNothing);
  });

  testWidgets('한쪽만 실패하면 남은 통화가 보인다', (tester) async {
    await _pump(tester, usdFail: true);
    expect(_t('내 투자를 불러오지 못했어요'), findsNothing);
    expect(_t('국내 평가금액'), findsOneWidget);
    expect(_t('숲길증권'), findsOneWidget);
  });

  testWidgets('보유 0 — 지표 0원과 안내', (tester) async {
    await _pump(tester, krw: _h('KRW', const []), usd: _h('USD', const []));
    expect(_t('보유 중인 종목이 없어요'), findsWidgets);
    expect(_t('0원'), findsOneWidget);
  });

  testWidgets('관심 — 그룹마다 제목 · ⋮ · 맨 끝 "그룹 추가", 보이는 묶음만 시세 한 번에', (
    tester,
  ) async {
    await _pump(
      tester,
      groups: [
        _group(1, '반도체', ['A1', 'A2']),
        _group(2, '배당', ['A2', 'A3']),
        _group(3, '비어 있는 그룹', []),
      ],
    );
    await tester.tap(_chip('관심'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_t('반도체 · 2'), findsOneWidget);
    expect(_t('아직 담은 종목이 없어요'), findsOneWidget);
    expect(find.bySemanticsLabel('반도체 더보기'), findsOneWidget);
    expect(quotesAsked, isNotEmpty);
    // 겹친 종목은 한 번만 — 그룹마다 따로 부르지 않는다
    expect(quotesAsked.toSet().length, 1);
    expect(quotesAsked.first, 'A1,A2,A3');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_tc('70,000원'), findsWidgets);
    await tester.scrollUntilVisible(
      _t('그룹 추가'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_t('그룹 추가'), findsOneWidget);
  });

  testWidgets(
    '관심에서 보유로 돌아와도 예외가 나지 않는다 — 묶음이 사라질 때 잠긴 트리에서 setState 를 부르지 않는다',
    (tester) async {
      await _pump(
        tester,
        groups: [
          _group(1, '반도체', ['A1', 'A2']),
        ],
      );
      await tester.tap(_chip('관심'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_t('반도체 · 2'), findsOneWidget);
      await tester.tap(_chip('보유'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(_t('반도체 · 2'), findsNothing);
    },
  );

  testWidgets('보유 탭에서는 관심 시세를 부르지 않는다', (tester) async {
    await _pump(
      tester,
      groups: [
        _group(1, '반도체', ['A1']),
      ],
    );
    expect(quotesAsked, isEmpty);
  });

  testWidgets('글자 200% 에서도 가로 넘침 없음', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  group('상세', () {
    testWidgets('보유 종목 — 내 보유 여섯 줄, 호가 · 체결 · 매매 없음, 둘째 안내 줄만', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900001'),
        size: const Size(360, 3000),
      );
      expect(_t('종목 상세'), findsOneWidget);
      expect(_t('내 보유'), findsOneWidget);
      for (final k in ['평가금액', '평가손익', '보유수량', '수익률', '평균단가', '매입금액']) {
        expect(_t(k), findsOneWidget, reason: k);
      }
      expect(_t('수수료·세금'), findsNothing);
      expect(_t('호가 · 체결'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is PButton && (w.label == '매도' || w.label == '매수'),
        ),
        findsNothing,
      );
      expect(_t('기본 정보'), findsOneWidget);
      expect(_t('일별 시세'), findsOneWidget);
      expect(_tc('토스'), findsNothing);
      expect(_tc('Open API 연동 시'), findsNothing);
      expect(_tc('시세는 투자 참고용이에요.'), findsOneWidget);
      expect(_tc('+'), findsNothing);
    });

    testWidgets('보유가 아닌 종목 — 내 보유 띠 없음, 시세 한 번 불러 등락을 보인다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'ZZ0001'),
        size: const Size(360, 3000),
      );
      expect(_t('내 보유'), findsNothing);
      expect(quotesAsked, ['ZZ0001']);
      expect(_tc('70,000원'), findsWidgets);
      expect(_tc('1.45%'), findsOneWidget);
    });
  });

  group('포트폴리오', () {
    testWidgets('환율이 있으면 도넛 + 범례(원화 환산 비중)', (tester) async {
      await _pump(
        tester,
        home: const NamuPortfolioPage(),
        size: const Size(360, 1200),
      );
      expect(_t('포트폴리오 구성'), findsOneWidget);
      expect(_t('모아 테크놀로지스'), findsOneWidget);
      expect(_tc('%'), findsWidgets);
    });

    testWidgets('환율이 없으면 도넛 대신 안내', (tester) async {
      await _pump(
        tester,
        home: const NamuPortfolioPage(),
        size: const Size(360, 1200),
        fx: null,
      );
      expect(_t('환율을 못 받아 구성 비중을 낼 수 없어요'), findsOneWidget);
      expect(_t('모아 테크놀로지스'), findsNothing);
    });
  });
}
