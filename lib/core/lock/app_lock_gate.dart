import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/lock/app_lock.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 앱 잠금 게이트 — `MaterialApp.router` 의 builder 로 라우터 전체를 감싼다.
///
/// 로그인과는 별개의 기기 잠금이다: 세션이 살아 있어도 앱을 새로 열거나
/// 백그라운드에서 돌아오면 Face ID·지문으로 본인 확인을 받은 뒤에야 화면을 보여준다.
/// 라우트가 아니라 오버레이라 딥링크·알림 진입 등 어떤 경로로 열려도 덮는다.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  /// OS 프롬프트가 떠 있는 동안 true.
  ///
  /// 프롬프트 자체가 lifecycle 을 흔든다 — iOS Face ID 는 inactive, 일부 안드로이드
  /// 기기는 paused 까지 보낸다. 이 동안의 이벤트로 재잠금·중복 프롬프트가 돌지 않게 막는다.
  bool _authenticating = false;

  /// 이번 잠금에서 자동 프롬프트를 이미 띄웠는가.
  ///
  /// 취소·불일치로 프롬프트가 닫히면 iOS 가 resumed 를 한 번 더 보내는데, 거기서
  /// 또 자동으로 띄우면 취소할 수 없는 핑퐁이 된다(시뮬레이터 실측). 자동은 잠금당
  /// 1회 — 이후 재시도는 잠금 화면 버튼만.
  bool _promptedSinceLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 콜드 스타트에 이미 잠겨 있으면(게이트 생성 전에 설정이 로드된 경우) 바로 프롬프트.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeAuthenticate(auto: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;
    switch (state) {
      // hidden 에서 잠가야 앱 스위처 스냅샷에도 잠금 화면이 찍힌다. inactive 는 안 된다 —
      // Face ID 프롬프트·알림 센터만 내려도 오는 이벤트라 잠금이 헛돈다.
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // 백그라운드로 나갈 때마다 자동 프롬프트 1회를 다시 허용한다.
        _promptedSinceLock = false;
        ref.read(appLockedProvider.notifier).lock();
      case AppLifecycleState.resumed:
        _maybeAuthenticate(auto: true);
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// [auto] 가 true 면 시스템이 부르는 자동 프롬프트 — 잠금당 1회만 띄운다.
  /// 잠금 화면 버튼(false)은 언제든 다시 띄운다.
  Future<void> _maybeAuthenticate({required bool auto}) async {
    if (_authenticating || !mounted) return;
    if (!ref.read(appLockedProvider)) return;
    if (auto && _promptedSinceLock) return;
    _promptedSinceLock = true;
    _authenticating = true;
    try {
      final l = AppLocalizations.of(context);
      final result = await ref.read(appLockAuthProvider).authenticate(
            reason: l.appLockPromptReason,
            signInTitle: l.appLockTitle,
            cancelLabel: l.actionCancel,
          );
      if (!mounted) return;
      switch (result) {
        case AppLockAuthResult.success:
          ref.read(appLockedProvider.notifier).unlock();
        case AppLockAuthResult.unavailable:
          // 잠금을 켠 뒤 기기에서 인증 수단이 전부 사라진 경우 — 확인할 방법이 없는데
          // 가둬 두면 앱을 영영 못 연다. 열어 주는 쪽이 덜 나쁘다.
          ref.read(appLockedProvider.notifier).unlock();
        case AppLockAuthResult.failure:
          // 잠금 유지 — 잠금 화면의 버튼으로 다시 시도한다.
          break;
      }
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockedProvider);
    ref.listen(appLockedProvider, (prev, next) {
      // 잠기는 순간 자동 프롬프트 — 단 포그라운드일 때만. 백그라운드 진입으로 잠긴
      // 경우는 여기서 띄우면 안 되고(화면 밖 프롬프트), resumed 핸들러가 띄운다.
      // null 은 아직 lifecycle 이벤트가 안 온 콜드 스타트 극초반 — 포그라운드로 본다.
      final ls = WidgetsBinding.instance.lifecycleState;
      if (next && prev != true &&
          (ls == null || ls == AppLifecycleState.resumed)) {
        _promptedSinceLock = false;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybeAuthenticate(auto: true));
      }
    });
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (locked) _LockScreen(onUnlock: () => _maybeAuthenticate(auto: false)),
      ],
    );
  }
}

/// 잠금 화면 — 콘텐츠 전체를 덮는 불투명 표면.
///
/// 프롬프트는 게이트가 자동으로 띄우고, 취소·불일치로 닫힌 뒤에는 이 화면의
/// 버튼으로 다시 부른다.
class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgSurface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpace.x24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: t.bgBrandSubtle,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.lock, size: 28, color: t.fgBrand),
                ),
                const SizedBox(height: PSpace.x20),
                Text(
                  l.appLockTitle,
                  style: PTypo.h3.copyWith(color: t.fgPrimary),
                ),
                const SizedBox(height: PSpace.x8),
                Text(
                  l.appLockLockedDesc,
                  textAlign: TextAlign.center,
                  style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                ),
                const SizedBox(height: PSpace.x32),
                PButton(
                  label: l.appLockUnlockAction,
                  icon: LucideIcons.fingerprint,
                  size: PButtonSize.lg,
                  onPressed: onUnlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
