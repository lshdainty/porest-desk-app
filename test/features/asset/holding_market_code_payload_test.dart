// 시장코드를 손에 쥐고 버리던 걸 고쳤다 — 종목 검색 응답은 marketCode 를 주고 검색 결과
// 줄에 "AAPL · NAS" 로 찍어 주기까지 하는데, 보유로 담을 때 심볼만 남겼다. 같은 티커가
// 여러 시장에 걸리는 종목(SPY·IVV·JEPI·SOXL)은 서버가 심볼만 보고 확정하지 못한다.
//
// 저장 요청 바디에 실제로 실리는지, 그리고 없을 땐 아예 안 나가는지(선택 필드라 서버가
// 심볼로 해석한다)를 고정한다.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';

/// 요청 바디를 잡아 두고 빈 자산 응답을 돌려주는 Dio.
(Dio, List<Map<String, dynamic>> captured) _capturingDio() {
  final captured = <Map<String, dynamic>>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add((options.data as Map).cast<String, dynamic>());
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: const {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': {
                'rowId': 1,
                'assetName': '증권계좌',
                'assetType': 'INVESTMENT',
              },
            },
          ),
        );
      },
    ),
  );
  return (dio, captured);
}

Map<String, dynamic> _firstHolding(Map<String, dynamic> body) =>
    (body['holdings'] as List).first as Map<String, dynamic>;

void main() {
  test('연동 보유의 시장코드가 저장 요청에 실린다', () async {
    final (dio, captured) = _capturingDio();

    await AssetRepository(dio).create(
      assetName: '증권계좌',
      assetType: 'INVESTMENT',
      holdings: const [
        AssetHolding(
          linked: true,
          marketCode: 'NAS',
          tossSymbol: 'SPY',
          quantity: '3',
        ),
      ],
    );

    final h = _firstHolding(captured.single);
    expect(h['marketCode'], 'NAS');
    expect(h['tossSymbol'], 'SPY');
  });

  test('시장코드가 없으면 키를 아예 안 보낸다 — 서버가 심볼로 해석한다', () async {
    final (dio, captured) = _capturingDio();

    await AssetRepository(dio).create(
      assetName: '증권계좌',
      assetType: 'INVESTMENT',
      holdings: const [
        AssetHolding(linked: true, tossSymbol: '005930', quantity: '10'),
      ],
    );

    expect(_firstHolding(captured.single).containsKey('marketCode'), isFalse);
  });

  test('미연동 보유는 시장코드를 담지 않는다 — 종목이 아니다', () async {
    final (dio, captured) = _capturingDio();

    await AssetRepository(dio).create(
      assetName: '증권계좌',
      assetType: 'INVESTMENT',
      holdings: const [
        AssetHolding(
          marketCode: 'NAS',
          holdingName: '금괴',
          holdingValue: 1000,
        ),
      ],
    );

    expect(_firstHolding(captured.single).containsKey('marketCode'), isFalse);
  });

  test('서버 응답의 시장코드를 그대로 받아 든다 — 편집에서 다시 돌려보내야 한다', () {
    final h = AssetHolding.fromJson(const {
      'rowId': 1,
      'linked': true,
      'marketCode': 'KOSPI',
      'tossSymbol': '005930',
    });

    expect(h.marketCode, 'KOSPI');
  });

  test('구버전 서버 응답(marketCode 없음)도 그대로 파싱된다', () {
    final h = AssetHolding.fromJson(const {
      'rowId': 1,
      'linked': true,
      'tossSymbol': '005930',
    });

    expect(h.marketCode, isNull);
  });
}
