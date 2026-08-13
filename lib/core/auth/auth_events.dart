import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 401(세션 만료) 신호. dio 에 의존하지 않아 dio↔auth 순환을 끊는다.
///
/// dio 인터셉터가 [SessionExpiredNotifier.bump] 로 값을 올리면 AuthNotifier 가
/// 이를 듣고 강제 로그아웃한다. (StateProvider 는 riverpod 3.x 에서 deprecated 라
/// 의존성 없는 `Notifier<int>` 로 동일 기능 구현.)
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// 401 발생 신호 — 단조 증가시켜 listener 가 변화를 감지한다.
  void bump() => state++;
}

final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);

/// 방금 로그아웃이 세션 만료 때문이었나.
///
/// 만료로 밀려난 것과 사용자가 직접 로그아웃한 것은 다르게 대해야 한다. 만료라면
/// SSO 에 Refresh 쿠키(7일)가 살아 있을 수 있어 조용히 되돌아올 수 있지만, 직접
/// 로그아웃한 사람을 곧바로 다시 로그인시키면 로그아웃이 안 되는 앱이 된다.
///
/// 로그인 화면이 이 값을 보고 자동 재인증을 걸지 정한다. 한 번 쓰면 바로 지운다 —
/// 남겨 두면 재인증이 실패해 돌아왔을 때 또 나가고, 그게 반복된다.
class ExpiredLogoutFlag extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final expiredLogoutProvider =
    NotifierProvider<ExpiredLogoutFlag, bool>(ExpiredLogoutFlag.new);
