import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/core/auth/auth_events.dart';

/// 세션 만료와 사용자 로그아웃은 다르게 대해야 한다.
///
/// 뒤섞이면 둘 중 하나가 깨진다 — 만료를 사용자 로그아웃처럼 다루면 1시간마다 로그인
/// 폼을 보게 되고(prompt=login), 반대로 다루면 로그아웃을 눌러도 무음 재인증이 조용히
/// 되살려 로그아웃이 안 되는 앱이 된다.
void main() {
  test('만료 표시는 기본이 꺼짐 — 평소 진입은 자동 재인증을 걸지 않는다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(expiredLogoutProvider), isFalse);
  });

  test('mark 하면 켜지고, clear 하면 다시 꺼진다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(expiredLogoutProvider.notifier).mark();
    expect(c.read(expiredLogoutProvider), isTrue);

    // 로그인 화면이 자동 진입을 시작하며 지운다. 안 지우면 재인증이 실패해 돌아왔을 때
    // 또 나가고, 그게 반복된다.
    c.read(expiredLogoutProvider.notifier).clear();
    expect(c.read(expiredLogoutProvider), isFalse);
  });

  test('401 신호는 단조 증가한다 — 리스너가 매번 변화를 감지할 수 있어야 한다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final seen = <int>[];
    c.listen(sessionExpiredProvider, (_, next) => seen.add(next));

    c.read(sessionExpiredProvider.notifier).bump();
    c.read(sessionExpiredProvider.notifier).bump();

    expect(seen, [1, 2]);
  });
}
