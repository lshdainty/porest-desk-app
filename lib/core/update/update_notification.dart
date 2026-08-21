/// 새 버전이 나오면 알림으로 알린다.
///
/// 앱은 켰을 때만 새 버전을 알아본다([updateStatusProvider]). 스토어를 안 쓰니 알림이
/// 없으면 "안 켠 사람" 에게는 영영 안 닿고, 서버가 앞서 나가면 구버전이 잘못된 값을
/// 주고받는다. 그래서 앱 밖에서도 두드린다.
///
/// **한 빌드에 한 번만 울린다.** 매번 울리면 받을 생각이 없는 사람에게는 걷어내야 하는
/// 벽이 되고, 그러면 알림 자체를 꺼 버린다 — 정말 알려야 할 때 닿을 길이 사라진다.
/// 전체 화면 안내가 `PrefsKeys.updateSkippedBuild` 로 같은 규칙을 지키는 것과 짝이다.
///
/// **안드로이드에서만 돈다.** iOS 는 백그라운드 실행 시점을 OS 가 정해 6시간 주기 같은
/// 약속이 성립하지 않고(저전력 모드면 아예 안 돈다), 알림을 띄워 봐야 앱이 직접 설치할
/// 수 없어 AltStore 를 거쳐야 한다 — 두드릴 실익이 적다. 대신 켰을 때의 전체 화면
/// 안내([UpdateGateScreen])가 iOS 몫을 그대로 맡는다.
///
/// 등록만 양쪽에 걸어 두는 것도 안 된다. workmanager 의 iOS 구현이 최소 14.0 을 요구해
/// 링크 단계에서 빌드가 깨진다 — Dart 쪽에서 안 부르는 것과 별개로 의존성은 붙는다.
/// 그래서 앱 최소 버전을 14.0 으로 올려 두었다(기기 지원 범위는 그대로다. iOS 13 이
/// 도는 기기는 전부 14 도 된다).
library;

import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/core/update/app_update.dart';


const _channelId = 'porest_update';
const _taskName = 'porest-update-check';
const _uniqueName = 'porest-update-check-periodic';

/// 이 빌드에 대해 이미 알림을 띄웠다 — 두 번 울리지 않게.
const _notifiedBuildKey = 'pd-update-notified-build';

/// 알림 하나만 쓴다. 새 버전이 또 나오면 앞의 것을 덮어써 목록에 쌓이지 않게 한다.
const _notificationId = 1001;

final _plugin = FlutterLocalNotificationsPlugin();

/// 백그라운드에서 workmanager 가 부르는 진입점.
///
/// 별도 아이솔레이트에서 돈다 — Riverpod provider 를 쓸 수 없어 필요한 것을 직접 만든다.
@pragma('vm:entry-point')
void updateCheckDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != _taskName) return true;
    try {
      await checkAndNotifyUpdate();
    } catch (_) {
      // 오프라인이거나 배포 전 — 알릴 게 없을 뿐이다. 실패로 잡으면 workmanager 가
      // 백오프로 계속 재시도해 배터리만 먹는다.
    }
    return true;
  });
}

/// 앱 시작 때 한 번 부른다 — 채널을 만들고 주기 작업을 등록한다.
///
/// 실패해도 던지지 않는다. 알림을 못 걸었다고 앱을 못 쓰게 할 이유가 없다.
Future<void> initUpdateNotifications() async {
  if (!Platform.isAndroid) return;
  try {
    await _plugin.initialize(
      settings: const InitializationSettings(
        // 앱 아이콘을 그대로 쓴다. 전용 흑백 아이콘을 두면 리소스가 하나 더 늘고,
        // 지금 알림은 이것 하나뿐이라 구분할 대상이 없다.
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        '앱 업데이트',
        description: '새 버전이 나오면 알려요.',
        importance: Importance.defaultImportance,
      ),
    );

    // 권한을 여기서 묻는다. 뒤로 미루면 물을 자리가 마땅치 않다 — 알림은 앱 밖에서
    // 두드리는 게 목적이라, 사용자가 설정 화면에 들어와야만 물을 수 있게 만들면
    // 대부분에게 영영 안 닿는다. 거절해도 아무 일도 안 일어난다(알림만 안 뜬다).
    await android?.requestNotificationsPermission();

    await Workmanager().initialize(updateCheckDispatcher);
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      // 안드로이드 최소 주기가 15분이지만 그렇게 자주 볼 이유가 없다. 앱 업데이트는
      // 몇 시간 늦게 알아도 아무 일도 안 생긴다.
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.connected),
      // 등록을 여러 번 해도 작업이 쌓이지 않게 — 앱을 켤 때마다 부른다.
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint('업데이트 알림 등록 실패(무시): $e');
  }
}

/// 새 버전이 있으면 알림을 띄운다. 이미 알린 빌드면 아무 일도 하지 않는다.
///
/// 백그라운드와 화면 양쪽에서 부를 수 있게 열어 둔다.
@visibleForTesting
Future<bool> checkAndNotifyUpdate({
  @visibleForTesting Future<AppRelease?> Function()? fetch,
  @visibleForTesting Future<int> Function()? currentBuild,
  @visibleForTesting Future<void> Function(AppRelease)? show,
}) async {
  final release = await (fetch ?? _fetchLatest)();
  if (release == null) return false;

  final current = await (currentBuild ?? _installedBuild)();
  if (release.buildNumber <= current) return false;

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt(_notifiedBuildKey) == release.buildNumber) return false;

  await (show ?? _show)(release);

  // 띄운 뒤에 적는다 — 먼저 적으면 show 가 실패했을 때 영영 안 울린다.
  await prefs.setInt(_notifiedBuildKey, release.buildNumber);
  return true;
}

/// 알림을 눌렀을 때 — 건너뛴 기록을 지워 업데이트 안내가 다시 뜨게 한다.
///
/// 누른 사람은 보겠다는 뜻이다. 예전에 [PrefsKeys.updateSkippedBuild] 로 넘긴 빌드면
/// 라우터가 게이트를 안 열어 알림을 눌러도 아무 일이 없다.
void _onTap(NotificationResponse response) {
  final build = int.tryParse(response.payload ?? '');
  if (build == null) return;
  SharedPreferences.getInstance().then((prefs) async {
    if (prefs.getInt(PrefsKeys.updateSkippedBuild) == build) {
      await prefs.remove(PrefsKeys.updateSkippedBuild);
    }
  });
}

Future<void> _show(AppRelease release) => _plugin.show(
      id: _notificationId,
      title: '새 버전 ${release.version}',
      // 무엇이 바뀌었는지는 앱에서 본다 — 알림은 있다는 사실만 알린다.
      body: '업데이트가 있어요. 눌러서 확인하세요.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '앱 업데이트',
          channelDescription: '새 버전이 나오면 알려요.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: '${release.buildNumber}',
    );

Future<AppRelease?> _fetchLatest() async {
  final res = await Dio().get<dynamic>(
    '${Env.webBaseUrl}/download/version.json',
    options: Options(
      headers: const {'Cache-Control': 'no-cache'},
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    ),
  );
  return AppRelease.tryParse(res.data);
}

Future<int> _installedBuild() async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber) ?? 0;
}
