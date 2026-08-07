import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:porest_desk_app/app/env.dart';

/// 새 버전 확인 — 스토어를 쓰지 않아 자동 업데이트가 없다.
///
/// 서버가 배포할 때 `/download/version.json` 을 갱신한다(앱 CI 가 만든다).
/// 그걸 읽어 지금 깔린 빌드보다 높으면 알린다.
///
/// 실패는 조용히 넘긴다 — 버전을 못 읽는다고 앱을 못 쓰게 할 이유가 없다.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.androidFile,
    required this.iosFile,
  });

  final String version;
  final int buildNumber;
  final String androidFile;
  final String iosFile;

  /// AltStore 소스 주소. CI 가 IPA 와 같이 올린다.
  String get altstoreSourceUrl => '${Env.webBaseUrl}/download/altstore.json';

  /// 받으러 갈 곳.
  ///
  /// 안드로이드는 APK 주소를 그대로 열면 받아서 바로 깔 수 있다.
  ///
  /// 아이폰은 사정이 다르다. 스토어 밖 앱은 스스로를 업데이트할 수 없고, 브라우저로
  /// IPA 를 열어도 서명이 없어 설치가 안 된다 — 파일만 받아지고 아무 일도 안 일어난다.
  /// 그래서 AltStore 에 소스를 넘겨 거기서 받게 한다. 무료 계정의 7일 만료도 AltStore
  /// 쪽에서 갱신되므로, iOS 에서 유일하게 끝까지 이어지는 경로다.
  String get downloadUrl => Platform.isIOS
      ? 'altstore://source?url=$altstoreSourceUrl'
      : '${Env.webBaseUrl}/download/$androidFile';

  /// AltStore 가 안 깔려 있으면 딥링크가 열리지 않는다. 그때 대신 보낼 안내 페이지.
  String get fallbackUrl => '${Env.webBaseUrl}/download';

  static AppRelease? tryParse(Object? json) {
    if (json is! Map) return null;
    final version = json['version'];
    final build = json['buildNumber'];
    final android = json['android'];
    final ios = json['ios'];
    if (version is! String || build is! num || android is! String) return null;
    return AppRelease(
      version: version,
      buildNumber: build.toInt(),
      androidFile: android,
      // ios 키는 나중에 붙었다. 옛 version.json 을 읽어도 죽지 않게 비워 둔다.
      iosFile: ios is String ? ios : '',
    );
  }
}

/// 지금 깔린 빌드보다 새 버전이 있으면 그 정보, 없으면 null.
final appUpdateProvider = FutureProvider<AppRelease?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final current = int.tryParse(info.buildNumber) ?? 0;

    final res = await Dio().get<dynamic>(
      '${Env.webBaseUrl}/download/version.json',
      options: Options(
        // 캐시된 옛 버전을 보고 "최신"이라 착각하지 않게.
        headers: const {'Cache-Control': 'no-cache'},
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );
    final release = AppRelease.tryParse(res.data);
    if (release == null) return null;

    // versionCode 로 비교한다 — 이름(1.2.0)은 dev/prod 가 같을 수 있지만
    // 빌드번호는 CI 실행번호라 항상 단조 증가한다.
    return release.buildNumber > current ? release : null;
  } catch (_) {
    // 배포 전이거나 오프라인 — 알릴 게 없을 뿐이다.
    return null;
  }
});
