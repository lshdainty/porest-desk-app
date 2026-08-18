import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/lock/app_lock.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';

/// 앱 잠금(생체인증) 스위치 — 표시 설정 '개인정보 보호' 의 행.
///
/// 켤 때 생체인증을 한 번 통과해야 켜진다 — 인증이 안 되는 상태(미등록·미지원)로
/// 잠가 두면 다음 실행부터 앱을 못 열기 때문에, 켜는 순간이 곧 작동 검증이다.
/// 끄는 건 그냥 꺼진다: 여기까지 왔다는 것 자체가 이미 잠금을 통과했다는 뜻이다.
class AppLockRow extends ConsumerWidget {
  const AppLockRow({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (!on) {
      await notifier.setAppLock(false);
      return;
    }
    final l = AppLocalizations.of(context);
    final result = await ref.read(appLockAuthProvider).authenticate(
          reason: l.appLockPromptReason,
          signInTitle: l.appLockTitle,
          cancelLabel: l.actionCancel,
        );
    switch (result) {
      case AppLockAuthResult.success:
        await notifier.setAppLock(true);
      case AppLockAuthResult.unavailable:
        if (context.mounted) showPSnackBar(context, l.appLockUnavailable);
      case AppLockAuthResult.failure:
        // 취소·불일치 — 스위치를 켜지 않고 그대로 둔다.
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final on = ref.watch(appLockEnabledProvider);

    // 금액 가리기 헤더 행과 같은 시각(36 아이콘 박스 + 제목/설명 + 스위치).
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x4, vertical: PSpace.x12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
            alignment: Alignment.center,
            child: Icon(LucideIcons.fingerprint,
                size: 17, color: t.fgSecondary),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appLockTitle,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.semi)),
                const SizedBox(height: 2),
                Text(l.appLockRowDesc,
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          SizedBox(
            height: 24,
            child: PSwitch(
              value: on,
              onChanged: (v) => _toggle(context, ref, v),
            ),
          ),
        ],
      ),
    );
  }
}
