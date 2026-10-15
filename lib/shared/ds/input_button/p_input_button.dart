import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/input/text_control.dart'
    show PTextFrame;

// input-button.yaml large — 앱은 늘 large 다(medium 40 · responsive 는 1280 이상 데스크톱 웹 몫).
const double _minHeight = 52;
const double _radius = PRounded.r3;
const double _paddingX = PSpacing.x4;
const double _gap = PSpacing.x2_5;
const double _icon = 20; // prefixIcon · suffixIcon
const double _clear = 22; // clearButton — 누르는 영역은 PTouch.min 까지 넓힌다
const double _focusRingWidth = 2; // focusRing.width
const double _focusRingOffset = 2; // focusRing.offset

/// Input Button — 입력칸 모양의 버튼. 누르면 고르는 자리(달력 · 시각 휠 · 아이콘 격자 · 검색 시트)를 연다. 구조는 SEED
/// Input Button(Field Button, 2026-10-01), 수치 원본은 porest-design `specs/components/input-button.yaml`(값은
/// `test/fixtures/design_spec/input-button.json`). 웹(desk-front `src/shared/ds/input-button`)과 같은 값 · 동작이다.
///
/// 이 위젯은 무엇을 여는지 모른다 — 값은 쓰는 쪽이 가지고([value]), 누르면 [onPressed] 를 부를 뿐이다. 시트(Bottom
/// Sheet) · "완료" · 닫기는 쓰는 쪽이 짠다. 앱은 시트만 쓴다(팝오버 없음). 라벨 · 설명 · 오류는 [PField] 가 둘레에서
/// 그린다 — Field 안에 두면 이름 · 설명 · 오류 · 필수 · 막힘을 받는다(직접 준 값이 이긴다).
///
/// 구조 — 상자(테두리 · 바탕 · 모서리) + 상자를 덮는 누름 층 + 누름을 지나 보내는 콘텐츠 층. 상자 어디를 눌러도(붙이개 ·
///   여백 포함) 눌린다. 지우기 버튼만 콘텐츠 위에서 따로 눌린다.
/// 크기 — large 52(모서리 12 · 좌우 16 · 사이 10 · 글자 t5 · 아이콘 20 · 지우기 22).
/// 상태 — 투명 바탕 · 안쪽 1px stroke-neutral-weak. 누르면 바탕이 bg-layer-default-pressed 로 바뀌고 콘텐츠(값 · 붙이개)만
///   2px 거리로 준다(기준 max(높이, 폭 ÷ 4, 24) — 모션 줄이기면 줄지 않는다). 오류는 안쪽 2px stroke-critical-solid(눌러도
///   그대로). 키보드 포커스에만 바깥 링 2px · 띄움 2px(터치로 눌러서는 없다). 비활성 · 읽기 전용은 bg-disabled(흐리게 하지
///   않는다) — 비활성은 글자 · 아이콘이 fg-disabled, 읽기 전용은 진한 글자 그대로. 둘 다 열지 않고, 비활성은 포커스도 못 받는다.
/// 지우기 — [onClear] 가 있고 값이 있고 막히지 않았을 때만. 누르면 [onClear] 만 부르고(열지 않는다) 칸으로 포커스를 돌려준다.
///   누름도 지우기 버튼만 준다(기준 24). 키보드 이동 순서에는 없다. 이름은 [clearLabel](기본 "지우기").
/// 이름 — 라벨(Field 의 라벨 또는 [semanticLabel]) + 고른 값, 비었으면 라벨 + placeholder. 붙이개 글 · Field 의 설명 · 오류는
///   설명으로 읽힌다. [expanded] 는 여는 자리가 열렸는지 알린다(웹 aria-expanded).
class PInputButton extends StatefulWidget {
  const PInputButton({
    super.key,
    this.value,
    this.placeholder,
    this.prefixText,
    this.prefixIcon,
    this.suffixText,
    this.suffixIcon,
    this.onPressed,
    this.onClear,
    this.clearLabel,
    this.disabled,
    this.readOnly,
    this.invalid,
    this.semanticLabel,
    this.expanded,
    this.focusNode,
    this.autofocus = false,
  });

  /// 고른 값 — 고른 자리의 표기 그대로(날짜 · 시각 · 이름). 비면(null · "") [placeholder].
  final String? value;

  /// 고르기 전의 글 — "{값의 종류} 선택"("날짜 선택"). 마침표 없이.
  final String? placeholder;

  /// 앞 글자 — 만 · https://.
  final String? prefixText;

  /// 앞 아이콘 — 값의 종류 · 고른 값에 딸린 아이콘(카테고리).
  final IconData? prefixIcon;

  /// 뒤 글자 — 단위(세 · cm).
  final String? suffixText;

  /// 뒤 아이콘 — 누르면 무엇이 열리는지(달력 · 시계 · 아래 화살표).
  final IconData? suffixIcon;

  /// 눌렀다 — 고르는 자리를 여는 것은 쓰는 쪽이다. 읽기 전용 · 비활성이면 부르지 않는다.
  final VoidCallback? onPressed;

  /// 지우기 — 주면 값이 있고 막히지 않았을 때만 지우기 버튼이 보인다(선택 사항인 칸에).
  final VoidCallback? onClear;

  /// 지우기 버튼의 이름 — 호출하는 쪽이 넘긴다. 없으면 "지우기"(dsInputClear).
  final String? clearLabel;

  /// 비활성 — 누르지 못하고 포커스도 못 받는다. null 이면 Field 의 값.
  final bool? disabled;

  /// 읽기 전용 — 포커스는 되고 열리지 않는다. null 이면 Field 의 값.
  final bool? readOnly;

  /// 오류 — 안쪽 2px 빨강(눌러도 그대로). null 이면 Field 의 값.
  final bool? invalid;

  /// 이름 — Field 밖에서 쓸 때. Field 안이면 Field 의 라벨이 이름이다.
  final String? semanticLabel;

  /// 여는 자리가 열려 있는가 — 화면 읽기 프로그램에 알린다(웹 aria-expanded). null 이면 알리지 않는다.
  final bool? expanded;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<PInputButton> createState() => _PInputButtonState();
}

class _PInputButtonState extends State<PInputButton> {
  FocusNode? _ownFocusNode;
  PFieldScope? _scope;
  bool _pressed = false;
  bool _hover = false;
  bool _focused = false;
  bool _focusVisible = false;
  final GlobalKey _clearKey = GlobalKey();

  /// 누름 축소의 기준 길이 max(높이, 폭 ÷ 4, 24) — 누르는 순간 그려진 크기에서 잰다.
  double _pressBasis = 24;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  PFieldControlData? get _field => _scope?.data;
  bool get _disabled => widget.disabled ?? _field?.disabled ?? false;
  bool get _readOnly => widget.readOnly ?? _field?.readOnly ?? false;
  bool get _invalid => widget.invalid ?? _field?.invalid ?? false;
  bool get _interactive => !_disabled && !_readOnly;
  bool get _hasValue => widget.value != null && widget.value!.isNotEmpty;
  bool get _showClear => widget.onClear != null && _hasValue && _interactive;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = PFieldScope.maybeOf(context);
    if (scope?.link != _scope?.link) {
      _scope?.link.detach(_focusNode);
      scope?.link.attach(_focusNode);
    }
    _scope = scope;
  }

  @override
  void didUpdateWidget(PInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      final old = oldWidget.focusNode ?? _ownFocusNode!;
      old.removeListener(_handleFocus);
      _scope?.link.detach(old);
      _focusNode.addListener(_handleFocus);
      _scope?.link.attach(_focusNode);
      _focused = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _scope?.link.detach(_focusNode);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  /// 누른 자리가 지우기 버튼(넓힌 영역 포함)인가 — 그 누름은 지우기가 받고 칸은 눌리지 않는다.
  bool _overClear(Offset global) {
    final box = _clearKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return false;
    final local = box.globalToLocal(global);
    final dx = math.max(0.0, (PTouch.min - box.size.width) / 2);
    final dy = math.max(0.0, (PTouch.min - box.size.height) / 2);
    return Rect.fromLTRB(
      -dx,
      -dy,
      box.size.width + dx,
      box.size.height + dy,
    ).contains(local);
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    if (value) {
      final size = context.size;
      if (size != null) {
        _pressBasis = math.max(size.height, math.max(size.width / 4, 24));
      }
    }
    setState(() => _pressed = value);
  }

  void _activate() {
    // 읽기 전용은 눌러도 · Enter · Space 로도 아무것도 열지 않는다
    if (!_interactive) return;
    widget.onPressed?.call();
  }

  void _clear() {
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final disabled = _disabled;
    final readOnly = _readOnly;
    final hasValue = _hasValue;

    final textStyle = PTypography.t5.copyWith(fontWeight: FontWeight.w400);
    final valueColor = disabled
        ? c.fgDisabled
        : hasValue
        ? c.fgNeutral
        : c.fgPlaceholder;
    final affixColor = disabled ? c.fgDisabled : c.fgNeutralSubtle;
    final iconColor = disabled ? c.fgDisabled : c.fgNeutralMuted;

    final background = disabled || readOnly
        ? c.bgDisabled
        : (_pressed || _hover)
        ? c.bgLayerDefaultPressed
        : const Color(0x00000000);

    Widget affixText(String text) => IgnorePointer(
      child: ExcludeSemantics(
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: textStyle.copyWith(color: affixColor),
        ),
      ),
    );
    Widget icon(IconData data) => IgnorePointer(
      child: ExcludeSemantics(
        child: Icon(data, size: _icon, color: iconColor),
      ),
    );

    final row = Row(
      spacing: _gap,
      children: [
        if (widget.prefixIcon != null) icon(widget.prefixIcon!),
        if (widget.prefixText != null) affixText(widget.prefixText!),
        Expanded(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Text(
                hasValue ? widget.value! : (widget.placeholder ?? ''),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: textStyle.copyWith(color: valueColor),
              ),
            ),
          ),
        ),
        if (_showClear)
          _ClearButton(
            key: _clearKey,
            color: c.fgNeutralSubtle,
            label: widget.clearLabel ?? l10n.dsInputClear,
            reduceMotion: reduceMotion,
            onPressed: _clear,
          ),
        if (widget.suffixText != null) affixText(widget.suffixText!),
        if (widget.suffixIcon != null) icon(widget.suffixIcon!),
      ],
    );

    final shrink = _pressed && _interactive && !reduceMotion;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _paddingX),
        child: Align(
          alignment: Alignment.centerLeft,
          heightFactor: 1,
          child: AnimatedScale(
            scale: shrink ? (_pressBasis - 2) / _pressBasis : 1,
            duration: PDuration.pressedScale,
            curve: PEasing.pressedScale,
            child: row,
          ),
        ),
      ),
    );

    // 이름 — 라벨 다음에 값이 이어 읽힌다(비었으면 placeholder). 붙이개 글 · Field 의 설명 · 오류는 설명이다
    final hint = <String>[
      for (final t in [widget.prefixText, widget.suffixText, _field?.message])
        if (t != null && t.isNotEmpty) t,
    ].join('\n');
    final shown = hasValue ? widget.value! : (widget.placeholder ?? '');

    final frame = TweenAnimationBuilder<Color>(
      tween: _PremultipliedColorTween(end: background),
      duration: reduceMotion ? Duration.zero : PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, color, child) => PTextFrame(
        underline: false,
        radius: _radius,
        background: color,
        emphasis: _invalid ? c.strokeCriticalSolid : null,
        child: child!,
      ),
      child: content,
    );

    final ring = _focusVisible && _focused
        ? Positioned(
            left: -(_focusRingOffset + _focusRingWidth),
            top: -(_focusRingOffset + _focusRingWidth),
            right: -(_focusRingOffset + _focusRingWidth),
            bottom: -(_focusRingOffset + _focusRingWidth),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: c.strokeFocusRing,
                    width: _focusRingWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    _radius + _focusRingOffset + _focusRingWidth,
                  ),
                ),
              ),
            ),
          )
        : null;

    // 누름 층 — 상자를 덮는다. 콘텐츠(frame 안)는 누름을 지나 보내고, 지우기 버튼만 위에서 따로 받는다
    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: !disabled,
      mouseCursor: disabled
          ? SystemMouseCursors.forbidden
          : readOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onShowFocusHighlight: (visible) {
        if (_focusVisible == visible) return;
        setState(() => _focusVisible = visible);
      },
      onShowHoverHighlight: (hover) {
        if (_hover == hover) return;
        setState(() => _hover = hover);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Semantics(
        container: true,
        button: true,
        enabled: !disabled,
        focusable: !disabled,
        focused: _focused,
        expanded: widget.expanded,
        isRequired: (_field?.required ?? false) ? true : null,
        validationResult: _invalid
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
        label: widget.semanticLabel ?? _field?.label,
        value: shown,
        hint: hint.isEmpty ? null : hint,
        onTap: _interactive ? _activate : null,
        excludeSemantics: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: _interactive
              ? (d) {
                  if (!_overClear(d.globalPosition)) _setPressed(true);
                }
              : null,
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _interactive ? _activate : null,
          child: Stack(clipBehavior: Clip.none, children: [frame, ?ring]),
        ),
      ),
    );
  }
}

/// 지우기 — lucide circle-x(fg-neutral-subtle). 누르면 [onPressed] 만 부르고(칸은 눌리지 않는다) 자기만 2px 거리로 준다
/// (기준 24). 보이는 22 를 PTouch.min 까지 넓힌 영역에서 받는다. 키보드 이동 순서에는 없다.
class _ClearButton extends StatefulWidget {
  const _ClearButton({
    super.key,
    required this.color,
    required this.label,
    required this.reduceMotion,
    required this.onPressed,
  });

  final Color color;
  final String label;
  final bool reduceMotion;
  final VoidCallback onPressed;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return _TouchTarget(
      minSize: PTouch.min,
      child: Semantics(
        container: true,
        button: true,
        label: widget.label,
        onTap: widget.onPressed,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed && !widget.reduceMotion ? (24 - 2) / 24 : 1,
            duration: PDuration.pressedScale,
            curve: PEasing.pressedScale,
            child: Icon(LucideIcons.circleX, size: _clear, color: widget.color),
          ),
        ),
      ),
    );
  }
}

/// 누르는 영역을 [minSize] 까지 넓힌다 — 놓인 자리는 그대로. 넓힌 자리에서 누르면 상자 가운데를 누른 것으로 친다.
/// 부모 상자 밖은 받을 수 없다(Flutter 는 부모 안에서만 자식에게 묻는다).
class _TouchTarget extends SingleChildRenderObjectWidget {
  const _TouchTarget({required this.minSize, required super.child});

  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchTarget(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTouchTarget renderObject,
  ) {
    renderObject.minSize = minSize;
  }
}

class _RenderTouchTarget extends RenderProxyBox {
  _RenderTouchTarget(this.minSize);

  double minSize;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final dx = math.max(0.0, (minSize - size.width) / 2);
    final dy = math.max(0.0, (minSize - size.height) / 2);
    final area = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
    if (!area.contains(position)) return false;
    final inside = size.contains(position)
        ? position
        : size.center(Offset.zero);
    if (hitTestChildren(result, position: inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// 색 사이 — 투명에서 나타날 때 그 색 그대로 진해진다(미리 곱한 알파로 섞는다 — 투명한 검정을 거치지 않는다).
class _PremultipliedColorTween extends Tween<Color> {
  _PremultipliedColorTween({super.end});

  @override
  Color lerp(double t) {
    final a = begin!;
    final b = end!;
    final alpha = (a.a + (b.a - a.a) * t).clamp(0.0, 1.0);
    if (alpha <= 0) return b.withValues(alpha: 0);
    double channel(double from, double to) =>
        (((from * a.a) + ((to * b.a) - (from * a.a)) * t) / alpha).clamp(
          0.0,
          1.0,
        );
    return Color.from(
      alpha: alpha,
      red: channel(a.r, b.r),
      green: channel(a.g, b.g),
      blue: channel(a.b, b.b),
    );
  }
}
