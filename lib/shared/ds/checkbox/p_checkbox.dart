import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/checkbox/selection_control.dart';

/// 크기 — 칸 · 라벨 · 줄 높이가 함께 정해진다. medium 20(라벨 14 · 줄 32, 기본) · large 24(라벨 16 · 줄 36 — 한 화면의
/// 중심 선택, 모바일에서 홀로 서는 선택).
enum PCheckboxSize { medium, large }

/// 모양 — square(칸 + 체크, 기본 — 여러 개를 고르는 목록 · 알고 골라야 하는 선택) · ghost(칸 없이 체크만 — 선택 안
/// 됨도 옅은 체크. 필수가 아니고 셋 이하일 때).
enum PCheckboxShape { square, ghost }

/// 톤 — 선택했을 때의 색. neutral(짙은 회색, 기본) · brand(서비스 핵심 흐름에서만).
enum PCheckboxTone { neutral, brand }

/// 라벨 굵기 — regular 400(기본) · bold 700(강조 · 묶음의 부모).
enum PCheckboxWeight { regular, bold }

/// 크기마다의 값(checkbox.yaml 크기 · 크기 × 모양).
class _SizeSpec {
  const _SizeSpec({
    required this.mark,
    required this.minHeight,
    required this.text,
    required this.squareIcon,
    required this.ghostIcon,
  });

  final double mark;
  final double minHeight;
  final TextStyle text;

  /// 칸 안 아이콘 — Ghost 는 칸이 없어 아이콘이 크다.
  final double squareIcon;
  final double ghostIcon;
}

const Map<PCheckboxSize, _SizeSpec> _sizes = {
  PCheckboxSize.medium: _SizeSpec(
    mark: 20,
    minHeight: 32,
    text: PTypography.t4,
    squareIcon: 12,
    ghostIcon: 14,
  ),
  PCheckboxSize.large: _SizeSpec(
    mark: 24,
    minHeight: 36,
    text: PTypography.t5,
    squareIcon: 14,
    ghostIcon: 18,
  ),
};

/// 칸 안의 아이콘 — lucide `Check`(선택) · `Minus`(일부 선택), 선 3.
enum _Glyph { check, minus }

/// 모양 · 톤 · 체크 여부 · 상태의 모습(checkbox.yaml 의 Square · Ghost 규칙). 상태는 enabled · pressed · disabled —
/// 웹의 hovered(누름 색과 같다) · focused(링)는 앱에 없다.
({SelectionColors colors, double borderWidth, _Glyph? glyph}) _look(
  PColors c, {
  required PCheckboxShape shape,
  required PCheckboxTone tone,
  required bool? checked,
  required bool enabled,
  required bool pressed,
}) {
  const clear = Color(0x00000000);
  final on = checked != false; // 선택 · 일부 선택
  final glyph = checked == null ? _Glyph.minus : _Glyph.check;
  final neutral = tone == PCheckboxTone.neutral;

  if (shape == PCheckboxShape.ghost) {
    // 칸 없이 체크만 — 선택 안 됨도 옅은 체크(fg-placeholder). 누르면 바탕이 생긴다
    final onBackground = neutral ? c.bgNeutralWeak : c.bgBrandWeakPressed;
    return (
      colors: (
        background: enabled && pressed
            ? (on ? onBackground : c.bgLayerDefaultPressed)
            : clear,
        border: clear,
        foreground: !enabled
            ? c.fgDisabled
            : on
            ? (neutral ? c.fgNeutral : c.fgBrand)
            : c.fgPlaceholder,
      ),
      borderWidth: 0,
      glyph: glyph,
    );
  }

  final (Color fill, Color fillPressed, Color mark) = neutral
      ? (c.bgNeutralInverted, c.bgNeutralInvertedPressed, c.fgNeutralInverted)
      : (c.bgBrandSolid, c.bgBrandSolidPressed, c.staticWhite);
  // 테두리 색은 선택해도 그대로 두고 두께만 0 — 풀면 선이 바로 선다(웹은 border-width 를 전환하지 않는다)
  final border = enabled ? c.strokeNeutralSolid : c.strokeNeutralWeak;
  // 선택 안 된 칸의 체크 색은 보이지 않는다 — 선택되면 그 색으로 바로 선다
  final foreground = enabled ? mark : c.fgDisabled;
  if (!on) {
    return (
      colors: (
        background: !enabled
            ? c.bgDisabled
            : pressed
            ? c.bgLayerDefaultPressed
            : clear,
        border: border,
        foreground: foreground,
      ),
      borderWidth: 1,
      glyph: null,
    );
  }
  return (
    colors: (
      background: !enabled
          ? c.bgDisabled
          : pressed
          ? fillPressed
          : fill,
      border: border,
      foreground: foreground,
    ),
    borderWidth: 0,
    glyph: glyph,
  );
}

/// 칸(Checkmark)만 — 그림뿐이다. 누르기 · 이름 · 상태 읽기는 감싸는 줄이 맡는다(목록 행 · 표 머리 — 행 전체가
/// 누르는 영역이다). 줄이 눌린 동안 [pressed] 를 주면 칸이 누름 색 · 축소로 반응한다(웹 group/checkbox).
///
/// [checked] 가 null 이면 일부 선택(가로줄). 바탕 · 테두리 · 아이콘 색은 150ms 로 함께 바뀌고 아이콘은 커지거나
/// 줄지 않는다. 테두리는 안쪽 1px — 칸 크기가 변하지 않는다. 비활성은 전용 색이고 흐리게 하지 않는다.
class PCheckmark extends StatelessWidget {
  const PCheckmark({
    super.key,
    required this.checked,
    this.size = PCheckboxSize.medium,
    this.shape = PCheckboxShape.square,
    this.tone = PCheckboxTone.neutral,
    this.enabled = true,
    this.pressed = false,
  });

  /// true 선택 · false 선택 안 됨 · null 일부 선택.
  final bool? checked;
  final PCheckboxSize size;
  final PCheckboxShape shape;
  final PCheckboxTone tone;
  final bool enabled;

  /// 감싸는 줄이 눌린 동안 — 비활성이면 무시한다.
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final s = _sizes[size]!;
    final pressedNow = enabled && pressed;
    final look = _look(
      context.colors,
      shape: shape,
      tone: tone,
      checked: checked,
      enabled: enabled,
      pressed: pressedNow,
    );
    final icon = shape == PCheckboxShape.ghost ? s.ghostIcon : s.squareIcon;
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
            key: const ValueKey('checkmark-box'),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(PRounded.r1),
              border: look.borderWidth > 0
                  ? Border.all(color: colors.border, width: look.borderWidth)
                  : null,
            ),
            child: Center(
              child: CustomPaint(
                key: const ValueKey('checkmark-icon'),
                size: Size.square(icon),
                painter: _GlyphPainter(look.glyph, colors.foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// lucide `Check` · `Minus` 를 24 칸 좌표 그대로, 선 3 · 둥근 끝 · 둥근 꺾임으로 그린다(크기에 맞춰 줄인다 — 웹
/// `<Check strokeWidth={3} />` 와 같다).
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);

  final _Glyph? glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final glyph = this.glyph;
    if (glyph == null) return;
    final u = size.width / 24;
    final path = switch (glyph) {
      // M20 6 9 17l-5-5
      _Glyph.check =>
        Path()
          ..moveTo(20 * u, 6 * u)
          ..lineTo(9 * u, 17 * u)
          ..lineTo(4 * u, 12 * u),
      // M5 12h14
      _Glyph.minus =>
        Path()
          ..moveTo(5 * u, 12 * u)
          ..lineTo(19 * u, 12 * u),
    };
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

/// Checkbox — 하나 이상의 옵션을 고르게 한다(칸 + 라벨). 구조는 SEED Checkbox(2026-09-30), 수치 원본은
/// porest-design `specs/components/checkbox.yaml`(값은 `test/fixtures/design_spec/checkbox.json` — 테스트가 위젯이
/// 그 값과 같은지 본다). 웹(desk-front `src/shared/ds/checkbox`)과 같은 값이다. 옛 위젯
/// (lib/shared/widgets/p_checkbox.dart)과 이름이 같다 — 자리로 가른다.
///
///   [PCheckbox] — 칸 + 라벨. 칸 · 라벨 어디를 눌러도 바뀐다
///   [PCheckmark] — 칸만(그림). 목록 행 · 표 머리에서 행이 누르기를 맡을 때
///   [PCheckboxGroup] — 묶음. 세로로 쌓고 줄 사이 12
///
/// 누르면 선택 ↔ 선택 안 됨, 일부 선택이면 선택으로([onChanged] 가 다음 값을 받는다 — 값은 쓰는 쪽이 쥔다).
/// 상태 — 누르면 칸만 누름 색 + 세로 2px 거리 축소(라벨은 줄지 않는다, 모션 줄이기면 축소 없이 색만).
///   [onChanged] 가 없으면 비활성 — 전용 색이고 흐리게 하지 않는다. 라벨도 비활성 색이다.
///   올림(hovered) · 포커스 링(focused)은 웹 상태라 앱에는 없다 — 키보드 포커스는 받고(Space 로 누른다, Enter 는
///   누르지 않는다) 링은 그리지 않는다.
/// 누르는 영역은 라벨까지 묶어 44 × 44 까지 넓힌다 — 놓인 자리는 그대로다. 줄은 칸 + 라벨만큼만 차지한다.
/// 읽기 — 라벨이 이름이고 선택 · 선택 안 됨 · 일부 선택(mixed)을 읽는다.
class PCheckbox extends StatelessWidget {
  const PCheckbox({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.size = PCheckboxSize.medium,
    this.shape = PCheckboxShape.square,
    this.tone = PCheckboxTone.neutral,
    this.weight = PCheckboxWeight.regular,
    this.focusNode,
  });

  /// 무엇을 고르는지 — 칸과 함께 눌리고, 이 줄의 이름으로 읽힌다.
  final String label;

  /// true 선택 · false 선택 안 됨 · null 일부 선택(묶음의 부모).
  final bool? checked;

  /// 누르면 다음 값 — 선택이면 false, 선택 안 됨 · 일부 선택이면 true. 없으면 비활성.
  final ValueChanged<bool>? onChanged;
  final PCheckboxSize size;
  final PCheckboxShape shape;
  final PCheckboxTone tone;
  final PCheckboxWeight weight;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _sizes[size]!;
    final onChanged = this.onChanged;
    final enabled = onChanged != null;
    return SelectionControl(
      label: label,
      labelStyle: s.text.copyWith(
        color: enabled ? c.fgNeutral : c.fgDisabled,
        fontWeight: weight == PCheckboxWeight.bold
            ? FontWeight.w700
            : FontWeight.w400,
      ),
      gap: PSpacing.x2,
      minHeight: s.minHeight,
      onActivate: enabled ? () => onChanged(checked != true) : null,
      focusNode: focusNode,
      semantics: SelectionSemantics(
        checked: checked ?? false,
        mixed: checked == null,
      ),
      markBuilder: (pressed) => PCheckmark(
        checked: checked,
        size: size,
        shape: shape,
        tone: tone,
        enabled: enabled,
        pressed: pressed,
      ),
    );
  }
}

/// 묶음(Checkbox Group) — 세로로 쌓고 줄 사이 12(줄 32 · 36 에 더해 44 · 48 마다 한 줄 — 이웃 줄과 누르는 영역이
/// 겹치지 않는다). 줄은 내용만큼만 차지하고 앞에 붙는다.
///
/// [semanticLabel] 은 무엇을 고르는지 — 묶음의 이름으로 읽는다. 부모(전체)를 맨 위에 둘 때 그 값(선택 · 일부 선택 ·
/// 선택 안 됨)은 쓰는 쪽이 자식에서 정한다. 오류는 칸을 바꾸지 않고 묶음 아래 글로 알린다 — 제목 · 오류 글은 묶음을
/// Field 로 감싸 붙인다(field.md).
class PCheckboxGroup extends StatelessWidget {
  const PCheckboxGroup({super.key, required this.children, this.semanticLabel});

  final List<Widget> children;

  /// 묶음의 이름(웹 aria-label).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PSpacing.x3,
        children: children,
      ),
    );
  }
}
