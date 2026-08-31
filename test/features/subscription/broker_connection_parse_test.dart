import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';

/// 응답 파싱 — 서버가 앞서 나가거나 뒤처져도 앱이 조용히 틀리지 않아야 한다.
void main() {
  group('MyFeatures', () {
    test('connectedBrokers 를 그대로 읽고 기본 증권사를 들고 온다', () {
      final f = MyFeatures.fromJson(const {
        'features': ['SECURITIES'],
        'connectedBrokers': ['TOSS', 'NAMU'],
        'primaryBroker': 'NAMU',
        'tossConnected': true,
      });

      expect(f.hasSecurities, isTrue);
      expect(f.connectedBrokers, ['TOSS', 'NAMU']);
      expect(f.primaryBroker, 'NAMU');
      expect(f.isConnected('NAMU'), isTrue);
      expect(f.hasBrokerConnection, isTrue);
    });

    test('구버전 서버(connectedBrokers 없음)는 tossConnected 로 되살린다', () {
      // 앱이 먼저 나가고 서버가 아직 안 올라간 구간이 실제로 생긴다.
      // 여기서 빈 목록으로 읽으면 증권 화면이 통째로 연결 유도로 되돌아간다.
      final f = MyFeatures.fromJson(const {
        'features': ['SECURITIES'],
        'tossConnected': true,
      });

      expect(f.connectedBrokers, ['TOSS']);
      expect(f.hasBrokerConnection, isTrue);
    });

    test('아무것도 없으면 빈 상태 — null 로 터지지 않는다', () {
      final f = MyFeatures.fromJson(const {});

      expect(f.features, isEmpty);
      expect(f.connectedBrokers, isEmpty);
      expect(f.primaryBroker, isNull);
      expect(f.hasBrokerConnection, isFalse);
    });
  });

  group('BrokerConnection', () {
    test('표시명·발급처·입력 라벨을 서버에서 받는다 — 증권사를 앱에 박지 않는 근거다', () {
      final c = BrokerConnection.fromJson(const {
        'broker': 'NAMU',
        'displayName': '나무증권',
        'issueUrl': 'https://www.nhplug.com',
        'keyLabel': 'App Key',
        'secretLabel': 'App Secret',
        'connected': true,
        'verified': true,
        'primary': true,
        'verifiedAt': '2026-08-24T09:00:00',
      });

      expect(c.displayName, '나무증권');
      expect(c.keyLabel, 'App Key');
      expect(c.primary, isTrue);
    });

    test('라벨이 비어 오면 일반 명칭으로 폴백한다 — 빈 칸을 보여주지 않는다', () {
      final c = BrokerConnection.fromJson(const {
        'broker': 'NEW',
        'connected': false,
      });

      expect(c.keyLabel, 'API Key');
      expect(c.secretLabel, 'API Secret');
      expect(c.connected, isFalse);
      expect(c.primary, isFalse);
    });
  });
}
