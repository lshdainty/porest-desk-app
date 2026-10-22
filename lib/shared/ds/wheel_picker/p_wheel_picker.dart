import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 크기 — 항목 높이. medium 44(기본 — 시각 · 월 고르기 · 연 · 월 휠) · small 36(좁은 팝오버).
enum PWheelPickerSize { small, medium }

/// 항목 글 정렬 — 시는 오른쪽(한 자리 · 두 자리 수의 끝을 맞춘다), 연은 오른쪽 · 월은 왼쪽(달만 고르기).
enum PWheelPickerAlign { left, center, right }

/// 쓰는 쪽이 값을 바꿨을 때 옮기는 방식 — auto(바로, 기본) · smooth(부드럽게). 모션 줄이기면 늘 바로.
enum PWheelPickerValueChange { auto, smooth }

/// 크기마다의 값(wheel-picker.yaml 크기) — 항목 높이 · 글자. 글자는 글자 크기 설정을 따르지 않는 px 이다(휠 칸이 넘치지
/// 않게 — 웹 text-t10-static · text-t7-static, 앱은 TextScaler.noScaling).
const Map<PWheelPickerSize, ({double item, TextStyle text})> _sizes = {
  PWheelPickerSize.small: (item: 36, text: PTypography.t7),
  PWheelPickerSize.medium: (item: 44, text: PTypography.t10),
};

/// 휠 전체의 높이 = 항목 높이 × 보이는 수.
double wheelPickerHeight(PWheelPickerSize size, int visibleItems) =>
    _sizes[size]!.item * visibleItems;

/// 안개 높이 — min(휠 높이 × 40%, 항목 3칸). medium 5개 88 · 7개 123 · small 5개 72(wheel-picker.yaml fog.height).
double wheelPickerFogHeight(PWheelPickerSize size, int visibleItems) => math
    .min(wheelPickerHeight(size, visibleItems) * 0.4, _sizes[size]!.item * 3);

/// 항목 글 좌우 여백 · 선택 띠를 휠 좌우 끝에서 들이는 거리(item.paddingX · indicator.insetX).
const double _itemPaddingX = PSpacing.x4;
const double _indicatorInsetX = PSpacing.x4;

/// 부드럽게 옮기는 시간 · 곡선 — 누른 항목을 가운데로 · 키로 옮길 때(스펙 "부드러운 스크롤", 시간은 스펙에 없다 —
/// 정착의 ease-out cubic 을 쓴다).
const Duration _moveDuration = PDuration.d4;
const Curve _moveCurve = Curves.easeOutCubic;

/// 한 칼럼의 항목 — 고르는 값 · 짧은 한 줄 글 · 읽는 글.
@immutable
class PWheelPickerOption<T> {
  const PWheelPickerOption({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  /// 칼럼 안에서 고유한 값.
  final T value;

  /// 항목 글 — 짧은 한 줄(숫자 · 짧은 낱말).
  final String label;

  /// 읽는 글 — 글과 다르게 읽어야 할 때("AM" → "오전"). 없으면 [label].
  final String? semanticLabel;
}

/// 휠이 멈춰 값이 정해졌을 때 — 지난번 멈춘 자리에서 움직인 칸 수(아래로 +, 위로 −). 반복 칼럼에서 끝 → 처음을 넘었는지
/// 알 수 있다(Time Picker 의 시 11 ↔ 12).
typedef PWheelPickerChanged<T> = void Function(T value, int stepDelta);

/// 휠이 놓이는 모양 — 크기 · 보이는 칸 수 · 막힘. 칼럼이 읽는다.
class _WheelScope extends InheritedWidget {
  const _WheelScope({
    required this.size,
    required this.visibleItems,
    required this.disabled,
    required super.child,
  });

  final PWheelPickerSize size;
  final int visibleItems;
  final bool disabled;

  static _WheelScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_WheelScope>();
    assert(scope != null, 'PWheelPickerColumn 은 PWheelPicker 안에 둔다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_WheelScope old) =>
      size != old.size ||
      visibleItems != old.visibleItems ||
      disabled != old.disabled;
}

/// Wheel Picker — 순서가 있는 값을 세로로 굴려 고르는 휠(한 칼럼 이상). 구조는 SEED Wheel Picker(2026-10-03), 수치 원본은
/// groo-design `specs/components/wheel-picker.yaml`(값은 `test/fixtures/design_spec/wheel-picker.json` — 테스트가 위젯이
/// 그 값과 같은지 본다). 웹(desk-front `src/shared/ds/wheel-picker`)과 같은 값이다.
///
///   [PWheelPicker] — 휠. 이름(semanticLabel — 필수)과 크기(small 36 · medium 44, 기본 medium) · 보이는 칸 수(5 · 7, 기본
///     5) · 막힘. 칼럼 묶음을 가운데에 모으고 가운데 선택 띠 · 위아래 안개를 그린다
///   [PWheelPickerColumn] — 칼럼. 항목 · 값 · 멈춘 뒤 부르는 콜백 · 반복 · 정렬 · 이름(필수)
///
/// 휠 높이 = 항목 높이 × 보이는 수(medium 5개 220 · 7개 308, small 5개 180), 바탕 bg-layer-floating. 항목은 medium 44 ·
/// 글자 26 / 35, small 36 · 20 / 27 — 글자 크기 설정을 따르지 않는 px. 500 · 숫자 폭 같게 · 좌우 16, 칼럼은 항목 글 폭 + 32
/// (폭을 정할 칼럼은 `width`). 선택 띠는 bg-neutral-weak · 모서리 r2 8 · 휠 좌우 끝에서 16 들임 · 항목 높이로 칼럼 뒤에
/// 깔린다. 글자는 띠 밖 fg-disabled, 띠에 걸친 부분만 fg-neutral(굴리는 동안에도 — 항목이 띠를 지나는 만큼 글자 위 부분 ·
/// 아래 부분이 띠 안 · 밖으로 나뉜다). 안개는 위아래 min(휠 높이 × 40%, 항목 3칸)에서 휠 바탕색으로 흐려진다
/// (gradient-fade-mask) — 이 부품이 제 안개를 가지므로 Scroll Fog 를 겹쳐 걸지 않는다.
///
/// 값은 휠이 멈춘 뒤에 정한다 — 굴리는 동안에는 띠를 지나는 항목만 짙게 칠하고, 가장 가까운 칸에 멈춘 뒤 `onChanged` 를 한
/// 번 부른다. 굴리는 동안 띠를 지나는 항목마다는 `onIndexChange`(값은 아직 정해지지 않았다 — 햅틱은 쓰는 쪽이 여기서 준다,
/// 이 부품은 소리 · 진동을 내지 않는다).
///
/// 움직임 — 손가락으로 밀면 플랫폼의 관성으로 굴러 가장 가까운 칸에 멈춘다(Flutter 의 ListWheelScrollView). 보이는 항목을
/// 누르면 그 항목을 가운데로 부드럽게 옮기고 멈춘 뒤 값이 정해진다. 키보드는 칼럼마다 Tab 자리 하나, ↑ ↓ 이전 · 다음
/// (누르고 있으면 바로바로), Home · End 처음 · 끝. 모션 줄이기면 프로그램이 하는 이동을 모두 바로 한다. 반복(loop)은 칼럼마다 —
/// 끄면 처음 · 끝에서 멈추고, 켜면 끝 다음에 처음이 이어진다. 막힘은 값은 그대로, 굴릴 수도 초점이 갈 수도 없고 고른 항목도
/// 흐리게(띠는 남는다). 쓰는 쪽이 값을 바꾸면 그 자리로 옮긴다(사용자가 만지는 동안에는 덮어쓰지 않는다).
/// 마우스 끌기 · 휠(3px 넘게 끌기, 놓을 때 속도로 ±3칸, 220 ~ 360ms · 휠 120ms 뒤 160ms)은 웹 입력이라 앱에 없다 — 손가락
/// 입력은 플랫폼 스크롤이 맡는다. 웹의 키보드 포커스 링(focused)도 앱에 없다 — 초점은 받고 링은 그리지 않는다.
///
/// 읽기 — 휠은 이름 있는 묶음, 칼럼은 조절 가능한 값(이름 · 지금 값의 글 · 다음 · 이전 값의 글, 올리기 · 내리기 동작)이고
/// 항목은 보조 기술에 숨긴다. 시각 · 연 · 월처럼 순서가 있는 값에만 쓴다 — 날짜는 달력, 순서 없는 긴 목록은 Select.
class PWheelPicker extends StatelessWidget {
  const PWheelPicker({
    super.key,
    required this.semanticLabel,
    required this.children,
    this.size = PWheelPickerSize.medium,
    this.visibleItems = 5,
    this.disabled = false,
  }) : assert(
         visibleItems == 5 || visibleItems == 7,
         '보이는 칸은 5 · 7 — 가운데 줄이 있어야 해서 홀수만',
       );

  /// 휠의 이름(웹 aria-label) — 무엇을 고르는지("월 선택").
  final String semanticLabel;

  /// [PWheelPickerColumn] 들 — 가운데에 모은다.
  final List<Widget> children;

  /// small 36(좁은 팝오버) · medium 44(기본).
  final PWheelPickerSize size;

  /// 보이는 칸 수 — 5(기본) · 7(달력 머리의 연 · 월 휠).
  final int visibleItems;

  /// 막힌 휠 — 값은 그대로, 굴릴 수도 초점이 갈 수도 없다.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = _sizes[size]!.item;
    final height = item * visibleItems;
    final fog = wheelPickerFogHeight(size, visibleItems);
    final fade = context.gradients.fadeMask;
    // 안개 — 휠 바탕색 판을 마스크(위 → 아래로 불투명)로 가린다. 위 판은 뒤집어 아래로 투명하다
    LinearGradient fogGradient({required bool flipped}) => LinearGradient(
      begin: flipped ? Alignment.bottomCenter : Alignment.topCenter,
      end: flipped ? Alignment.topCenter : Alignment.bottomCenter,
      colors: [
        for (final color in fade.colors)
          c.bgLayerFloating.withValues(alpha: c.bgLayerFloating.a * color.a),
      ],
      stops: fade.stops,
    );
    // 위 판은 위에서 아래로 투명해지게(= 아래 판을 뒤집은 것)
    Widget fogPanel({required bool top}) => Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: fog,
      child: IgnorePointer(
        child: DecoratedBox(
          key: ValueKey(top ? 'wheel-fog-top' : 'wheel-fog-bottom'),
          decoration: BoxDecoration(gradient: fogGradient(flipped: top)),
        ),
      ),
    );

    return _WheelScope(
      size: size,
      visibleItems: visibleItems,
      disabled: disabled,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        enabled: !disabled,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: ClipRect(
            child: ColoredBox(
              key: const ValueKey('wheel-root'),
              color: c.bgLayerFloating,
              child: Stack(
                children: [
                  // 선택 띠 — 칼럼 뒤에 깔린다. 휠 좌우 끝에서 16 들인 가운데 줄
                  Positioned(
                    left: _indicatorInsetX,
                    right: _indicatorInsetX,
                    top: (height - item) / 2,
                    height: item,
                    child: DecoratedBox(
                      key: const ValueKey('wheel-indicator'),
                      decoration: BoxDecoration(
                        color: c.bgNeutralWeak,
                        borderRadius: BorderRadius.circular(PRounded.r2),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    ),
                  ),
                  fogPanel(top: true),
                  fogPanel(top: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 칼럼 — 값을 굴려 고르는 한 줄. [PWheelPicker] 안에 둔다.
///
/// [value] 를 주면 쓰는 쪽이 값을 쥔다(제어) — 사용자가 고른 값은 [onChanged] 로만 알리고, 번호는 쓰는 쪽이 정한다.
/// 주지 않으면 [initialValue](없으면 첫 항목)에서 시작해 이 칼럼이 쥔다.
class PWheelPickerColumn<T> extends StatefulWidget {
  const PWheelPickerColumn({
    super.key,
    required this.semanticLabel,
    required this.options,
    this.value,
    this.initialValue,
    this.onChanged,
    this.onJump,
    this.onIndexChange,
    this.loop = false,
    this.align = PWheelPickerAlign.center,
    this.width,
    this.valueChange = PWheelPickerValueChange.auto,
  }) : assert(options.length > 0, '칼럼에 항목이 없다 — options 에 하나 이상 넣는다');

  /// 칼럼 이름(필수) — "연도" · "월" · "시" · "분". 항목에 단위를 붙이지 않는 숫자 칼럼은 이 이름이 단위를 알린다.
  final String semanticLabel;

  /// 항목 — 하나 이상, 값은 칼럼 안에서 고유.
  final List<PWheelPickerOption<T>> options;

  /// 고른 값(제어) — [options] 안의 값.
  final T? value;

  /// 처음 값(제어하지 않을 때) — 없으면 첫 항목.
  final T? initialValue;

  /// 휠이 멈춰 값이 정해졌을 때 한 번 — 값이 바뀌었을 때만.
  final PWheelPickerChanged<T>? onChanged;

  /// Home · End 로 건너뛰어 멈춰 값이 정해졌을 때 — 이때는 [onChanged] 대신 이것을 부른다(없으면 [onChanged] 로 stepDelta 와
  /// 함께 알린다). 반복 칼럼에서 지나간 칸 수가 아니라 간 값 자체로 셈해야 할 때(시: 오전 · 오후를 그대로 두고 1 · 12 로 간다,
  /// 03-C 결정 3A). 웹 `WheelPickerValueChangeDetails.jump` 와 같은 뜻이다.
  final ValueChanged<T>? onJump;

  /// 굴리는 동안 띠를 지나는 항목마다(햅틱 등) — 값은 아직 정해지지 않았다. 쓰는 쪽이 움직인 때만(밀기 · 누르기 · 키)
  /// 부르고, 쓰는 쪽이 값을 바꿔 옮길 때는 부르지 않는다.
  final void Function(int index, T value)? onIndexChange;

  /// 끝 다음에 처음을 잇는다(월 · 시 · 분). 끄면 처음 · 끝에서 멈춘다.
  final bool loop;

  /// 항목 글 정렬 — 시는 오른쪽.
  final PWheelPickerAlign align;

  /// 칼럼 폭 — 폭을 정할 칼럼(연 120 · 월 96). 없으면 항목 글 폭 + 좌우 16.
  final double? width;

  /// 쓰는 쪽이 값을 바꿨을 때 옮기는 방식.
  final PWheelPickerValueChange valueChange;

  @override
  State<PWheelPickerColumn<T>> createState() => _PWheelPickerColumnState<T>();
}

class _PWheelPickerColumnState<T> extends State<PWheelPickerColumn<T>> {
  late FixedExtentScrollController _controller;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PWheelPickerColumn');

  /// 이 칼럼이 쥔 값(제어하지 않을 때).
  late T _inner = widget.initialValue ?? widget.options.first.value;

  /// 지난번 멈춘 자리(물리 번호) — stepDelta 의 기준.
  late int _lastSettled;

  /// 마지막으로 띠를 지난 항목(물리 번호) — 한 프레임에 여러 칸을 건너뛰어도 지나간 항목마다 알린다.
  late int _lastVisual;

  /// 키보드로 가는 중인 자리 — 빠르게 거듭 누르면 가던 자리에서 이어 간다. 손으로 만지면 지운다.
  int? _keyboardTarget;

  /// 사용자가 움직이는 중 — 지나는 항목을 알리고, 멈추면 값을 정한다.
  bool _notify = false;

  /// 사용자가 끌고 있다 — 쓰는 쪽이 바꾼 값으로 덮어쓰지 않는다.
  bool _dragging = false;

  /// 지금 가는 이동이 Home · End 의 건너뛰기다 — 멈추면 [PWheelPickerColumn.onJump] 로 알리고 지운다.
  bool _jump = false;

  /// 우리가 값 맞추기로 옮기는 중 — 알리지 않는다.
  bool _syncing = false;

  /// 칼럼 폭 계산 캐시 — 글 · 크기가 바뀌면 다시 잰다.
  ({PWheelPickerSize size, double width})? _labelWidth;

  T get _current => widget.value ?? _inner;

  int get _count => widget.options.length;

  int _logicalOf(T value) {
    final i = widget.options.indexWhere((o) => o.value == value);
    return i < 0 ? 0 : i;
  }

  /// 물리 번호 → 항목 번호 — 반복 칼럼은 앞뒤로 이어지고(끝 없이 음수까지), 아니면 범위 안이다.
  int _indexOf(int physical) => widget.loop
      ? ((physical % _count) + _count) % _count
      : physical.clamp(0, _count - 1);

  @override
  void initState() {
    super.initState();
    final start = _logicalOf(_current);
    _lastSettled = start;
    _lastVisual = start;
    _controller = FixedExtentScrollController(initialItem: start);
  }

  @override
  void didUpdateWidget(PWheelPickerColumn<T> old) {
    super.didUpdateWidget(old);
    if (old.options.length != widget.options.length ||
        old.loop != widget.loop ||
        _labelsChanged(old.options)) {
      _labelWidth = null;
    }
    // 쓰는 쪽이 값을 바꿨다 — 그 자리로 옮긴다(그리는 중에 스크롤을 건드리지 않게 다음 프레임에)
    if (old.value != widget.value ||
        old.options.length != widget.options.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncToValue());
    }
  }

  bool _labelsChanged(List<PWheelPickerOption<T>> before) {
    for (var i = 0; i < before.length && i < widget.options.length; i++) {
      if (before[i].label != widget.options[i].label) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// 값에 맞는 자리로 — 반복 칼럼은 지금 가운데에서 가장 가까운 같은 값으로 간다. 사용자가 만지는 동안에는 덮어쓰지 않는다.
  void _syncToValue() {
    if (!mounted || !_controller.hasClients || _dragging || _notify) return;
    final center = _controller.selectedItem;
    final want = _logicalOf(_current);
    if (_indexOf(center) == want && (!_count.isFinite || _centered(center))) {
      _lastSettled = center;
      _keyboardTarget = center;
      return;
    }
    var target = want;
    if (widget.loop) {
      // 가장 가까운 같은 값 — 끝을 넘어 이어지는 쪽이 가까우면 그쪽으로
      var delta = want - _indexOf(center);
      if (delta > _count / 2) delta -= _count;
      if (delta < -_count / 2) delta += _count;
      target = center + delta;
    }
    _lastSettled = target;
    _keyboardTarget = target;
    final smooth =
        widget.valueChange == PWheelPickerValueChange.smooth && !_reduceMotion;
    if (smooth) {
      _controller.animateToItem(
        target,
        duration: _moveDuration,
        curve: _moveCurve,
      );
    } else {
      _syncing = true;
      _controller.jumpToItem(target);
      _syncing = false;
    }
  }

  bool _centered(int center) =>
      (_controller.offset - center * _itemExtent).abs() < 0.5;

  double get _itemExtent => _sizes[_scopeSize]!.item;
  PWheelPickerSize _scopeSize = PWheelPickerSize.medium;

  // ── 멈춤 · 지나감 ─────────────────────────────────────────────

  /// 멈췄다 — 가장 가까운 칸의 값을 정한다(바뀌었을 때만 한 번).
  void _settle() {
    if (!mounted || !_controller.hasClients) return;
    final p = _controller.selectedItem;
    final stepDelta = p - _lastSettled;
    _lastSettled = p;
    _keyboardTarget = p;
    _notify = false;
    final value = widget.options[_indexOf(p)].value;
    final jumped = _jump;
    _jump = false;
    if (value != _current) {
      if (widget.value == null) setState(() => _inner = value);
      final onJump = widget.onJump;
      if (jumped && onJump != null) {
        onJump(value);
      } else {
        widget.onChanged?.call(value, stepDelta);
      }
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || _syncing) return false;
    if (n is ScrollStartNotification) {
      if (n.dragDetails != null) {
        // 손가락이 닿았다 — 지나는 항목을 알리고, 쓰는 쪽의 값 · 키 자리는 접는다
        _dragging = true;
        _jump = false;
        _notify = true;
        _keyboardTarget = null;
      }
    } else if (n is ScrollEndNotification) {
      _dragging = false;
      _settle();
    }
    return false;
  }

  void _onSelectedItem(int physical) {
    final previous = _lastVisual;
    _lastVisual = physical;
    if (!_notify || _syncing || physical == previous) return;
    // 한 프레임에 여러 칸을 건너뛰어도 띠를 지난 항목마다
    final dir = physical > previous ? 1 : -1;
    for (
      var p = previous + dir;
      dir > 0 ? p <= physical : p >= physical;
      p += dir
    ) {
      final index = _indexOf(p);
      widget.onIndexChange?.call(index, widget.options[index].value);
    }
  }

  // ── 누르기 · 키 · 조절 ────────────────────────────────────────

  /// 그 자리(물리 번호)로 — 부드럽게(모션 줄이기 · 키를 누르고 있으면 바로), 멈춘 뒤 값을 정한다.
  void _moveToPhysical(int physical, {bool smooth = true, bool jump = false}) {
    if (!_controller.hasClients) return;
    var target = physical;
    if (!widget.loop) target = target.clamp(0, _count - 1);
    _keyboardTarget = target;
    // 이미 그 자리면 움직일 것이 없다 — 알림도 오지 않으니 움직이는 중으로 남기지 않는다
    if (target == _controller.selectedItem && _centered(target)) return;
    _jump = jump;
    _notify = true;
    if (smooth && !_reduceMotion) {
      _controller.animateToItem(
        target,
        duration: _moveDuration,
        curve: _moveCurve,
      );
    } else {
      // 바로 옮긴다 — 끝 알림이 곧바로 와 값을 정한다
      _controller.jumpToItem(target);
    }
  }

  void _step(int by, {bool smooth = true}) {
    if (!_controller.hasClients) return;
    final from = _keyboardTarget ?? _controller.selectedItem;
    _moveToPhysical(from + by, smooth: smooth);
  }

  void _moveToIndex(int index, {bool smooth = true, bool jump = false}) {
    if (!_controller.hasClients) return;
    final from = _keyboardTarget ?? _controller.selectedItem;
    var target = index;
    if (widget.loop) {
      // 같은 값 중 가까운 쪽
      var delta = index - _indexOf(from);
      if (delta > _count / 2) delta -= _count;
      if (delta < -_count / 2) delta += _count;
      target = from + delta;
    }
    _moveToPhysical(target, smooth: smooth, jump: jump);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    // 누르고 있으면(repeat) 바로바로, 아니면 부드럽게
    final smooth = event is! KeyRepeatEvent;
    final from = _keyboardTarget ?? _controller.selectedItem;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveToIndex(_indexOf(from) - 1, smooth: smooth);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _moveToIndex(_indexOf(from) + 1, smooth: smooth);
    } else if (key == LogicalKeyboardKey.home) {
      _moveToIndex(0, smooth: smooth, jump: true);
    } else if (key == LogicalKeyboardKey.end) {
      _moveToIndex(_count - 1, smooth: smooth, jump: true);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// 눌렀다 — 누른 자리의 항목을 가운데로. 그 항목의 물리 번호 = (스크롤 + 누른 높이 − 가운데 + 항목 반)을 항목 높이로 나눈 몫.
  void _onTapUp(TapUpDetails details, double height) {
    if (!_controller.hasClients) return;
    final item = _itemExtent;
    final physical =
        ((_controller.offset +
                    details.localPosition.dy -
                    height / 2 +
                    item / 2) /
                item)
            .floor();
    if (!widget.loop && (physical < 0 || physical >= _count)) return;
    if (physical == _controller.selectedItem && _centered(physical)) return;
    _keyboardTarget = null;
    _moveToPhysical(physical);
  }

  // ── 그리기 ────────────────────────────────────────────────────

  TextStyle _textStyle(Color color) => _sizes[_scopeSize]!.text.copyWith(
    fontWeight: FontWeight.w500,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );

  Alignment get _alignment => switch (widget.align) {
    PWheelPickerAlign.left => Alignment.centerLeft,
    PWheelPickerAlign.center => Alignment.center,
    PWheelPickerAlign.right => Alignment.centerRight,
  };

  /// 항목 하나 — 높이 · 좌우 여백 · 정렬 · 글(한 줄, 글자 크기 설정을 따르지 않는다).
  Widget _item(int index, Color color) => SizedBox(
    height: _itemExtent,
    child: Align(
      alignment: _alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _itemPaddingX),
        child: Text(
          widget.options[index].label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textScaler: TextScaler.noScaling,
          style: _textStyle(color),
        ),
      ),
    ),
  );

  /// 칼럼 폭 — 항목 글 중 가장 넓은 것 + 좌우 16.
  double _columnWidth(BuildContext context) {
    if (widget.width != null) return widget.width!;
    final cached = _labelWidth;
    if (cached != null && cached.size == _scopeSize) return cached.width;
    final width = () {
      var widest = 0.0;
      final direction = Directionality.of(context);
      for (final option in widget.options) {
        final painter = TextPainter(
          text: TextSpan(
            text: option.label,
            style: _textStyle(const Color(0xFF000000)),
          ),
          textDirection: direction,
          textScaler: TextScaler.noScaling,
          maxLines: 1,
        )..layout();
        widest = math.max(widest, painter.width);
        painter.dispose();
      }
      return widest + 2 * _itemPaddingX;
    }();
    _labelWidth = (size: _scopeSize, width: width);
    return width;
  }

  /// 띠에 걸친 부분 — 지금 스크롤에서 띠와 겹치는 항목(많아야 둘)을 고른 색으로, 띠 높이만 잘라 그린다.
  Widget _selectedLayer(Color color, int initialPhysical) {
    final item = _itemExtent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pixels = _controller.hasClients
            ? _controller.offset
            : initialPhysical * item;
        final first = (pixels / item).floor();
        return ClipRect(
          key: const ValueKey('wheel-selected-layer'),
          child: SizedBox(
            height: item,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final p in [first, first + 1])
                  if (widget.loop || (p >= 0 && p < _count))
                    Positioned(
                      top: p * item - pixels,
                      left: 0,
                      right: 0,
                      height: item,
                      child: _item(_indexOf(p), color),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = _WheelScope.of(context);
    _scopeSize = scope.size;
    final c = context.colors;
    final item = _itemExtent;
    final height = item * scope.visibleItems;
    final disabled = scope.disabled;
    final width = _columnWidth(context);
    final current = _current;
    final logical = _logicalOf(current);
    final options = widget.options;
    final canUp = widget.loop || logical > 0;
    final canDown = widget.loop || logical < _count - 1;
    String say(int index) =>
        options[index].semanticLabel ?? options[index].label;
    final initial = _controller.initialItem;

    final children = [for (var i = 0; i < _count; i++) _item(i, c.fgDisabled)];
    Widget wheel = ListWheelScrollView.useDelegate(
      controller: _controller,
      physics: disabled
          ? const NeverScrollableScrollPhysics()
          : const FixedExtentScrollPhysics(),
      itemExtent: item,
      // 평평한 휠 — 항목이 곧은 줄로 선다(원통으로 휘지 않는다)
      diameterRatio: 100,
      perspective: 0.0001,
      useMagnifier: false,
      overAndUnderCenterOpacity: 1,
      onSelectedItemChanged: _onSelectedItem,
      childDelegate: widget.loop
          ? ListWheelChildLoopingListDelegate(children: children)
          : ListWheelChildListDelegate(children: children),
    );
    wheel = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: wheel,
    );
    // 띠 안은 띠 위 글자가 그리므로 띠 밖만 그린다 — 그리기만 자르고 눌리는 자리는 그대로다
    wheel = _BandPunch(band: item, child: wheel);
    wheel = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: disabled ? null : (d) => _onTapUp(d, height),
      child: wheel,
    );

    return SizedBox(
      width: width,
      height: height,
      child: Semantics(
        container: true,
        label: widget.semanticLabel,
        value: say(logical),
        enabled: !disabled,
        increasedValue: canDown
            ? say(widget.loop ? (logical + 1) % _count : logical + 1)
            : null,
        decreasedValue: canUp
            ? say(widget.loop ? (logical - 1 + _count) % _count : logical - 1)
            : null,
        onIncrease: disabled || !canDown ? null : () => _step(1),
        onDecrease: disabled || !canUp ? null : () => _step(-1),
        child: Focus(
          focusNode: _focusNode,
          canRequestFocus: !disabled,
          onKeyEvent: disabled ? null : _onKey,
          child: MouseRegion(
            cursor: disabled
                ? SystemMouseCursors.basic
                : SystemMouseCursors.grab,
            child: Stack(
              children: [
                Positioned.fill(child: ExcludeSemantics(child: wheel)),
                Positioned(
                  left: 0,
                  right: 0,
                  top: (height - item) / 2,
                  height: item,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: _selectedLayer(
                        disabled ? c.fgDisabled : c.fgNeutral,
                        initial,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 가운데 [band] 높이 줄만 빼고 그린다 — 자식은 늘 그대로 눌린다(그리기만 자르는 것이라 띠 위에서 끌어도 휠이 구른다).
class _BandPunch extends SingleChildRenderObjectWidget {
  const _BandPunch({required this.band, required Widget child})
    : super(child: child);

  final double band;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBandPunch(band);

  @override
  void updateRenderObject(BuildContext context, _RenderBandPunch renderObject) {
    renderObject.band = band;
  }
}

class _RenderBandPunch extends RenderProxyBox {
  _RenderBandPunch(this._band);

  double _band;
  set band(double value) {
    if (value == _band) return;
    _band = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final top = (size.height - _band) / 2;
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(Rect.fromLTWH(0, top, size.width, _band));
    context.pushClipPath(
      needsCompositing,
      offset,
      Offset.zero & size,
      path,
      super.paint,
    );
  }
}
