/// 라이브 시세 한 벌 — 자산 화면 세 곳(목록·상세·추가/편집)이 **같은 규칙**을 쓰게 모아 둔 provider.
///
/// 흩어져 있던 탓에 실제로 두 번 어긋났다.
/// - 증권사 무관 경로로 옮길 때 목록만 옮기고 상세·추가/편집이 토스 provider 에 남아,
///   나무 사용자는 한 화면에서 총액은 맞고 종목별 평가액만 '—' 였다.
/// - 원화 환산이 "KRW 아니면 USD" 였다. 토스 시절엔 통화가 둘뿐이라 맞았지만 나무를 붙이며
///   JPY·HKD·CNY 가 들어와, 엔화 종목에 달러 환율을 곱하면 평가액이 백 배 넘게 부푼다.
///
/// 그래서 **통화별 환율**과 **전일 종가 조달**을 여기 한 곳에 둔다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/features/stocks/application/securities_providers.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/data/securities_repository.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';

/// 환산이 끝난 시세 묶음. 화면은 여기서만 값을 꺼낸다.
class LivePrices {
  const LivePrices._(this._quotes, this._rates, this._prevCloses);

  const LivePrices.empty()
    : _quotes = const {},
      _rates = const {},
      _prevCloses = const {};

  final Map<String, BrokerQuote> _quotes;
  final Map<String, double> _rates;
  final Map<String, double> _prevCloses;

  /// 원표기 견적 — 통화 기호를 붙여 보여줄 때 쓴다. 환산은 [unitKrw] 를 써라.
  BrokerQuote? quoteOf(String symbol) => _quotes[symbol];

  /// 1주 원화 환산가. 시세·환율 미확보면 null — 호출부가 그 자산 평가를 접는다.
  double? unitKrw(String symbol) {
    final q = _quotes[symbol];
    return q == null ? null : _toKrw(q.price, q.currency);
  }

  /// 전일 종가의 원화 환산가. 등락 표시 전용 — 없으면 등락을 감춘다.
  double? prevUnitKrw(String symbol) {
    final q = _quotes[symbol];
    if (q == null) return null;
    final prev = q.previousClose ?? _prevCloses[symbol];
    if (prev == null || prev <= 0) return null;
    return _toKrw(prev, q.currency);
  }

  double? _toKrw(double price, String currency) {
    if (currency.toUpperCase() == 'KRW') return price;
    final rate = _rates[currency.toUpperCase()];
    // 환율을 못 구한 통화는 환산하지 않는다 — 다른 통화 환율을 대신 곱하면 금액이 통째로 틀린다.
    return (rate != null && rate > 0) ? price * rate : null;
  }
}

/// 심볼 목록(콤마 구분, 정렬)에 대한 라이브 시세. 빈 문자열이면 아무것도 조회하지 않는다.
///
/// 게이트(프로 + 증권사 연결)는 호출부가 이미 확인한 것으로 본다 — 심볼이 비어 있으면
/// 어차피 조회가 없다.
final livePricesProvider = FutureProvider.family<LivePrices, String>((
  ref,
  symbolsCsv,
) async {
  final symbols = symbolsCsv.split(',').where((s) => s.isNotEmpty).toList();
  if (symbols.isEmpty) return const LivePrices.empty();

  final repo = await ref.watch(securitiesRepositoryProvider.future);
  final quotes = await repo.getPrices(symbols);
  final bySymbol = {for (final q in quotes) q.symbol: q};

  // 응답에 실제로 등장한 통화만 환율을 받는다 — 안 쓰는 통화를 미리 묻지 않는다.
  final currencies = {
    for (final q in quotes)
      if (q.currency.toUpperCase() != 'KRW') q.currency.toUpperCase(),
  };
  final rates = <String, double>{};
  for (final c in currencies) {
    try {
      final rate = await repo.getExchangeRate(base: c, quote: 'KRW');
      if (rate != null && rate > 0) rates[c] = rate;
    } catch (_) {
      // 못 구한 통화는 환산하지 않는다. 그 종목만 평가에서 빠진다.
    }
  }

  // 전일 종가는 증권사마다 사정이 다르다. 나무는 시세 응답에 딸려 오고, 토스는 캔들을
  // 종목마다 따로 받아야 한다 — 그래서 기본 소스가 토스일 때만 캔들을 부른다.
  // 나무 사용자가 부르면 토스 크리덴셜이 없어 종목 수만큼 403 이 나간다.
  final prevCloses = <String, double>{};
  final primary = ref.watch(myFeaturesProvider).asData?.value.primaryBroker;
  if (primary == 'TOSS') {
    for (final s in symbols) {
      if (bySymbol[s]?.previousClose != null) continue;
      try {
        final prev = await ref.watch(prevCloseProvider(s).future);
        if (prev != null && prev > 0) prevCloses[s] = prev;
      } catch (_) {}
    }
  }

  return LivePrices._(bySymbol, rates, prevCloses);
});

/// 심볼 집합을 provider 키로 쓸 문자열로. 정렬해 같은 집합이 같은 키가 되게 한다.
String livePricesKey(Iterable<String> symbols) {
  final list = symbols.where((s) => s.isNotEmpty).toSet().toList()..sort();
  return list.join(',');
}
