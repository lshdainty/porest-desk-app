import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/auth/oauth_callback_handler.dart';
import 'package:porest_desk_app/core/auth/oauth_flow_store.dart';

/// 플러그인 채널 없이 도는 인메모리 secure storage — read/write/delete 만 흉내낸다.
class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> map = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => map[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    map.remove(key);
  }

  // 나머지 멤버는 이 테스트에서 안 쓴다.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeSecureStorage storage;
  late OAuthFlowStore store;
  late List<({String code, String verifier})> exchanged;
  late OAuthCallbackHandler handler;

  setUp(() {
    storage = _FakeSecureStorage();
    store = OAuthFlowStore(storage);
    exchanged = [];
    handler = OAuthCallbackHandler(
      store: store,
      exchange: ({required String code, required String codeVerifier}) async {
        exchanged.add((code: code, verifier: codeVerifier));
      },
    );
  });

  Uri callback({String? code, String? state}) => Uri.parse(
    'porestdesk://oauth/callback'
    '?${code != null ? 'code=$code&' : ''}${state != null ? 'state=$state' : ''}',
  );

  group('정상 콜백', () {
    test('state 일치 → 보관한 verifier 로 교환하고 흐름을 소비한다', () async {
      await store.savePending(verifier: 'v1', state: 's1');

      final result = await handler.handle(callback(code: 'c1', state: 's1'));

      expect(result, OAuthCallbackResult.exchanged);
      expect(exchanged, [(code: 'c1', verifier: 'v1')]);
      expect(await store.restorePending(), isNull, reason: '재배달 방어 — 흐름 소비');
    });

    test('교환 성공 시 로그아웃의 폼 강제 예약도 해제된다', () async {
      await store.markForceLoginPrompt();
      await store.savePending(verifier: 'v1', state: 's1');

      await handler.handle(callback(code: 'c1', state: 's1'));

      expect(await store.isForceLoginPrompt(), isFalse);
    });
  });

  group('위조·잡음 콜백', () {
    test('state 불일치 → 교환하지 않고, 진행 중 흐름은 남긴다', () async {
      await store.savePending(verifier: 'v1', state: 's1');

      final result = await handler.handle(
        callback(code: 'evil', state: 'wrong'),
      );

      expect(result, OAuthCallbackResult.stateMismatch);
      expect(exchanged, isEmpty);
      expect(
        await store.restorePending(),
        isNotNull,
        reason: '위조 콜백이 진짜 흐름을 지우면 안 된다',
      );
    });

    test('진행 중 흐름이 없으면(중복 배달) 무시한다', () async {
      final result = await handler.handle(callback(code: 'c1', state: 's1'));

      expect(result, OAuthCallbackResult.noPendingFlow);
      expect(exchanged, isEmpty);
    });

    test('code 가 없으면 무시한다', () async {
      await store.savePending(verifier: 'v1', state: 's1');

      final result = await handler.handle(callback(state: 's1'));

      expect(result, OAuthCallbackResult.noCode);
      expect(exchanged, isEmpty);
    });

    test('콜백 스킴이 아니면 손대지 않는다', () async {
      final result = await handler.handle(
        Uri.parse('https://desk.porest.cloud/x'),
      );

      expect(result, OAuthCallbackResult.notCallback);
    });
  });

  group('교환 실패', () {
    test('exchange 가 던지면 그대로 전파된다 (흐름은 이미 소비 — 코드는 1회용)', () async {
      handler = OAuthCallbackHandler(
        store: store,
        exchange: ({required String code, required String codeVerifier}) async {
          throw StateError('exchange down');
        },
      );
      await store.savePending(verifier: 'v1', state: 's1');

      await expectLater(
        handler.handle(callback(code: 'c1', state: 's1')),
        throwsA(isA<StateError>()),
      );
      expect(await store.restorePending(), isNull);
    });
  });
}
