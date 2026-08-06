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
  });

  final String version;
  final int buildNumber;
  final String androidFile;

  /// 브라우저로 열 다운로드 주소. 앱 안에서 받으면 설치 권한 처리가 번거로워
  /// 외부 브라우저에 넘긴다.
  String get downloadUrl => '${Env.webBaseUrl}/download/$androidFile';

  static AppRelease? tryParse(Object? json) {
    if (json is! Map) return null;
    final version = json['version'];
    final build = json['buildNumber'];
    final android = json['android'];
    if (version is! String || build is! num || android is! String) return null;
    return AppRelease(
      version: version,
      buildNumber: build.toInt(),
      androidFile: android,
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
