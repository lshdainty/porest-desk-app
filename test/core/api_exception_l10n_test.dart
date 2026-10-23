// 서버 문장이 없을 때의 폴백 — 영어 상수 · 코드가 섞인 문장 대신 로케일 문구(03F-011a). 코드는 code 에만 있다.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';

DioException _e({Response<dynamic>? res}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: res,
);

void main() {
  tearDown(() => Intl.defaultLocale = null);

  test('한국어 — 네트워크 · 비JSON 502 · message 없는 JSON', () {
    Intl.defaultLocale = 'ko';
    final net = ApiException.fromDio(_e());
    expect(net.code, 'NETWORK');
    expect(net.message, '네트워크 연결이 불안정해요. 잠시 뒤 다시 시도해주세요.');
    final bad = ApiException.fromDio(
      _e(
        res: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 502,
          data: 'Bad Gateway',
        ),
      ),
    );
    expect(bad.code, 'HTTP_502');
    expect(bad.message, '요청을 처리하지 못했어요. 잠시 뒤 다시 시도해주세요.');
    expect(bad.message.contains('502'), isFalse, reason: '코드를 문장에 섞지 않는다');
    final json = ApiException.fromDio(
      _e(
        res: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
          data: <String, dynamic>{'code': 'X_1'},
        ),
      ),
    );
    expect(json.message, bad.message);
    expect(json.code, 'X_1');
  });

  test('영어', () {
    Intl.defaultLocale = 'en';
    expect(
      ApiException.fromDio(_e()).message,
      'The network connection is unstable. Please try again in a moment.',
    );
  });

  test('서버가 준 문장은 그대로', () {
    final r = ApiException.fromDio(
      _e(
        res: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: <String, dynamic>{'code': 'A', 'message': '서버 문장'},
        ),
      ),
    );
    expect(r.message, '서버 문장');
  });
}
