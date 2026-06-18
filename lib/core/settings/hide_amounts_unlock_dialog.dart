import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
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

/// 금액 숨김 토글 — 잠금 해제(true→false) 시 비밀번호 검증을 거친다.
/// 검증 성공 시 hideAmounts=false 로 변경, 실패·취소 시 상태 유지.
Future<void> toggleHideAmountsWithUnlock(
    BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider).value;
  final currentlyHidden = settings?.hideAmounts ?? false;
  final notifier = ref.read(settingsProvider.notifier);
  if (!currentlyHidden) {
    await notifier.setHideAmounts(true);
    return;
  }
  final ok = await showHideAmountsUnlockDialog(context);
  if (ok) {
    await notifier.setHideAmounts(false);
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
        _error = e.message.isEmpty ? '비밀번호가 일치하지 않습니다.' : e.message;
        _submitting = false;
        _ctrl.clear();
      });
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PFormAlertDialog(
      title: '금액 보기 인증',
      titleLeading:
          Icon(LucideIcons.shieldCheck, size: 18, color: t.fgBrand),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('금액을 다시 보려면 비밀번호로 본인 확인이 필요해요.',
              style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x16),
          Text('비밀번호',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: '비밀번호 입력',
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
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: (_ctrl.text.trim().isEmpty || _submitting) ? null : _submit,
          child: _submitting
              ? const PCircularProgressIndicator(size: 16, strokeWidth: 2)
              : const Text('확인'),
        ),
      ],
    );
  }
}
