// 증권사 공통 맞춤(I-13b 13b-1) — 응답 모양(칸이 빠져도 깨지지 않는다) · 그 탭 증권사 경로 · 시장 대표 종목 · 임베드 쿼리 자리.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/stocks/application/namu_model.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
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

  test('임베드 증권사 쿼리는 웹이 알기 전에는 주소에 실리지 않는다', () {
    expect(kEmbedBrokerQueryEnabled, isFalse);
    final url = buildEmbedUrl(
      webBaseUrl: 'https://example.invalid',
      symbol: 'A',
      range: '1D',
      theme: 'light',
      isUs: false,
      broker: 'namu',
    );
    expect(Uri.parse(url).queryParameters.containsKey('broker'), isFalse);
  });
}
