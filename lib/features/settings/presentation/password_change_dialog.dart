import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/password_rules.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 비밀번호 변경 다이얼로그 — front `PasswordChangeDialog` 미러.
///
/// PATCH /users/me/password (currentPassword, newPassword, confirmPassword)
/// 다이얼로그가 아니라 바텀시트로 띄운다.
///
/// 규칙 체크리스트(8자 이상·특수문자)와 불일치 문구가 입력 중에 붙었다 떨어졌다
/// 하며 세로가 계속 변한다. 가운데 뜨는 다이얼로그는 그때마다 위아래로 튀지만,
/// 시트는 아래에 붙어 있어 늘어나도 흔들리지 않는다. 웹 모바일도 같은 이유로
/// drawer 다(front PasswordChangeDialog).
Future<void> showPasswordChangeDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  await showPSheet<void>(
    context,
    title: l.navChangePassword,
    // 입력 3개짜리라 화면을 85% 점유할 이유가 없다 — 내용 높이만 쓴다.
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _PasswordChangeDialog(controller: controller),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.passwordChangeAction,
    ),
  );
  controller.dispose();
}

class _PasswordChangeDialog extends ConsumerStatefulWidget {
  const _PasswordChangeDialog({required this.controller});
  final PSheetController controller;

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
  void initState() {
    super.initState();
    widget.controller.onSubmit = _submit;
  }

  /// 입력이 바뀔 때마다 footer 버튼 활성/로딩을 맞춘다.
  void _syncFooter() {
    widget.controller
      ..setCanSubmit(_canSubmit)
      ..setSubmitting(_submitting);
  }

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
    // 정책은 kPasswordRules 단일 소스 — 아래 체크리스트가 보여주는 것과 동일
    return c.isNotEmpty && isPasswordValid(n) && n == f && n != c;
  }

  /// 현재 비밀번호와 동일한지 — 서버(SSO)도 거부하므로 제출 전에 알린다
  bool get _sameAsCurrent =>
      _currentCtrl.text.isNotEmpty && _newCtrl.text == _currentCtrl.text;

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
      _syncFooter();
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
      showPSnackBar(
        context,
        l.passwordChanged,
        severity: PSnackSeverity.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isEmpty ? l.passwordChangeFailed : e.message;
        _submitting = false;
        _syncFooter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 시트 header(제목·X)와 footer(취소·변경)는 showPSheet 이 그린다 — 여기선 폼만.
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.lg),
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
            onChanged: (_) => setState(_syncFooter),
          ),
          const SizedBox(height: PSpace.x12),
          PSectionLabel(l.passwordNew),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _newCtrl,
            obscureText: true,
            enabled: !_submitting,
            placeholder: l.passwordNewPlaceholder,
            onChanged: (_) => setState(_syncFooter),
          ),
          // 입력 중 실시간 규칙 표시 — 변경 버튼을 누르기 전에 미달 조건을 알 수 있게
          if (_newCtrl.text.isNotEmpty) ...[
            const SizedBox(height: PSpace.xs),
            for (final rule in kPasswordRules)
              _RuleRow(ok: rule.test(_newCtrl.text), label: rule.label(l)),
          ],
          if (_sameAsCurrent)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.passwordSameAsCurrent,
                style: PTypo.caption.copyWith(color: t.statusDanger),
              ),
            ),
          const SizedBox(height: PSpace.x12),
          PSectionLabel(l.passwordNewConfirm),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _confirmCtrl,
            obscureText: true,
            enabled: !_submitting,
            placeholder: l.passwordConfirmPlaceholder,
            onChanged: (_) => setState(_syncFooter),
          ),
          // 입력 중 실시간 일치 표시 — 위 규칙 체크리스트와 같은 문법(체크/X).
          // 확인 입력이 비면 표시하지 않는다(입력 시작 전부터 불일치로 겁주지 않게).
          if (_confirmCtrl.text.isNotEmpty)
            _RuleRow(
              ok: _newCtrl.text == _confirmCtrl.text,
              label: _newCtrl.text == _confirmCtrl.text
                  ? l.passwordMatched
                  : l.passwordMismatch,
              // 불일치는 규칙 미달(아직 채우는 중)과 달리 두 값이 어긋난 '충돌'
              failColor: t.statusDanger,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: PTypo.caption.copyWith(color: t.statusDanger),
              ),
            ),
        ],
      ),
    );
  }
}

/// 규칙 한 줄 — 충족=체크 / 미달=X
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.ok, required this.label, this.failColor});

  final bool ok;
  final String label;

  /// 미달일 때 색. 규칙은 아직 채우는 중이라 기본 muted 를 쓰고,
  /// 확인 입력 불일치는 두 값이 어긋난 '충돌'이라 호출처가 danger 를 넘긴다.
  final Color? failColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = ok ? t.statusSuccessFg : (failColor ?? t.fgTertiary);
    return Padding(
      padding: const EdgeInsets.only(top: PSpace.xs),
      child: Row(
        children: [
          Icon(ok ? LucideIcons.check : LucideIcons.x, size: 14, color: color),
          const SizedBox(width: PSpace.sm),
          Text(label, style: PTypo.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
