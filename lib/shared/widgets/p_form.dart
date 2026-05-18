import 'package:flutter/material.dart';

import '../../app/theme/elevation.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// specs/components/form.md 미러 (Flutter 적응).
///
/// react-hook-form + Zod 패턴을 Flutter `Form` + `FormField`/`Validators`로 대치.
/// 시각 토큰(form-card / form-grid / form-actions)은 Flutter 위젯으로 재구성.
///
/// 사용 예:
/// ```dart
/// final formKey = GlobalKey<FormState>();
/// PForm(
///   formKey: formKey,
///   children: [
///     PFormGroup(label: '이메일', required: true, helper: '도메인 포함',
///         child: PTextInput(...)),
///     PFormActions(children: [...]),
///   ],
/// )
/// ```
class PForm extends StatelessWidget {
  const PForm({
    super.key,
    required this.formKey,
    required this.children,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.layout = PFormLayout.card,
    this.gap = PSpace.x24,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final AutovalidateMode autovalidateMode;
  final PFormLayout layout;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
    final body = layout == PFormLayout.card
        ? Container(
            constraints: const BoxConstraints(maxWidth: 640),
            padding: const EdgeInsets.all(PSpace.x32),
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: PRadius.brLg,
              boxShadow: PorestElevation.sm,
            ),
            child: column,
          )
        : column;
    return Form(
      key: formKey,
      autovalidateMode: autovalidateMode,
      child: body,
    );
  }
}

enum PFormLayout { card, inline }

/// form-group — label + control + helper + (RHF FormMessage 대응) error 묶음.
///
/// label은 우측에 빨간 `*` (required). helper는 입력 가이드. error는 Flutter
/// `FormFieldState.errorText` 자동 표시(field 내부) — 외부 error 메시지가 필요
/// 한 경우 [errorText] prop.
class PFormGroup extends StatelessWidget {
  const PFormGroup({
    super.key,
    required this.child,
    this.label,
    this.required = false,
    this.helper,
    this.errorText,
  });

  final Widget child;
  final String? label;
  final bool required;
  final String? helper;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: PFontSize.body,
                fontWeight: PFontWeight.medium,
                color: hasError ? t.statusDanger : t.fgPrimary,
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: t.statusDanger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        child,
        if (helper != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.bodySm,
              color: t.fgSecondary,
            ),
          ),
        ],
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.bodySm,
              fontWeight: PFontWeight.medium,
              color: t.statusDanger,
            ),
          ),
        ],
      ],
    );
  }
}

/// form-actions — bottom border + flex justify-end + gap-md.
class PFormActions extends StatelessWidget {
  const PFormActions({super.key, required this.children, this.gap = PSpace.x8});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.only(top: PSpace.x16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderDefault)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 흔히 쓰는 validator 모음 — spec의 Zod 패턴 등가.
class PValidators {
  PValidators._();

  static FormFieldValidator<String> required([String message = '필수 입력입니다']) =>
      (v) => (v == null || v.trim().isEmpty) ? message : null;

  static FormFieldValidator<String> minLength(int len,
          [String? message]) =>
      (v) => (v != null && v.length < len)
          ? (message ?? '$len자 이상 입력하세요')
          : null;

  static FormFieldValidator<String> maxLength(int len,
          [String? message]) =>
      (v) => (v != null && v.length > len)
          ? (message ?? '$len자 이하로 입력하세요')
          : null;

  static final _emailRe =
      RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static FormFieldValidator<String> email(
          [String message = '이메일 형식이 아닙니다']) =>
      (v) => (v == null || v.isEmpty || _emailRe.hasMatch(v)) ? null : message;

  /// 여러 validator chain — 첫 실패 message 반환.
  static FormFieldValidator<T> compose<T>(
          List<FormFieldValidator<T>> validators) =>
      (value) {
        for (final v in validators) {
          final r = v(value);
          if (r != null) return r;
        }
        return null;
      };
}
