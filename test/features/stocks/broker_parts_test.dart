// 증권사 공통 맞춤(I-13b 13b-1) — 응답 모양(칸이 빠져도 깨지지 않는다) · 그 탭 증권사 경로 · 시장 대표 종목 · 임베드 쿼리 자리.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/stocks/application/namu_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_bridge.dart';

/// 요청 경로만 기록하고 빈 `data` 로 답하는 어댑터.
class _Recorder implements HttpClientAdapter {
  final paths = <String>[];
  final queries = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    queries.add(options.queryParameters);
    return ResponseBody.fromString(
      '{"data":null}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  _more();
  test('나무 상세 시세 — 칸이 거의 없어도 깨지지 않고, 0 · 빈 값은 null', () {
    final d = NamuQuoteDetail.fromJson({
      'symbol': '005930',
      'price': '0',
      'open': '',
      'volume': 1234,
      'warnings': [
        {'warningType': 'INVESTMENT_ATTENTION'},
        {'nothing': 1},
      ],
      'orderbook': {'asks': [], 'bids': []},
    });
    expect(d.price, isNull);
    expect(d.open, isNull);
    expect(d.volume, 1234);
    expect(d.warnings, ['INVESTMENT_ATTENTION']);
    expect(d.orderbook, isNull);
    expect(d.hasToday, isTrue);
    expect(NamuQuoteDetail.fromJson({}).hasToday, isFalse);
  });

  test('나무 호가는 토스 호가 모양으로 옮겨진다', () {
    final d = NamuQuoteDetail.fromJson({
      'orderbook': {
        'currency': 'KRW',
        'asks': [
          {'price': '70100', 'volume': '10'},
        ],
        'bids': [
          {'price': '70000', 'volume': '20'},
        ],
      },
    });
    expect(d.orderbook!.asks.single.priceValue, 70100);
    expect(d.orderbook!.bids.single.volumeValue, 20);
  });

  test('투자자별 — 개인이 null 이어도 읽힌다', () {
    final days = investorDaysFromJson([
      {
        'date': '2026-10-23',
        'individual': null,
        'foreigner': '3400',
        'institution': '-100',
      },
    ]);
    expect(days.single.individual, isNull);
    expect(days.single.foreigner, 3400);
    expect(days.single.institution, -100);
  });

  test('나무 화면은 나무 경로를 부른다 — /securities/* 가 아니다', () async {
    final rec = _Recorder();
    final repo = NamuRepository(Dio()..httpClientAdapter = rec);
    await repo.getListQuotes(['A', 'B']);
    await repo.getCandles('A', '1d', size: 10);
    await repo.getExchangeRate();
    await repo.getQuoteDetail('A', us: false);
    await repo.getQuoteDetail('MOA', us: true);
    await repo.getExecutions('A', us: false);
    await repo.getExecutions('MOA', us: true);
    await repo.getInvestors('A');
    await repo.getUsdDeposit();
    expect(rec.paths, [
      '/namu/prices',
      '/namu/candles',
      '/namu/exchange-rate',
      '/namu/kr/quote',
      '/namu/gb/quote',
      '/namu/kr/executions',
      '/namu/gb/executions',
      '/namu/kr/investors',
      '/namu/margin',
    ]);
    expect(rec.paths.where((p) => p.startsWith('/securities')), isEmpty);
    expect(rec.queries.first['symbols'], 'A,B');
  });

  test('시장 대표 종목 — 보유 첫 종목, 없으면 관심 첫 종목, 시장마다', () {
    StockWatchGroup g(List<(String, String)> items) => StockWatchGroup(
      rowId: 1,
      groupName: 'g',
      sortOrder: 1,
      items: [
        for (final (i, e) in items.indexed)
          WatchItem(
            rowId: i,
            stockMasterRowId: 1,
            countryCode: e.$2,
            marketCode: 'X',
            symbol: e.$1,
            nameKr: e.$1,
            securityType: 'STOCK',
            currency: 'KRW',
          ),
      ],
    );
    final empty = mergeNamuHoldings(null, null, null);
    final reps = namuMarketRepresentatives(empty, [
      g([('K1', 'KR'), ('U1', 'US'), ('K2', 'KR')]),
    ]);
    expect(reps.kr, 'K1');
    expect(reps.us, 'U1');
    final none = namuMarketRepresentatives(empty, const []);
    expect(none.kr, isNull);
    expect(none.us, isNull);
  });

  test('임베드 증권사 쿼리는 웹이 알게 된 뒤라 주소에 실린다', () {
    expect(kEmbedBrokerQueryEnabled, isTrue);
    final url = buildEmbedUrl(
      webBaseUrl: 'https://example.invalid',
      symbol: 'A',
      range: '1D',
      theme: 'light',
      isUs: false,
      broker: 'namu',
    );
    expect(Uri.parse(url).queryParameters['broker'], 'namu');
  });

  test('증권사를 모르면(broker null) 쿼리를 싣지 않는다', () {
    final url = buildEmbedUrl(
      webBaseUrl: 'https://example.invalid',
      symbol: 'A',
      range: '1D',
      theme: 'light',
      isUs: false,
    );
    expect(Uri.parse(url).queryParameters.containsKey('broker'), isFalse);
  });
}

void _more() {
  group('서머타임 규칙(N2) — 3월 둘째 일요일 ~ 11월 첫째 일요일', () {
    test('2026: 3월 8일 07:00 UTC 부터 · 11월 1일 06:00 UTC 전까지', () {
      expect(
        isUsEasternDst(DateTime.utc(2026, 3, 8, 6, 59)),
        isFalse,
        reason: '둘째 일요일 직전',
      );
      expect(
        isUsEasternDst(DateTime.utc(2026, 3, 8, 7)),
        isTrue,
        reason: '둘째 일요일 시작',
      );
      expect(
        isUsEasternDst(DateTime.utc(2026, 3, 7, 23)),
        isFalse,
        reason: '전날(토요일)',
      );
      expect(
        isUsEasternDst(DateTime.utc(2026, 3, 20, 16)),
        isTrue,
        reason: '3월 20일은 EDT 다(옛 어림은 EST)',
      );
      expect(
        isUsEasternDst(DateTime.utc(2026, 11, 1, 5, 59)),
        isTrue,
        reason: '첫째 일요일 끝나기 전',
      );
      expect(
        isUsEasternDst(DateTime.utc(2026, 11, 1, 6)),
        isFalse,
        reason: '첫째 일요일 02:00 EDT',
      );
      expect(
        isUsEasternDst(DateTime.utc(2026, 10, 31, 12)),
        isTrue,
        reason: '전날(토요일)',
      );
      expect(isUsEasternDst(DateTime.utc(2026, 11, 2, 12)), isFalse);
    });

    test('2027(다음 3월 14일) · 2028 윤년(3월 12일 · 11월 5일)도 같은 규칙', () {
      expect(isUsEasternDst(DateTime.utc(2027, 3, 14, 6, 59)), isFalse);
      expect(isUsEasternDst(DateTime.utc(2027, 3, 14, 7)), isTrue);
      expect(isUsEasternDst(DateTime.utc(2027, 11, 7, 5, 59)), isTrue);
      expect(isUsEasternDst(DateTime.utc(2027, 11, 7, 6)), isFalse);
      // 윤년 2024: 3월 10일 · 11월 3일
      expect(isUsEasternDst(DateTime.utc(2024, 3, 10, 6, 59)), isFalse);
      expect(isUsEasternDst(DateTime.utc(2024, 3, 10, 7)), isTrue);
      expect(isUsEasternDst(DateTime.utc(2024, 11, 3, 6)), isFalse);
    });

    TossCandle bar(String ts, {String close = '2'}) => TossCandle(
      timestamp: ts,
      openPrice: '1',
      highPrice: '3',
      lowPrice: '1',
      closePrice: close,
      volume: '10',
    );

    test('3월 20일(2026) 미국 장중 — 현지 자정 봉이 오늘이고 전일 종가는 전날 봉', () {
      final now = DateTime.utc(2026, 3, 20, 16); // 뉴욕 12:00 EDT
      final candles = [
        bar('2026-03-20T00:00:00-04:00', close: '9'),
        bar('2026-03-19T00:00:00-04:00', close: '5'),
      ];
      expect(marketToday('MOA', now), '2026-03-20');
      expect(todayBarOf(candles, 'MOA', now)?.closePrice, '9');
      expect(
        prevCloseFromCandles(candles, marketToday('MOA', now), symbol: 'MOA'),
        5.0,
      );
    });

    test('11월 첫째 일요일 전(2026-10-30) · 직후(2026-11-02)도 봉 날짜가 하루 밀리지 않는다', () {
      final c1 = [
        bar('2026-10-30T00:00:00-04:00', close: '9'),
        bar('2026-10-29T00:00:00-04:00', close: '5'),
      ];
      final n1 = DateTime.utc(2026, 10, 30, 16);
      expect(todayBarOf(c1, 'MOA', n1)?.closePrice, '9');
      final c2 = [
        bar('2026-11-02T00:00:00-05:00', close: '9'),
        bar('2026-10-30T00:00:00-04:00', close: '5'),
      ];
      final n2 = DateTime.utc(2026, 11, 2, 17);
      expect(todayBarOf(c2, 'MOA', n2)?.closePrice, '9');
      expect(
        prevCloseFromCandles(c2, marketToday('MOA', n2), symbol: 'MOA'),
        5.0,
      );
    });
  });

  group('전일 종가 다시 받기(N3)', () {
    test('받은 날과 지금 시장 날짜가 다른 종목만 고른다 — 미국은 현지 날짜', () {
      final days = {'005930': '2026-10-28', 'MOA': '2026-10-28'};
      // 한국 10-29 01:00 → 국내 10-29, 미국 동부 10-28(전날 밤)
      final now = DateTime.utc(2026, 10, 28, 16);
      expect(stalePrevCloseSymbols(days, now), ['005930']);
      expect(stalePrevCloseSymbols(days, DateTime.utc(2026, 10, 29, 10)), [
        '005930',
        'MOA',
      ]);
      expect(stalePrevCloseSymbols(const {}, now), isEmpty);
    });
  });

  group('오늘 시세 오늘 봉(M11) — 그 시장의 오늘', () {
    TossCandle bar(String ts, {String o = '1'}) => TossCandle(
      timestamp: ts,
      openPrice: o,
      highPrice: '2',
      lowPrice: '1',
      closePrice: '2',
      volume: '10',
    );

    test('미국: 한국 낮(미국 새벽)에도 현지 거래일 봉을 찾는다', () {
      // 한국 2026-10-29 12:00 = 미국 동부 10-28 23:00 — 기기 날짜(10-29)로 견주면 못 찾는다.
      final now = DateTime.utc(2026, 10, 29, 3);
      final found = todayBarOf(
        [
          bar('2026-10-27T00:00:00-04:00'),
          bar('2026-10-28T00:00:00-04:00', o: '9'),
        ],
        'MOA',
        now,
      );
      expect(found?.openPrice, '9');
    });

    test('국내: 한국 날짜 봉만, 어제 봉이면 null · 봉 순서(최신순)를 믿지 않는다', () {
      final now = DateTime.utc(2026, 10, 29, 1);
      expect(
        todayBarOf([bar('2026-10-28T00:00:00+09:00')], '005930', now),
        isNull,
      );
      final found = todayBarOf(
        [
          bar('2026-10-29T00:00:00+09:00', o: '7'),
          bar('2026-10-28T00:00:00+09:00'),
        ],
        '005930',
        now,
      );
      expect(found?.openPrice, '7');
      expect(todayBarOf(const [], '005930', now), isNull);
    });
  });

  group('시장 대표 종목은 정렬이 바뀌어도 그대로(M14)', () {
    NamuMergedView view(List<String> symbols) => mergeNamuHoldings(
      NamuHoldings(
        accountNo: 'a',
        currency: 'KRW',
        totalEvalAmount: '0',
        totalProfitLoss: '0',
        profitRate: '0',
        items: [
          for (final (i, s) in symbols.indexed)
            NamuHoldingItem(
              symbol: s,
              name: s,
              quantity: '1',
              avgPrice: '1',
              currentPrice: '1',
              evalAmount: '${100 - i}',
              profitLoss: '0',
            ),
        ],
      ),
      null,
      null,
    );

    test('이전 대표가 후보에 남아 있으면 첫 줄이 바뀌어도 유지, 사라지면 새 첫 줄', () {
      final first = namuMarketRepresentatives(view(['A', 'B']), const []);
      expect(first.kr, 'A');
      final reordered = namuMarketRepresentatives(
        view(['B', 'A']),
        const [],
        prevKr: first.kr,
      );
      expect(reordered.kr, 'A', reason: '정렬이 바뀌어 키가 바뀌면 장 상태 줄이 깜빡인다');
      final gone = namuMarketRepresentatives(
        view(['B', 'C']),
        const [],
        prevKr: 'A',
      );
      expect(gone.kr, 'B');
    });
  });

  test('나무 미국 체결 시각은 오프셋을 읽어 한국 시각으로(M7)', () {
    final t = tradesFromJson([
      {
        'price': '412.3',
        'volume': '5',
        'timestamp': '2026-10-29T10:11:12-04:00',
      },
    ]);
    expect(clock12Minutes(t.single.timestamp), '오후 11:11');
    expect(clock12Minutes('2026-10-29T13:00:00+09:00'), '오후 1:00');
  });

  test('나무 상장일 원문 20040101 도 연도 붙은 날짜로(M6)', () {
    expect(fullDateOf('20040101'), '2004년 1월 1일');
    expect(fullDateOf('1975-06-11'), '1975년 6월 11일');
  });

  test('새 영어 글은 웹 CSV 와 같다(M15)', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(en['stocksBuyingPowerKrw'], 'Orderable · KRW');
    expect(en['stocksBuyingPowerUsd'], 'Orderable · USD');
    expect(en['namuDepositUsd'], 'Deposit · USD');
    expect(en['stocksTodayQuote'], "Today's quotes");
    expect(en['stocksInvestorTitle'], 'Net buying by investor');
    expect(en['stocksWarningInvestmentAttention'], 'Investment attention');
    expect(en['stocksMarketAfter'], 'After-market');
    expect(en['stocksMarketHalted'], 'Temporarily closed');
    expect(en['namuFxUnavailableShort'], 'No FX rate');
  });
}
