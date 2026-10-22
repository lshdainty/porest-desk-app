// 읽기 요청의 10초 한도 · 저절로 다시 시도(skeleton.md "요청 제한 10초", 03E-021).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart'
    show kSecuritiesPathPrefixes;
import 'package:groo_damda_app/core/network/interceptors/read_retry_interceptor.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

/// 차례대로 응답하는 가짜 어댑터 — 숫자는 상태 코드, 'net' 은 연결 실패, 'hang' 은 끝내 안 온다.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.script);
  final List<Object> script;
  int calls = 0;
  final methods = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    methods.add(options.method);
    final step = script[calls < script.length ? calls : script.length - 1];
    calls++;
    if (step == 'net') {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    if (step == 'hang') {
      await cancelFuture;
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: options.cancelToken?.cancelError?.error,
      );
    }
    final code = step as int;
    return ResponseBody.fromString(
      jsonEncode({'ok': code < 400}),
      code,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _Adapter adapter, List<Duration> slept, List<DioException> after})
_make(
  List<Object> script, {
  Duration timeout = PLoadingTiming.timeout,
  List<Duration> delays = PLoadingTiming.retryDelays,
  bool realSleep = false,
  List<String> noRetry = const [],
}) {
  final adapter = _Adapter(script);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = ReadDeadlineAdapter(adapter, timeout: timeout);
  final slept = <Duration>[];
  final after = <DioException>[];
  dio.interceptors
    ..add(
      ReadRetryInterceptor(
        dio,
        timeout: timeout,
        delays: delays,
        noRetryPathPrefixes: noRetry,
        sleep: (d) async {
          slept.add(d);
          if (realSleep) await Future<void>.delayed(d);
        },
      ),
    )
    // 뒤 인터셉터(401 처리 · 로그 · 토스트) — 다시 시도로 살아난 요청의 첫 실패는 여기까지 오지 않는다
    ..add(
      InterceptorsWrapper(
        onError: (e, h) {
          after.add(e);
          h.next(e);
        },
      ),
    );
  return (dio: dio, adapter: adapter, slept: slept, after: after);
}

void main() {
  test('스펙 값 — 처음부터 다시 시도까지 합쳐 10초 · 읽기만 2번 1초 · 2초 뒤', () {
    expect(PLoadingTiming.timeout, const Duration(seconds: 10));
    expect(PLoadingTiming.retryDelays, const [
      Duration(seconds: 1),
      Duration(seconds: 2),
    ]);
  });

  test('5xx 는 1초 뒤 다시 보내 살아나고, 뒤 인터셉터는 첫 실패를 보지 못한다', () async {
    final m = _make([500, 200]);
    final res = await m.dio.get<dynamic>('/a');
    expect(res.statusCode, 200);
    expect(m.adapter.calls, 2);
    expect(m.slept, [const Duration(seconds: 1)]);
    expect(m.after, isEmpty);
  });

  test(
    '계속 실패하면 1초 · 2초 뒤 두 번만 다시 보내고(모두 3번) 마지막 실패를 올린다 — 뒤 인터셉터는 한 번만 본다',
    () async {
      final m = _make([503]);
      await expectLater(
        m.dio.get<dynamic>('/a'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            503,
          ),
        ),
      );
      expect(m.adapter.calls, 3);
      expect(m.slept, const [Duration(seconds: 1), Duration(seconds: 2)]);
      expect(m.after.length, 1, reason: '마지막 실패만 뒤 인터셉터를 거친다');
    },
  );

  test('네트워크가 안 닿아도 읽기는 다시 보낸다', () async {
    final m = _make(['net', 200]);
    final res = await m.dio.get<dynamic>('/a');
    expect(res.statusCode, 200);
    expect(m.adapter.calls, 2);
  });

  test('4xx(권한 없음 · 없는 데이터 · 잘못된 요청)는 다시 하지 않고 바로 실패다', () async {
    for (final code in [400, 401, 403, 404, 422]) {
      final m = _make([code, 200]);
      await expectLater(
        m.dio.get<dynamic>('/a'),
        throwsA(isA<DioException>()),
        reason: '$code',
      );
      expect(m.adapter.calls, 1, reason: '$code 는 한 번');
      expect(m.slept, isEmpty);
      expect(m.after.length, 1);
    }
  });

  test('쓰기(POST · PUT · PATCH · DELETE)는 저절로 다시 보내지 않는다 — 두 번 들어간다', () async {
    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      final m = _make([500, 200]);
      await expectLater(
        m.dio.request<dynamic>('/a', options: Options(method: method)),
        throwsA(isA<DioException>()),
        reason: method,
      );
      expect(m.adapter.calls, 1, reason: method);
      expect(m.slept, isEmpty, reason: method);
    }
  });

  test('다시 시도로 10초를 넘기게 되면 하지 않는다', () async {
    // 한도 500ms · 다시 시도 100ms, 400ms — 둘째는 100 + 400 = 500 이 한도에 닿아 하지 않는다
    final m = _make(
      [500],
      timeout: const Duration(milliseconds: 500),
      delays: const [Duration(milliseconds: 100), Duration(milliseconds: 400)],
      realSleep: true,
    );
    await expectLater(m.dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
    expect(m.adapter.calls, 2, reason: '한 번만 다시 보낸다');
    expect(m.slept, const [Duration(milliseconds: 100)]);
  });

  test('끝내 안 오면 한도에서 끊고 시간 초과 실패로 올린다 — 다시 시도도 그 안에서만', () async {
    final m = _make(
      ['hang'],
      timeout: const Duration(milliseconds: 300),
      delays: const [Duration(milliseconds: 50), Duration(milliseconds: 50)],
      realSleep: true,
    );
    final started = DateTime.now();
    await expectLater(
      m.dio.get<dynamic>('/a'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.receiveTimeout,
        ),
      ),
    );
    final took = DateTime.now().difference(started);
    expect(took, lessThan(const Duration(milliseconds: 900)));
    expect(took, greaterThanOrEqualTo(const Duration(milliseconds: 290)));
  });

  test('사용자가 취소한 요청은 다시 보내지 않는다', () async {
    final m = _make(['hang']);
    final token = CancelToken();
    final future = m.dio.get<dynamic>('/a', cancelToken: token);
    final check = expectLater(
      future,
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    token.cancel('user');
    await check;
    expect(m.adapter.calls, 1);
    expect(m.slept, isEmpty);
  });

  test('kNoReadDeadline 을 단 읽기는 한도도 다시 시도도 없다', () async {
    final m = _make([500, 200]);
    await expectLater(
      m.dio.get<dynamic>(
        '/a',
        options: Options(extra: {kNoReadDeadline: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(m.adapter.calls, 1);
  });

  test('증권 조회 경로는 한도만 받고 다시 보내지 않는다 — 다른 경로는 그대로 다시 보낸다', () async {
    final m = _make([503, 200], noRetry: kSecuritiesPathPrefixes);
    await expectLater(
      m.dio.get<dynamic>('/toss/prices'),
      throwsA(isA<DioException>()),
    );
    expect(m.adapter.calls, 1);
    for (final path in [
      '/namu/accounts',
      '/securities/prices',
      '/stock-watch/groups',
      '/stocks',
    ]) {
      final x = _make([503, 200], noRetry: kSecuritiesPathPrefixes);
      await expectLater(
        x.dio.get<dynamic>(path),
        throwsA(isA<DioException>()),
        reason: path,
      );
      expect(x.adapter.calls, 1, reason: path);
    }
    final other = _make([503, 200], noRetry: kSecuritiesPathPrefixes);
    final res = await other.dio.get<dynamic>('/assets');
    expect(res.statusCode, 200);
    expect(other.adapter.calls, 2);
  });
}
