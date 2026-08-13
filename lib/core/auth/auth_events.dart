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
