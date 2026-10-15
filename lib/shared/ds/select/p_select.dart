import 'dart:math' as math;

import 'package:flutter/rendering.dart' show SemanticsValidationResult;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/checkbox/selection_control.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/input/text_control.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

/// 선택지 하나 — 값 · 글 · 설명(한 줄) · 앞 아이콘. 글은 명사형으로 짧게, 코드값(`Y` · `ANNUAL`)을 글로 내지 않는다.
/// 앞 아이콘은 묶음 안에서 모두 두거나 모두 뺀다(아이콘만으로 뜻을 알리지 않는다).
@immutable
class PSelectItem<T> {
  const PSelectItem({
    required this.value,
    required this.label,
    this.description,
    this.prefixIcon,
    this.enabled = true,
  });

  final T value;
  final String label;

  /// 한 줄 설명 — 시트의 줄에만 보이고 칸에는 보이지 않는다.
  final String? description;

  /// 앞 아이콘 — 고르면 칸의 앞 아이콘이 이것으로 바뀐다.
  final IconData? prefixIcon;

  /// false 면 이 선택지만 막힌다.
  final bool enabled;
}

/// 묶음 — 성격이나 정렬 기준이 다른 선택지를 나눈다. 제목은 없어도 된다. 묶음이 둘 이상이면 사이에 선을 저절로 긋는다.
@immutable
class PSelectGroup<T> {
  const PSelectGroup({this.label, required this.items});

  final String? label;
  final List<PSelectItem<T>> items;
}

// select.yaml — 앱은 늘 large(medium 40 · responsive 는 1280 이상 데스크톱 웹 몫이다)
const double _triggerMinHeight = 52;
const double _triggerRadius = PRounded.r3;
const double _triggerPaddingX = PSpacing.x4;
const double _triggerGap = PSpacing.x2_5;
const double _iconSize = 20; // prefixIcon · chevron

// 목록 — select.yaml content · item · groupLabel · divider (large)
const double _contentRadius = PRounded.r5;
const double _contentPaddingY = PSpacing.x2;
const double _contentGap = PSpacing.x2; // 묶음 사이 — 선 위 8 · 선 · 아래 8
const double _contentOffset = PSpacing.x2; // 트리거와의 거리 · 화면 가장자리와의 거리
const double _contentMaxHeight = 480;
const double _contentMinHeight = 200; // 남은 화면이 좁아도 이만큼은 둔다
const double _itemPaddingX = PSpacing.x4;
const double _itemPaddingY = PSpacing.x3;
const double _itemGap = PSpacing.x3;
const double _itemIconSize = 22;
const double _indicatorSize = 14;
const double _highlightInset = PSpacing.x2; // 알약 좌우 들임
const double _groupLabelPaddingY = PSpacing.x2_5;

/// Select — 짧은 선택지 5개 이상에서 폼에 넣을 값을 고르는 칸. 구조는 SEED Select(2026-10-01), 수치 원본은 porest-design
/// `specs/components/select.yaml`(값은 `test/fixtures/design_spec/select.json` — 테스트가 위젯이 그 값과 같은지 본다).
/// 웹(desk-front `src/shared/ds/select`)과 같은 칸이다.
///
/// 목록은 폰에서도 **칸 아래에 붙는다**(시트로 바꾸지 않는다 — SEED). 아래가 모자라면 위로 열리고, 화면 가장자리와는 8을
/// 둔다. 시트가 필요한 달력 · 시각 · 검색해 고르는 긴 목록은 Input Button 이 연다.
///
/// 라벨 · 설명 · 오류는 [PField] 가 둘레에서 그린다 — 늘 Field 의 라벨과 함께 쓴다(Field 밖이면 [semanticLabel] 이 이름).
///   칸 — 투명 바탕 · 안쪽 1px stroke-neutral-weak · 높이 52 · 모서리 12 · 좌우 16 · 값 t5. 누르면 바탕이 누름 색이 되고
///   값 · 아이콘만 2px 거리 줄어든다. 오류는 안쪽 2px stroke-critical-solid, 비활성 · 읽기 전용은 bg-disabled(흐리게 하지 않는다).
///   비활성 글자 · 아이콘은 fg-disabled, 읽기 전용은 진한 글자 그대로 — 포커스는 되고 열리지 않는다. 목록이 열려 있는 동안
///   셰브론이 180° 돈다(열 때 150ms · 닫을 때 100ms). 열린 채 막히면 닫힌다.
///   목록 — 칸 폭 그대로 · 칸 아래 8(모자라면 위) · 모서리 20 · bg-layer-floating · shadow-s3 · 높이는 min(480, 남은 화면)
///   (200 보다 좁지 않다), 넘치면 목록 안에서 스크롤. 선택지 글은 자르지 않고 줄바꿈하고 칸만 한 줄로 말줄임한다.
///   선택지는 46(설명이 있으면 66) · 좌우 16 · 앞 아이콘 22 · 고른 선택지는 오른쪽 체크 14(바탕 · 굵기는 그대로). 누르면
///   좌우 8 들어온 알약(모서리 12)이 서고 콘텐츠만 2px 거리 줄어든다. 묶음이 둘 이상이면 사이에 선을 긋는다.
/// 값 — 하나 고르기는 고른 선택지의 글. 여럿 고르기([PSelect.multiple])는 고른 순서대로 ", " 로 잇고, 칸 폭을 넘으면
///   [overflowLabel] 로 "첫 값 외 N개" 꼴로 줄인다(글은 호출하는 쪽이 정한다 — 없으면 말줄임). 목록에 없는 값이면 placeholder.
/// 앞 아이콘 — 하나를 골랐으면 그 선택지의 아이콘(없으면 [prefixIcon]), 둘 이상이거나 없으면 [prefixIcon].
/// 하나 고르기는 고르면 목록이 닫히고, 고른 선택지를 다시 눌러도 풀리지 않는다("없음" 은 "{칸 이름} 없음" 선택지로 둔다).
/// 여럿 고르기는 목록이 열린 채로 남고 다시 누르면 풀린다.
/// 닫기 — 바깥 누르기 · 뒤로 가기 · Esc · Tab. 키보드 — 칸에서 ↓ ↑ Enter Space 로 열고, 목록에서 ↓ ↑ 로 선택지를 짚고(막힌
/// 선택지는 건너뛴다) Enter · Space 로 고른다. 읽기 — 칸은 버튼이고 이름은 Field 의 라벨(없으면 [semanticLabel]), 값은
/// 고른 글이다. 목록은 listbox, 선택지는 선택 여부를 읽는다.
class PSelect<T> extends StatefulWidget {
  /// 하나 고르기.
  const PSelect({
    super.key,
    required this.groups,
    required this.value,
    required ValueChanged<T>? onChanged,
    required this.placeholder,
    this.prefixIcon,
    this.semanticLabel,
    this.disabled,
    this.readOnly,
    this.invalid,
    this.focusNode,
  }) : multiple = false,
       values = const [],
       _onChanged = onChanged,
       _onChangedMany = null,
       overflowLabel = null,
       formatValue = null;

  /// 여럿 고르기 — [values] 는 고른 순서대로 쌓인다.
  const PSelect.multiple({
    super.key,
    required this.groups,
    required this.values,
    required ValueChanged<List<T>>? onChanged,
    required this.placeholder,
    this.overflowLabel,
    this.formatValue,
    this.prefixIcon,
    this.semanticLabel,
    this.disabled,
    this.readOnly,
    this.invalid,
    this.focusNode,
  }) : multiple = true,
       value = null,
       _onChanged = null,
       _onChangedMany = onChanged;

  final List<PSelectGroup<T>> groups;
  final bool multiple;

  /// 고른 값(하나 고르기) — 없으면 고르지 않았다.
  final T? value;

  /// 고른 값들(여럿 고르기).
  final List<T> values;

  final ValueChanged<T>? _onChanged;
  final ValueChanged<List<T>>? _onChangedMany;

  /// 고르기 전의 글 — "{값의 종류} 선택"("결제 수단 선택"). 라벨만 그대로 두지 않는다.
  final String placeholder;

  /// 여럿을 골라 칸 폭을 넘을 때의 글 — (첫 값, 나머지 개수) → "식비 외 2개". 없으면 말줄임.
  final String Function(String first, int others)? overflowLabel;

  /// 여럿 고른 값의 글을 바꾼다 — 고른 순서대로 받는다(필터의 "식비 또는 교통" 처럼 접속사로 잇는 자리).
  final String Function(List<PSelectItem<T>> selected)? formatValue;

  /// 칸 앞 아이콘 — 어떤 종류의 값을 고르는 자리인지 알린다.
  final IconData? prefixIcon;

  /// Field 밖에서의 이름(웹 aria-label).
  final String? semanticLabel;

  /// 막는다 · 읽기 전용 · 오류 — null 이면 Field 의 값.
  final bool? disabled;
  final bool? readOnly;
  final bool? invalid;
  final FocusNode? focusNode;

  @override
  State<PSelect<T>> createState() => _PSelectState<T>();
}

class _PSelectState<T> extends State<PSelect<T>>
    with SingleTickerProviderStateMixin {
  FocusNode? _ownFocusNode;
  PFieldScope? _scope;
  bool _pressed = false;
  bool _open = false;

  final OverlayPortalController _portal = OverlayPortalController(
    debugLabel: 'PSelect',
  );
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: PDuration.d3,
    reverseDuration: PDuration.d2,
  );

  /// 칸과 목록을 한 영역으로 묶는다 — 칸을 누르는 것은 "바깥" 이 아니다(칸이 스스로 여닫는다).
  final Object _tapGroup = Object();
  final FocusNode _listNode = FocusNode(debugLabel: 'PSelect list');
  final GlobalKey _firstSelected = GlobalKey();

  /// 키보드로 짚은 선택지(마우스 · 터치는 짚지 않는다).
  final ValueNotifier<int?> _highlight = ValueNotifier<int?>(null);

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  PFieldControlData? get _field => _scope?.data;
  bool get _disabled => widget.disabled ?? _field?.disabled ?? false;
  bool get _readOnly => widget.readOnly ?? _field?.readOnly ?? false;
  bool get _invalid => widget.invalid ?? _field?.invalid ?? false;
  bool get _required => _field?.required ?? false;
  bool get _canOpen => !_disabled && !_readOnly;

  List<T> get _selection => widget.multiple
      ? widget.values
      : [if (widget.value != null) widget.value as T];

  List<PSelectItem<T>> get _items => [
    for (final g in widget.groups) ...g.items,
  ];

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !_open && _portal.isShowing) {
        _portal.hide();
      }
    });
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
  void didUpdateWidget(PSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _scope?.link.detach(oldWidget.focusNode ?? _ownFocusNode!);
      _scope?.link.attach(_focusNode);
    }
    if (!_canOpen) {
      _pressed = false;
      // 열린 채 막히면 닫힌다
      if (_open) WidgetsBinding.instance.addPostFrameCallback((_) => _close());
    }
  }

  @override
  void dispose() {
    _scope?.link.detach(_focusNode);
    _ownFocusNode?.dispose();
    _listNode.dispose();
    _highlight.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── 값 ──────────────────────────────────────────────────

  /// 고른 선택지 — 고른 순서대로. 목록에 없는 값은 건너뛴다.
  List<PSelectItem<T>> _selectedItems() {
    final items = _items;
    return [
      for (final v in _selection)
        for (final item in items)
          if (item.value == v) item,
    ];
  }

  String get _name =>
      widget.semanticLabel ?? _field?.label ?? widget.placeholder;

  void _pick(PSelectItem<T> item) {
    if (!item.enabled) return;
    if (widget.multiple) {
      final onChanged = widget._onChangedMany;
      if (onChanged == null) return;
      final now = widget.values;
      onChanged(
        now.contains(item.value)
            ? [
                for (final v in now)
                  if (v != item.value) v,
              ]
            : [...now, item.value],
      );
      setState(() {});
    } else {
      // 이미 고른 선택지를 다시 눌러도 풀리지 않는다
      if (widget.value != item.value) widget._onChanged?.call(item.value);
      _close();
    }
  }

  // ── 열기 · 닫기 ─────────────────────────────────────────

  void _openList({bool byKeyboard = false}) {
    if (!_canOpen || _open) return;
    setState(() => _open = true);
    _portal.show();
    _anim.forward();
    final items = _items;
    final first = items.indexWhere(
      (i) => _selection.contains(i.value) && i.enabled,
    );
    // 키로 열면 고른 선택지(없으면 첫 선택지)를 짚는다 — 포인터로 열면 스크롤만 하고 미리 짚지 않는다
    _highlight.value = byKeyboard
        ? (first >= 0 ? first : items.indexWhere((i) => i.enabled))
        : null;
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_open) return;
      _listNode.requestFocus();
      final target = _firstSelected.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.5);
    });
  }

  void _close({bool returnFocus = true}) {
    if (!_open) return;
    setState(() => _open = false);
    _highlight.value = null;
    _anim.reverse();
    if (returnFocus) _focusNode.requestFocus();
  }

  void _move(int step) {
    final items = _items;
    var i = _highlight.value ?? (step > 0 ? -1 : items.length);
    for (var n = 0; n < items.length; n++) {
      i += step;
      if (i < 0 || i >= items.length) return;
      if (items[i].enabled) {
        _highlight.value = i;
        return;
      }
    }
  }

  KeyEventResult _onListKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final items = _items;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.home) {
      _highlight.value = items.indexWhere((i) => i.enabled);
    } else if (key == LogicalKeyboardKey.end) {
      _highlight.value = items.lastIndexWhere((i) => i.enabled);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final at = _highlight.value;
      if (at != null) _pick(items[at]);
    } else if (key == LogicalKeyboardKey.escape) {
      _close();
    } else if (key == LogicalKeyboardKey.tab) {
      // Tab 은 닫고 포커스를 다음 칸으로 보낸다
      _close(returnFocus: false);
      return KeyEventResult.ignored;
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ── 그리기 ──────────────────────────────────────────────

  Widget _list(BuildContext context, OverlayChildLayoutInfo info) {
    final target = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final selection = _selection;
    final multiple = widget.multiple;
    var keyed = false;
    var index = 0;

    final children = <Widget>[];
    for (final (g, group) in widget.groups.indexed) {
      if (g > 0) {
        children
          ..add(const SizedBox(height: _contentGap))
          ..add(const _GroupDivider())
          ..add(const SizedBox(height: _contentGap));
      }
      final rows = <Widget>[];
      if (group.label != null) rows.add(_GroupLabel(group.label!));
      for (final item in group.items) {
        final at = index++;
        final on = selection.contains(item.value);
        final key = on && !keyed ? _firstSelected : null;
        if (key != null) keyed = true;
        rows.add(
          _ItemRow(
            key: key,
            item: item,
            selected: on,
            multiple: multiple,
            highlight: _highlight,
            index: at,
            onTap: () => _pick(item),
          ),
        );
      }
      children.add(
        Semantics(
          container: true,
          label: group.label,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        ),
      );
    }

    final c = context.colors;
    Widget list = DecoratedBox(
      key: const ValueKey('select-content-box'),
      decoration: BoxDecoration(
        color: c.bgLayerFloating,
        borderRadius: BorderRadius.circular(_contentRadius),
        boxShadow: context.shadows.s3,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_contentRadius),
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: _contentPaddingY),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    list = Semantics(
      container: true,
      explicitChildNodes: true,
      label: _name,
      child: list,
    );
    list = Focus(focusNode: _listNode, onKeyEvent: _onListKey, child: list);
    list = TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) => _close(returnFocus: false),
      child: list,
    );

    // 열 때 0.95 → 1 · 투명 → 불투명(붙은 쪽에서 커진다), 닫을 때 반대. 모션 줄이기면 투명도만
    final screen = media.size;
    final below = screen.height - target.bottom >= target.top; // 더 넓은 쪽이 목록 자리
    list = AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = (_open ? PEasing.enter : PEasing.exit).transform(_anim.value);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: reduceMotion ? 1 : 0.95 + 0.05 * t,
            alignment: below ? Alignment.topCenter : Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: list,
    );

    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _ListLayout(target: target, safe: media.padding),
        child: list,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = _disabled;
    final readOnly = _readOnly;
    final selected = _selectedItems();
    final pressed = _pressed && _canOpen;

    // 앞 아이콘 — 하나를 골랐으면 그 선택지의 것(없으면 칸의 것)
    final icon = selected.length == 1
        ? (selected.first.prefixIcon ?? widget.prefixIcon)
        : widget.prefixIcon;
    final iconColor = disabled ? c.fgDisabled : c.fgNeutralMuted;
    final valueStyle = PTypography.t5.copyWith(
      color: disabled ? c.fgDisabled : c.fgNeutral,
    );
    final placeholderStyle = PTypography.t5.copyWith(
      color: disabled ? c.fgDisabled : c.fgPlaceholder,
    );

    final Widget valueText = selected.isEmpty
        ? Text(
            widget.placeholder,
            key: const ValueKey('select-value'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: placeholderStyle,
          )
        : _SummaryText(
            key: const ValueKey('select-value'),
            labels: [for (final i in selected) i.label],
            text: widget.formatValue?.call(selected),
            overflowLabel: widget.overflowLabel,
            style: valueStyle,
          );

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final restBackground = disabled || readOnly
        ? c.bgDisabled
        : const Color(0x00000000);

    Widget content = LayoutBuilder(
      builder: (context, constraints) => SelectionPressScale(
        pressed: pressed,
        size: Size(constraints.maxWidth, _triggerMinHeight),
        child: Padding(
          key: const ValueKey('select-content'),
          padding: const EdgeInsets.symmetric(horizontal: _triggerPaddingX),
          child: Row(
            spacing: _triggerGap,
            children: [
              if (icon != null)
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    key: const ValueKey('select-prefix-icon'),
                    size: _iconSize,
                    color: iconColor,
                  ),
                ),
              Expanded(child: valueText),
              ExcludeSemantics(
                child: AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  // 열 때 150ms · 닫을 때 100ms
                  duration: reduceMotion
                      ? Duration.zero
                      : _open
                      ? PDuration.d3
                      : PDuration.d2,
                  curve: PEasing.easing,
                  child: Icon(
                    LucideIcons.chevronDown,
                    key: const ValueKey('select-chevron'),
                    size: _iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _triggerMinHeight),
      child: Align(
        alignment: Alignment.centerLeft,
        heightFactor: 1,
        child: content,
      ),
    );

    final frame = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: pressed ? 1 : 0),
      duration: reduceMotion ? Duration.zero : PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, t, child) => PTextFrame(
        key: const ValueKey('select-trigger'),
        underline: false,
        radius: _triggerRadius,
        // 누름 색은 투명에서 나타난다 — 투명한 검정을 거치지 않게 같은 색의 투명으로 섞는다
        background: restBackground.a == 0
            ? Color.lerp(
                c.bgLayerDefaultPressed.withValues(alpha: 0),
                c.bgLayerDefaultPressed,
                t,
              )!
            : restBackground,
        emphasis: _invalid ? c.strokeCriticalSolid : null,
        child: child!,
      ),
      child: content,
    );

    Widget trigger = Semantics(
      container: true,
      button: true,
      enabled: !disabled,
      focusable: !disabled,
      expanded: _open,
      readOnly: readOnly,
      isRequired: _required ? true : null,
      validationResult: _invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      label: _name,
      value: selected.isEmpty
          ? null
          : (widget.formatValue?.call(selected) ??
                selected.map((i) => i.label).join(', ')),
      hint: selected.isEmpty ? widget.placeholder : null,
      onTap: _canOpen ? _openList : null,
      excludeSemantics: true,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): _OpenIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): _OpenIntent(),
          SingleActivator(LogicalKeyboardKey.enter): _OpenIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): _OpenIntent(),
          SingleActivator(LogicalKeyboardKey.space): _OpenIntent(),
        },
        child: Actions(
          actions: {
            _OpenIntent: CallbackAction<_OpenIntent>(
              onInvoke: (_) {
                if (_open) {
                  _close();
                } else {
                  _openList(byKeyboard: true);
                }
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: _focusNode,
            canRequestFocus: !disabled,
            child: MouseRegion(
              cursor: disabled
                  ? SystemMouseCursors.forbidden
                  : readOnly
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapDown: _canOpen
                    ? (_) => setState(() => _pressed = true)
                    : null,
                onTapUp: _canOpen
                    ? (_) => setState(() => _pressed = false)
                    : null,
                onTapCancel: _canOpen
                    ? () => setState(() => _pressed = false)
                    : null,
                onTap: _canOpen
                    ? (_open ? _close : _openList)
                    : disabled
                    ? null
                    : _focusNode.requestFocus,
                child: frame,
              ),
            ),
          ),
        ),
      ),
    );

    trigger = TapRegion(groupId: _tapGroup, child: trigger);
    // 뒤로 가기 — 열려 있으면 목록만 닫는다
    trigger = PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: trigger,
    );
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: _list,
      child: trigger,
    );
  }
}

class _OpenIntent extends Intent {
  const _OpenIntent();
}

/// 목록 자리 — 칸 폭 그대로 칸 아래 8, 모자라면 위. 높이는 min(480, 남은 화면)이고 남은 화면이 200 보다 좁아도 200 은 둔다.
/// 화면 가장자리와는 8(안전 영역이 있으면 그 값 — 더 큰 쪽)을 둔다.
class _ListLayout extends SingleChildLayoutDelegate {
  _ListLayout({required this.target, required this.safe});

  final Rect target;
  final EdgeInsets safe;

  double _top(Size size) => math.max(safe.top, _contentOffset);
  double _bottom(Size size) =>
      size.height - math.max(safe.bottom, _contentOffset);

  double _roomBelow(Size size) =>
      _bottom(size) - (target.bottom + _contentOffset);
  double _roomAbove(Size size) => target.top - _contentOffset - _top(size);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final room = math.max(_roomBelow(size), _roomAbove(size));
    final height = math.max(
      _contentMinHeight,
      math.min(_contentMaxHeight, room),
    );
    return BoxConstraints(
      minWidth: target.width,
      maxWidth: target.width,
      maxHeight: height,
    );
  }

  bool _below(Size size, Size child) =>
      child.height <= _roomBelow(size) || _roomBelow(size) >= _roomAbove(size);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = _below(size, childSize);
    final top = below
        ? target.bottom + _contentOffset
        : math.max(_top(size), target.top - _contentOffset - childSize.height);
    return Offset(target.left, top);
  }

  @override
  bool shouldRelayout(_ListLayout old) =>
      target != old.target || safe != old.safe;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;
}

/// 칸의 값 글 — 한 줄. 여럿이면 ", " 로 잇고, 칸 폭을 넘으면 [overflowLabel] 로 "첫 값 외 N개" 로 줄인다.
class _SummaryText extends StatelessWidget {
  const _SummaryText({
    super.key,
    required this.labels,
    required this.text,
    required this.overflowLabel,
    required this.style,
  });

  final List<String> labels;

  /// 호출하는 쪽이 정한 글 — 있으면 그대로(넘치면 말줄임).
  final String? text;
  final String Function(String first, int others)? overflowLabel;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final joined = text ?? labels.join(', ');
    final shorten = overflowLabel;
    return LayoutBuilder(
      builder: (context, constraints) {
        var shown = joined;
        if (text == null && shorten != null && labels.length > 1) {
          final painter = TextPainter(
            text: TextSpan(text: joined, style: style),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final over = painter.didExceedMaxLines;
          painter.dispose();
          if (over) shown = shorten(labels.first, labels.length - 1);
        }
        return Text(
          shown,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

/// 묶음 제목 — 14/19 · 500 · fg-neutral-subtle · 좌우 16 · 위아래 10.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _itemPaddingX,
        vertical: _groupLabelPaddingY,
      ),
      child: Text(
        keepAll(label),
        semanticsLabel: label,
        key: const ValueKey('select-group-label'),
        style: PTypography.t4.copyWith(
          color: context.colors.fgNeutralSubtle,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 묶음 사이 선 — 1px · stroke-neutral-subtle · 좌우 16. 선택지 사이에는 없다.
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('select-divider'),
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: _itemPaddingX),
        color: context.colors.strokeNeutralSubtle,
      ),
    );
  }
}

/// 선택지 한 줄 — 46(설명이 있으면 66). 바탕 층(알약 — 누름 · 키보드 위치, 줄지 않는다)과 콘텐츠 층(앞 아이콘 · 글 · 체크,
/// 누르면 2px 거리 줄어든다). 알약은 좌우 8 들어오고 글은 줄 가장자리에서 16 에서 시작한다. 막힌 선택지는 알약이 서지 않는다.
class _ItemRow<T> extends StatefulWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.selected,
    required this.multiple,
    required this.highlight,
    required this.index,
    required this.onTap,
  });

  final PSelectItem<T> item;
  final bool selected;
  final bool multiple;
  final ValueListenable<int?> highlight;
  final int index;
  final VoidCallback onTap;

  @override
  State<_ItemRow<T>> createState() => _ItemRowState<T>();
}

class _ItemRowState<T> extends State<_ItemRow<T>> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = widget.item;
    final enabled = item.enabled;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final labelColor = enabled ? c.fgNeutral : c.fgDisabled;
    final descColor = enabled ? c.fgNeutralSubtle : c.fgDisabled;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _itemPaddingX,
        vertical: _itemPaddingY,
      ),
      child: Row(
        spacing: _itemGap,
        children: [
          if (item.prefixIcon != null)
            ExcludeSemantics(
              child: Icon(
                item.prefixIcon,
                key: const ValueKey('select-item-icon'),
                size: _itemIconSize,
                color: labelColor,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x0_5,
              children: [
                // 선택지 글은 목록 안에서 줄바꿈된다(자르지 않는다)
                Text(
                  keepAll(item.label),
                  key: const ValueKey('select-item-label'),
                  style: PTypography.t5.copyWith(color: labelColor),
                ),
                if (item.description != null)
                  Text(
                    keepAll(item.description!),
                    key: const ValueKey('select-item-description'),
                    style: PTypography.t3.copyWith(color: descColor),
                  ),
              ],
            ),
          ),
          // 고른 선택지에만 — 고르지 않으면 체크도 자리도 없다
          if (widget.selected)
            ExcludeSemantics(
              child: Icon(
                LucideIcons.check500,
                key: const ValueKey('select-item-indicator'),
                size: _indicatorSize,
                color: enabled ? c.fgNeutral : c.fgDisabled,
              ),
            ),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: widget.selected,
      checked: widget.multiple ? widget.selected : null,
      label: item.description == null
          ? item.label
          : '${item.label}, ${item.description}',
      onTap: enabled ? widget.onTap : null,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          key: const ValueKey('select-item'),
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onTap : null,
          child: ValueListenableBuilder<int?>(
            valueListenable: widget.highlight,
            builder: (context, at, _) {
              final pill = enabled && (_pressed || at == widget.index);
              return Stack(
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: pill ? 1 : 0),
                      duration: reduceMotion
                          ? Duration.zero
                          : PDuration.colorTransition,
                      curve: PEasing.easing,
                      builder: (context, t, _) => Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _highlightInset * t,
                        ),
                        child: DecoratedBox(
                          key: const ValueKey('select-item-highlight'),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              c.bgLayerFloatingPressed.withValues(alpha: 0),
                              c.bgLayerFloatingPressed,
                              t,
                            ),
                            borderRadius: BorderRadius.circular(PRounded.r3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 콘텐츠 층 — 누르는 동안만 준다(키보드 위치는 축소 없음)
                  LayoutBuilder(
                    builder: (context, constraints) => AnimatedScale(
                      key: const ValueKey('select-item-content'),
                      scale: _pressed && enabled && !reduceMotion
                          ? SelectionPressScale.scaleOf(
                              Size(constraints.maxWidth, 46),
                            )
                          : 1,
                      duration: PDuration.pressedScale,
                      curve: PEasing.pressedScale,
                      child: content,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
