// 새 버전 알림 — 한 빌드에 한 번만 울린다.
//
// 매번 울리면 받을 생각이 없는 사람에게는 걷어내야 하는 벽이 되고, 그러면 알림 자체를
// 꺼 버린다. 그 순간 정말 알려야 할 때(강제 업데이트) 닿을 길이 사라진다.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/core/update/update_notification.dart';

const _newer = AppRelease(
  version: '1.20.0',
  buildNumber: 200,
  androidFile: 'a.apk',
  iosFile: 'a.ipa',
  notes: '새 기능\n- 무엇',
  minBuildNumber: 0,
);

Future<bool> _run({
  AppRelease? latest = _newer,
  int installed = 100,
  List<AppRelease>? shown,
}) => checkAndNotifyUpdate(
  fetch: () async => latest,
  currentBuild: () async => installed,
  show: (r) async => shown?.add(r),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('설치된 빌드보다 높으면 알린다', () async {
    expect(await _run(), isTrue);
  });

  test('같은 빌드에는 두 번 울리지 않는다', () async {
    expect(await _run(), isTrue);
    expect(await _run(), isFalse);
  });

  test('더 새 빌드가 나오면 다시 울린다', () async {
    expect(await _run(), isTrue);
    const next = AppRelease(
      version: '1.21.0',
      buildNumber: 201,
      androidFile: 'a.apk',
      iosFile: 'a.ipa',
      notes: '',
      minBuildNumber: 0,
    );
    expect(await _run(latest: next), isTrue);
  });

  test('설치본이 최신이면 울리지 않는다', () async {
    expect(await _run(installed: 200), isFalse);
    expect(await _run(installed: 999), isFalse);
  });

  test('받아오지 못하면 울리지 않는다 — 오프라인·배포 전', () async {
    expect(await _run(latest: null), isFalse);
  });
}
