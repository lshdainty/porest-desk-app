import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_section_label.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';

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
      showPSnackBar(context, '비밀번호가 변경되었습니다');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isEmpty ? '비밀번호 변경에 실패했습니다.' : e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PFormAlertDialog(
      title: '비밀번호 변경',
      titleLeading: Icon(LucideIcons.key, size: 18, color: t.fgBrand),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSectionLabel('현재 비밀번호'),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: _currentCtrl,
              obscureText: true,
              enabled: !_submitting,
              placeholder: '현재 비밀번호',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: PSpace.x12),
            PSectionLabel('새 비밀번호'),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: _newCtrl,
              obscureText: true,
              enabled: !_submitting,
              placeholder: '8자 이상',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: PSpace.x12),
            PSectionLabel('새 비밀번호 확인'),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: _confirmCtrl,
              obscureText: true,
              enabled: !_submitting,
              placeholder: '한 번 더 입력',
              onChanged: (_) => setState(() {}),
            ),
            if (_newCtrl.text.isNotEmpty &&
                _confirmCtrl.text.isNotEmpty &&
                _newCtrl.text != _confirmCtrl.text)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('새 비밀번호가 일치하지 않습니다',
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
          label: '취소',
          variant: PButtonVariant.ghost,
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(),
        ),
        PButton(
          label: '변경',
          loading: _submitting,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

