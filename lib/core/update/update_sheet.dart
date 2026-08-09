import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/update/apk_installer.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 새 버전이 있으면 앱에 들어올 때 한 번 크게 알린다.
///
/// 홈 배너만 두면 스쳐 지나간다. 스토어가 없어 알림도 안 오니, 새 버전을 알 기회가
/// 여기뿐이다. 대신 막지는 않는다 — 미루면 배너로 물러나고 그 버전은 다시 묻지 않는다.
///
/// **안드로이드 전용이다.** iOS 는 앱이 스스로를 설치할 수 없어서(서명 없는 IPA 는
/// 브라우저로 열어도 안 깔린다) 크게 띄워 봐야 할 수 있는 게 없다. 그쪽은 홈 배너에서
/// AltStore 로 넘기는 길만 둔다.
Future<void> maybeShowUpdateSheet(
  BuildContext context,
  WidgetRef ref,
  AppRelease release,
) async {
  if (!Platform.isAndroid) return;
  if (await loadSkippedBuild() >= release.buildNumber) return;
  if (!context.mounted) return;

  final l = AppLocalizations.of(context);
  final started = await showPSheet<bool>(
    context,
    title: l.updateSheetTitle(release.version),
    initialChildSize: 0.95,
    maxChildSize: 0.95,
    minChildSize: 0.6,
    contentBuilder: (ctx, scroll) => _UpdateBody(release: release, scroll: scroll),
    footerBuilder: (ctx) => _UpdateFooter(release: release),
  );

  // 스와이프로 닫은 것도 "나중에" 와 같은 뜻으로 본다. 안 그러면 들어올 때마다 다시 뜬다.
  if (started != true) await saveSkippedBuild(release.buildNumber);
}

class _UpdateBody extends StatelessWidget {
  const _UpdateBody({required this.release, required this.scroll});

  final AppRelease release;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final lines = release.notes
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(PSpace.x24, 0, PSpace.x24, PSpace.x24),
      children: [
        Text(
          l.updateSheetSubtitle,
          style: PTypo.body.copyWith(color: t.fgSecondary, height: 1.6),
        ),
        const SizedBox(height: PSpace.x24),

        if (lines.isEmpty)
          Text(
            l.updateSheetNoNotes,
            style: PTypo.bodySm.copyWith(color: t.fgTertiary, height: 1.6),
          )
        else ...[
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: PSpace.x8),
                    child: Text(
                      // CI 가 '- ' 를 붙여 보낸다. 여기서 점을 다시 그리므로 떼어 낸다.
                      line.startsWith('- ') ? line.substring(2) : line,
                      style: PTypo.bodySm
                          .copyWith(color: t.fgSecondary, height: 1.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 취소·업데이트 버튼. 받는 동안에는 좌측에 진행률이 대신 들어간다.
///
/// 표준 시트 footer(`PSheetFooter`)를 그대로 쓴다 — 버튼 배치·간격·비활성 규칙이
/// 다른 시트와 같아야 한다. 진행률은 그 컴포넌트가 열어 둔 `leftSlot` 에 얹는다.
class _UpdateFooter extends ConsumerStatefulWidget {
  const _UpdateFooter({required this.release});

  final AppRelease release;

  @override
  ConsumerState<_UpdateFooter> createState() => _UpdateFooterState();
}

class _UpdateFooterState extends ConsumerState<_UpdateFooter> {
  final _controller = PSheetController()..canSubmit = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final progress = ref.watch(apkInstallerProvider);

    // 받는 중에는 제출 버튼이 스스로 잠긴다(PSheetFooter 가 submitting 을 본다).
    _controller.setSubmitting(progress.isBusy);
    _controller.onSubmit = () => _start(context, ref);

    return PSheetFooter(
      controller: _controller,
      submitLabel: progress.stage == ApkStage.failed
          ? l.updateSheetRetry
          : l.updateSheetNow,
      submitIcon: LucideIcons.download,
      cancelLabel: l.updateSheetLater,
      leftSlot: progress.isBusy
          ? Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: PSpace.x16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final release = widget.release;
    final ok = await ref.read(apkInstallerProvider.notifier).downloadAndOpen(release);
    if (!context.mounted) return;

    if (ok) {
      // 설치 화면이 떴다. 시트는 닫아 준다 — 돌아왔을 때 남아 있으면 어수선하다.
      Navigator.of(context).pop(true);
      return;
    }

    // 앱 안에서 못 받았으면 브라우저에 넘긴다. 거기서는 받아지는 경우가 있다.
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l.updateSheetFailed)));
    await launchUrl(
      Uri.parse(release.androidUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
