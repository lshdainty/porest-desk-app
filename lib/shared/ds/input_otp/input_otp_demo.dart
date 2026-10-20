import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input_otp/p_input_otp.dart';

const _description = '10분 안에 입력해주세요 · 5번 틀리면 다시 받아요.';
const _error = '코드가 맞지 않거나 시간이 지났어요. 확인하거나 다시 받아주세요.';

String _cooldown(int n) => '다시 받기($n초)';

/// 카탈로그(/dev/ds) — 상태(기본 · 오류 · 막힘 — 포커스는 직접 눌러 본다) × 칸 · 설명 줄 · 다시 받기, 다시 받기의 때
/// (처음 · 다시 받기 · 남은 초), 붙여넣기 · 다시 받기 흐름. 앱은 늘 large(52)다.
class InputOtpDemo extends StatelessWidget {
  const InputOtpDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '상태 — 칸은 Input 한 칸이다(자릿수만큼 나누지 않는다). 포커스는 직접 눌러 본다',
          children: [
            _Sample(label: 'enabled'),
            _Sample(label: 'invalid', invalid: true),
            _Sample(label: 'disabled', disabled: true),
          ],
        ),
        DemoBlock(
          title: '다시 받기의 때 — 코드 받기 · 다시 받기 · 다시 받기(52초, 막힘)',
          children: [
            _Sample(label: 'first', resend: _Resend.first),
            _Sample(label: 'ready', resend: _Resend.ready),
            _Sample(label: 'cooldown', resend: _Resend.cooldown),
          ],
        ),
        DemoBlock(
          title: '붙여넣기 · 다시 받기 — "123 456" · "인증 코드: 123456" 을 붙여 본다',
          children: [_Flow()],
        ),
      ],
    );
  }
}

enum _Resend { first, ready, cooldown }

class _Sample extends StatefulWidget {
  const _Sample({
    required this.label,
    this.invalid = false,
    this.disabled = false,
    this.resend = _Resend.ready,
  });

  final String label;
  final bool invalid;
  final bool disabled;
  final _Resend resend;

  @override
  State<_Sample> createState() => _SampleState();
}

class _SampleState extends State<_Sample> {
  final FocusNode _focus = FocusNode();
  late DateTime? _sentAt = switch (widget.resend) {
    _Resend.first => null,
    _Resend.ready => DateTime.now().subtract(const Duration(seconds: 120)),
    _Resend.cooldown => DateTime.now().subtract(const Duration(seconds: 8)),
  };

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PField(
          label: '인증 코드',
          description: _description,
          invalid: widget.invalid,
          errorMessage: _error,
          disabled: widget.disabled,
          child: PInputOtp(
            focusNode: _focus,
            initialValue: '123456',
            placeholder: '6자리 숫자',
          ),
        ),
        PInputOtpResend(
          sentAt: _sentAt,
          codeFocusNode: _focus,
          firstLabel: '코드 받기',
          readyLabel: '다시 받기',
          cooldownLabel: _cooldown,
          onResend: () => setState(() => _sentAt = DateTime.now()),
        ),
      ],
    );
  }
}

/// 본인 확인 흐름 — 붙여넣기 · 다시 받기 · 확인(저절로 보내지 않는다).
class _Flow extends StatefulWidget {
  const _Flow();

  @override
  State<_Flow> createState() => _FlowState();
}

class _FlowState extends State<_Flow> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();
  DateTime? _sentAt;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PField(
          label: '인증 코드',
          description: _description,
          invalid: _error != null,
          errorMessage: _error,
          child: PInputOtp(
            controller: _code,
            focusNode: _focus,
            placeholder: '6자리 숫자',
            // 고치기 시작하면 설명 줄로 돌아온다
            onChanged: (_) => setState(() => _error = null),
          ),
        ),
        PInputOtpResend(
          sentAt: _sentAt,
          codeFocusNode: _focus,
          firstLabel: '코드 받기',
          readyLabel: '다시 받기',
          cooldownLabel: _cooldown,
          onResend: () => setState(() => _sentAt = DateTime.now()),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PButton(
            label: '확인(데모)',
            variant: PButtonVariant.neutralSolid,
            size: PButtonSize.medium,
            onPressed: () => setState(
              () => _error = _code.text.length < 6
                  ? '인증 코드 6자리를 입력해주세요.'
                  : _error,
            ),
          ),
        ),
      ],
    );
  }
}
