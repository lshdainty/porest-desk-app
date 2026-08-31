// StocksRepository 는 네트워크 실패를 ApiException 으로 정규화해서 내보내야 한다.
//
// getCandles 는 count 에 따라 경로가 갈린다 — ≤200 은 단일 요청, 초과는 커서 누적.
// 단일 요청 경로가 한동안 `return _getCandlePage(...)` 로 await 없이 반환하고 있었다.
// async 함수에서 Future 를 await 없이 return 하면 그 Future 는 try 블록이 끝난 뒤에
// 완료되므로 `on DioException` 이 잡지 못하고, 이 경로만 DioException 이 그대로 샜다.
// 호출부(prevCloseProvider 등)가 catch (_) 로 전부 삼키고 있어 증상이 안 보였을 뿐이다.
//
// 두 경로 모두 같은 예외 타입을 내보내는지 고정한다.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_repository.dart';

/// 모든 요청을 DioException 으로 거절하는 Dio — 네트워크 무응답 상황.
Dio _failingDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ),
    ),
  );
  return dio;
}

Future<Object?> _thrownBy(Future<void> Function() body) async {
  try {
    await body();
    return null;
  } catch (e) {
    return e;
  }
}

void main() {
  late StocksRepository repo;

  setUp(() => repo = StocksRepository(_failingDio()));

  test('getCandles — 단일 요청 경로(count ≤ 200)도 ApiException 으로 정규화한다', () async {
    final e = await _thrownBy(() => repo.getCandles('005930', '1d', count: 3));

    expect(
      e,
      isA<ApiException>(),
      reason: 'DioException 이 그대로 나오면 await 가 빠져 try 를 벗어난 것',
    );
  });

  test('getCandles — count 미지정도 단일 요청 경로를 탄다', () async {
    final e = await _thrownBy(() => repo.getCandles('005930', '1d'));

    expect(e, isA<ApiException>());
  });

  test('getCandles — 커서 누적 경로(count > 200)도 ApiException 으로 정규화한다', () async {
    final e = await _thrownBy(
      () => repo.getCandles('005930', '1d', count: 500),
    );

    expect(e, isA<ApiException>());
  });

  test('네트워크 무응답은 NETWORK 코드로 정규화된다', () async {
    final e = await _thrownBy(() => repo.getCandles('005930', '1d', count: 3));

    expect((e! as ApiException).code, 'NETWORK');
  });
}
