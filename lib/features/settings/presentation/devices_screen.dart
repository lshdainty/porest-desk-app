import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/now_tick.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/settings/application/session_providers.dart';
import 'package:porest_desk_app/features/settings/domain/device_session.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

/// "로그인된 기기" — 계정 > 보안에서 들어온다.
///
/// 이 계정으로 살아 있는 세션을 기기별로 보여 주고, 낯선 기기를 끊게 한다.
/// 목록·해지 모두 desk 백엔드만 부른다(SSO 왕복 없음) — desk 가 로그인마다 자기
/// 세션 테이블에 한 행을 남기기 때문이다.
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  /// 해지 중인 세션 — 그 행의 버튼만 잠근다. 목록 전체를 잠그면 다른 기기를
  /// 이어서 끊으려던 손이 멈춘다.
  String? _revoking;

  Future<void> _revoke(DeviceSession device) async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.devicesLogoutTitle,
      message: l.devicesLogoutConfirm(device.deviceLabel ?? l.devicesUnknown),
      confirmLabel: l.devicesLogout,
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _revoking = device.sessionId);
    try {
      final repo = await ref.read(sessionRepositoryProvider.future);
      await repo.revoke(device.sessionId);
      if (!mounted) return;
      // 지금 이 기기를 끊었으면 여기 머물 이유가 없다 — 로그인 화면으로 보낸다.
      if (device.current) {
        await ref.read(authProvider.notifier).logout();
        return;
      }
      ref.invalidate(deviceSessionListProvider);
    } on ApiException {
      // 서버 메시지는 전역 인터셉터가 띄운다.
    } finally {
      if (mounted) setState(() => _revoking = null);
    }
  }

  Future<void> _revokeAll() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.devicesLogoutAllTitle,
      message: l.devicesLogoutAllConfirm,
      confirmLabel: l.devicesLogoutAll,
      destructive: true,
    );
    if (!ok || !mounted) return;

    try {
      final repo = await ref.read(sessionRepositoryProvider.future);
      await repo.revokeAll();
      if (!mounted) return;
      // 전부 끊었으니 이 기기도 끊겼다. 화면에 남겨 두면 다음 요청마다 401 이 난다.
      //
      // 성공 토스트는 띄우지 않는다 — 확인 다이얼로그에서 "다시 로그인해야 해요" 라고
      // 이미 말했고, 로그인 화면으로 떨어지는 것 자체가 결과다.
      await ref.read(authProvider.notifier).logout();
    } on ApiException {
      // 서버 메시지는 전역 인터셉터가 띄운다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(deviceSessionListProvider);
    // 상대시각의 기준점 — 화면을 열어 둔 채로도 흐르게 한다(웹 `useNow` 정합).
    // 한 번 watch 해 행마다 내리면 모든 행이 같은 '지금' 을 쓴다.
    final now = ref.watch(nowTickProvider);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(l.devicesTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(deviceSessionListProvider);
          await ref.read(deviceSessionListProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x24, vertical: PSpace.x24),
          children: [
            Text(l.devicesIntro,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary, height: 1.5)),
            const SizedBox(height: PSpace.x24),
            listAsync.when(
              loading: () => const PListSkeleton(rows: 3, showAvatar: true),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                child: Text('${l.devicesLoadError}\n$e',
                    style: PTypo.bodySm.copyWith(color: t.statusDanger)),
              ),
              data: (devices) => devices.isEmpty
                  ? PEmptyState(
                      icon: LucideIcons.monitorOff,
                      message: l.devicesEmpty,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < devices.length; i++) ...[
                          if (i > 0) const PDivider(),
                          _DeviceRow(
                            device: devices[i],
                            tokens: t,
                            now: now,
                            busy: _revoking == devices[i].sessionId,
                            onRevoke: () => _revoke(devices[i]),
                          ),
                        ],
                        const SizedBox(height: PSpace.x32),
                        // 비상 버튼이라 목록 아래에 둔다 — 위에 두면 기기 하나만
                        // 끊으려던 손이 먼저 닿는다.
                        PButton(
                          label: l.devicesLogoutAll,
                          variant: PButtonVariant.dangerSoft,
                          size: PButtonSize.md,
                          fullWidth: true,
                          onPressed: _revokeAll,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: PSpace.x32),
          ],
        ),
      ),
    );
  }
}

/// 기기 한 줄 — 아이콘 + 이름(+현재 기기) + 마지막 사용 + [로그아웃].
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.tokens,
    required this.now,
    required this.busy,
    required this.onRevoke,
  });

  final DeviceSession device;
  final PorestTokens tokens;

  /// 상대시각의 기준점 — 호출부에서 `nowTickProvider` 로 받아 내린다.
  /// 기본값을 두지 않는 이유는 [_relativeTime] 주석 참고.
  final DateTime now;
  final bool busy;
  final VoidCallback onRevoke;

  /// 아이콘은 서버가 준 형태로 고른다 — 기기 이름 문자열을 여기서 다시 뜯지 않는다.
  IconData get _icon => switch (device.deviceKind) {
        DeviceKind.mobile => LucideIcons.smartphone,
        DeviceKind.tablet => LucideIcons.tablet,
        DeviceKind.desktop => LucideIcons.monitor,
        DeviceKind.unknown => LucideIcons.circleHelp,
      };

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final when = _relativeTime(l, device.activeAt, now);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: t.bgMuted, borderRadius: PRadius.brMd),
            alignment: Alignment.center,
            child: Icon(_icon, size: 18, color: t.fgSecondary),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.deviceLabel ?? l.devicesUnknown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PTypo.body.copyWith(
                            color: t.fgPrimary, fontWeight: PFontWeight.semi),
                      ),
                    ),
                    if (device.current) ...[
                      const SizedBox(width: 6),
                      PBadge(
                          label: l.devicesCurrent,
                          variant: PBadgeVariant.outlineSuccess),
                    ],
                  ],
                ),
                if (when != null) ...[
                  const SizedBox(height: 2),
                  Text(l.devicesLastUsed(when),
                      style: PTypo.caption.copyWith(
                          color: t.fgTertiary,
                          fontWeight: PFontWeight.regular)),
                ],
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          PButton(
            label: l.devicesLogout,
            variant: PButtonVariant.ghost,
            size: PButtonSize.sm,
            loading: busy,
            onPressed: onRevoke,
          ),
        ],
      ),
    );
  }
}

/// 서버가 준 `[UTC]` 시각 → "방금 · 3분 전 · 어제 · 2026-08-24".
///
/// [parseServerUtc] 를 거쳐야 한다 — 시간대 없는 문자열을 그대로 파싱하면 UTC 가
/// 로컬로 둔갑해 KST 에서 9시간이 어긋난다.
///
/// [now] 는 기준 시각이며 **인자로 받는다**. 여기서 [DateTime.now] 를 부르면 그 값은
/// 화면을 다시 그릴 때만 바뀌어, 기기 목록을 열어 둔 채로는 "방금" 에 멈춘다.
/// 넘길 값은 `nowTickProvider` 가 주는 흐르는 '지금' 이다. 기본값을 두면 안 넘긴
/// 호출부가 조용히 멈춘 시계로 돌아가므로 필수로 둔다.
String? _relativeTime(AppLocalizations l, String? iso, DateTime now) {
  final dt = parseServerUtc(iso);
  if (dt == null) return null;
  final diff = now.difference(dt);
  final m = diff.inMinutes;
  if (m < 1) return l.dateJustNow;
  if (m < 60) return l.dateMinutesAgo(m);
  final h = diff.inHours;
  if (h < 24) return l.dateHoursAgo(h);
  final d = diff.inDays;
  if (d == 1) return l.dateYesterday;
  if (d < 7) return l.dateDaysAgo(d);
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  return '${dt.year}-$mm-$dd';
}
