import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
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

/// 카드 묶음 토글 — 켜기는 그냥, 풀기는 비밀번호 검증을 거친다.
///
/// 여러 장을 한 번에 넘기면 **인증도 한 번**이다. 카드마다 비밀번호를 치게 하면
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
  final ok = await showHideAmountsUnlockDialog(context);
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
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: (_ctrl.text.trim().isEmpty || _submitting) ? null : _submit,
          child: _submitting
              ? const PCircularProgressIndicator(size: 16, strokeWidth: 2)
              : Text(l.actionConfirm),
        ),
      ],
    );
  }
}
