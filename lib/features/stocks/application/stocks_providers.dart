/// 토스증권 Open API 연동 Riverpod providers.
/// 모든 provider 는 에러(키 미설정 503·미기동)를 삼키고 null/false 로 폴백 → 화면은 mock 유지.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_mock.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_repository.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';

final stocksRepositoryProvider = FutureProvider<StocksRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return StocksRepository(dio);
});

/// 화면 진입 시 전체 종목 라이브 시세 + 환율을 받아 mock 모듈에 적용.
/// 키 있으면 실데이터(kStocks[].price / kFxUsdKrw 갱신), 없으면 mock 유지. applied 여부 반환.
final stockLiveOverlayProvider = FutureProvider<bool>((ref) async {
  var applied = false;
  final StocksRepository repo;
  try {
    repo = await ref.watch(stocksRepositoryProvider.future);
  } catch (_) {
    return false;
  }
  try {
    final prices = await repo.getPrices(kStocks.map((s) => s.ticker).toList());
    final map = {for (final p in prices) p.symbol: p.priceValue};
    if (applyLivePrices(map)) applied = true;
  } catch (_) {
    // 키 없음/미기동 → mock 시세 유지
  }
  try {
    final fx = await repo.getExchangeRate();
    if (setLiveFx(fx.rateValue)) applied = true;
  } catch (_) {
    // mock 환율 유지
  }
  return applied;
});

/// 종목 호가 (라이브). 에러/미설정 시 null → 호가창 의사난수 폴백.
final tossOrderbookProvider =
    FutureProvider.family<TossOrderbook?, String>((ref, symbol) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getOrderbook(symbol);
  } catch (_) {
    return null;
  }
});

/// 종목 체결 내역 (라이브). 에러/미설정 시 null → 체결 테이프 의사난수 폴백.
final tossTradesProvider =
    FutureProvider.family<List<TossTrade>?, String>((ref, symbol) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getTrades(symbol);
  } catch (_) {
    return null;
  }
});
