import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/update/apk_installer.dart';
import 'package:porest_desk_app/core/update/auto_blocker_guide.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/features/update/presentation/release_notes_view.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_alert.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 업데이트 — 설정에서 들어와 지금 상태를 확인하고, 있으면 여기서 받는다.
///
/// 알림은 UpdateGateScreen 이 맡는다(새 버전이 나오면 빌드번호당 한 번 전체 화면으로
/// 가로막는다). 이 화면은 그걸 넘긴 사람이 나중에 스스로 찾아오는 자리다 — 스토어의
/// "업데이트" 탭과 같다. 그래서 뒤로 가기를 막지 않는다.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final statusAsync = ref.watch(updateStatusProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        backgroundColor: t.bgCanvas,
        elevation: 0,
        leading: const PBackButton(),
        title: Text(
          l.updateTitle,
          style: PTypo.bodyLg.copyWith(
            color: t.fgPrimary,
            fontWeight: PFontWeight.bold,
          ),
        ),
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // 서버를 못 읽어도 화면은 뜬다 — 지금 버전만이라도 보여 준다.
        error: (_, _) => const _Body(status: null),
        data: (s) => _Body(status: s),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.status});

  final UpdateStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final s = status;
    final latest = s?.latest;
    final hasUpdate = s?.hasUpdate ?? false;
    // 서버를 못 읽은 것과 "받을 게 없다" 는 다르다. 예전엔 둘을 같이 취급해서 서버가
    // 죽어 있어도 "최신 버전이에요" 라고 안심시켰다 — 업데이트 안내가 조용히 멈췄다.
    final checkFailed = s == null || s.checkFailed;

    return ListView(
      padding: const EdgeInsets.all(PSpace.x24),
      children: [
        // ── 상태 한 줄 — 최신인지 아닌지가 먼저 보여야 한다.
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasUpdate ? t.bgBrandSubtle : t.bgMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                hasUpdate
                    ? LucideIcons.download
                    : checkFailed
                    ? LucideIcons.triangleAlert
                    : LucideIcons.check,
                size: 20,
                color: hasUpdate
                    ? t.fgBrand
                    : checkFailed
                    ? t.statusWarningFg
                    : t.fgSecondary,
              ),
            ),
            const SizedBox(width: PSpace.x16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasUpdate
                        ? l.updateAvailable(latest!.version)
                        : checkFailed
                        ? l.updateCheckFailedTitle
                        : l.updateUpToDate,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // 지금 버전은 서버와 무관하게 알고 있다 — 확인에 실패해도 보여 준다.
                    checkFailed
                        ? l.updateCheckFailed
                        : l.updateCurrentBuild(s.currentBuild.toString()),
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── 바뀐 것
        if (hasUpdate && latest!.notes.trim().isNotEmpty) ...[
          const SizedBox(height: PSpace.x32),
          Text(
            l.updateSheetChanges,
            style: PTypo.bodySm.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
          ),
          const SizedBox(height: PSpace.x12),
          Container(
            padding: const EdgeInsets.all(PSpace.x16),
            decoration: BoxDecoration(
              color: t.bgMuted,
              borderRadius: PRadius.brLg,
            ),
            child: PReleaseNotes(notes: latest.notes),
          ),
        ],

        // ── 받기
        if (hasUpdate) ...[
          const SizedBox(height: PSpace.x32),
          // 삼성 기기는 자동 차단을 끄기 전엔 설치가 막힌다 — 받기 전에 알려 준다.
          // 받고 나서 알면 다운로드가 헛수고가 된다.
          const _AutoBlockerNotice(),
          _DownloadButton(release: latest!),
        ],
      ],
    );
  }
}

/// 삼성 "자동 차단" 안내 — 그 기기에서만 나온다.
///
/// One UI 6.0(Android 14)부터 기본으로 켜져 있고 **스토어 밖에서 온 앱의 설치를
/// 통째로 막는다**. 우리 앱이 위험해서가 아니라 사이드로드라는 경로 자체를 막는
/// 것이라, 끄기 전에는 받아도 설치 화면에서 튕긴다.
///
/// 앱이 스스로 풀 방법은 없다 — 설정으로 데려다주는 것까지가 전부다.
class _AutoBlockerNotice extends StatefulWidget {
  const _AutoBlockerNotice();

  @override
  State<_AutoBlockerNotice> createState() => _AutoBlockerNoticeState();
}

class _AutoBlockerNoticeState extends State<_AutoBlockerNotice> {
  bool _show = false;

  /// 설정에 다녀온 뒤 안내 문구 — 어디까지 열렸느냐에 따라 남은 걸음이 다르다.
  AutoBlockerTarget? _opened;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final blocking = await AutoBlockerGuide.isBlockingDevice();
    if (!mounted) return;
    setState(() => _show = blocking);
  }

  Future<void> _open() async {
    final target = await AutoBlockerGuide.open();
    if (!mounted) return;
    setState(() => _opened = target);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    // 자동 차단 화면이 바로 열렸으면 토글만 끄면 되고, 보안 설정까지만 갔으면
    // 목록에서 찾아야 한다. 아무것도 못 열었을 때만 전체 경로를 적어 준다.
    final description = switch (_opened) {
      AutoBlockerTarget.autoBlocker => l.updateAutoBlockerAfterDirect,
      AutoBlockerTarget.security => l.updateAutoBlockerAfterSecurity,
      AutoBlockerTarget.settings ||
      AutoBlockerTarget.none => l.updateAutoBlockerPath,
      null => l.updateAutoBlockerDesc,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x16),
      child: PAlert(
        title: l.updateAutoBlockerTitle,
        description: description,
        variant: PAlertVariant.warning,
        action: PButton(
          label: l.updateAutoBlockerOpen,
          size: PButtonSize.sm,
          variant: PButtonVariant.secondary,
          onPressed: _open,
        ),
      ),
    );
  }
}

/// 받기 버튼 — 안드로이드는 앱 안에서 받아 설치 화면까지, iOS 는 AltStore 로.
class _DownloadButton extends ConsumerWidget {
  const _DownloadButton({required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final progress = ref.watch(apkInstallerProvider);

    if (progress.isBusy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progress.stage == ApkStage.opening
                ? l.updateSheetOpening
                : l.updateSheetDownloading,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x8),
          ClipRRect(
            borderRadius: PRadius.brFull,
            child: LinearProgressIndicator(
              // 서버가 길이를 안 주면 비율을 모른다 — 그때는 흐르는 표시로.
              value: progress.ratio,
              minHeight: 6,
              backgroundColor: t.bgMuted,
              color: t.bgBrandSolid,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: PButton(
        label: progress.stage == ApkStage.failed
            ? l.updateSheetRetry
            : l.updateSheetNow,
        icon: LucideIcons.download,
        size: PButtonSize.lg,
        onPressed: () => _start(context, ref),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    // iOS 는 앱이 스스로를 설치할 수 없다. AltStore 에 넘긴다.
    if (!Platform.isAndroid) {
      await openReleaseExternally(release);
      return;
    }

    final ok = await ref
        .read(apkInstallerProvider.notifier)
        .downloadAndOpen(release);
    if (ok || !context.mounted) return;

    // 앱 안에서 못 받았으면 브라우저에 넘긴다. 거기서는 받아지는 경우가 있다.
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.updateSheetFailed)));
    await openReleaseExternally(release);
  }
}
