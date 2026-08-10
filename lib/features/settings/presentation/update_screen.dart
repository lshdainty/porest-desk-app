import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/update/apk_installer.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 업데이트 — 설정에서 들어와 지금 상태를 확인하고, 있으면 여기서 받는다.
///
/// 예전엔 앱을 열 때마다 전체 화면으로 알리고 홈에도 배너를 뒀는데, 받을 생각이
/// 없는 사람에게는 매번 걷어내야 하는 벽이었다. 이제 알림은 걷고 확인은 이 화면으로
/// 모은다 — 스토어의 "업데이트" 탭과 같은 자리다.
///
/// 다만 [forced] 면 이야기가 다르다. 서버와 앱이 어긋나 잘못된 값을 주고받을 수 있는
/// 상태라, 받기 전에는 앱으로 돌아갈 수 없다. 뒤로 가기도 막는다.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key, this.forced = false});

  final bool forced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final statusAsync = ref.watch(updateStatusProvider);

    return PopScope(
      // 강제일 때는 뒤로 가기로 빠져나갈 수 없다.
      canPop: !forced,
      child: Scaffold(
        backgroundColor: t.bgCanvas,
        appBar: AppBar(
          backgroundColor: t.bgCanvas,
          elevation: 0,
          leading: forced ? const SizedBox.shrink() : const PBackButton(),
          title: Text(
            l.updateTitle,
            style: PTypo.bodyLg
                .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
          ),
        ),
        body: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // 서버를 못 읽어도 화면은 뜬다 — 지금 버전만이라도 보여 준다.
          error: (_, _) => _Body(status: null, forced: forced),
          data: (s) => _Body(status: s, forced: forced),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.status, required this.forced});

  final UpdateStatus? status;
  final bool forced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final s = status;
    final latest = s?.latest;
    final hasUpdate = s?.hasUpdate ?? false;

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
                hasUpdate ? LucideIcons.download : LucideIcons.check,
                size: 20,
                color: hasUpdate ? t.fgBrand : t.fgSecondary,
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
                        : l.updateUpToDate,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.semi),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s == null
                        ? l.updateCheckFailed
                        : l.updateCurrentBuild(s.currentBuild.toString()),
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── 강제 — 왜 막혔는지 먼저 말한다.
        if (forced) ...[
          const SizedBox(height: PSpace.x24),
          Container(
            padding: const EdgeInsets.all(PSpace.x16),
            decoration: BoxDecoration(
              color: t.statusWarningSubtle,
              borderRadius: PRadius.brLg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.triangleAlert,
                    size: 18, color: t.statusWarningFg),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Text(
                    l.updateRequiredDesc,
                    style: PTypo.bodySm
                        .copyWith(color: t.statusWarningFg, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── 바뀐 것
        if (hasUpdate && latest!.notes.trim().isNotEmpty) ...[
          const SizedBox(height: PSpace.x32),
          Text(
            l.updateSheetChanges,
            style: PTypo.bodySm
                .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
          ),
          const SizedBox(height: PSpace.x12),
          Container(
            padding: const EdgeInsets.all(PSpace.x16),
            decoration:
                BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in latest.notes
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: PSpace.x8),
                    child: Text(
                      // CI 가 '- ' 를 붙여 보낸다.
                      line.startsWith('- ') ? line.substring(2) : line,
                      style: PTypo.bodySm
                          .copyWith(color: t.fgSecondary, height: 1.6),
                    ),
                  ),
              ],
            ),
          ),
        ],

        // ── 받기
        if (hasUpdate) ...[
          const SizedBox(height: PSpace.x32),
          _DownloadButton(release: latest!),
        ],
      ],
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

    final ok =
        await ref.read(apkInstallerProvider.notifier).downloadAndOpen(release);
    if (ok || !context.mounted) return;

    // 앱 안에서 못 받았으면 브라우저에 넘긴다. 거기서는 받아지는 경우가 있다.
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.updateSheetFailed)));
    await openReleaseExternally(release);
  }
}
