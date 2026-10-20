import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';

/// 글에서 숫자만 — 전각 숫자(０-９)는 보통 숫자로 바꿔 센다(웹 NFKC 와 같은 셈, 전각 숫자만 푼다).
@visibleForTesting
String otpDigitsOf(String text) {
  final out = StringBuffer();
  for (final unit in text.runes) {
    if (unit >= 0x30 && unit <= 0x39) {
      out.writeCharCode(unit);
    } else if (unit >= 0xFF10 && unit <= 0xFF19) {
      out.writeCharCode(unit - 0xFF10 + 0x30);
    }
  }
  return out.toString();
}

/// 남은 초 — 보낸 때부터 cooldown 안이면 올림한 초(cooldown 을 넘지 않는다), 아니면 0.
@visibleForTesting
int otpRemainingOf(DateTime? sentAt, int cooldownSeconds, DateTime now) {
  if (sentAt == null) return 0;
  final left =
      sentAt
          .add(Duration(seconds: cooldownSeconds))
          .difference(now)
          .inMicroseconds /
      Duration.microsecondsPerSecond;
  return math.min(cooldownSeconds, math.max(0, left.ceil()));
}

/// 코드 칸의 글 거르기 — 치기 · 붙여넣기 · 자동 채우기 모두 글에서 숫자만 뽑아 앞 [length] 자리를 쓴다
/// ("123 456" · "123-456" · "인증 코드: 123456" → 123456). 숫자를 [length] 자리 이상 담은 글을 붙여 넣으면(한 번에 두 글자
/// 이상 들어온 글) 칸의 값을 그 숫자로 바꾼다 — 칸에 이미 숫자가 있어도(받은 코드 하나를 통째로 넣는 자리다).
/// 걸러져 글이 바뀌면 커서는 그 앞 숫자 뒤에 둔다. `maxLength` 를 걸지 않는다 — 먼저 자르면 붙인 글의 숫자를 잃는다.
class PInputOtpFormatter extends TextInputFormatter {
  const PInputOtpFormatter({this.length = 6});

  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    // 새로 들어온 가운데 — 앞뒤로 같은 글을 빼고 남은 것
    final old = oldValue.text;
    var head = 0;
    while (head < old.length && head < raw.length && old[head] == raw[head]) {
      head++;
    }
    var tail = 0;
    while (tail < old.length - head &&
        tail < raw.length - head &&
        old[old.length - 1 - tail] == raw[raw.length - 1 - tail]) {
      tail++;
    }
    final inserted = raw.substring(head, raw.length - tail);
    final pasted = otpDigitsOf(inserted);
    if (inserted.runes.length > 1 && pasted.length >= length) {
      final code = pasted.substring(0, length);
      return TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
    }

    final next = otpDigitsOf(raw);
    final cut = next.length > length ? next.substring(0, length) : next;
    if (cut == raw) return newValue;
    final caret = newValue.selection.extentOffset;
    final before = caret < 0 || caret > raw.length
        ? raw
        : raw.substring(0, caret);
    final at = math.min(cut.length, otpDigitsOf(before).length);
    return TextEditingValue(
      text: cut,
      selection: TextSelection.collapsed(offset: at),
    );
  }
}

/// Input OTP — 메일 · 문자로 받은 일회용 인증 코드(지금은 숫자 6자리)를 넣는 칸. [PInput](상자형 large 52) 한 칸이다 —
/// 칸을 자릿수만큼 나누지 않는다(SEED Text Input 의 "Input을 나누지 말고"). 수치 원본은 groo-design
/// `specs/components/input-otp.yaml`(값은 `test/fixtures/design_spec/input-otp.json`), 칸의 상자 · 글자 · 상태는
/// input.yaml(Input), 라벨 · 설명 · 오류는 field.yaml(Field)이 원본이다. 웹(desk-front `src/shared/ds/input-otp`)과 같은 값이다.
/// 앱은 늘 large(52) — medium(40) · responsive 는 1280 이상 데스크톱 웹 몫이다(Input 과 같다).
///
/// 숫자 키보드 · 자동 채우기(one-time-code) · 고정폭 숫자를 스스로 건다. 6자리를 채워도 아무것도 보내지 않는다
/// (확인 단추를 누른다). 라벨 · 설명 · 오류는 [PField] 가 둘레에서 그린다 — 유효 시간 · 틀릴 수 있는 횟수를 설명 줄에 늘 둔다.
/// 문구(placeholder "6자리 숫자")는 부르는 쪽이 넘긴다.
class PInputOtp extends StatelessWidget {
  const PInputOtp({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.length = 6,
    this.placeholder,
    this.onChanged,
    this.disabled,
    this.invalid,
    this.semanticLabel,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? initialValue;

  /// 코드 칸의 초점 — [PInputOtpResend.codeFocusNode] 와 같은 것을 준다.
  final FocusNode? focusNode;

  /// 자릿수 — 기본 6.
  final int length;

  /// 빈 칸의 글 — "6자리 숫자".
  final String? placeholder;

  /// 숫자만 · 최대 [length] 자 — 붙여넣기 · 자동 채우기도 이 값으로(값이 바뀔 때만).
  final ValueChanged<String>? onChanged;
  final bool? disabled;
  final bool? invalid;

  /// 이름 — Field 밖에서 쓸 때. Field 안이면 Field 의 라벨("인증 코드")이 이름이다.
  final String? semanticLabel;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => PInput(
    controller: controller,
    initialValue: initialValue == null
        ? null
        : otpDigitsOf(
            initialValue!,
          ).substring(0, math.min(length, otpDigitsOf(initialValue!).length)),
    focusNode: focusNode,
    placeholder: placeholder,
    onChanged: onChanged,
    disabled: disabled,
    invalid: invalid,
    semanticLabel: semanticLabel,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    autofillHints: const [AutofillHints.oneTimeCode],
    inputFormatters: [PInputOtpFormatter(length: length)],
    tabularFigures: true,
  );
}

/// 다시 받기 — Button neutralWeak medium(40), 칸 아래 왼쪽(Field 꼬리 ↔ 단추 12). 보내기 전에는 [firstLabel]("코드 받기"),
/// 보낸 뒤 [cooldownSeconds] 안이면 [cooldownLabel]("다시 받기(52초)") + 막힘(Button 의 전용 색 — 흐리게 하지 않는다),
/// 지나면 [readyLabel]("다시 받기"). 남은 초는 단추가 1초마다 스스로 센다. 누르면 [onResend] 를 부르고 초점을 코드 칸으로 옮긴다 —
/// 막히는 단추에 초점이 남아 빠지지 않게. [onResend] 가 Future 를 돌려주면 끝날 때까지 다시 누를 수 없다(Button).
/// 남은 초는 단추 이름에 들어 있어 초점이 오면 읽힌다 — 1초마다 알리지 않는다.
class PInputOtpResend extends StatefulWidget {
  const PInputOtpResend({
    super.key,
    required this.sentAt,
    required this.onResend,
    required this.firstLabel,
    required this.readyLabel,
    required this.cooldownLabel,
    this.cooldownSeconds = 60,
    this.codeFocusNode,
    this.disabled = false,
    @visibleForTesting this.now,
  });

  /// 마지막으로 보낸 때 — 아직 안 보냈으면 null.
  final DateTime? sentAt;

  /// 코드를 보낸다 — Future 를 돌려주면 끝날 때까지 다시 누를 수 없다.
  final FutureOr<void> Function() onResend;

  /// "코드 받기"
  final String firstLabel;

  /// "다시 받기"
  final String readyLabel;

  /// "다시 받기(52초)" — 괄호는 앞 글자에 붙인다.
  final String Function(int seconds) cooldownLabel;

  /// 다시 받을 수 있을 때까지(초) — 기본 60(서버의 다시 받기 60초).
  final int cooldownSeconds;

  /// 보낸 뒤 초점을 옮길 코드 칸의 초점.
  final FocusNode? codeFocusNode;
  final bool disabled;

  /// 지금 — 테스트가 시계를 바꿔 끼운다.
  final DateTime Function()? now;

  @override
  State<PInputOtpResend> createState() => _PInputOtpResendState();
}

class _PInputOtpResendState extends State<PInputOtpResend> {
  late DateTime _now = _clock();
  Timer? _timer;

  DateTime _clock() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(PInputOtpResend old) {
    super.didUpdateWidget(old);
    if (old.sentAt != widget.sentAt ||
        old.cooldownSeconds != widget.cooldownSeconds) {
      _now = _clock();
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 1초마다 — 남은 초가 바뀌는 때에 맞춰 다시 잰다. 다 지나면 멈춘다.
  void _schedule() {
    _timer?.cancel();
    final sentAt = widget.sentAt;
    if (sentAt == null) return;
    final left = sentAt
        .add(Duration(seconds: widget.cooldownSeconds))
        .difference(_now);
    if (left <= Duration.zero) return;
    final ms = left.inMilliseconds % 1000;
    _timer = Timer(Duration(milliseconds: ms == 0 ? 1000 : ms), () {
      if (!mounted) return;
      setState(() => _now = _clock());
      _schedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = otpRemainingOf(
      widget.sentAt,
      widget.cooldownSeconds,
      _now,
    );
    final label = widget.sentAt == null
        ? widget.firstLabel
        : remaining > 0
        ? widget.cooldownLabel(remaining)
        : widget.readyLabel;
    final blocked = widget.disabled || remaining > 0;
    return Padding(
      padding: const EdgeInsets.only(top: PSpacing.x3),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: PButton(
          label: label,
          variant: PButtonVariant.neutralWeak,
          size: PButtonSize.medium,
          onPressed: blocked
              ? null
              : () {
                  final result = widget.onResend();
                  // 단추가 막히기 전에 초점을 코드 칸으로 — 막힌 단추에서 초점이 본문으로 빠지지 않게
                  widget.codeFocusNode?.requestFocus();
                  return result;
                },
        ),
      ),
    );
  }
}
