/// 나무증권 조회 providers. 토스와 나눠 둔다 — 두 증권사가 주는 데이터가 겹치지 않는다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/stocks/data/namu_repository.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';

final namuRepositoryProvider = FutureProvider<NamuRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return NamuRepository(dio);
});

/// 나무 보유 종목. 통화가 KRW 면 국내, 그 밖이면 해외 — 서버가 엔드포인트를 가른다.
final namuHoldingsProvider =
    FutureProvider.family<NamuHoldings, String>((ref, currency) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  return repo.getHoldings(currency: currency);
});

/// 선택 종목의 나무 현재가. 국내·해외 분기는 stock_master 의 국가코드가 정한다.
final namuPriceProvider =
    FutureProvider.family<BrokerPrice?, StockMasterItem>((ref, item) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  return item.countryCode == 'KR'
      ? repo.getKrPrice(item.symbol)
      : repo.getGbPrice(item.symbol);
});
