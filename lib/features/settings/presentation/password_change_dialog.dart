import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 비밀번호 변경 다이얼로그 — front `PasswordChangeDialog` 미러.
///
/// PATCH /users/me/password (currentPassword, newPassword, confirmPassword)
Future<void> showPasswordChangeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PasswordChangeDialog(),
  );
}

class _PasswordChangeDialog extends ConsumerStatefulWidget {
  const _PasswordChangeDialog();

  @override
  ConsumerState<_PasswordChangeDialog> createState() =>
      _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends ConsumerState<_PasswordChangeDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_submitting) return false;
    final c = _currentCtrl.text;
    final n = _newCtrl.text;
    final f = _confirmCtrl.text;
    return c.isNotEmpty && n.length >= 8 && n == f;
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, l.passwordChanged);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isEmpty ? l.passwordChangeFailed : e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return PFormAlertDialog(
      title: l.navChangePassword,
      titleLeading: Icon(LucideIcons.key, size: 18, color: t.fgBrand),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSectionLabel(l.passwordCurrent),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: _currentCtrl,
              obscureText: true,
              enabled: !_submitting,
              placeholder: l.passwordCurrent,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: PSpace.x12),
            PSectionLabel(l.passwordNew),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: _newCtrl,
              obscureText: true,
              enabled: !_submitting,
              placeholder: l.passwordNewPlaceholder,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: PSpace.x12),
            PSectionLabel(l.passwordNewConfirm),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: _confirmCtrl,
              obscureText: true,
              enabled: !_submitting,
              placeholder: l.passwordConfirmPlaceholder,
              onChanged: (_) => setState(() {}),
            ),
            if (_newCtrl.text.isNotEmpty &&
                _confirmCtrl.text.isNotEmpty &&
                _newCtrl.text != _confirmCtrl.text)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.passwordMismatch,
                    style:
                        PTypo.caption.copyWith(color: t.statusDanger)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        PTypo.caption.copyWith(color: t.statusDanger)),
              ),
          ],
        ),
      ),
      actions: [
        PButton(
          label: l.actionCancel,
          variant: PButtonVariant.ghost,
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(),
        ),
        PButton(
          label: l.passwordChangeAction,
          loading: _submitting,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

