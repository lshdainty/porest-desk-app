import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/tooltip/p_tooltip.dart';

// color-swatch.yaml 의 값 — 토큰이 있는 값은 토큰으로 적는다.
const double _swatch = PSpacing.x10; // swatch.size 40
const double _touch = PTouch.min; // swatch.touchTarget 44 × 44
const double _slop = (_touch - _swatch) / 2; // 누르는 영역이 칸 밖으로 나가는 폭
const int _columns = 5; // group.columns
const double _gap = PSpacing.x3; // group.gap 12
const double _checkSize = PSpacing.x4; // check.size 16
const double _checkStroke =
    2.5; // check.strokeWidth(24 칸 좌표 — 웹 <Check strokeWidth={2.5} />)
const double _ringWidth = 2; // ring.outlineWidth
const double _ringOffset = 2; // ring.outlineOffset
const double _focusWidth = 2; // focusRing.width
const double _focusOffset = 6; // focusRing.offset
const double _dividerWidth = 1; // divider.width
const double _dividerGap = PSpacing.x4; // divider.gap 16
const double _currentBorder = 2; // current.borderWidth(점선)
const double _labelMarginTop = PSpacing.x1_5; // currentLabel.marginTop 6

/// 격자의 폭 — 5 × 40 + 4 × 12 = 248.
const double _gridWidth = _columns * _swatch + (_columns - 1) * _gap;

/// 지금 색 칸 · 선 · 격자가 한 줄로 서는 폭(40 + 16 + 1 + 16 + 248). 놓인 자리가 이보다 좁으면 지금 색 칸을 격자 위에 둔다.
const double pColorSwatchStackBelow =
    _swatch + _dividerGap + _dividerWidth + _dividerGap + _gridWidth;

/// 색상환 차례 — 격자의 차례(5 × 2).
const List<PChartColor> pColorSwatchOrder = [
  PChartColor.red,
  PChartColor.orange,
  PChartColor.yellow,
  PChartColor.green,
  PChartColor.blue,
  PChartColor.indigo,
  PChartColor.violet,
  PChartColor.pink,
  PChartColor.brown,
  PChartColor.gray,
];

/// 색 이름 — 칸의 이름(라디오). "색상 N" · hex 를 이름으로 두지 않는다.
const Map<PChartColor, String> pColorSwatchNames = {
  PChartColor.red: '빨강',
  PChartColor.orange: '주황',
  PChartColor.yellow: '노랑',
  PChartColor.green: '초록',
  PChartColor.blue: '파랑',
  PChartColor.indigo: '남색',
  PChartColor.violet: '보라',
  PChartColor.pink: '분홍',
  PChartColor.brown: '갈색',
  PChartColor.gray: '회색',
};

/// 같은 목록이 아직 쓰지 않은 첫 색(v110 배정 순서 — 파랑 → 초록 → 주황 → 보라 → 분홍 → 남색 → 빨강 → 노랑 → 갈색).
/// 아홉 색을 다 쓰면 파랑, 회색은 주지 않는다("기타" 전용). 새 항목은 늘 빨강으로 시작하지 않는다.
PChartColor pFirstUnusedColor(Iterable<PChartColor?> used) {
  final taken = used.toSet();
  for (final color in kChartOrder) {
    if (!taken.contains(color)) return color;
  }
  return PChartColor.blue;
}

/// 고른 칸 — 색 하나 또는 지금 색 칸(저장 값을 그대로 둔다).
@immutable
class PColorSwatchValue {
  const PColorSwatchValue.color(PChartColor this.color);

  /// 지금 색 칸 — 값은 저장 값 그대로("current").
  const PColorSwatchValue.current() : color = null;

  final PChartColor? color;

  bool get isCurrent => color == null;

  @override
  bool operator ==(Object other) =>
      other is PColorSwatchValue && other.color == color;

  @override
  int get hashCode => color.hashCode;

  @override
  String toString() => color == null ? 'current' : color!.name;
}

/// 지금 색 칸의 체크 — fg-neutral · fg-neutral-inverted 가운데 그 색 위 대비가 큰 쪽(저장 색은 모드를 따르지 않는다).
@visibleForTesting
Color pColorSwatchCheckOn(PColors c, Color background) {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  return contrast(c.fgNeutralInverted, background) >=
          contrast(c.fgNeutral, background)
      ? c.fgNeutralInverted
      : c.fgNeutral;
}

/// Color Swatch — 카테고리 · 태그 · 라벨 · 저축 목표 · 캘린더에 붙일 색을 고르는 묶음. SEED 에는 색 고르기 부품이 없다 —
/// 칸의 칠 · 크기 · 고른 표시 · 키보드 · 새 항목의 첫 색은 groo 가 정했다(2026-10-09). 수치 원본은 groo-design
/// `specs/components/color-swatch.yaml`(값은 `test/fixtures/design_spec/color-swatch.json`). 웹(desk-front
/// `src/shared/ds/color-swatch`)과 같은 값이다. 옛 PColorPicker 를 대신한다.
///
/// 칸 — 원 40(누르는 영역 44) · 5개씩 두 줄 · 사이 12(폭과 상관없이 248), v110 차트 색(라이트 700 · 다크 800-dark)으로
///   꽉 채운다. 이름은 색 이름("빨강") — 마우스를 올리거나 키보드 초점이 오면 같은 이름의 툴팁이 뜬다.
/// 고름 — 칸 바깥 2 띄운 2px 고리(stroke-neutral-contrast) + 가운데 체크 16 · 선 2.5(fg-neutral-inverted). 키보드 포커스 링은
///   고리 바깥(띄움 6 · 2px). 누르면 칸 2px 거리 축소(40 → 0.95, 모션 줄이기면 하지 않는다). 고름은 바로 나타난다(0ms).
/// 지금 색 · 자동 — [currentColor](팔레트 밖 저장 색)를 주면 격자 앞에 "지금 색" 칸, [autoColor](색 없는 항목에 차트가 줄 색)를
///   주면 점선 원(2px stroke-neutral-solid)의 "자동" 칸을 두고 세로 선(1px, 사이 16)으로 가른다. 칸 아래 6 에 같은 이름 글
///   (12 / 16 · fg-neutral-muted). 그 칸을 고르면 값은 [PColorSwatchValue.current] — 저장 값을 그대로 둔다. 놓인 자리가 321 보다
///   좁으면 지금 색 칸을 격자 위 줄에 두고 선을 가로 1px 로 가른다 — 사이는 그대로 16.
/// 키보드(radiogroup) — 묶음에 Tab 하나(고른 칸, 없으면 첫 칸). ← → 는 차례대로 옮기며 고른다(줄 끝에서 다음 줄로, 끝에서 처음으로 —
///   지금 색 칸은 차례의 맨 앞, RTL 은 반대), ↑ ↓ 는 위아래 줄의 같은 칸(지금 색 칸에서는 그대로), Home · End 는 첫 · 마지막 칸,
///   Space 는 초점의 칸을 고른다. 이미 고른 칸을 다시 고르면 알리지 않는다(라디오).
/// 막힘 — 색은 그대로 두고 누르기만 막는다(Tab 에서도 빠진다). 고른 칸의 고리는 stroke-neutral-solid 로 남긴다.
/// 접근성 — 묶음이 이름(Field 라벨)으로, 칸이 색 이름 · 고른 상태로 읽힌다(같은 묶음의 라디오).
class PColorSwatchGroup extends StatefulWidget {
  const PColorSwatchGroup({
    super.key,
    required this.value,
    required this.onChanged,
    this.currentColor,
    this.autoColor,
    this.disabled,
    this.semanticLabel,
    this.names = pColorSwatchNames,
    this.currentName = '지금 색',
    this.autoName = '자동',
  });

  /// 고른 칸 — null 이면 고른 칸 없음.
  final PColorSwatchValue? value;

  /// 고르면 — 같은 칸을 다시 고르면 부르지 않는다(라디오).
  final ValueChanged<PColorSwatchValue>? onChanged;

  /// 팔레트 밖 저장 색(가져오기의 #9E9E9E) — 주면 격자 앞에 "지금 색" 칸.
  final Color? currentColor;

  /// 색 없는 항목에 차트가 줄 색 — 주면 격자 앞에 "자동" 칸(점선 원). [currentColor] 가 있으면 그쪽.
  final PChartColor? autoColor;

  /// 막힘 — null 이면 Field 의 막힘.
  final bool? disabled;

  /// 묶음 이름 — Field 밖에서 쓸 때. Field 안이면 Field 의 라벨이 이름이다.
  final String? semanticLabel;

  /// 색 이름 — 칸의 이름. 부르는 쪽 말로 바꿀 때.
  final Map<PChartColor, String> names;
  final String currentName;
  final String autoName;

  @override
  State<PColorSwatchGroup> createState() => _PColorSwatchGroupState();
}

class _PColorSwatchGroupState extends State<PColorSwatchGroup> {
  List<FocusNode> _nodes = [];

  bool get _hasCurrent =>
      widget.currentColor != null || widget.autoColor != null;

  /// 차례 — 지금 색 칸이 맨 앞, 그 뒤 색상환 10.
  List<PColorSwatchValue> get _order => [
    if (_hasCurrent) const PColorSwatchValue.current(),
    for (final c in pColorSwatchOrder) PColorSwatchValue.color(c),
  ];

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _ensureNodes(int n) {
    if (_nodes.length == n) return;
    for (final node in _nodes) {
      node.dispose();
    }
    _nodes = [
      for (var i = 0; i < n; i++) FocusNode(debugLabel: 'p-color-swatch-$i'),
    ];
  }

  bool _disabled(BuildContext context) =>
      widget.disabled ?? PFieldScope.maybeOf(context)?.data.disabled ?? false;

  void _select(PColorSwatchValue next) {
    if (next == widget.value) return; // 이미 고른 칸 — 알리지 않는다
    widget.onChanged?.call(next);
  }

  KeyEventResult _onKey(BuildContext context, int i, KeyEvent e) {
    if (e is KeyUpEvent || _disabled(context)) return KeyEventResult.ignored;
    final order = _order;
    final n = order.length;
    final offset = _hasCurrent ? 1 : 0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = e.logicalKey;
    int? j;
    if (key == LogicalKeyboardKey.arrowRight) {
      j = (i + (rtl ? n - 1 : 1)) % n;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      j = (i + (rtl ? 1 : n - 1)) % n;
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      // 위아래 줄의 같은 칸 — 지금 색 칸은 줄 밖이라 그대로
      if (i < offset) return KeyEventResult.handled;
      final g = i - offset;
      final rows = (pColorSwatchOrder.length / _columns).ceil();
      final down = key == LogicalKeyboardKey.arrowDown;
      final row = (g ~/ _columns + (down ? 1 : rows - 1)) % rows;
      j =
          offset +
          math.min(row * _columns + g % _columns, pColorSwatchOrder.length - 1);
    } else if (key == LogicalKeyboardKey.home) {
      j = 0;
    } else if (key == LogicalKeyboardKey.end) {
      j = n - 1;
    } else if (key == LogicalKeyboardKey.space) {
      // 초점의 칸을 고른다
      _select(order[i]);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
    _nodes[j].requestFocus();
    _select(order[j]);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = _disabled(context);
    final field = PFieldScope.maybeOf(context)?.data;
    final order = _order;
    _ensureNodes(order.length);
    final offset = _hasCurrent ? 1 : 0;
    final selectedIndex = widget.value == null
        ? -1
        : order.indexOf(widget.value!);
    final tabbable = selectedIndex >= 0 ? selectedIndex : 0;

    Widget cell(int i) {
      final v = order[i];
      final checked = v == widget.value;
      final isCurrent = v.isCurrent;
      final custom = widget.currentColor != null;
      final name = isCurrent
          ? (custom ? widget.currentName : widget.autoName)
          : widget.names[v.color!]!;
      final fill = isCurrent
          ? (custom ? widget.currentColor! : widget.autoColor!.of(c))
          : v.color!.of(c);
      final checkColor = isCurrent && custom
          ? pColorSwatchCheckOn(c, fill)
          : c.fgNeutralInverted;
      Widget swatch = _SwatchCell(
        key: ValueKey('swatch-$i'),
        node: _nodes[i],
        name: name,
        fill: fill,
        dashed: isCurrent && !custom,
        checked: checked,
        disabled: disabled,
        tabbable: i == tabbable,
        checkColor: checkColor,
        onSelect: () => _select(v),
        onKey: (e) => _onKey(context, i, e),
      );
      // 지금 색 칸은 이름이 아래 글로 보인다 — 툴팁 없이
      if (!isCurrent) {
        swatch = PTooltip(message: name, child: swatch);
      }
      // 누르는 영역 44 — 툴팁 바깥에서 넓힌다(사이의 상자들이 칸 밖 누름을 먼저 거르지 않게)
      return _HitSlop(child: swatch);
    }

    final grid = SizedBox(
      key: const ValueKey('swatch-grid'),
      width: _gridWidth,
      child: Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (var k = 0; k < pColorSwatchOrder.length; k++) cell(k + offset),
        ],
      ),
    );

    Widget body;
    if (!_hasCurrent) {
      body = Align(alignment: AlignmentDirectional.centerStart, child: grid);
    } else {
      // 열 폭은 칸(40) — 글은 가운데에 두고 칸보다 넓어도 열 폭을 키우지 않는다(321 의 셈이 글꼴에 흔들리지 않게)
      final currentColumn = SizedBox(
        key: const ValueKey('swatch-current-column'),
        width: _swatch,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell(0),
            const SizedBox(height: _labelMarginTop),
            ExcludeSemantics(
              child: SizedBox(
                height: PTypography.t2.fontSize! * PTypography.t2.height!,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: Text(
                    widget.currentColor != null
                        ? widget.currentName
                        : widget.autoName,
                    key: const ValueKey('swatch-current-label'),
                    maxLines: 1,
                    softWrap: false,
                    style: PTypography.t2.copyWith(color: c.fgNeutralSubtle),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      body = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : pColorSwatchStackBelow;
          final row = width >= pColorSwatchStackBelow;
          final divider = ExcludeSemantics(
            child: Container(
              key: const ValueKey('swatch-divider'),
              width: row ? _dividerWidth : null,
              height: row ? null : _dividerWidth,
              color: c.strokeNeutralWeak,
            ),
          );
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: row
                ? IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: _dividerGap,
                      children: [currentColumn, divider, grid],
                    ),
                  )
                : IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: _dividerGap,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: currentColumn,
                        ),
                        divider,
                        grid,
                      ],
                    ),
                  ),
          );
        },
      );
    }

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? field?.label,
      isRequired: (field?.required ?? false) ? true : null,
      validationResult: (field?.invalid ?? false)
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: body,
    );
  }
}

/// 누르는 영역을 칸 밖으로 [_slop] 넓힌다(40 → 44) — 이웃 칸과 겹치지 않는다(사이 12).
class _HitSlop extends SingleChildRenderObjectWidget {
  const _HitSlop({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitSlop();
}

class _RenderHitSlop extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final inside = Rect.fromLTWH(
      -_slop,
      -_slop,
      size.width + _slop * 2,
      size.height + _slop * 2,
    ).contains(position);
    if (!inside) return false;
    return super.hitTest(
      result,
      position: Offset(
        position.dx.clamp(0.0, size.width),
        position.dy.clamp(0.0, size.height),
      ),
    );
  }
}

class _SwatchCell extends StatefulWidget {
  const _SwatchCell({
    super.key,
    required this.node,
    required this.name,
    required this.fill,
    required this.dashed,
    required this.checked,
    required this.disabled,
    required this.tabbable,
    required this.checkColor,
    required this.onSelect,
    required this.onKey,
  });

  final FocusNode node;
  final String name;
  final Color fill;
  final bool dashed;
  final bool checked;
  final bool disabled;
  final bool tabbable;
  final Color checkColor;
  final VoidCallback onSelect;
  final KeyEventResult Function(KeyEvent) onKey;

  @override
  State<_SwatchCell> createState() => _SwatchCellState();
}

class _SwatchCellState extends State<_SwatchCell> {
  bool _pressed = false;
  bool _focused = false;
  bool _focusVisible = false;

  @override
  void initState() {
    super.initState();
    widget.node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_SwatchCell old) {
    super.didUpdateWidget(old);
    if (old.node != widget.node) {
      old.node.removeListener(_onFocus);
      widget.node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    widget.node.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    // 키보드로 초점이 왔을 때만 링 — 손가락으로 눌러도 초점은 가지만 링은 없다
    final visible =
        widget.node.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (visible != _focusVisible || widget.node.hasFocus != _focused) {
      setState(() {
        _focusVisible = visible;
        _focused = widget.node.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = widget.disabled;
    final ringColor = disabled ? c.strokeNeutralSolid : c.strokeNeutralContrast;
    const ring = _swatch + (_ringOffset + _ringWidth) * 2;
    const focusRing = _swatch + (_focusOffset + _focusWidth) * 2;

    final dot = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: _swatch,
          child: CustomPaint(
            painter: _SwatchPainter(
              fill: widget.fill,
              dashedColor: widget.dashed ? c.strokeNeutralSolid : null,
            ),
          ),
        ),
        if (widget.checked) ...[
          // 고른 고리 — 칸 바깥 2 띄운 2px(0ms 로 바로)
          Positioned(
            left: -(_ringOffset + _ringWidth),
            top: -(_ringOffset + _ringWidth),
            width: ring,
            height: ring,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('swatch-ring'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: _ringWidth),
                ),
              ),
            ),
          ),
          SizedBox.square(
            dimension: _checkSize,
            child: CustomPaint(
              key: const ValueKey('swatch-check'),
              painter: _CheckPainter(widget.checkColor),
            ),
          ),
        ],
        if (_focusVisible && !disabled)
          Positioned(
            left: -(_focusOffset + _focusWidth),
            top: -(_focusOffset + _focusWidth),
            width: focusRing,
            height: focusRing,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('swatch-focus-ring'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.strokeFocusRing,
                    width: _focusWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: Semantics(
        container: true,
        label: widget.name,
        checked: widget.checked,
        inMutuallyExclusiveGroup: true,
        enabled: !disabled,
        focusable: !disabled,
        focused: widget.node.hasFocus,
        onTap: disabled ? null : widget.onSelect,
        child: ExcludeSemantics(
          child: Focus(
            focusNode: widget.node,
            canRequestFocus: !disabled,
            skipTraversal: !widget.tabbable,
            onKeyEvent: (_, e) => widget.onKey(e),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: disabled
                  ? null
                  : (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              onTap: disabled ? null : widget.onSelect,
              child: SelectionPressScale(
                pressed: _pressed && !disabled,
                size: const Size.square(_swatch),
                child: dot,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  const _SwatchPainter({required this.fill, this.dashedColor});

  final Color fill;

  /// 점선 테두리 색 — 있으면 자동 칸(2px 점선).
  final Color? dashedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, size.width / 2, Paint()..color = fill);
    final dashed = dashedColor;
    if (dashed == null) return;
    // 테두리는 상자 안쪽에 선다(border-box) — 지름 40 안에 2px
    final r = size.width / 2 - _currentBorder / 2;
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    const dash = 3 * _currentBorder;
    const gap = 2 * _currentBorder;
    final paint = Paint()
      ..color = dashed
      ..style = PaintingStyle.stroke
      ..strokeWidth = _currentBorder;
    for (final metric in path.computeMetrics()) {
      final count = math.max(1, (metric.length / (dash + gap)).round());
      final step = metric.length / count;
      final on = step * dash / (dash + gap);
      for (var k = 0; k < count; k++) {
        canvas.drawPath(metric.extractPath(k * step, k * step + on), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.fill != fill || old.dashedColor != dashedColor;
}

/// lucide `Check` 를 24 칸 좌표 그대로, 선 2.5 · 둥근 끝 · 둥근 꺾임으로 그린다(16 으로 줄인다 — 웹 `<Check strokeWidth={2.5} />`).
class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 24;
    final path = Path()
      ..moveTo(20 * u, 6 * u)
      ..lineTo(9 * u, 17 * u)
      ..lineTo(4 * u, 12 * u);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _checkStroke * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
