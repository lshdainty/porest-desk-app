import 'dart:io';

import 'package:flutter/services.dart';

/// 안내를 눌렀을 때 실제로 열린 화면.
///
/// 자동 차단 화면은 공개 API 가 아니라 늘 열리지는 않는다. 어디까지 갔는지에 따라
/// 사용자에게 남은 걸음을 다르게 알려 줘야 한다.
enum AutoBlockerTarget {
  /// 자동 차단 화면까지 바로 갔다 — 토글만 끄면 된다.
  autoBlocker,

  /// 보안 설정까지 갔다 — 목록에서 "자동 차단" 을 찾아야 한다.
  security,

  /// 설정 앱만 열렸다 — 경로를 따라가야 한다.
  settings,

  /// 아무것도 못 열었다.
  none;

  static AutoBlockerTarget parse(String? raw) => switch (raw) {
        'auto_blocker' => AutoBlockerTarget.autoBlocker,
        'security' => AutoBlockerTarget.security,
        'settings' => AutoBlockerTarget.settings,
        _ => AutoBlockerTarget.none,
      };
}

/// 삼성 "자동 차단"(Auto Blocker) 안내.
///
/// One UI 6.0(Android 14)부터 기본으로 켜져 있고 **스토어 밖에서 온 앱의 설치를
/// 통째로 막는다**. 우리 앱이 위험해서가 아니라 사이드로드라는 경로 자체를 막는
/// 것이라, 이걸 끄기 전에는 설치도 업데이트도 되지 않는다.
///
/// 스토어로 배포하지 않는 한 앱이 스스로 풀 방법은 없다 — 설정으로 데려다주는
/// 것까지가 할 수 있는 전부다.
class AutoBlockerGuide {
  const AutoBlockerGuide._();

  static const MethodChannel _channel = MethodChannel('porest/device_guide');

  /// 이 기기에 자동 차단이 있는가 — 삼성 + Android 14 이상.
  ///
  /// 없는 기기에 안내를 띄우면 있지도 않은 설정을 찾게 만든다.
  static Future<bool> isBlockingDevice() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isAutoBlockerDevice') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// 자동 차단 설정을 연다 — 못 열면 보안 설정, 그것도 안 되면 설정 앱.
  static Future<AutoBlockerTarget> open() async {
    if (!Platform.isAndroid) return AutoBlockerTarget.none;
    try {
      final raw = await _channel.invokeMethod<String>('openAutoBlockerSettings');
      return AutoBlockerTarget.parse(raw);
    } on MissingPluginException {
      return AutoBlockerTarget.none;
    } on PlatformException {
      return AutoBlockerTarget.none;
    }
  }
}
