import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/checkbox/selection_control.dart';

/// 크기 — 이름은 트랙 높이다(SEED). s16(트랙 26 × 16 · 라벨 13 — 촘촘한 자리) · s24(38 × 24 · 라벨 14, 기본) ·
/// s32(52 × 32 · 라벨 16 — 제목이 큰 줄, 모바일에서 홀로 서는 스위치).
enum PSwitchSize { s16, s24, s32 }

/// 톤 — 켰을 때의 색. neutral(짙은 회색, 기본) · brand(서비스 핵심 흐름에서만).
enum PSwitchTone { neutral, brand }

/// 크기마다의 값(switch.yaml 크기).
class _SizeSpec {
  const _SizeSpec({
    required this.width,
    required this.height,
    required this.padding,
    required this.thumb,
    required this.minHeight,
    required this.gap,
    required this.text,
  });

  final double width;
  final double height;

  /// 트랙 안쪽 여백 — 엄지와 트랙 가장자리 사이.
  final double padding;
  final double thumb;
  final double minHeight;
  final double gap;
  final TextStyle text;

  /// 켜면 엄지가 가는 거리 — 트랙 폭 − 트랙 높이.
  double get travel => width - height;
}

const Map<PSwitchSize, _SizeSpec> _sizes = {
  PSwitchSize.s16: _SizeSpec(
    width: 26,
    height: 16,
    padding: PSpacing.x0_5,
    thumb: 12,
    // 트랙(16)보다 크다 — 누르는 영역의 바닥(SEED)
    minHeight: 24,
    gap: PSpacing.x1_5,
    text: PTypography.t3,
  ),
  PSwitchSize.s24: _SizeSpec(
    width: 38,
    height: 24,
    padding: PSpacing.x0_5,
    thumb: 20,
    minHeight: 24,
    gap: PSpacing.x2,
    text: PTypography.t4,
  ),
  PSwitchSize.s32: _SizeSpec(
    width: 52,
    height: 32,
    padding: 3, // 토큰 없음 — switch.yaml 이 3px 로 적는다
    thumb: 26,
    minHeight: 32,
    gap: PSpacing.x2_5,
    text: PTypography.t5,
  ),
};

/// 끈 엄지의 크기 — 켜면 1. 색 말고도 자리 · 크기로 켬 · 끔이 갈린다(SEED).
const double _offThumbScale = 0.8;

/// 색 전환이 엄지보다 늦게 시작하는 시간 — 엄지가 움직이기 시작한 뒤에 색이 바뀐다(switch.yaml transitionDelay,
/// 토큰 없음).
const Duration _colorDelay = Duration(milliseconds: 20);

/// 톤 · 켬 · 상태의 모습(switch.yaml 의 끔 · 켬 · 톤 규칙). 누름은 색을 바꾸지 않는다 — 켜짐 색이 상태를 뜻해서다.
/// 바탕은 트랙, 안의 것은 엄지 색이다.
({SelectionColors colors, double borderWidth}) _look(
  PColors c, {
  required PSwitchTone tone,
  required bool checked,
  required bool enabled,
}) {
  final neutral = tone == PSwitchTone.neutral;
  final thumb = neutral ? c.fgNeutralInverted : c.staticWhite;
  // 막힌 끔의 안쪽 선 — 다른 때는 두께 0 이라 그리지 않는다
  final border = c.strokeNeutralWeak;
  if (!checked) {
    return enabled
        ? (
            colors: (
              background: c.strokeNeutralSolid,
              border: border,
              foreground: thumb,
            ),
            borderWidth: 0,
          )
        : (
            colors: (
              background: c.bgDisabled,
              border: border,
              foreground: c.fgDisabled,
            ),
            borderWidth: 1,
          );
  }
  // 막혀도 켜진 모양 그대로 색만 — 채운 트랙 + 밝은 엄지
  return (
    colors: enabled
        ? (
            background: neutral ? c.bgNeutralInverted : c.bgBrandSolid,
            border: border,
            foreground: thumb,
          )
        : (background: c.fgDisabled, border: border, foreground: c.bgDisabled),
    borderWidth: 0,
  );
}

/// 스위치(Switchmark)만 — 트랙과 엄지, 그림뿐이다. 누르기 · 이름 · 상태 읽기는 감싸는 줄이 맡는다(설정 줄 — 줄
/// 전체가 누르는 영역이고 줄의 제목이 스위치의 이름이다). 줄 전체가 눌리며 줄어드는 자리(List 의 스위치 줄)에서는
/// [pressed] 를 주지 않는다 — 이미 줄어드는 요소 안의 요소는 따로 줄지 않는다(Feedback v104).
///
/// 켜면 엄지가 트랙 폭 − 트랙 높이만큼 옆으로 가며 0.8 → 1 로 커진다(150ms). 트랙 · 엄지 색은 그 20ms 뒤에 50ms 로
/// 바뀐다. 누름은 색을 바꾸지 않고 스위치만 세로 2px 거리 줄인다. 막힌 끔의 안쪽 선은 트랙 크기를 바꾸지 않는다.
class PSwitchmark extends StatelessWidget {
  const PSwitchmark({
    super.key,
    required this.checked,
    this.size = PSwitchSize.s24,
    this.tone = PSwitchTone.neutral,
    this.enabled = true,
    this.pressed = false,
  });

  final bool checked;
  final PSwitchSize size;
  final PSwitchTone tone;
  final bool enabled;

  /// 감싸는 줄이 눌린 동안 — 비활성이면 무시한다.
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final s = _sizes[size]!;
    final look = _look(
      context.colors,
      tone: tone,
      checked: checked,
      enabled: enabled,
    );
    final round = BorderRadius.circular(PRounded.full);
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final colorDuration = PDuration.d1 + _colorDelay;
    return SelectionPressScale(
      pressed: enabled && pressed,
      size: Size(s.width, s.height),
      child: TweenAnimationBuilder<SelectionColors>(
        tween: SelectionColorsTween(end: look.colors),
        duration: colorDuration,
        curve: Interval(
          _colorDelay.inMicroseconds / colorDuration.inMicroseconds,
          1,
          curve: PEasing.easing,
        ),
        builder: (context, colors, _) => SizedBox(
          width: s.width,
          height: s.height,
          child: DecoratedBox(
            key: const ValueKey('switchmark-track'),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: round,
              // 안쪽 선 — DecoratedBox 는 테두리를 안쪽에 그리고 자리를 바꾸지 않는다(웹 inset-ring)
              border: look.borderWidth > 0
                  ? Border.all(color: colors.border, width: look.borderWidth)
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(s.padding),
              // 엄지 — 자리 · 크기는 150ms(색보다 먼저)
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: checked ? 1 : 0),
                duration: PDuration.d3,
                curve: PEasing.easing,
                builder: (context, t, _) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Transform.translate(
                    offset: Offset(direction * s.travel * t, 0),
                    child: Transform.scale(
                      scale: _offThumbScale + (1 - _offThumbScale) * t,
                      child: SizedBox.square(
                        dimension: s.thumb,
                        child: DecoratedBox(
                          key: const ValueKey('switchmark-thumb'),
                          decoration: BoxDecoration(
                            color: colors.foreground,
                            borderRadius: round,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Switch — 설정 · 상태를 바로 켜고 끈다(스위치 + 라벨). 구조는 SEED Switch(2026-09-30), 수치 원본은 porest-design
/// `specs/components/switch.yaml`(값은 `test/fixtures/design_spec/switch.json` — 테스트가 위젯이 그 값과 같은지
/// 본다). 웹(desk-front `src/shared/ds/switch`)과 같은 값이다. 옛 위젯(lib/shared/widgets/p_switch.dart)과 이름이
/// 같다 — 자리로 가른다.
///
///   [PSwitch] — 스위치 왼쪽 · 라벨 오른쪽. 스위치 · 라벨 어디를 눌러도 바뀐다
///   [PSwitchmark] — 스위치만(그림). 설정 줄이 누르기를 맡을 때(List 의 스위치 줄)
///
/// 누르는 순간 적용되는 설정에만 쓴다 — 저장해야 적용되면 Checkbox 다. 누르면 바로 바뀐다([onChanged] 가 다음 값을
/// 받는다 — 값은 쓰는 쪽이 쥔다). 서버 응답을 기다리지 않고, 저장에 실패하면 되돌리고 무엇이 안 됐는지 알린다.
/// 상태 — 누르면 색은 그대로, 스위치만 세로 2px 거리 축소(모션 줄이기면 축소만 빠진다 — 엄지 이동 · 색 전환은 그대로).
///   [onChanged] 가 없으면 비활성 — 켜진 채 막히면 켜진 모양 그대로 회색, 꺼진 채 막히면 옅은 트랙 + 안쪽 선 + 회색
///   엄지. 라벨도 비활성 색이다(막힌 켬은 꺼진 트랙과 비슷한 회색이라 라벨이 막힘을 알린다).
///   올림(hovered — 색이 바뀌지 않는다) · 포커스 링(focused)은 웹 상태라 앱에는 없다 — 키보드 포커스는 받고(Space ·
///   Enter 로 누른다) 링은 그리지 않는다.
/// 누르는 영역은 라벨까지 묶어 44 × 44 까지 넓힌다 — 놓인 자리는 그대로다. 줄은 스위치 + 라벨만큼만 차지한다.
/// 읽기 — 라벨이 이름이고 켬 · 끔(toggled)을 읽는다.
class PSwitch extends StatelessWidget {
  const PSwitch({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.size = PSwitchSize.s24,
    this.tone = PSwitchTone.neutral,
    this.focusNode,
  });

  /// 무엇을 켜고 끄는지 — 스위치와 함께 눌리고, 이 스위치의 이름으로 읽힌다.
  final String label;
  final bool checked;

  /// 누르면 다음 값(!checked). 없으면 비활성.
  final ValueChanged<bool>? onChanged;
  final PSwitchSize size;
  final PSwitchTone tone;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _sizes[size]!;
    final onChanged = this.onChanged;
    final enabled = onChanged != null;
    return SelectionControl(
      label: label,
      // 라벨 굵기는 크기와 상관없이 500
      labelStyle: s.text.copyWith(
        color: enabled ? c.fgNeutral : c.fgDisabled,
        fontWeight: FontWeight.w500,
      ),
      gap: s.gap,
      minHeight: s.minHeight,
      onActivate: enabled ? () => onChanged(!checked) : null,
      activateOnEnter: true,
      focusNode: focusNode,
      semantics: SelectionSemantics(toggled: checked),
      markBuilder: (pressed) => PSwitchmark(
        checked: checked,
        size: size,
        tone: tone,
        enabled: enabled,
        pressed: pressed,
      ),
    );
  }
}
