/// "이 화면이 지금 사용자 눈에 보이는가" 두 조각 — 셸 라우트와 앱 포그라운드.
///
/// 탭 셸(`IndexedStack`)은 여섯 화면을 **계속 mount 해 둔다.** 그래서 화면 안에서는
/// 자기가 보이는지를 알 방법이 없다 — `initState`·`dispose` 는 탭을 옮겨도 안 돌고,
/// 화면 안 `GoRouterState.of(context)` 는 어느 탭에 있든 늘 자기 라우트를 돌려준다.
///
/// 주기 작업(타이머·폴링)을 가진 화면이 이걸 모르면 앱을 켜 둔 내내 돈다. 안 보이는
/// 동안 받아 온 값은 아무도 못 보고 사라지므로, 배터리·데이터만 쓴다.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 셸에서 지금 보이고 있는 라우트 — `MobileScaffold` 가 라우트가 바뀔 때 적어 둔다.
///
/// 셸 밖(루트 네비게이터에 push 된 화면·테스트)에서는 아무도 안 적으므로 `null` 이다.
/// `null` 은 **"셸이 판단해 주지 않는다"** 는 뜻이라 [isScreenVisible] 이 보이는 것으로
/// 본다 — 셸 밖에서 열린 화면은 그 자체로 맨 위다.
final activeShellRouteProvider =
    NotifierProvider<ActiveShellRouteNotifier, String?>(
      ActiveShellRouteNotifier.new,
    );

class ActiveShellRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPath(String path) => state = path;
}

/// 앱이 지금 앞에 나와 있는가 — 화면이 꺼졌거나 다른 앱에 가려지면 `false`.
///
/// 관찰자를 여기서 직접 드는 이유는 이 값이 **화면이 아니라 앱의 상태**이기 때문이다.
/// 화면마다 각자 `WidgetsBindingObserver` 를 달면 화면 수만큼 판정이 갈리고, 셸에
/// 상주하는 화면은 dispose 가 안 돌아 떼어질 자리도 없다.
/// (`nowTickProvider` 도 같은 이유로 `AppLifecycleListener` 를 직접 든다.)
final appForegroundProvider = NotifierProvider<AppForegroundNotifier, bool>(
  AppForegroundNotifier.new,
);

class AppForegroundNotifier extends Notifier<bool> {
  @override
  bool build() {
    final listener = AppLifecycleListener(
      onStateChange: (s) => state = isForegroundLifecycle(s),
    );
    ref.onDispose(listener.dispose);
    // lifecycle 이벤트는 **바뀔 때만** 온다. 콜드 스타트 극초반은 아직 아무것도
    // 안 와서 `null` 인데, 그때는 앞에 나와 있는 것이 맞다(`AppLockGate` 와 같은 판정).
    final now = WidgetsBinding.instance.lifecycleState;
    return now == null || isForegroundLifecycle(now);
  }
}

/// lifecycle 을 "보이는가" 로 옮긴다.
///
/// `inactive` 를 보이는 것으로 세는 게 요점이다 — 알림 센터를 내리거나 전화가 오는
/// 잠깐이 여기다. 이걸 안 보이는 것으로 세면 화면을 그대로 보고 있는데도 타이머가
/// 섰다 다시 서고, 되돌아올 때마다 재시작 조회가 한 번씩 더 나간다.
/// 화면이 실제로 꺼지면 `hidden`·`paused` 가 뒤따르므로 놓치지 않는다.
bool isForegroundLifecycle(AppLifecycleState state) => switch (state) {
  AppLifecycleState.resumed || AppLifecycleState.inactive => true,
  AppLifecycleState.hidden ||
  AppLifecycleState.paused ||
  AppLifecycleState.detached => false,
};

/// [route] 화면이 지금 보이는가 — 셸에서 그 라우트가 앞이고, 앱도 앞에 있을 때.
bool isScreenVisible(WidgetRef ref, String route) {
  if (!ref.read(appForegroundProvider)) return false;
  final active = ref.read(activeShellRouteProvider);
  return active == null || active == route;
}
