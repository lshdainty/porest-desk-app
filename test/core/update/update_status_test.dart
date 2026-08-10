import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/core/update/app_update.dart';

/// 강제 업데이트는 잘못 걸리면 앱을 통째로 못 쓰게 만든다. 판정 조건을 못 박아 둔다.
void main() {
  AppRelease release({int build = 10, int minBuild = 0}) => AppRelease(
        version: '1.0.0',
        buildNumber: build,
        androidFile: 'a.apk',
        iosFile: 'a.ipa',
        notes: '',
        minBuildNumber: minBuild,
      );

  group('hasUpdate — 받을 게 있나', () {
    test('서버 빌드가 더 높으면 있다', () {
      final s = UpdateStatus(currentBuild: 9, latest: release(build: 10));
      expect(s.hasUpdate, isTrue);
    });

    test('같으면 없다', () {
      final s = UpdateStatus(currentBuild: 10, latest: release(build: 10));
      expect(s.hasUpdate, isFalse);
    });

    test('내가 더 높아도 없다 — dev 빌드가 운영보다 앞설 수 있다', () {
      final s = UpdateStatus(currentBuild: 11, latest: release(build: 10));
      expect(s.hasUpdate, isFalse);
    });

    test('서버를 못 읽었으면 없다', () {
      const s = UpdateStatus(currentBuild: 9, latest: null);
      expect(s.hasUpdate, isFalse);
    });
  });

  group('mustUpdate — 더 못 쓰나', () {
    test('하한보다 낮으면 막는다', () {
      final s = UpdateStatus(currentBuild: 9, latest: release(minBuild: 10));
      expect(s.mustUpdate, isTrue);
    });

    test('하한과 같으면 통과 — 하한은 "이 값 이상이면 된다" 는 뜻이다', () {
      final s = UpdateStatus(currentBuild: 10, latest: release(minBuild: 10));
      expect(s.mustUpdate, isFalse);
    });

    test('하한이 0 이면 아무도 안 막는다 — 평소 상태', () {
      final s = UpdateStatus(currentBuild: 1, latest: release(minBuild: 0));
      expect(s.mustUpdate, isFalse);
    });

    test('서버를 못 읽었으면 막지 않는다 — 오프라인이 사람을 앱 밖에 세우면 안 된다', () {
      const s = UpdateStatus(currentBuild: 1, latest: null);
      expect(s.mustUpdate, isFalse);
    });

    test('새 버전이 있어도 하한을 넘겼으면 안 막는다 — 미루는 건 사용자 몫', () {
      final s = UpdateStatus(
          currentBuild: 10, latest: release(build: 20, minBuild: 10));
      expect(s.hasUpdate, isTrue);
      expect(s.mustUpdate, isFalse);
    });
  });

  group('tryParse — 옛 version.json 도 읽는다', () {
    test('minBuildNumber 가 없으면 0 — 필드가 없다고 앱을 막으면 안 된다', () {
      final r = AppRelease.tryParse({
        'version': '1.0.0',
        'buildNumber': 5,
        'android': 'a.apk',
      });
      expect(r, isNotNull);
      expect(r!.minBuildNumber, 0);
      expect(UpdateStatus(currentBuild: 1, latest: r).mustUpdate, isFalse);
    });

    test('값이 있으면 그대로 읽는다', () {
      final r = AppRelease.tryParse({
        'version': '1.0.0',
        'buildNumber': 30,
        'android': 'a.apk',
        'minBuildNumber': 25,
      });
      expect(r!.minBuildNumber, 25);
    });

    test('형식이 깨졌으면 null — 잘못된 응답으로 막지 않는다', () {
      expect(AppRelease.tryParse('not json'), isNull);
      expect(AppRelease.tryParse({'version': 1}), isNull);
    });
  });
}
