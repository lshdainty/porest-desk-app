// 로그인한 사람이 바뀌었는지는 `SessionOwner` 하나가 가린다.
//
// 판정이 틀리면 두 방향으로 다 아프다. 놓치면 앞사람 몫으로 받아 둔 값이 다음 사람
// 화면에 뜨고, 헛짚으면 같은 사람이 쓰는 도중에 앱이 처음부터 다시 열린다(무음
// 재인증·이름 변경·로그인 도중의 중간 상태). 그래서 상태 전이를 하나씩 못 박는다.
//
// 인증 상태는 **진짜 riverpod 이 만든 값**을 그대로 먹인다. `AuthNotifier` 가 하는 대로
// `state = AsyncLoading()` → `state = AsyncData(...)` 를 밟으면, 중간의 로딩은 이전 값을
// 들고 있다(`isLoading && hasValue`). 손으로 만든 `AsyncLoading()` 으로는 그 모양이 안
// 나와서 "값만 보고 판정하는" 실수를 못 잡는다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/auth/session_owner.dart';
import 'package:porest_desk_app/core/auth/user.dart';

const _alice = User(
  rowId: 1,
  userId: 'alice',
  userName: 'Alice',
  userEmail: 'alice@example.com',
);
const _bob = User(
  rowId: 2,
  userId: 'bob',
  userName: 'Bob',
  userEmail: 'bob@example.com',
);

/// `AuthNotifier` 와 같은 순서로 상태를 밟는 대역 — 서버·쿠키만 뺐다.
class _Auth extends AsyncNotifier<User?> {
  _Auth(this._atLaunch);

  /// 앱을 켰을 때 쿠키가 가리키는 사람. 없으면 로그인 화면에서 시작한다.
  final User? _atLaunch;

  @override
  Future<User?> build() async => _atLaunch;

  /// `exchangeAndLoginWithCode` — 로딩을 거쳐 사용자가 실린다.
  void signIn(User user) {
    state = const AsyncLoading();
    state = AsyncData(user);
  }

  /// `logout` — 로딩을 거쳐 null 이 실린다.
  void signOut() {
    state = const AsyncLoading();
    state = const AsyncData(null);
  }

  /// 로그인 실패 — 로딩을 거쳐 에러가 실린다.
  void failSignIn() {
    state = const AsyncLoading();
    state = AsyncError(StateError('exchange failed'), StackTrace.empty);
  }

  /// 무음 재인증 — 로그인한 채로 같은 사람이 한 번 더 실린다(값은 달라질 수 있다).
  void reauthenticate(User user) => state = AsyncData(user);
}

/// 인증 상태가 바뀔 때마다 판정을 받아 적는다 — 앱 셸의 auth 리스너와 같은 배선.
class _Harness {
  _Harness._(this._container, this._provider);

  static Future<_Harness> launch({User? signedInAs}) async {
    final provider = AsyncNotifierProvider<_Auth, User?>(
      () => _Auth(signedInAs),
    );
    final container = ProviderContainer.test();
    final h = _Harness._(container, provider);
    container.listen<AsyncValue<User?>>(provider, (_, next) {
      h.seen.add(next);
      if (h._owner.replacedBy(next)) h.replacedAt.add(next);
    }, fireImmediately: true);
    await container.read(provider.future);
    return h;
  }

  final ProviderContainer _container;
  final AsyncNotifierProvider<_Auth, User?> _provider;
  final _owner = SessionOwner();

  /// 리스너가 본 상태 전부.
  final seen = <AsyncValue<User?>>[];

  /// "다른 사람이 들어왔다" 고 판정한 상태들.
  final replacedAt = <AsyncValue<User?>>[];

  _Auth get auth => _container.read(_provider.notifier);
}

void main() {
  group('바뀐 게 아니다', () {
    test('앱을 켜서 처음 확인된 사람', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      expect(h.seen.last.value, _alice);
      expect(h.replacedAt, isEmpty, reason: '이 컨테이너가 받아 둔 것이 아직 없다');
    });

    test('로그인 화면에서 시작해 처음 들어온 사람', () async {
      final h = await _Harness.launch();

      h.auth.signIn(_alice);

      expect(h.replacedAt, isEmpty);
    });

    test('같은 사람의 무음 재인증 — 이름이 바뀌어 와도 같은 사람이다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.reauthenticate(_alice.copyWith(userName: 'Alice Kim'));
      h.auth.reauthenticate(_alice.copyWith(userEmail: 'kim@example.com'));

      expect(
        h.replacedAt,
        isEmpty,
        reason: '주인은 rowId 로 가린다 — 표시 이름·이메일은 같은 사람이어도 바뀐다',
      );
    });

    test('로그아웃 — 받아 둔 것은 여전히 앞사람 몫이다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signOut();

      expect(h.replacedAt, isEmpty);
    });

    test('같은 사람이 나갔다 다시 들어왔다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signOut();
      h.auth.signIn(_alice);

      expect(h.replacedAt, isEmpty);
    });

    test('로그인에 실패한 채로는 아무도 들어온 게 아니다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signOut();
      h.auth.failSignIn();

      expect(h.seen.last.hasError, isTrue);
      expect(h.replacedAt, isEmpty);
    });
  });

  group('바뀌었다', () {
    test('앞사람이 나가고 다른 사람이 들어왔다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signOut();
      h.auth.signIn(_bob);

      expect(
        h.replacedAt.map((s) => s.value),
        [_bob],
        reason: '로그아웃이 주인을 비우면 여기가 "첫 로그인" 으로 읽혀 Alice 의 값이 Bob 에게 넘어간다',
      );
    });

    test('판정은 확정된 값에서만 난다 — 로그인 도중의 로딩은 이전 값을 들고 있다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signOut();
      h.auth.signIn(_bob);

      // 이 테스트가 막는 실수의 전제 — 로딩 상태가 이전 값을 그대로 들고 온다.
      final leaving = h.seen.firstWhere((s) => s.isLoading && s.hasValue);
      expect(
        leaving.value,
        _alice,
        reason: '전제가 깨졌다 — riverpod 이 로딩에 이전 값을 안 싣는다면 이 테스트는 다시 봐야 한다',
      );
      // 판정이 난 자리는 Bob 이 **확정된** 상태 하나뿐이다.
      expect(h.replacedAt, hasLength(1));
      expect(h.replacedAt.single.isLoading, isFalse);
      expect(h.replacedAt.single.value, _bob);
    });

    test('로그인이 한 번 실패한 뒤 다른 사람이 들어와도 잡는다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signOut();
      h.auth.failSignIn();
      h.auth.signIn(_bob);

      expect(h.replacedAt.map((s) => s.value), [_bob]);
    });

    test('로그아웃 없이 곧바로 다른 사람으로 바뀌었다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signIn(_bob);

      expect(h.replacedAt.map((s) => s.value), [_bob]);
    });

    test('바뀐 뒤에는 새 사람이 주인이다 — 한 번만 알린다', () async {
      final h = await _Harness.launch(signedInAs: _alice);

      h.auth.signIn(_bob);
      h.auth.reauthenticate(_bob.copyWith(userName: 'Bobby'));
      expect(h.replacedAt.map((s) => s.value?.rowId), [_bob.rowId]);

      h.auth.signIn(_alice);
      expect(h.replacedAt.map((s) => s.value?.rowId), [
        _bob.rowId,
        _alice.rowId,
      ]);
    });
  });

  test('주인은 컨테이너마다 따로 센다 — 새 컨테이너는 처음부터다', () {
    // 사람이 바뀌면 컨테이너를 새로 만든다. 주인 기록이 컨테이너 밖에 있으면 새
    // 컨테이너의 첫 로그인을 "또 바뀌었다" 로 읽어 끝없이 다시 만든다.
    final first = ProviderContainer.test();
    final second = ProviderContainer.test();

    first.read(sessionOwnerProvider).replacedBy(const AsyncData(_alice));

    expect(
      identical(
        first.read(sessionOwnerProvider),
        first.read(sessionOwnerProvider),
      ),
      isTrue,
    );
    expect(
      second.read(sessionOwnerProvider).replacedBy(const AsyncData(_bob)),
      isFalse,
      reason: '새 컨테이너가 앞 컨테이너의 주인을 기억하고 있다',
    );
  });
}
