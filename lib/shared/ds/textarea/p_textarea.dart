import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/input/text_control.dart';

/// 여백 — 입력(value)이 가진다(textarea.yaml large: 위아래 14 · 좌우 16).
const EdgeInsets _padding = EdgeInsets.symmetric(
  horizontal: PSpacing.x4,
  vertical: PSpacing.x3_5,
);

/// 자동 높이의 시작 줄 수 — 3줄(94 = 22 × 3 + 14 × 2).
const int _autoLines = 3;

/// 고정 높이의 최소 줄 수 — 2줄(72 = 22 × 2 + 14 × 2).
const int _fixedLines = 2;

/// Textarea — 여러 줄 글을 받는 입력칸. 구조는 SEED Textarea(2026-10-01), 수치 원본은 porest-design
/// `specs/components/textarea.yaml`(값은 `test/fixtures/design_spec/textarea.json`). 웹(desk-front
/// `src/shared/ds/textarea`)과 같은 값이다.
///
/// 상자 · 테두리 · 상태는 Input 의 상자형과 같다([PTextFrame] — 안쪽 1px, 포커스 · 오류 2px, 비활성 · 읽기 전용은
/// bg-disabled 바탕, 비활성 글자 fg-disabled). 다른 것은 높이 · 여백 · 자라는 방식이다. 라벨 · 설명 · 오류 · 글자 수는
/// [PField] 가 둘레에서 그린다. 앱은 늘 large(글자 t5 · 모서리 12 · 여백 위아래 14 · 좌우 16) 다.
///
/// 높이
///   [autoSize] true(기본)  3줄(94)에서 시작해 쓴 만큼 바로 자란다(움직임 없이). [maxHeight] 를 주면 그 높이부터
///                          칸 안에서 스크롤 — 시트 · 대화상자처럼 높이가 정해진 곳에서는 꼭 준다.
///   [autoSize] false        [height] 로 정한 높이(2줄 72 이상), 넘치는 글은 칸 안에서 스크롤.
/// 손잡이(resize)는 없다. Enter 는 줄바꿈이다(폼을 제출하지 않는다).
class PTextarea extends PTextControl {
  const PTextarea({
    super.key,
    super.controller,
    super.initialValue,
    super.focusNode,
    super.placeholder,
    super.onChanged,
    super.disabled,
    super.readOnly,
    super.invalid,
    super.semanticLabel,
    super.autofocus,
    super.inputFormatters,
    this.autoSize = true,
    this.maxHeight,
    this.height,
  }) : assert(autoSize || height != null, '자동 높이를 끄면 높이를 정한다(SEED)'),
       assert(!autoSize || height == null, '자동 높이면 height 대신 maxHeight'),
       assert(autoSize || maxHeight == null, '고정 높이에는 최대 높이가 없다'),
       assert(height == null || height >= 72, '2줄(72)보다 낮게 두지 않는다'),
       assert(maxHeight == null || maxHeight >= 94, '최대 높이는 3줄(94) 이상');

  /// 자동 높이 — 3줄에서 시작해 쓴 만큼 자란다. false 면 [height] 고정.
  final bool autoSize;

  /// 자동 높이의 최대(여백 포함) — 그 높이부터 칸 안에서 스크롤. 없으면 끝없이 자란다.
  final double? maxHeight;

  /// 고정 높이(여백 포함) — 자동 높이를 끄면 반드시 정한다.
  final double? height;

  @override
  State<PTextarea> createState() => _PTextareaState();
}

class _PTextareaState extends PTextControlState<PTextarea> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = this.disabled;
    final readOnly = this.readOnly;
    const text = PTypography.t5;

    final editable = buildEditable(
      style: text.copyWith(
        color: disabled ? c.fgDisabled : c.fgNeutral,
        fontWeight: FontWeight.w400,
      ),
      placeholderStyle: text.copyWith(
        color: disabled ? c.fgDisabled : c.fgPlaceholder,
        fontWeight: FontWeight.w400,
      ),
      multiline: true,
      // 자동 높이는 줄 수로 자란다(3줄부터), 고정 높이는 정한 높이를 채운다
      minLines: widget.autoSize ? _autoLines : null,
      maxLines: null,
      expands: !widget.autoSize,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );

    Widget value = Padding(padding: _padding, child: editable);
    if (!widget.autoSize) {
      // 2줄보다 낮게 두지 않는다 — 글자 크기 설정이 커져도 2줄은 보인다
      final lineHeight =
          MediaQuery.textScalerOf(context).scale(text.fontSize!) * text.height!;
      value = SizedBox(
        height: math.max(
          widget.height!,
          _padding.vertical + _fixedLines * lineHeight,
        ),
        child: value,
      );
    } else if (widget.maxHeight != null) {
      value = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: value,
      );
    }

    return TextFieldTapRegion(
      child: MouseRegion(
        cursor: disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.text,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: disabled ? null : focusFromBox,
          child: PTextFrame(
            underline: false,
            radius: PRounded.r3,
            background: disabled || readOnly
                ? c.bgDisabled
                : const Color(0x00000000),
            emphasis: emphasisColor(c),
            // 입력이 상자를 채운다 — 여백을 눌러도 가장 가까운 글자에 캐럿
            child: editableHitArea(
              extendStart: true,
              extendEnd: true,
              child: value,
            ),
          ),
        ),
      ),
    );
  }
}
