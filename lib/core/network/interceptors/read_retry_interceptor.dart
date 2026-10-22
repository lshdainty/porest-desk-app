import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart'
    show PLoadingTiming;

/// 특정 읽기만 10초 한도에서 빼려면 `Options(extra: {kNoReadDeadline: true})` — 진행을 아는 긴 일은 다 끝나는 시간이
/// 아니라 진행이 멈추는 시간을 본다(skeleton.md "요청 제한 10초").
const String kNoReadDeadline = 'noReadDeadline';

const String _startedKey = '_readStartedAt';
const String _attemptKey = '_readAttempt';
const String _deadlineReason = 'readDeadline';

bool _isRead(RequestOptions o) =>
    o.method.toUpperCase() == 'GET' &&
    o.responseType != ResponseType.stream &&
    o.extra[kNoReadDeadline] != true;

DioException _timedOut(RequestOptions options, Duration timeout) =>
    DioException(
      requestOptions: options,
      type: DioExceptionType.receiveTimeout,
      error: _deadlineReason,
      message: '읽기 요청이 ${timeout.inSeconds}초를 넘겼다',
    );

/// 읽기(GET) 요청의 **10초 한도 · 저절로 다시 시도**(skeleton.md "요청 제한 10초 · 다시 시도는 그 안에서", 03E-021).
///
/// - 처음 요청부터 다시 시도까지 **합쳐** 10초([PLoadingTiming.timeout])가 지나면 끊고 실패로 올린다. 끊는 일은
///   [ReadDeadlineAdapter] 가 맡는다(이 인터셉터는 처음 시각만 적는다).
/// - 읽기만 2번까지, 1초 · 2초([PLoadingTiming.retryDelays]) 뒤에 다시 보낸다. 10초를 넘기게 되면 하지 않는다.
/// - 증권 조회([noRetryPathPrefixes])는 한도만 받고 다시 보내지 않는다.
/// - 4xx(권한 없음 · 없는 데이터 · 잘못된 요청)는 다시 하지 않고 바로 실패다. 저장 · 삭제 같은 쓰기(GET 이 아닌 것)는 저절로
///   다시 보내지 않는다 — 두 번 들어간다. 사용자가 취소한 요청도 다시 보내지 않는다.
///
/// 인터셉터 목록의 **맨 앞**에 둔다 — 다시 시도로 살아난 요청은 뒤 인터셉터(401 처리 · 로그)가 첫 실패를 보지 못한다.
/// 다시 시도는 같은 [Dio] 로 처음부터 다시 보내고(쿠키 · 인증 인터셉터를 다시 거친다), 그 마지막 결과가 그대로 이 요청의
/// 결과다. Riverpod 의 기본 재시도(10회)는 앱 `ProviderScope` 에서 껐다 — 한도는 여기 한 곳이다.
class ReadRetryInterceptor extends Interceptor {
  ReadRetryInterceptor(
    this._dio, {
    this.timeout = PLoadingTiming.timeout,
    this.delays = PLoadingTiming.retryDelays,
    this.noRetryPathPrefixes = const [],
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final Dio _dio;
  final Duration timeout;
  final List<Duration> delays;

  /// 이 경로로 시작하는 읽기는 10초 한도만 받고 저절로 다시 보내지 않는다 — 증권사가 429(유량 초과)로 거절했을 때 한도를 넘긴
  /// 바로 그 순간에 더 치지 않게(웹 증권 조회 `retry: false`, 앱 `securitiesNoRetry` 와 같은 까닭).
  final List<String> noRetryPathPrefixes;
  final Future<void> Function(Duration) _sleep;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 처음 시각 — 다시 시도 요청은 이 값을 이어 받는다(그래서 합쳐서 10초다)
    if (_isRead(options)) {
      options.extra[_startedKey] ??= DateTime.now();
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_isRead(options) || err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }
    final status = err.response?.statusCode;
    if (status != null && status >= 400 && status < 500) {
      return handler.next(err); // 다시 해도 같다
    }
    if (noRetryPathPrefixes.any(options.path.startsWith)) {
      return handler.next(err);
    }
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (attempt >= delays.length) return handler.next(err);
    final started = options.extra[_startedKey] as DateTime? ?? DateTime.now();
    final delay = delays[attempt];
    // 기다린 뒤 보내면 10초를 넘기게 되는가
    if (DateTime.now().difference(started) + delay >= timeout) {
      return handler.next(err);
    }
    await _sleep(delay);
    try {
      final retry = options.copyWith(
        extra: {...options.extra, _attemptKey: attempt + 1},
      );
      final response = await _dio.fetch<dynamic>(retry);
      handler.resolve(response);
    } on DioException catch (e) {
      // 마지막 결과는 이미 뒤 인터셉터를 거쳤다 — 다시 거치지 않고 올린다
      handler.reject(e);
    }
  }
}

/// 읽기 요청을 처음 시각부터 10초에서 끊는 어댑터 — 안쪽 어댑터를 감싼다. 끊으면 안쪽 연결도 닫히게 취소 신호를 함께 보내고,
/// 시간 초과([DioExceptionType.receiveTimeout])로 올린다. 취소 토큰으로 끊으면 뒤 인터셉터가 이미 취소된 토큰과 경주해
/// 오류 종류를 바꿔 버려서 어댑터에서 끊는다.
class ReadDeadlineAdapter implements HttpClientAdapter {
  ReadDeadlineAdapter(this._inner, {this.timeout = PLoadingTiming.timeout});

  final HttpClientAdapter _inner;
  final Duration timeout;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final started = options.extra[_startedKey] as DateTime?;
    if (started == null || !_isRead(options)) {
      return _inner.fetch(options, requestStream, cancelFuture);
    }
    final remaining = timeout - DateTime.now().difference(started);
    if (remaining <= Duration.zero) throw _timedOut(options, timeout);
    final deadline = Completer<void>();
    final timer = Timer(remaining, deadline.complete);
    final merged = Future.any<void>([deadline.future, ?cancelFuture]);
    try {
      return await Future.any<ResponseBody>([
        _inner.fetch(options, requestStream, merged).catchError((
          Object e,
          StackTrace s,
        ) {
          // 우리가 끊어서 난 오류는 시간 초과다
          if (deadline.isCompleted) throw _timedOut(options, timeout);
          throw e;
        }),
        deadline.future.then<ResponseBody>(
          (_) => throw _timedOut(options, timeout),
        ),
      ]);
    } finally {
      timer.cancel();
    }
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
