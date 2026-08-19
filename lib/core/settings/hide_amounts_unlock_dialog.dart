import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/lock/app_lock.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';

/// 금액 숨김 잠금해제 다이얼로그.
///
/// hideAmounts=true → false 전환 시 호출. 비밀번호 검증이 성공하면 [true] 반환.
/// 취소·실패 시 [false] 또는 null 반환.
Future<bool> showHideAmountsUnlockDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _HideAmountsUnlockDialog(),
  );
  return ok == true;
}

/// 금액을 다시 보기 위한 본인 확인 — 생체인증을 먼저, 안 되면 비밀번호.
///
/// 앱 잠금을 켠 사람은 이미 이 앱에서 생체인증을 쓰기로 한 것이다. 그 사람에게까지
/// 카드를 풀 때마다 비밀번호를 치게 하면 화면·카드별로 골라 보는 기능 자체를 안 쓰게 된다.
/// 앱 잠금이 꺼져 있으면 프롬프트를 띄우지 않는다 — 켠 적 없는 사람에게 갑자기 Face ID 가
/// 뜨는 건 놀랄 일이다.
///
/// 생체를 취소하거나 실패하면 비밀번호로 물러선다. 풀려던 의도는 분명하니 길을 막지 않되,
/// 거기서도 취소할 수 있다.
Future<bool> confirmHideAmountsUnlock(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(appLockEnabledProvider)) {
    final l = AppLocalizations.of(context);
    final result = await ref.read(appLockAuthProvider).authenticate(
          reason: l.unlockBiometricReason,
          signInTitle: l.unlockTitle,
          cancelLabel: l.actionCancel,
        );
    if (result == AppLockAuthResult.success) return true;
    if (!context.mounted) return false;
  }
  return showHideAmountsUnlockDialog(context);
}

/// 카드 묶음 토글 — 켜기는 그냥, 풀기는 본인 확인을 거친다.
///
/// 여러 장을 한 번에 넘기면 **인증도 한 번**이다. 카드마다 확인을 받으면
/// 페이지·전체 잠그기를 쓸 수가 없다.
Future<void> setHideCardsWithUnlock(
  BuildContext context,
  WidgetRef ref, {
  required Iterable<String> cards,
  required bool hide,
}) async {
  final notifier = ref.read(settingsProvider.notifier);
  if (hide) {
    await notifier.hideCards(cards);
    return;
  }
  final ok = await confirmHideAmountsUnlock(context, ref);
  if (ok) {
    await notifier.revealCards(cards);
  }
}

class _HideAmountsUnlockDialog extends ConsumerStatefulWidget {
  const _HideAmountsUnlockDialog();

  @override
  ConsumerState<_HideAmountsUnlockDialog> createState() =>
      _HideAmountsUnlockDialogState();
}

class _HideAmountsUnlockDialogState
    extends ConsumerState<_HideAmountsUnlockDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _ctrl.text;
    if (pw.trim().isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.verifyPassword(pw);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isEmpty ? AppLocalizations.of(context).unlockMismatch : e.message;
        _submitting = false;
        _ctrl.clear();
      });
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return PFormAlertDialog(
      title: l.unlockTitle,
      titleLeading:
          Icon(LucideIcons.shieldCheck, size: 18, color: t.fgBrand),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.unlockBody,
              style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x16),
          Text(l.unlockPasswordLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: l.unlockPasswordHint,
              errorText: _error,
            ),
            onChanged: (_) => setState(() {
              if (_error != null) _error = null;
            }),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        // raw TextButton/FilledButton 은 CLAUDE.md 금지 — PButton 으로 통일.
        // 취소는 secondary(테두리 없는 회색 채움), ghost 는 전체 폭 배치에서
        // 버튼으로 안 보인다(spec button.md Migration notes 2026-08).
        PButton(
          label: l.actionCancel,
          variant: PButtonVariant.secondary,
          size: PButtonSize.lg,
          fullWidth: true,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        PButton(
          label: l.actionConfirm,
          size: PButtonSize.lg,
          fullWidth: true,
          loading: _submitting,
          onPressed: (_ctrl.text.trim().isEmpty || _submitting) ? null : _submit,
        ),
      ],
    );
  }
}
