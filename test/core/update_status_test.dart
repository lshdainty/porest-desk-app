import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/core/update/app_update.dart';

/// 전체 화면 안내를 언제 띄울지 — 예전에 이 판정이 없어 열 때마다 떴고, "받을 생각이
/// 없는 사람에게는 매번 걷어내야 하는 벽" 이라 걷어냈다. 다시 붙이는 조건이 이 규칙이라
/// 여기가 흔들리면 같은 이유로 또 걷어내게 된다.
AppRelease _release({required int build, int minBuild = 0}) => AppRelease(
  version: '1.12.0',
  buildNumber: build,
  androidFile: 'app.apk',
  iosFile: 'app.ipa',
  notes: '- feat: something',
  minBuildNumber: minBuild,
);

void main() {
  group('shouldGate', () {
    test('새 버전이 있고 건너뛴 적 없으면 띄운다', () {
      final s = UpdateStatus(currentBuild: 100, latest: _release(build: 101));
      expect(s.shouldGate(null), isTrue);
    });

    test('건너뛴 빌드는 다시 안 띄운다 — 빌드번호당 한 번', () {
      final s = UpdateStatus(currentBuild: 100, latest: _release(build: 101));
      expect(s.shouldGate(101), isFalse);
    });

    test('다음 버전이 나오면 다시 띄운다 — 건너뛰기는 그 빌드에만 걸린다', () {
      final s = UpdateStatus(currentBuild: 100, latest: _release(build: 102));
      expect(s.shouldGate(101), isTrue);
    });

    test('강제는 건너뛰기를 무시한다', () {
      final s = UpdateStatus(
        currentBuild: 100,
        latest: _release(build: 101, minBuild: 101),
      );
      expect(s.shouldGate(101), isTrue);
      expect(s.mustUpdate, isTrue);
    });

    test('최신이면 안 띄운다', () {
      final s = UpdateStatus(currentBuild: 101, latest: _release(build: 101));
      expect(s.shouldGate(null), isFalse);
    });

    test('서버를 못 읽었으면 안 띄운다 — 네트워크가 끊겼다고 앱을 막지 않는다', () {
      const s = UpdateStatus(currentBuild: 100, latest: null);
      expect(s.shouldGate(null), isFalse);
      expect(s.mustUpdate, isFalse);
    });
  });

  group('checkFailed', () {
    test('못 읽으면 "확인 실패" — "최신" 과 구분된다', () {
      const s = UpdateStatus(currentBuild: 100, latest: null);
      expect(s.checkFailed, isTrue);
      // 이걸 안 가르면 서버가 죽어 있을 때 화면이 "최신 버전이에요" 라고 안심시킨다.
      expect(s.hasUpdate, isFalse);
    });

    test('읽었으면 최신이어도 확인 실패가 아니다', () {
      final s = UpdateStatus(currentBuild: 101, latest: _release(build: 101));
      expect(s.checkFailed, isFalse);
    });
  });

  group('mustUpdate', () {
    test('하한보다 낮으면 막는다', () {
      final s = UpdateStatus(
        currentBuild: 100,
        latest: _release(build: 105, minBuild: 103),
      );
      expect(s.mustUpdate, isTrue);
    });

    test('하한과 같으면 막지 않는다 — 하한은 "이 번호부터 쓸 수 있다"', () {
      final s = UpdateStatus(
        currentBuild: 103,
        latest: _release(build: 105, minBuild: 103),
      );
      expect(s.mustUpdate, isFalse);
    });

    test('옛 version.json(minBuildNumber 없음)은 아무도 막지 않는다', () {
      final s = UpdateStatus(currentBuild: 1, latest: _release(build: 105));
      expect(s.mustUpdate, isFalse);
    });
  });
}
