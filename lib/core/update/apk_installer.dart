import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/core/update/app_update.dart';

/// 안드로이드에서 새 APK 를 받아 설치 화면까지 데려다준다.
///
/// **자동 설치는 안 된다.** 스토어 밖에서 온 APK 는 시스템이 사용자에게 한 번 더
/// 묻게 돼 있고(Android 보안 정책), 기기 관리자 앱이 아닌 한 그 화면을 건너뛸 방법이
/// 없다. 여기서 줄이는 건 그 앞의 걸음이다 — 브라우저로 나가 받고 알림을 눌러
/// 되돌아오는 대신, 앱 안에서 받아 곧장 설치 화면을 띄운다.
enum ApkStage { idle, downloading, opening, failed }

class ApkProgress {
  const ApkProgress({
    this.stage = ApkStage.idle,
    this.received = 0,
    this.total = 0,
  });

  final ApkStage stage;
  final int received;
  final int total;

  /// 0.0~1.0. 서버가 길이를 안 주면(total<=0) null — 그때는 무한 진행 표시를 쓴다.
  double? get ratio => total > 0 ? (received / total).clamp(0.0, 1.0) : null;

  bool get isBusy => stage == ApkStage.downloading || stage == ApkStage.opening;
}

class ApkInstaller extends Notifier<ApkProgress> {
  CancelToken? _cancel;

  @override
  ApkProgress build() {
    ref.onDispose(() => _cancel?.cancel());
    return const ApkProgress();
  }

  /// 받아서 설치 화면을 연다. 성공하면 true.
  ///
  /// 저장 위치는 앱 전용 캐시다. 공유 저장소가 아니라서 따로 권한이 필요 없고,
  /// 설치가 끝나면 시스템이 알아서 치워도 그만인 자리다.
  Future<bool> downloadAndOpen(AppRelease release) async {
    if (state.isBusy) return false;

    _cancel = CancelToken();
    state = const ApkProgress(stage: ApkStage.downloading);
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${release.androidFile}';

      // 받다 만 파일이 남아 있으면 설치가 "패키지 손상"으로 튕긴다. 늘 새로 받는다.
      final file = File(path);
      if (file.existsSync()) await file.delete();

      await Dio().download(
        release.androidUrl,
        path,
        cancelToken: _cancel,
        onReceiveProgress: (received, total) {
          state = ApkProgress(
            stage: ApkStage.downloading,
            received: received,
            total: total,
          );
        },
      );

      state = const ApkProgress(stage: ApkStage.opening);
      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        state = const ApkProgress(stage: ApkStage.failed);
        return false;
      }
      state = const ApkProgress();
      return true;
    } catch (_) {
      // 네트워크가 끊겼거나 저장에 실패했다. 사용자는 다시 누르면 된다 —
      // 어차피 실패해도 잃는 건 받던 파일뿐이다.
      state = const ApkProgress(stage: ApkStage.failed);
      return false;
    } finally {
      _cancel = null;
    }
  }
}

final apkInstallerProvider = NotifierProvider<ApkInstaller, ApkProgress>(
  ApkInstaller.new,
);

/// "나중에" 를 누른 빌드번호. 그 버전은 전체 화면으로 다시 묻지 않는다.
///
/// 홈 배너는 그대로 남는다 — 미뤘다고 없던 일이 되는 건 아니고, 마음이 바뀌면
/// 거기서 다시 들어갈 수 있어야 한다.
const _kSkippedBuildKey = 'pd-update-skipped-build';

Future<int> loadSkippedBuild() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_kSkippedBuildKey) ?? 0;
}

Future<void> saveSkippedBuild(int buildNumber) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kSkippedBuildKey, buildNumber);
}
