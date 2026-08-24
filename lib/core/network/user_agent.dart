import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 서버가 "로그인된 기기" 목록에 쓸 이름을 뽑아낼 수 있게 보내는 User-Agent.
///
/// <p>안 보내면 dart:io 기본값(`Dart/3.9 (dart:io)`)이 나가는데, 그걸로는 앱이라는
/// 것만 알 뿐 어떤 기기인지 알 수 없다. 목록에 전부 "Porest 앱" 으로만 보인다.
///
/// 형태: `Porest/1.2.3 (Android 14)` — 서버 UserAgentParser 가 이 형태를 안다.
/// iPhone·iPad 는 구분하지 않는다. Platform 이 'ios' 까지만 알려주고, 기종을 알려면
/// device_info_plus 를 더 넣어야 하는데 그만한 값은 아니다.
Future<String> buildUserAgent() async {
  final version = await _appVersion();
  final platform = _platform();
  return platform == null ? 'Porest/$version' : 'Porest/$version ($platform)';
}

Future<String> _appVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    // 버전을 못 읽어도 UA 는 보낸다 — 기기 이름이 목적이지 버전이 목적이 아니다.
    return 'unknown';
  }
}

String? _platform() {
  if (kIsWeb) return null; // 웹 빌드는 브라우저 UA 가 나간다 — 덮어쓰지 않는다.
  try {
    if (Platform.isAndroid) return 'Android ${_osVersion()}'.trim();
    if (Platform.isIOS) return 'iOS ${_osVersion()}'.trim();
    if (Platform.isMacOS) return 'Macintosh';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
  } catch (_) {
    return null;
  }
  return null;
}

/// `Platform.operatingSystemVersion` 은 플랫폼마다 형태가 제각각이다
/// (iOS "Version 17.5 (Build 21F79)", Android "Android 14 (API 34)").
/// 첫 숫자만 뽑아 `17.5` · `14` 로 줄인다 — 없으면 빈 문자열.
String _osVersion() {
  final m = RegExp(r'\d+(\.\d+)?').firstMatch(Platform.operatingSystemVersion);
  return m?.group(0) ?? '';
}
