import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/text_control.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 상자 배치 — horizontal(앞 · 본문 · 컨트롤이 한 줄, 세로 가운데) · vertical(앞이 위, 컨트롤은 위 오른쪽). 묶음의 열 수가
/// 정하고(1열 가로형 · 2 ~ 3열 세로형) 상자마다 바꿀 수 있다.
enum PSelectBoxLayout { horizontal, vertical }

/// 펼침을 보일 때 — 고르면(기본) · 고르지 않으면 · 늘.
enum PSelectBoxFooterVisibility { whenSelected, whenNotSelected, always }

/// 하나 고르기 상자의 오른쪽 컨트롤 — 라디오(기본) · 없음(테두리만으로 고른 것이 보일 때).
enum PRadioSelectBoxControl { radio, none }

/// 여럿 고르기 상자의 오른쪽 컨트롤 — 칸 없는 체크(기본) · 없음.
enum PCheckSelectBoxControl { check, none }

// select-box.yaml
const double _radius = PRounded.r3;
const double _gap = PSpacing.x1_5; // 콘텐츠 ↔ 컨트롤
const double _horizontalGap = PSpacing.x3; // 앞 ↔ 본문
const double _verticalGap = PSpacing.x2_5; // 앞(위) ↔ 본문
const double _prefixSize = 22;
const double _controlSize = 20;
const double _bodyGap = PSpacing.x0_5;
const double _bodyPaddingRight = PSpacing.x1;
const double _footerPaddingX = PSpacing.x5;
const double _footerPaddingBottom = PSpacing.x4;
const double _groupGap = PSpacing.x3; // 상자 사이 가로 · 세로
const double _stretchSlack = 0.001; // 같은 높이 제약의 여유(아래 격자 설명)

/// 묶음이 상자에게 내려주는 값 — 열 수 · 막힘 · 오류.
class _SelectBoxScope extends InheritedWidget {
  const _SelectBoxScope({
    required this.columns,
    required this.disabled,
    required this.invalid,
    required super.child,
  });

  final int columns;
  final bool disabled;
  final bool invalid;

  static _SelectBoxScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectBoxScope>();

  @override
  bool updateShouldNotify(_SelectBoxScope old) =>
      columns != old.columns ||
      disabled != old.disabled ||
      invalid != old.invalid;
}

/// 묶음의 이름 · 막힘 · 오류 · 필수 — 직접 준 값이 Field 의 값을 이긴다.
({bool disabled, bool invalid, bool required}) _groupState(
  BuildContext context, {
  bool? disabled,
  bool? invalid,
  bool? required,
}) {
  final field = PFieldScope.maybeOf(context)?.data;
  return (
    disabled: disabled ?? field?.disabled ?? false,
    invalid: invalid ?? field?.invalid ?? false,
    required: required ?? field?.required ?? false,
  );
}

/// 상자 묶음의 격자 — 1 ~ 3열, 사이 12. 2열 이상이면 묶음의 모든 줄이 가장 긴 상자의 높이로 같다(SEED grid-auto-rows 1fr),
/// 1열은 상자마다 제 높이다. 칸이 비면(5개를 2열) 마지막 줄 오른쪽이 빈다 — 부르는 쪽이 열 수를 맞춘다.
class _SelectBoxGrid extends MultiChildRenderObjectWidget {
  const _SelectBoxGrid({required this.columns, required super.children});

  final int columns;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSelectBoxGrid(columns);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSelectBoxGrid renderObject,
  ) {
    renderObject.columns = columns;
  }
}

class _GridParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSelectBoxGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GridParentData> {
  _RenderSelectBoxGrid(this._columns);

  int _columns;
  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GridParentData) {
      child.parentData = _GridParentData();
    }
  }

  double _cellWidth(double width) =>
      (width - _groupGap * (_columns - 1)) / _columns;

  List<RenderBox> get _kids {
    final out = <RenderBox>[];
    for (var c = firstChild; c != null; c = childAfter(c)) {
      out.add(c);
    }
    return out;
  }

  /// 줄마다의 높이 — 2열 이상이면 모든 줄이 가장 높은 상자에 맞춘다.
  List<double> _rowHeights(List<double> natural) {
    final rows = <double>[];
    for (var i = 0; i < natural.length; i += _columns) {
      rows.add(
        natural
            .sublist(i, math.min(i + _columns, natural.length))
            .reduce(math.max),
      );
    }
    if (_columns > 1 && rows.isNotEmpty) {
      final tallest = rows.reduce(math.max);
      return [for (final _ in rows) tallest];
    }
    return rows;
  }

  double _totalHeight(List<double> rows) =>
      rows.fold<double>(0, (a, b) => a + b) +
      _groupGap * math.max(0, rows.length - 1);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final cell = BoxConstraints.tightFor(width: _cellWidth(width));
    final natural = [for (final k in _kids) k.getDryLayout(cell).height];
    if (natural.isEmpty) return Size(width, 0);
    return constraints.constrain(
      Size(width, _totalHeight(_rowHeights(natural))),
    );
  }

  @override
  void performLayout() {
    final kids = _kids;
    final width = constraints.maxWidth;
    final cellW = _cellWidth(width);
    if (kids.isEmpty) {
      size = constraints.constrain(Size(width, 0));
      return;
    }
    // 먼저 제 높이를 잰다 — 그다음 줄 높이에 맞춰 다시 둔다
    final natural = <double>[];
    for (final k in kids) {
      k.layout(
        BoxConstraints(minWidth: cellW, maxWidth: cellW),
        parentUsesSize: true,
      );
      natural.add(k.size.height);
    }
    final rows = _rowHeights(natural);
    var y = 0.0;
    for (var r = 0; r < rows.length; r++) {
      for (var col = 0; col < _columns; col++) {
        final i = r * _columns + col;
        if (i >= kids.length) break;
        final k = kids[i];
        // 같은 높이로 늘릴 때 — 높이를 꼭 맞추되(min) 상한을 아주 조금 느슨하게 둔다. 높이까지 딱 맞는 제약은 그 상자를
        // 재배치 경계로 만들어, 펼침이 열리고 닫히며 자라는 높이가 격자에 닿지 않는다(줄 높이가 낡은 채 남는다).
        if (_columns > 1) {
          k.layout(
            BoxConstraints(
              minWidth: cellW,
              maxWidth: cellW,
              minHeight: rows[r],
              maxHeight: rows[r] + _stretchSlack,
            ),
            parentUsesSize: true,
          );
        }
        (k.parentData! as _GridParentData).offset = Offset(
          col * (cellW + _groupGap),
          y,
        );
      }
      y += rows[r] + _groupGap;
    }
    size = constraints.constrain(Size(width, _totalHeight(rows)));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsic(width);
  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsic(width);

  double _intrinsic(double width) {
    final natural = [
      for (final k in _kids) k.getMinIntrinsicHeight(_cellWidth(width)),
    ];
    return natural.isEmpty ? 0 : _totalHeight(_rowHeights(natural));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

Widget _grid(int columns, List<Widget> children) =>
    _SelectBoxGrid(columns: columns, children: children);

/// 하나 고르기 묶음 — 상자 [PRadioSelectBox] 를 격자로 담는다. 이름이 있어야 한다(Field 로 감싸면 Field 의 라벨이 이름,
/// 아니면 [semanticLabel]). 오류는 상자를 바꾸지 않고 묶음 아래 글(Field 의 꼬리)로 알린다. 값을 쥐고, 이미 고른 상자를
/// 다시 눌러도 풀리지 않는다. [onChanged] 가 없으면 묶음 전체가 막힌다.
///
/// 키보드 — 묶음에 들어오면 고른 상자(없으면 첫 상자)로 오고, 화살표로 옮기며 고른다(막힌 상자는 건너뛴다). Space 로
/// 고른다. Enter 는 고르지 않는다(폼 제출에 둔다).
class PRadioSelectBoxGroup<T> extends StatelessWidget {
  const PRadioSelectBoxGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.columns = 1,
    this.semanticLabel,
    this.disabled,
    this.invalid,
    this.required,
  }) : assert(columns >= 1 && columns <= 3, '열은 1 ~ 3');

  final T? value;
  final ValueChanged<T>? onChanged;

  /// 상자 — [PRadioSelectBox] 들(같은 값 타입).
  final List<Widget> children;
  final int columns;
  final String? semanticLabel;
  final bool? disabled;
  final bool? invalid;
  final bool? required;

  @override
  Widget build(BuildContext context) {
    final state = _groupState(
      context,
      disabled: disabled,
      invalid: invalid,
      required: required,
    );
    final onChanged = state.disabled ? null : this.onChanged;
    return _SelectBoxScope(
      columns: columns,
      disabled: onChanged == null,
      invalid: state.invalid,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (next) {
          if (onChanged == null || next == null || next == value) return;
          onChanged(next);
        },
        child: Semantics(
          label: semanticLabel ?? PFieldScope.maybeOf(context)?.data.label,
          isRequired: state.required ? true : null,
          validationResult: state.invalid
              ? SemanticsValidationResult.invalid
              : SemanticsValidationResult.none,
          child: _grid(columns, children),
        ),
      ),
    );
  }
}

/// 여럿 고르기 묶음 — 상자 [PCheckSelectBox] 를 격자로 담는다(fieldset). 이름 · 오류는 [PRadioSelectBoxGroup] 과 같다.
/// 상자마다 Tab 으로 닿고 Space 로 켜고 끈다.
class PCheckSelectBoxGroup extends StatelessWidget {
  const PCheckSelectBoxGroup({
    super.key,
    required this.children,
    this.columns = 1,
    this.semanticLabel,
    this.disabled,
    this.invalid,
    this.required,
  }) : assert(columns >= 1 && columns <= 3, '열은 1 ~ 3');

  final List<Widget> children;
  final int columns;
  final String? semanticLabel;
  final bool? disabled;
  final bool? invalid;
  final bool? required;

  @override
  Widget build(BuildContext context) {
    final state = _groupState(
      context,
      disabled: disabled,
      invalid: invalid,
      required: required,
    );
    return _SelectBoxScope(
      columns: columns,
      disabled: state.disabled,
      invalid: state.invalid,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel ?? PFieldScope.maybeOf(context)?.data.label,
        isRequired: state.required ? true : null,
        validationResult: state.invalid
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
        child: _grid(columns, children),
      ),
    );
  }
}

/// Select Box(하나 고르기) — 테두리 상자로 선택지를 보여 주고 하나를 고르게 한다. 구조는 SEED Select Box(2026-10-01), 수치
/// 원본은 groo-design `specs/components/select-box.yaml`(값은 `test/fixtures/design_spec/select-box.json`). 웹(desk-front
/// `src/shared/ds/select-box`)과 같은 값이다. [PRadioSelectBoxGroup] 안에서만 쓴다.
///
/// 상자 하나 = 선택지 하나. 펼침을 뺀 상자 전체가 누르는 영역이다. 고른 상자는 테두리가 안쪽 2px 짙은 색으로 바뀐다(바탕은
/// 그대로, 내용이 밀리지 않는다). 누르면 바탕이 누름 색이 되고 누르는 자리(앞 · 본문 · 컨트롤)만 2px 거리 줄어든다 — 컨트롤은
/// 따로 줄지 않고 라디오는 자기 누름 색이 된다. 비활성은 제목 · 설명 · 앞 글자가 비활성 색이고 테두리는 1px(고른 채여도 2px
/// 옅은 선)이다 — 흐리게 하지 않는다. 컨트롤이 none 이어도 읽기는 유지된다.
/// 펼침([footer]) — 고른 상자 아래로 열리는 딸린 입력 · 안내. 안쪽 여백 좌우 20 · 아래 16, 눌러도 고르지 않는다. 닫히면
/// 보이지 않고 키보드 · 읽기에도 닿지 않는다.
class PRadioSelectBox<T> extends StatefulWidget {
  const PRadioSelectBox({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.labelBadge,
    this.prefix,
    this.footer,
    this.footerVisibility = PSelectBoxFooterVisibility.whenSelected,
    this.layout,
    this.control = PRadioSelectBoxControl.radio,
    this.enabled = true,
    this.focusNode,
  });

  final T value;

  /// 제목 — 16 · 500, 짧게.
  final String label;

  /// 설명 — 13, 두 줄까지.
  final String? description;

  /// 제목 옆 배지 — 사이 4("추천" 같은 짧은 표시).
  final Widget? labelBadge;

  /// 앞 — 아이콘 22 · 그림.
  final Widget? prefix;
  final Widget? footer;
  final PSelectBoxFooterVisibility footerVisibility;

  /// 묶음의 열 수에서 온다 — 상자마다 바꿀 때만.
  final PSelectBoxLayout? layout;
  final PRadioSelectBoxControl control;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<PRadioSelectBox<T>> createState() => _PRadioSelectBoxState<T>();
}

class _PRadioSelectBoxState<T> extends State<PRadioSelectBox<T>>
    with RadioClient<T> {
  FocusNode? _ownFocusNode;
  bool _groupEnabled = true;

  @override
  FocusNode get focusNode =>
      widget.focusNode ??
      (_ownFocusNode ??= FocusNode(
        debugLabel: 'PRadioSelectBox ${widget.label}',
      ));

  @override
  T get radioValue => widget.value;

  @override
  bool get tristate => false;

  @override
  bool get enabled => widget.enabled && _groupEnabled && registry != null;

  bool get _selected =>
      registry != null && registry!.groupValue == widget.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registry = RadioGroup.maybeOf<T>(context);
    _groupEnabled = !(_SelectBoxScope.maybeOf(context)?.disabled ?? false);
  }

  @override
  void dispose() {
    registry = null;
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _select() {
    // 이미 고른 상자를 다시 눌러도 풀리지 않는다
    if (_selected) return;
    registry?.onChanged(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      registry != null,
      'PRadioSelectBox 는 같은 값 타입(T)의 PRadioSelectBoxGroup 안에서만 쓴다 — PRadioSelectBox<$T>',
    );
    final enabled = this.enabled;
    final selected = _selected;
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    return _SelectBoxFrame(
      label: widget.label,
      description: widget.description,
      labelBadge: widget.labelBadge,
      prefix: widget.prefix,
      footer: widget.footer,
      footerVisibility: widget.footerVisibility,
      layout: widget.layout,
      selected: selected,
      enabled: enabled,
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
      control: widget.control == PRadioSelectBoxControl.radio
          ? (pressed) => PRadiomark(
              checked: selected,
              size: PRadioSize.medium,
              enabled: enabled,
              pressed: pressed,
              // 누르는 자리가 이미 줄어든다 — 라디오는 누름 색만
              scaleOnPress: false,
            )
          : null,
    );
  }
}

/// Select Box(여럿 고르기) — [PCheckSelectBoxGroup] 안에서 쓴다. 컨트롤은 칸 없는 체크(Checkbox 의 ghost — 꺼지면 옅은
/// 체크)이고 none 이면 테두리만으로 알린다(여럿이면 몇 개까지 고를 수 있는지 미리 적는다). 일부 선택은 없다. 나머지는
/// [PRadioSelectBox] 와 같다.
class PCheckSelectBox extends StatelessWidget {
  const PCheckSelectBox({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.description,
    this.labelBadge,
    this.prefix,
    this.footer,
    this.footerVisibility = PSelectBoxFooterVisibility.whenSelected,
    this.layout,
    this.control = PCheckSelectBoxControl.check,
    this.focusNode,
  });

  final String label;
  final bool checked;

  /// 누르면 다음 값. 없으면 막힌 상자.
  final ValueChanged<bool>? onChanged;
  final String? description;

  /// 제목 옆 배지 — 사이 4("추천" 같은 짧은 표시).
  final Widget? labelBadge;
  final Widget? prefix;
  final Widget? footer;
  final PSelectBoxFooterVisibility footerVisibility;
  final PSelectBoxLayout? layout;
  final PCheckSelectBoxControl control;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final groupOff = _SelectBoxScope.maybeOf(context)?.disabled ?? false;
    final onChanged = groupOff ? null : this.onChanged;
    final enabled = onChanged != null;
    return _SelectBoxFrame(
      label: label,
      description: description,
      labelBadge: labelBadge,
      prefix: prefix,
      footer: footer,
      footerVisibility: footerVisibility,
      layout: layout,
      selected: checked,
      enabled: enabled,
      onActivate: enabled ? () => onChanged(!checked) : null,
      focusNode: focusNode,
      semantics: SelectionSemantics(
        checked: checked,
        invalid: _SelectBoxScope.maybeOf(context)?.invalid ?? false,
      ),
      control: control == PCheckSelectBoxControl.check
          ? (pressed) => PCheckmark(
              checked: checked,
              size: PCheckboxSize.medium,
              shape: PCheckboxShape.ghost,
              enabled: enabled,
              // 칸 없는 체크는 바탕이 없다 — 상자가 누름을 맡는다
              pressed: false,
              scaleOnPress: false,
            )
          : null,
    );
  }
}

class _ActivateIntent extends Intent {
  const _ActivateIntent();
}

/// 상자 한 개의 그림 · 누르기 — 하나 · 여럿 고르기가 함께 쓴다.
class _SelectBoxFrame extends StatefulWidget {
  const _SelectBoxFrame({
    required this.label,
    required this.description,
    required this.labelBadge,
    required this.prefix,
    required this.footer,
    required this.footerVisibility,
    required this.layout,
    required this.selected,
    required this.enabled,
    required this.onActivate,
    required this.focusNode,
    required this.semantics,
    required this.control,
  });

  final String label;
  final String? description;

  /// 제목 옆 배지 — 사이 4("추천" 같은 짧은 표시).
  final Widget? labelBadge;
  final Widget? prefix;
  final Widget? footer;
  final PSelectBoxFooterVisibility footerVisibility;
  final PSelectBoxLayout? layout;
  final bool selected;
  final bool enabled;
  final VoidCallback? onActivate;
  final FocusNode? focusNode;
  final SelectionSemantics semantics;

  /// 컨트롤 — 없으면 '없음'(그려지지 않고 읽기는 유지된다).
  final Widget Function(bool pressed)? control;

  @override
  State<_SelectBoxFrame> createState() => _SelectBoxFrameState();
}

class _SelectBoxFrameState extends State<_SelectBoxFrame> {
  static const Map<ShortcutActivator, Intent> _spaceOnly = {
    SingleActivator(LogicalKeyboardKey.space): _ActivateIntent(),
  };

  final GlobalKey _triggerKey = GlobalKey();
  bool _pressed = false;
  Size _pressSize = const Size(0, 44);

  void _down(TapDownDetails _) {
    final box = _triggerKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) _pressSize = box.size;
    setState(() => _pressed = true);
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  void didUpdateWidget(_SelectBoxFrame old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) _pressed = false;
  }

  bool get _footerOpen => switch (widget.footerVisibility) {
    PSelectBoxFooterVisibility.always => true,
    PSelectBoxFooterVisibility.whenSelected => widget.selected,
    PSelectBoxFooterVisibility.whenNotSelected => !widget.selected,
  };

  Widget _label(PColors c, bool enabled) => Text(
    keepAll(widget.label),
    key: const ValueKey('select-box-label'),
    style: PTypography.t5.copyWith(
      fontWeight: FontWeight.w500,
      color: enabled ? c.fgNeutral : c.fgDisabled,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scope = _SelectBoxScope.maybeOf(context);
    final layout =
        widget.layout ??
        ((scope?.columns ?? 1) > 1
            ? PSelectBoxLayout.vertical
            : PSelectBoxLayout.horizontal);
    final vertical = layout == PSelectBoxLayout.vertical;
    final enabled = widget.enabled;
    final pressed = enabled && _pressed;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // 앞 · 본문
    final prefix = widget.prefix == null
        ? null
        : ExcludeSemantics(
            child: IconTheme(
              data: IconThemeData(
                size: _prefixSize,
                color: enabled ? c.fgNeutral : c.fgDisabled,
              ),
              child: widget.prefix!,
            ),
          );
    final body = Padding(
      padding: const EdgeInsets.only(right: _bodyPaddingRight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: _bodyGap,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x1,
            children: [
              Flexible(child: _label(c, enabled)),
              ?widget.labelBadge,
            ],
          ),
          if (widget.description != null)
            Text(
              keepAll(widget.description!),
              key: const ValueKey('select-box-description'),
              style: PTypography.t3.copyWith(
                color: enabled ? c.fgNeutralMuted : c.fgDisabled,
              ),
            ),
        ],
      ),
    );
    final control = widget.control == null
        ? null
        : ExcludeSemantics(
            child: SizedBox.square(
              dimension: _controlSize,
              child: Center(child: widget.control!(pressed)),
            ),
          );

    final Widget content = vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: _verticalGap,
            children: [?prefix, body],
          )
        : Row(
            spacing: _horizontalGap,
            children: [
              ?prefix,
              Flexible(child: body),
            ],
          );

    final Widget trigger = Padding(
      key: const ValueKey('select-box-trigger'),
      padding: vertical
          ? const EdgeInsets.symmetric(
              horizontal: PSpacing.x4,
              vertical: PSpacing.x5,
            )
          : const EdgeInsets.fromLTRB(
              PSpacing.x5,
              PSpacing.x4,
              PSpacing.x4,
              PSpacing.x4,
            ),
      child: Row(
        crossAxisAlignment: vertical
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        spacing: _gap,
        children: [
          Expanded(
            child: Align(
              alignment: vertical ? Alignment.topLeft : Alignment.centerLeft,
              child: content,
            ),
          ),
          ?control,
        ],
      ),
    );

    // 누르는 자리 — 같은 높이로 늘면 남는 자리까지 채운다(빈 아래쪽도 눌린다). 누르면 이 자리만 준다
    Widget action = AnimatedScale(
      key: const ValueKey('select-box-content'),
      scale: pressed && !reduceMotion
          ? SelectionPressScale.scaleOf(_pressSize)
          : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: SizedBox(key: _triggerKey, child: trigger),
    );
    action = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: enabled ? _down : null,
      onTapUp: enabled ? (_) => _up() : null,
      onTapCancel: enabled ? _up : null,
      onTap: enabled ? widget.onActivate : null,
      child: action,
    );

    final footer = widget.footer == null
        ? null
        : _Footer(
            open: _footerOpen,
            always:
                widget.footerVisibility == PSelectBoxFooterVisibility.always,
            child: widget.footer!,
          );

    Widget box = LayoutBuilder(
      builder: (context, constraints) {
        // 같은 높이로 늘어난 자리(2열 이상)면 누르는 자리가 남는 자리를 채운다
        final stretch = constraints.hasBoundedHeight;
        return Column(
          mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stretch)
              Expanded(child: SizedBox.expand(child: action))
            else
              action,
            ?footer,
          ],
        );
      },
    );

    box = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: pressed ? 1 : 0),
      duration: reduceMotion ? Duration.zero : PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, t, child) => PTextFrame(
        key: const ValueKey('select-box-root'),
        underline: false,
        radius: _radius,
        // 누름 색은 투명에서 나타난다 — 투명한 검정을 거치지 않게 같은 색의 투명으로 섞는다
        background: Color.lerp(
          c.bgLayerDefaultPressed.withValues(alpha: 0),
          c.bgLayerDefaultPressed,
          t,
        )!,
        // 고른 테두리는 안쪽 2px 덧그림 — 막히면 옅은 선
        emphasis: widget.selected
            ? (enabled ? c.strokeNeutralContrast : c.strokeNeutralWeak)
            : null,
        child: child!,
      ),
      child: box,
    );

    final s = widget.semantics;
    return Semantics(
      container: true,
      explicitChildNodes: false,
      enabled: enabled,
      checked: s.checked,
      selected: s.selected,
      inMutuallyExclusiveGroup: s.inMutuallyExclusiveGroup ? true : null,
      hint: s.hint,
      validationResult: s.invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      label: widget.description == null
          ? widget.label
          : '${widget.label}, ${widget.description}',
      onTap: enabled ? widget.onActivate : null,
      excludeSemantics: true,
      child: Shortcuts(
        shortcuts: _spaceOnly,
        child: Actions(
          actions: {
            _ActivateIntent: CallbackAction<_ActivateIntent>(
              onInvoke: (_) {
                widget.onActivate?.call();
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: widget.focusNode,
            canRequestFocus: enabled,
            child: MouseRegion(
              cursor: enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              child: box,
            ),
          ),
        ),
      ),
    );
  }
}

/// 펼침 — 고른 상자 아래로 열린다. 높이는 열 때 400ms · 닫을 때 300ms, 투명도는 열 때 300ms · 닫을 때 400ms(내용이 높이보다
/// 먼저 사라지지 않게). 닫히면 보이지 않고 눌림 · 키보드 · 읽기에도 닿지 않는다. 모션 줄이기면 높이는 바로 바뀌고 투명도만
/// 150ms. 안쪽 여백 좌우 20 · 아래 16.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.open,
    required this.always,
    required this.child,
  });

  final bool open;
  final bool always;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      key: const ValueKey('select-box-footer-inner'),
      padding: const EdgeInsets.fromLTRB(
        _footerPaddingX,
        0,
        _footerPaddingX,
        _footerPaddingBottom,
      ),
      child: child,
    );
    if (always) return inner;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final height = reduceMotion
        ? Duration.zero
        : open
        ? const Duration(milliseconds: 400)
        : PDuration.d6;
    final fade = reduceMotion
        ? PDuration.d3
        : open
        ? PDuration.d6
        : const Duration(milliseconds: 400);
    return ExcludeFocus(
      excluding: !open,
      child: ExcludeSemantics(
        excluding: !open,
        child: IgnorePointer(
          ignoring: !open,
          child: ClipRect(
            child: AnimatedAlign(
              key: const ValueKey('select-box-footer'),
              alignment: Alignment.topCenter,
              heightFactor: open ? 1 : 0,
              duration: height,
              curve: PEasing.easing,
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: fade,
                curve: PEasing.easing,
                child: inner,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
