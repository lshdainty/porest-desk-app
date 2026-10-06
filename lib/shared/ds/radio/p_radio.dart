import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/checkbox/selection_control.dart';

/// 크기 — 동그라미 · 점 · 라벨 · 줄 높이가 함께 정해진다(Checkbox 와 같은 크기 — 한 폼에 함께 서도 줄이 맞는다).
/// medium 20(점 8 · 라벨 14 · 줄 32, 기본) · large 24(점 10 · 라벨 16 · 줄 36).
enum PRadioSize { medium, large }

/// 톤 — 선택했을 때의 색. neutral(짙은 회색, 기본) · brand(서비스 핵심 흐름에서만). 한 묶음 안에서 섞지 않는다.
enum PRadioTone { neutral, brand }

/// 라벨 굵기 — regular 400(기본) · bold 700(강조).
enum PRadioWeight { regular, bold }

/// 크기마다의 값(radio-group.yaml 크기).
class _SizeSpec {
  const _SizeSpec({
    required this.mark,
    required this.dot,
    required this.minHeight,
    required this.text,
  });

  final double mark;
  final double dot;
  final double minHeight;
  final TextStyle text;
}

const Map<PRadioSize, _SizeSpec> _sizes = {
  PRadioSize.medium: _SizeSpec(
    mark: 20,
    dot: 8,
    minHeight: 32,
    text: PTypography.t4,
  ),
  PRadioSize.large: _SizeSpec(
    mark: 24,
    dot: 10,
    minHeight: 36,
    text: PTypography.t5,
  ),
};

/// 톤 · 선택 여부 · 상태의 모습(radio-group.yaml 의 선택 안 됨 · 선택 규칙). 상태는 enabled · pressed · disabled —
/// 웹의 hovered(누름 색과 같다) · focused(링)는 앱에 없다.
({SelectionColors colors, double borderWidth}) _look(
  PColors c, {
  required PRadioTone tone,
  required bool checked,
  required bool enabled,
  required bool pressed,
}) {
  const clear = Color(0x00000000);
  // 테두리 색은 선택해도 그대로 두고 두께만 0 — 풀면 선이 바로 선다
  final border = enabled ? c.strokeNeutralSolid : c.strokeNeutralWeak;
  if (!checked) {
    return (
      colors: (
        background: !enabled
            ? c.bgDisabled
            : pressed
            ? c.bgLayerDefaultPressed
            : clear,
        border: border,
        // 점은 자리에 있고 색만 투명하다 — 채움과 함께 색으로 나타난다
        foreground: clear,
      ),
      borderWidth: 1,
    );
  }
  final neutral = tone == PRadioTone.neutral;
  final (Color fill, Color fillPressed, Color dot) = neutral
      ? (c.bgNeutralInverted, c.bgNeutralInvertedPressed, c.fgNeutralInverted)
      : (c.bgBrandSolid, c.bgBrandSolidPressed, c.staticWhite);
  return (
    colors: (
      // 막혀도 채운 원 그대로 색만(Checkbox 와 같다)
      background: !enabled
          ? c.bgDisabled
          : pressed
          ? fillPressed
          : fill,
      border: border,
      foreground: enabled ? dot : c.fgDisabled,
    ),
    borderWidth: 0,
  );
}

/// 동그라미(Radiomark)만 — 그림뿐이다. 누르기 · 이름 · 상태 읽기는 감싸는 줄이 맡는다(라벨이 따로 서는 줄 — 줄
/// 전체가 누르는 영역이다). 줄이 눌린 동안 [pressed] 를 주면 동그라미가 누름 색 · 축소로 반응한다(웹 group/radio).
///
/// 선택 안 됨은 테두리 원, 선택은 테두리 없이 채운 원 + 가운데 점. 채움 · 테두리 · 점이 150ms 로 함께 바뀌고 점은
/// 커지거나 줄지 않는다. 비활성은 전용 색이고 흐리게 하지 않는다.
class PRadiomark extends StatelessWidget {
  const PRadiomark({
    super.key,
    required this.checked,
    this.size = PRadioSize.medium,
    this.tone = PRadioTone.neutral,
    this.enabled = true,
    this.pressed = false,
  });

  final bool checked;
  final PRadioSize size;
  final PRadioTone tone;
  final bool enabled;

  /// 감싸는 줄이 눌린 동안 — 비활성이면 무시한다.
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final s = _sizes[size]!;
    final pressedNow = enabled && pressed;
    final look = _look(
      context.colors,
      tone: tone,
      checked: checked,
      enabled: enabled,
      pressed: pressedNow,
    );
    final round = BorderRadius.circular(PRounded.full);
    return SelectionPressScale(
      pressed: pressedNow,
      size: Size.square(s.mark),
      child: TweenAnimationBuilder<SelectionColors>(
        tween: SelectionColorsTween(end: look.colors),
        duration: PDuration.colorTransition,
        curve: PEasing.easing,
        builder: (context, colors, _) => SizedBox.square(
          dimension: s.mark,
          child: DecoratedBox(
            key: const ValueKey('radiomark-ring'),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: round,
              border: look.borderWidth > 0
                  ? Border.all(color: colors.border, width: look.borderWidth)
                  : null,
            ),
            child: Center(
              child: SizedBox.square(
                dimension: s.dot,
                child: DecoratedBox(
                  key: const ValueKey('radiomark-dot'),
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
    );
  }
}

/// Radio Group — 여러 옵션 가운데 하나만 고르게 한다. 구조는 SEED Radio(2026-09-30), 수치 원본은 porest-design
/// `specs/components/radio-group.yaml`(값은 `test/fixtures/design_spec/radio-group.json` — 테스트가 위젯이 그 값과
/// 같은지 본다). 웹(desk-front `src/shared/ds/radio-group`)과 같은 값이다. 옛 위젯(lib/shared/widgets/p_radio.dart ·
/// p_radio_list.dart)과는 이름이 다르다.
///
///   [PRadioGroup] — 묶음. 세로로만 쌓고 줄 사이 12, 값을 쥔다
///   [PRadio] — 동그라미 + 라벨. 묶음 안에서만 쓴다
///   [PRadiomark] — 동그라미만(그림). 라벨이 따로 서는 줄이 누르기를 맡을 때
///
/// 하나를 고르면 앞에 고른 것은 풀린다. 이미 고른 것을 다시 눌러도 풀리지 않는다([onChanged] 를 부르지 않는다).
/// 선택지는 둘에서 다섯 — 여섯 이상이면 Select, 설명 · 딸린 입력이 붙으면 Select Box, 가로로 짧게 고르면
/// Segmented · Chip 이다. 오류는 동그라미를 바꾸지 않고 묶음 아래 글로 알린다 — 제목 · 오류 글은 묶음을 Field 로
/// 감싸 붙인다(field.md).
///
/// 키보드 — 묶음에 들어오면 고른 선택지(없으면 첫 선택지)로 간다. 화살표로 이전 · 다음 선택지로 옮기며 고르고(막힌
/// 선택지는 건너뛰고 끝에서 돈다), Space 로 포커스된 선택지를 고른다. Enter 는 고르지 않는다(폼 제출에 둔다).
/// Flutter 의 RadioGroup 이 맡는다 — 웹 Radix 와 같은 APG 동작이다.
/// 읽기 — 묶음은 radio group 이고 [semanticLabel] 이 이름이다. 선택지는 라벨 · 선택 여부를 읽는다.
class PRadioGroup<T> extends StatelessWidget {
  const PRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.semanticLabel,
  });

  /// 고른 값 — 없으면 아무것도 고르지 않았다. 골라 둘 수 있으면 처음부터 하나를 골라 둔다.
  final T? value;

  /// 다른 선택지를 고르면 그 값. 없으면 묶음 전체가 비활성 — 고른 선택지는 채운 원 그대로 색만 바뀐다.
  final ValueChanged<T>? onChanged;

  /// 선택지 — [PRadio] 들(같은 값 타입).
  final List<Widget> children;

  /// 묶음의 이름(웹 aria-label) — 무엇을 고르는지.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return _PRadioGroupScope(
      enabled: onChanged != null,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (next) {
          if (onChanged == null || next == null || next == value) return;
          onChanged(next);
        },
        // 이름은 RadioGroup 의 묶음 노드에 붙는다(그 안의 선택지는 저마다 노드다)
        child: Semantics(
          label: semanticLabel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x3,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// 묶음이 막혔는지 — [PRadio] 가 읽는다.
class _PRadioGroupScope extends InheritedWidget {
  const _PRadioGroupScope({required this.enabled, required super.child});

  final bool enabled;

  static bool enabledOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PRadioGroupScope>()
          ?.enabled ??
      true;

  @override
  bool updateShouldNotify(_PRadioGroupScope oldWidget) =>
      enabled != oldWidget.enabled;
}

/// Radio 한 줄 — 동그라미 + 라벨. [PRadioGroup] 안에서만 쓴다(같은 값 타입). 동그라미 · 라벨 어디를 눌러도 고른다.
///
/// 상태 — 누르면 동그라미만 누름 색 + 세로 2px 거리 축소(라벨은 줄지 않는다, 모션 줄이기면 축소 없이 색만).
///   [enabled] 가 false 면(또는 묶음이 막히면) 비활성 — 전용 색이고 흐리게 하지 않는다. 골라 둔 채로 막을 수 있다.
///   올림(hovered) · 포커스 링(focused)은 웹 상태라 앱에는 없다 — 키보드 포커스는 받고 링은 그리지 않는다.
/// 누르는 영역은 라벨까지 묶어 44 × 44 까지 넓힌다 — 놓인 자리는 그대로다. 줄은 동그라미 + 라벨만큼만 차지한다.
/// 라벨은 하나뿐이다(길면 줄이 바뀐다) — 설명 줄 · 딸린 입력이 필요하면 Select Box 다.
class PRadio<T> extends StatefulWidget {
  const PRadio({
    super.key,
    required this.value,
    required this.label,
    this.size = PRadioSize.medium,
    this.tone = PRadioTone.neutral,
    this.weight = PRadioWeight.regular,
    this.enabled = true,
    this.focusNode,
  });

  /// 이 선택지의 값 — 묶음의 값과 같으면 선택이다.
  final T value;

  /// 무엇을 고르는지 — 동그라미와 함께 눌리고, 이 선택지의 이름으로 읽힌다.
  final String label;
  final PRadioSize size;
  final PRadioTone tone;
  final PRadioWeight weight;

  /// false 면 이 선택지만 막힌다.
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<PRadio<T>> createState() => _PRadioState<T>();
}

class _PRadioState<T> extends State<PRadio<T>> with RadioClient<T> {
  FocusNode? _ownFocusNode;
  bool _groupEnabled = true;

  @override
  FocusNode get focusNode =>
      widget.focusNode ??
      (_ownFocusNode ??= FocusNode(debugLabel: 'PRadio ${widget.label}'));

  @override
  T get radioValue => widget.value;

  @override
  bool get tristate => false;

  // 화살표가 건너뛸 선택지 — 이 선택지 또는 묶음이 막혔다
  @override
  bool get enabled => widget.enabled && _groupEnabled && registry != null;

  bool get _selected =>
      registry != null && registry!.groupValue == widget.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registry = RadioGroup.maybeOf<T>(context);
    _groupEnabled = _PRadioGroupScope.enabledOf(context);
  }

  @override
  void dispose() {
    registry = null;
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _select() {
    // 이미 고른 것을 다시 눌러도 풀리지 않는다
    if (_selected) return;
    registry?.onChanged(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      registry != null,
      'PRadio 는 같은 값 타입(T)의 PRadioGroup 안에서만 쓴다 — PRadio<$T>',
    );
    final c = context.colors;
    final s = _sizes[widget.size]!;
    final enabled = this.enabled;
    final selected = _selected;
    // iOS 의 VoiceOver 는 선택을 selected 로 읽는다 — 고르지 않은 선택지는 "선택되지 않음" 을 덧붙인다(RawRadio 와 같다)
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    return SelectionControl(
      label: widget.label,
      labelStyle: s.text.copyWith(
        color: enabled ? c.fgNeutral : c.fgDisabled,
        fontWeight: widget.weight == PRadioWeight.bold
            ? FontWeight.w700
            : FontWeight.w400,
      ),
      gap: PSpacing.x2,
      minHeight: s.minHeight,
      onActivate: enabled ? _select : null,
      focusNode: focusNode,
      semantics: SelectionSemantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        selected: apple ? selected : null,
        hint: apple && !selected
            ? WidgetsLocalizations.of(context).radioButtonUnselectedLabel
            : null,
      ),
      markBuilder: (pressed) => PRadiomark(
        checked: selected,
        size: widget.size,
        tone: widget.tone,
        enabled: enabled,
        pressed: pressed,
      ),
    );
  }
}
