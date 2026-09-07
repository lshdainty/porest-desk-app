// 보유 종목의 `sortOrder` 를 저장 요청에 싣지 않는다 (QA #91).
//
// 앱은 보유마다 `sortOrder` 를 매겨 보냈는데 서버 `HoldingRequest` 에 그 필드가 없어
// Jackson 이 조용히 버렸다. 순서는 **보낸 배열의 인덱스**로 서버가 정하고
// (`AssetServiceImpl.saveHoldings` 의 `i`), 조회는 `sortOrder asc, rowId asc` 로 그
// 순서를 되돌려준다. 즉 배열 순서만 지키면 왕복이 맞고, 번호를 따로 실을 자리는 없다.
//
// 여기서 고정하는 것은 둘이다.
//   ① 요청 바디의 보유에 `sortOrder` 키가 없다 — 다시 실으면 "보낸 번호대로 저장된다" 는
//      착각이 되살아나고, 배열 순서와 어긋나도 아무도 모른다
//   ② 배열 순서가 화면 순서 그대로다 — 이제 이게 유일한 순서 신호다
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

List<Map<String, dynamic>> _holdings(Map<String, dynamic> body) =>
    (body['holdings'] as List).cast<Map<String, dynamic>>();

/// 화면에서 담긴 상태 그대로 — 각 행이 자기 sortOrder 를 들고 있다.
const _rows = [
  AssetHolding(linked: true, tossSymbol: 'SPY', quantity: '3', sortOrder: 0),
  AssetHolding(
    linked: true,
    tossSymbol: '005930',
    quantity: '10',
    sortOrder: 1,
  ),
  AssetHolding(holdingName: '금괴', holdingValue: 1000, sortOrder: 2),
];

void main() {
  test('생성 요청의 보유에는 sortOrder 키가 없다', () async {
    final (dio, captured) = _capturingDio();

    await AssetRepository(
      dio,
    ).create(assetName: '증권계좌', assetType: 'INVESTMENT', holdings: _rows);

    for (final h in _holdings(captured.single)) {
      expect(h.containsKey('sortOrder'), isFalse, reason: '$h');
    }
  });

  test('수정 요청의 보유에도 sortOrder 키가 없다', () async {
    final (dio, captured) = _capturingDio();

    await AssetRepository(dio).update(
      id: 1,
      assetName: '증권계좌',
      assetType: 'INVESTMENT',
      holdings: _rows,
    );

    for (final h in _holdings(captured.single)) {
      expect(h.containsKey('sortOrder'), isFalse, reason: '$h');
    }
  });

  test('순서는 배열 순서가 지킨다 — 서버가 인덱스로 sortOrder 를 매긴다', () async {
    final (dio, captured) = _capturingDio();

    await AssetRepository(dio).create(
      assetName: '증권계좌',
      assetType: 'INVESTMENT',
      // 화면에서 금괴를 맨 앞으로 끌어올린 상태. 행이 들고 있던 sortOrder 는
      // 그대로(0·1·2)라 번호로는 순서가 뒤집힌 걸 알 수 없다 — 배열만이 안다.
      holdings: [_rows[2], _rows[0], _rows[1]],
    );

    final sent = _holdings(captured.single);
    expect(sent[0]['holdingName'], '금괴');
    expect(sent[1]['tossSymbol'], 'SPY');
    expect(sent[2]['tossSymbol'], '005930');
  });

  test('서버가 내려준 sortOrder 는 그대로 파싱한다 — 응답에는 남아 있다', () {
    final h = AssetHolding.fromJson(const {
      'rowId': 1,
      'linked': true,
      'tossSymbol': '005930',
      'sortOrder': 2,
    });

    expect(h.sortOrder, 2);
  });
}
