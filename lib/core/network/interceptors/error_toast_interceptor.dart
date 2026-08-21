import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// API 에러가 아무 데도 안 보이고 사라지는 걸 막는 마지막 그물.
///
/// 앱은 화면마다 `on ApiException catch` 로 토스트를 띄운다(72곳). 문맥을 붙일 수
/// 있어서 좋지만, 한 군데라도 빠뜨리면 사용자는 눌렀는데 아무 일도 안 일어난 것처럼
/// 느낀다. 웹은 axios 인터셉터가 전부 받아 그 구멍이 구조적으로 안 생긴다
/// (`shared/api/base.ts`).
///
/// 여기서는 웹처럼 "무조건 전역" 으로 가지 않는다. 그러면 화면이 이미 띄운 토스트와
/// 겹쳐 두 개가 뜬다. 대신 **짧게 미뤘다가 띄우고, 그 사이 화면이 자기 에러 토스트를
/// 띄우면 취소**한다. 결과적으로
///   - 화면이 처리한 에러 → 화면의 문맥 있는 메시지 하나 (`삭제 실패: …`)
///   - 아무도 처리 안 한 에러 → 서버 메시지가 그물에 걸려 뜬다
///
/// 401 은 건너뛴다 — AuthInterceptor 가 세션 만료 신호를 올리고 로그인으로 보낸다.
/// 특정 요청만 빼려면 `Options(extra: {kSilentErrorToast: true})`.
const String kSilentErrorToast = 'silentErrorToast';

/// 화면이 자기 에러 토스트를 띄울 시간. 사용자가 알아채기 전 길이면서,
/// catch 블록이 도는 데는 충분하다(같은 이벤트 루프 턴 안에서 끝난다).
const Duration _graceWindow = Duration(milliseconds: 400);

/// 같은 메시지 연타 방지 — 병렬 요청이 같은 에러로 떨어질 때.
const Duration _throttle = Duration(seconds: 3);

GlobalKey<ScaffoldMessengerState>? _messengerKey;
Timer? _pending;
final Map<String, DateTime> _recent = {};

/// 앱 시작 시 한 번 등록. 인터셉터에는 BuildContext 가 없어 이 키로 토스트를 띄운다.
void registerErrorToastMessenger(GlobalKey<ScaffoldMessengerState> key) {
  _messengerKey = key;
}

/// 화면이 자기 에러 토스트를 띄웠다 — 대기 중인 전역 토스트를 취소한다.
/// [showPSnackBar] 가 error severity 로 호출될 때 자동으로 불린다.
void cancelPendingGlobalErrorToast() {
  _pending?.cancel();
  _pending = null;
}

/// 테스트용 — 지연 타이머와 throttle 기록을 비운다.
@visibleForTesting
void resetGlobalErrorToastState() {
  cancelPendingGlobalErrorToast();
  _recent.clear();
}

class ErrorToastInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 예약을 먼저 한다. handler.next 는 dio 체인을 이어가며 제어를 넘기므로
    // 그 뒤 코드는 돌지 않을 수 있다.
    schedule(err);
    handler.next(err);
  }

  /// 토스트 예약 — [onError] 가 하는 일 전부. dio 체인 없이 검증할 수 있게 분리했다.
  @visibleForTesting
  void schedule(DioException err) {
    if (err.requestOptions.extra[kSilentErrorToast] == true) return;
    if (err.response?.statusCode == 401) return;

    final message = ApiException.fromDio(err).message;
    final last = _recent[message];
    if (last != null && DateTime.now().difference(last) < _throttle) return;

    _pending?.cancel();
    _pending = Timer(_graceWindow, () {
      _pending = null;
      final key = _messengerKey;
      final ctx = key?.currentContext;
      final state = key?.currentState;
      if (ctx == null || state == null || !ctx.mounted) return;
      _recent[message] = DateTime.now();
      // ctx 는 테마·로케일 조회용(둘 다 messenger 위에 있다), state 는 표시용.
      showPSnackBar(ctx, message,
          severity: PSnackSeverity.error, messenger: state);
    });
  }
}
