import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/update/apk_installer.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/features/update/presentation/release_notes_view.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 새 버전이 나왔을 때 앞을 막고 알리는 화면.
///
/// 스토어를 쓰지 않아 자동 업데이트가 없다. 알리지 않으면 구버전이 계속 남고, 서버가
/// 앞서 나가면 잘못된 값을 주고받게 된다.
///
/// 예전에도 전체 화면으로 알린 적이 있는데 열 때마다 떠서 "받을 생각이 없는 사람에게는
/// 매번 걷어내야 하는 벽" 이 됐고, 그래서 걷어냈다. 이번엔 <b>빌드번호당 한 번</b>만
/// 띄운다 — [취소]를 누르면 그 빌드는 다시 묻지 않고, 다음 버전이 나와야 또 뜬다.
/// 이 조건이 빠지면 예전과 같은 벽이 되어 또 걷어내게 된다.
///
/// 강제([UpdateStatus.mustUpdate])면 이야기가 다르다. 건너뛰기를 무시하고 매번 막는다.
/// 취소하면 왜 못 넘어가는지 알리고 안드로이드는 앱을 닫는다. iOS 는 닫지 않는다 — §종료 참고.
class UpdateGateScreen extends ConsumerWidget {
  const UpdateGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final status = ref.watch(updateStatusProvider).value;
    final release = status?.latest;

    // 게이트는 라우터가 shouldGate 로 열어 준다. 그 사이 상태가 바뀌어 볼 게 없어지면
    // 조용히 빠져나간다(취소 직후 재평가가 늦게 도는 찰나 등).
    if (release == null) {
      return Scaffold(
        backgroundColor: t.bgCanvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final forced = status!.mustUpdate;

    return PopScope(
      // 강제면 시스템 뒤로가기로도 못 빠져나간다. 일반이면 뒤로가기 = 취소와 같다.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancel(context, ref, status: status, forced: forced);
      },
      child: Scaffold(
        backgroundColor: t.bgCanvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PSpace.x24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: PSpace.x24),
                _Header(release: release, currentBuild: status.currentBuild),
                if (forced) ...[
                  const SizedBox(height: PSpace.x24),
                  const _ForcedNotice(),
                ],
                const SizedBox(height: PSpace.x32),
                // 바뀐 내용은 길 수 있어 남는 공간을 다 쓰고 그 안에서 스크롤한다.
                // 노트가 비어 있으면(옛 version.json) 섹션 자체를 숨긴다.
                Expanded(child: _Changes(notes: release.notes)),
                const SizedBox(height: PSpace.x24),
                _Actions(
                  release: release,
                  forced: forced,
                  onCancel: () =>
                      _cancel(context, ref, status: status, forced: forced),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 취소 — 일반이면 이 빌드를 기억하고 물러난다, 강제면 왜 못 넘어가는지 알린다.
  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref, {
    required UpdateStatus status,
    required bool forced,
  }) async {
    if (forced) {
      await _confirmForcedExit(context);
      return;
    }

    // 기억시킨 뒤 라우터가 다시 평가하면 shouldGate 가 거짓이 되어 저절로 풀린다.
    // pop 이 아니라 go 인 이유: 게이트는 리다이렉트로 들어와 돌아갈 스택이 없을 수 있다.
    await ref.read(skippedBuildProvider.notifier).skip(status.latest!.buildNumber);
    if (context.mounted) context.go('/home');
  }

  /// 강제인데 취소를 눌렀을 때. 안드로이드는 확인 즉시 앱을 닫는다.
  ///
  /// iOS 는 닫지 않는다. 프로그램으로 앱을 끝내는 건 애플이 권하지 않고
  /// `SystemNavigator.pop()` 도 동작이 보장되지 않는다 — `exit(0)` 은 사용자에게
  /// 크래시처럼 보인다. 대신 이 화면에 그대로 둔다. 어차피 여기서 못 나가므로
  /// 구버전을 못 쓰게 한다는 목적은 똑같이 이룬다.
  Future<void> _confirmForcedExit(BuildContext context) async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => PFormAlertDialog(
        titleLeading: Icon(
          LucideIcons.triangleAlert,
          size: 18,
          color: ctx.tokens.statusWarningFg,
        ),
        title: l.updateGateForcedCancelBody,
        content: const SizedBox.shrink(),
        actions: [
          PButton(
            label: l.actionConfirm,
            onPressed: () {
              // 다이얼로그를 먼저 닫지 않는다 — 닫기와 종료가 겹치면 종료 직전
              // 프레임에서 에러가 남는다. 안드는 여기서 바로 끝낸다.
              if (Platform.isAndroid) {
                SystemNavigator.pop();
                return;
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.release, required this.currentBuild});

  final AppRelease release;
  final int currentBuild;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration:
              BoxDecoration(color: t.bgBrandSubtle, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(LucideIcons.download, size: 24, color: t.fgBrand),
        ),
        const SizedBox(width: PSpace.x16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.updateGateTitle(release.version),
                style: PTypo.bodyLg.copyWith(
                    color: t.fgPrimary, fontWeight: PFontWeight.bold),
              ),
              const SizedBox(height: PSpace.x4),
              Text(
                l.updateCurrentBuild(currentBuild.toString()),
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForcedNotice extends StatelessWidget {
  const _ForcedNotice();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.statusWarningSubtle,
        borderRadius: PRadius.brLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.triangleAlert, size: 18, color: t.statusWarningFg),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Text(
              l.updateRequiredDesc,
              style:
                  PTypo.bodySm.copyWith(color: t.statusWarningFg, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Changes extends StatelessWidget {
  const _Changes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    if (!PReleaseNotes.hasContent(notes)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.updateSheetChanges,
          style: PTypo.bodySm
              .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
        ),
        const SizedBox(height: PSpace.x12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(PSpace.x16),
            decoration:
                BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brLg),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [PReleaseNotes(notes: notes)],
            ),
          ),
        ),
      ],
    );
  }
}

/// [취소] [설치] — 안드로이드는 앱 안에서 받아 설치까지, iOS 는 AltStore 로 넘긴다.
class _Actions extends ConsumerWidget {
  const _Actions({
    required this.release,
    required this.forced,
    required this.onCancel,
  });

  final AppRelease release;
  final bool forced;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final progress = ref.watch(apkInstallerProvider);

    // 받는 중에는 버튼 대신 진행 상태를 보여 준다 — 두 번 누르는 걸 막는다.
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

    return Row(
      children: [
        Expanded(
          child: PButton(
            label: l.actionCancel,
            // ghost 는 배경이 없어 전체 폭 배치에서 버튼으로 안 보인다 — 테두리 없는
            // 회색 채움(spec button.md Migration notes 2026-08).
            variant: PButtonVariant.secondary,
            size: PButtonSize.lg,
            fullWidth: true,
            onPressed: onCancel,
          ),
        ),
        const SizedBox(width: PSpace.x12),
        Expanded(
          child: PButton(
            label: progress.stage == ApkStage.failed
                ? l.updateSheetRetry
                : l.updateGateInstall,
            size: PButtonSize.lg,
            onPressed: () => _install(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    // iOS 는 앱이 스스로를 설치할 수 없다. AltStore 에 넘긴다 — 설치가 끝나면
    // 프로세스가 교체되므로 게이트는 저절로 사라진다. 그 전에 돌아오면 다시 보인다.
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
