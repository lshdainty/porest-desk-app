/// KRX 상장종목 마스터 — 토스 연결 종목 검색용(이름→코드).
///
/// 토스 Open API 는 종목명 검색이 없고 6자리 단축코드로만 시세를 조회하므로,
/// 이름 검색을 위해 KRX 공식 상장종목(코드+이름) 데이터를 정적 asset 으로 동봉한다.
/// 코드는 KRX 표준 단축코드 = 토스 코드. 실제 시세 가능 여부(정합성)는 연결 시 백엔드가 토스로 검증.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// KRX 상장종목 한 건 (코드 + 이름 + 시장).
class KrxStock {
  const KrxStock({required this.ticker, required this.name, required this.market});

  final String ticker; // KRX 6자리 단축코드 (= 토스 코드)
  final String name;
  final String market; // KOSPI | KOSDAQ | KONEX

  factory KrxStock.fromJson(Map<String, dynamic> j) => KrxStock(
        ticker: (j['ticker'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        market: (j['market'] as String?) ?? '',
      );
}

/// 종목 마스터 — assets/data/krx_stocks.json 1회 로드. 검색·코드→이름 조회 제공.
class KrxStockMaster {
  KrxStockMaster(this._stocks) : _byTicker = {for (final s in _stocks) s.ticker: s};

  final List<KrxStock> _stocks;
  final Map<String, KrxStock> _byTicker;

  KrxStock? byTicker(String ticker) => _byTicker[ticker];

  /// 이름 부분일치 OR 코드 부분일치 상위 [limit] 개.
  List<KrxStock> search(String query, {int limit = 8}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final upper = q.toUpperCase();
    final out = <KrxStock>[];
    for (final s in _stocks) {
      if (s.name.contains(q) || s.ticker.contains(upper)) {
        out.add(s);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}

/// 마스터 로드 (앱 세션 1회, keepAlive). 실패 시 빈 마스터.
final krxStockMasterProvider = FutureProvider<KrxStockMaster>((ref) async {
  ref.keepAlive();
  try {
    final raw = await rootBundle.loadString('assets/data/krx_stocks.json');
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => KrxStock.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return KrxStockMaster(list);
  } catch (_) {
    return KrxStockMaster(const []);
  }
});
