import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

// 선택 컨트롤 셋(카탈로그 "5 선택 컨트롤" — Checkbox · Radio · Switch)이 함께 쓰는 부품. 셋은 줄 · 누르는 영역 ·
// 누름 축소 · 색 전환이 같은 규칙이다(radio-group.yaml · switch.yaml 이 "Checkbox 와 같게" 라고 적는다).
// 화면에서 직접 쓰지 않는다 — PCheckbox · PRadio · PSwitch 와 그 표시(PCheckmark · PRadiomark · PSwitchmark)가 쓴다.

/// 표시(칸 · 동그라미 · 스위치)의 세 색 — 바탕 · 테두리 · 안의 것(체크 · 점 · 엄지). 함께 전환된다.
typedef SelectionColors = ({Color background, Color border, Color foreground});

/// [SelectionColors] 사이 — 미리 곱한 알파로 섞는다(CSS 전환과 같다). 투명에서 나타나는 색이 투명한 검정을 거쳐
/// 어두워졌다 밝아지지 않는다(다크의 밝은 채움 · 흰 점).
///
/// 목표 색([end])은 8비트로 맞춰 둔다. MaterialApp 은 ThemeData 가 바뀌면 200ms 동안 두 테마를 섞는데(AnimatedTheme —
/// 라이트 ↔ 다크를 바꿀 때), 섞인 역할 색에는 부동소수 찌꺼기가 끼어 목표가 프레임마다 "바뀌고" 전환이 매 프레임
/// 처음부터 다시 시작돼 멈춰 보인다. 스펙 색은 모두 8비트라 맞춰도 값은 그대로다. (`PorestTheme.light()` 는 늘 같은
/// 테마를 돌려주므로 같은 테마끼리 섞는 일은 없다.)
class SelectionColorsTween extends Tween<SelectionColors> {
  SelectionColorsTween({SelectionColors? end})
    : super(
        end: end == null
            ? null
            : (
                background: _snap(end.background),
                border: _snap(end.border),
                foreground: _snap(end.foreground),
              ),
      );

  static Color _snap(Color color) => Color(color.toARGB32());

  @override
  SelectionColors lerp(double t) {
    final a = begin!;
    final b = end!;
    return (
      background: _lerpPremultiplied(a.background, b.background, t),
      border: _lerpPremultiplied(a.border, b.border, t),
      foreground: _lerpPremultiplied(a.foreground, b.foreground, t),
    );
  }
}

Color _lerpPremultiplied(Color a, Color b, double t) {
  final alpha = (a.a + (b.a - a.a) * t).clamp(0.0, 1.0);
  if (alpha <= 0) return b.withValues(alpha: 0);
  double channel(double from, double to) =>
      ((from * a.a + (to * b.a - from * a.a) * t) / alpha).clamp(0.0, 1.0);
  return Color.from(
    alpha: alpha,
    red: channel(a.r, b.r),
    green: channel(a.g, b.g),
    blue: channel(a.b, b.b),
  );
}

/// 누름 축소 — 표시만 세로 2px 거리 줄인다(Feedback 의 눌림 피드백, v104). 가운데를 기준으로 줄고 놓인 자리는
/// 그대로다. 모션 줄이기면 줄지 않는다 — 색 전환만 남는다.
class SelectionPressScale extends StatelessWidget {
  const SelectionPressScale({
    super.key,
    required this.pressed,
    required this.size,
    required this.child,
  });

  final bool pressed;

  /// 표시의 크기 — 배율의 기준 길이를 여기서 잰다.
  final Size size;
  final Widget child;

  /// 눌린 배율 = (기준 − 2) ÷ 기준, 기준 = max(높이, 폭 ÷ 4, 24) — 칸 · 동그라미는 24, 스위치 32 는 32.
  static double scaleOf(Size size) {
    final basis = math.max(size.height, math.max(size.width / 4, 24.0));
    return (basis - 2) / basis;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedScale(
      scale: pressed && !reduceMotion ? scaleOf(size) : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: child,
    );
  }
}

/// 줄이 읽히는 모습 — Checkbox 는 checked · mixed, Radio 는 checked + 묶음, Switch 는 toggled.
@immutable
class SelectionSemantics {
  const SelectionSemantics({
    this.checked,
    this.mixed,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.selected,
    this.hint,
  });

  final bool? checked;
  final bool? mixed;
  final bool? toggled;
  final bool inMutuallyExclusiveGroup;

  /// iOS 의 Radio — VoiceOver 는 선택을 selected 로 읽는다(Flutter RawRadio 와 같다).
  final bool? selected;
  final String? hint;
}

/// 선택 컨트롤 한 줄 — 표시 + 라벨. Checkbox · Radio · Switch 가 함께 쓴다.
///
///   누르기 — 표시 · 라벨 어디를 눌러도 [onActivate]. 누르는 동안 표시가 누름 모습이다([markBuilder] 의 pressed).
///   누르는 영역 — 줄과 따로 44 × 44 까지 넓힌다. 놓인 자리는 그대로이고, 부모 상자 안에서만 받는다(Flutter 는
///     부모 안에서만 자식에게 묻는다). 묶음은 줄 사이 12 라 이웃 줄과 겹치지 않는다.
///   맞춤 — 줄은 표시 + 라벨만큼만 차지한다(웹 align-self: flex-start). 부모가 폭을 정해 줘도 앞에 붙고, 나머지
///     자리는 누르지 않는다.
///   라벨 — 길면 낱말 단위로 줄을 바꾼다(DESIGN v114). 표시는 줄 가운데에 선다. 라벨이 이 줄의 이름으로 읽힌다.
///   키보드 — 포커스를 받고 Space 로 누른다(Switch 는 Enter 도 — [activateOnEnter]). 포커스 링은 웹 상태라
///     그리지 않는다.
///   [onActivate] 가 없으면 비활성 — 누르기 · 키보드 · 포커스에서 빠진다.
class SelectionControl extends StatefulWidget {
  const SelectionControl({
    super.key,
    required this.markBuilder,
    required this.label,
    required this.labelStyle,
    required this.gap,
    required this.minHeight,
    required this.onActivate,
    required this.semantics,
    this.activateOnEnter = false,
    this.focusNode,
  });

  /// 표시 — pressed 는 줄이 눌린 동안 true 다(비활성이면 늘 false).
  final Widget Function(bool pressed) markBuilder;
  final String label;

  /// 글자 · 굵기 · 색까지 정한 라벨 모습.
  final TextStyle labelStyle;

  /// 표시 ↔ 라벨.
  final double gap;
  final double minHeight;

  /// 없으면 비활성.
  final VoidCallback? onActivate;
  final SelectionSemantics semantics;

  /// Enter 로도 누른다 — Switch. Checkbox · Radio 의 Enter 는 폼 제출에 둔다(누르지 않고 위로 보낸다).
  final bool activateOnEnter;
  final FocusNode? focusNode;

  @override
  State<SelectionControl> createState() => _SelectionControlState();
}

class _ActivateSelectionIntent extends Intent {
  const _ActivateSelectionIntent();
}

class _SelectionControlState extends State<SelectionControl> {
  static const Map<ShortcutActivator, Intent> _spaceOnly = {
    SingleActivator(LogicalKeyboardKey.space): _ActivateSelectionIntent(),
  };
  static const Map<ShortcutActivator, Intent> _spaceOrEnter = {
    SingleActivator(LogicalKeyboardKey.space): _ActivateSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.enter): _ActivateSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): _ActivateSelectionIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = {
    _ActivateSelectionIntent: CallbackAction<_ActivateSelectionIntent>(
      onInvoke: (_) {
        _activate();
        return null;
      },
    ),
  };

  bool _pressed = false;

  bool get _enabled => widget.onActivate != null;

  @override
  void didUpdateWidget(SelectionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 사이 막히면 누름이 남지 않게
    if (!_enabled) _pressed = false;
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() => widget.onActivate?.call();

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final s = widget.semantics;
    // 누르는 영역(44)을 맡는 상자가 가장 바깥이다 — 안쪽 상자는 제 크기 밖에서 누른 것을 받지 않는다
    return _SelectionTarget(
      child: Semantics(
        container: true,
        enabled: enabled,
        checked: s.checked,
        mixed: s.mixed,
        toggled: s.toggled,
        selected: s.selected,
        inMutuallyExclusiveGroup: s.inMutuallyExclusiveGroup ? true : null,
        hint: s.hint,
        onTap: enabled ? _activate : null,
        // 막혀도 짜임은 그대로 둔다 — 바뀌면 그 아래가 새로 만들어져 색 전환이 끊긴다
        child: Shortcuts(
          shortcuts: widget.activateOnEnter ? _spaceOrEnter : _spaceOnly,
          child: Actions(
            actions: _actions,
            child: Focus(
              focusNode: widget.focusNode,
              canRequestFocus: enabled,
              child: MouseRegion(
                // 웹 cursor pointer · not-allowed
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.forbidden,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTapDown: enabled ? (_) => _setPressed(true) : null,
                  onTapUp: enabled ? (_) => _setPressed(false) : null,
                  onTapCancel: enabled ? () => _setPressed(false) : null,
                  onTap: enabled ? _activate : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: widget.minHeight),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: widget.gap,
                      children: [
                        widget.markBuilder(enabled && _pressed),
                        Flexible(
                          child: Text(
                            keepAll(widget.label),
                            semanticsLabel: widget.label,
                            style: widget.labelStyle,
                          ),
                        ),
                      ],
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

/// 줄을 앞(가로) · 가운데(세로)에 두고 내용만큼만 받는다 — 그리고 누르는 영역을 줄과 따로 [PTouch.min] 까지 넓힌다.
///
/// 넓힌 자리에서 누르면 줄 가운데를 누른 것으로 친다(Button 의 누르는 영역과 같은 방법). 이 상자가 부모가 준 폭을
/// 다 차지해도(묶음 폭으로 늘인 자리) 줄 밖은 받지 않는다.
class _SelectionTarget extends SingleChildRenderObjectWidget {
  const _SelectionTarget({required Widget super.child});

  @override
  _RenderSelectionTarget createRenderObject(BuildContext context) =>
      _RenderSelectionTarget(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSelectionTarget renderObject,
  ) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class _RenderSelectionTarget extends RenderShiftedBox {
  _RenderSelectionTarget(this._textDirection) : super(null);

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Offset _childOffset(Size size, Size childSize) => Offset(
    _textDirection == TextDirection.ltr ? 0 : size.width - childSize.width,
    (size.height - childSize.height) / 2,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(child!.getDryLayout(constraints.loosen()));

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final childConstraints = constraints.loosen();
    final result = child!.getDryBaseline(childConstraints, baseline);
    if (result == null) return null;
    final childSize = child!.getDryLayout(childConstraints);
    return result +
        _childOffset(constraints.constrain(childSize), childSize).dy;
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(child.size);
    (child.parentData! as BoxParentData).offset = _childOffset(
      size,
      child.size,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child!;
    final offset = (child.parentData! as BoxParentData).offset;
    final row = offset & child.size;
    final dx = math.max(0.0, (PTouch.min - row.width) / 2);
    final dy = math.max(0.0, (PTouch.min - row.height) / 2);
    final area = Rect.fromLTRB(
      row.left - dx,
      row.top - dy,
      row.right + dx,
      row.bottom + dy,
    );
    if (!area.contains(position)) return false;
    // 넓힌 자리에서 누르면 줄 가운데를 누른 것으로 친다
    final inside = row.contains(position) ? position : row.center;
    final hit = result.addWithPaintOffset(
      offset: offset,
      position: inside,
      hitTest: (result, local) => child.hitTest(result, position: local),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}
