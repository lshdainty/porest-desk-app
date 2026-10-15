import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

// List 의 줄 틀 — 줄의 종류(보기만 · 누르는 · 링크 · 컨트롤 · 부모)가 함께 쓰는 짜임. 화면에서 직접 쓰지 않는다 —
// PListItem · PListButtonItem · PListLinkItem · PListSwitchItem · PListCheckItem · PListRadioItem · PListParentItem
// (p_list.dart · p_list_parent_item.dart)이 이 틀에 줄의 종류만 얹는다. 수치 원본은 porest-design
// `specs/components/list.yaml`(값은 `test/fixtures/design_spec/list.json`), 웹은 desk-front `src/shared/ds/list`.

/// 맞춤 — center(기본: 앞 · 뒤가 본문의 세로 가운데) · top(제목이 두 줄을 넘거나 설명이 길 때 — 위에 맞춘다). 한 목록
/// 안에서는 줄마다 섞지 않는다.
enum PListAlign { center, top }

/// 단계 — none(단계 없는 목록, 기본) · parent(맨 위 단계 줄 — 앞에 꺾쇠 자리 52) · child(하위 줄 — 부모의 제목
/// 자리 104).
enum PListNest { none, parent, child }

/// 하위 줄(nest=child)의 들임 — 부모의 제목 자리 = 4 + 꺾쇠 44 + 4 + 타일 40 + 12(사용자 결정 17B). 토큰에 없다(list.yaml
/// 이 104 로 적는다).
const double kPListChildStart = 104;

/// 앞 아이콘(설정 · 메뉴 줄)의 크기 — 간격 토큰에 22 가 없다(list.yaml icon.size 22).
const double kPListIconSize = 22;

/// 꺾쇠 단추 자리 — 보이는 상자 44 + 단추 뒤 4(부모 줄의 앞 붙이개가 52 에서 시작한다).
const double kPListExpandSlot = PTouch.min + PSpacing.x1;

/// 본문 최소 폭 — 1em(본문 글자 크기) + 뒤 여백 10(list.yaml body.minWidth `1em`, 뒤 여백은 따로).
final double kPListBodyMinWidth = PTypography.t5.fontSize! + PSpacing.x2_5;

/// 부모 줄의 최소 콘텐츠 높이 — 꺾쇠 단추(44)가 위아래 2 를 줄의 여백에 겹쳐 타일 40 줄의 높이(64)를 그대로 둔다.
const double kPListExpandSlotHeight = PTouch.min - 2 * PSpacing.x0_5;

/// 목록(PList · 묶음)이 줄에 넘기는 값 — 누름 · 호버 바탕의 모서리(카드 안에서는 동심 모서리)와 단계.
class PListScope extends InheritedWidget {
  const PListScope({
    super.key,
    required this.itemRadius,
    required this.nest,
    required super.child,
  });

  /// 누름 바탕의 모서리 — 기본 10. 카드 안에서는 카드 모서리 − 카드 가장자리에서 바탕까지 거리.
  final double itemRadius;
  final PListNest nest;

  static ({double itemRadius, PListNest nest}) of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PListScope>();
    return (
      itemRadius: scope?.itemRadius ?? PRounded.r2_5,
      nest: scope?.nest ?? PListNest.none,
    );
  }

  @override
  bool updateShouldNotify(PListScope oldWidget) =>
      itemRadius != oldWidget.itemRadius || nest != oldWidget.nest;
}

/// 줄 안의 따로 눌리는 것(작은 버튼 · 꺾쇠 단추)이 눌리는 동안을 센다 — 그동안은 줄이 눌린 모습이 되지 않는다.
class PListActionTracker {
  final Set<int> _pointers = {};

  bool get active => _pointers.isNotEmpty;

  void down(int pointer) => _pointers.add(pointer);

  void up(int pointer) => _pointers.remove(pointer);
}

/// 줄이 아래 층(콘텐츠 · 마크)에 넘기는 상태 — 눌림 · 막힘.
class PListRowScope extends InheritedWidget {
  const PListRowScope({
    super.key,
    required this.pressed,
    required this.disabled,
    required this.tracker,
    required super.child,
  });

  final bool pressed;
  final bool disabled;
  final PListActionTracker tracker;

  static PListRowScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PListRowScope>();

  static bool pressedOf(BuildContext context) =>
      maybeOf(context)?.pressed ?? false;

  static bool disabledOf(BuildContext context) =>
      maybeOf(context)?.disabled ?? false;

  @override
  bool updateShouldNotify(PListRowScope oldWidget) =>
      pressed != oldWidget.pressed || disabled != oldWidget.disabled;
}

/// 카탈로그 전용 — 안의 줄(또는 꺾쇠 단추)을 눌린 모습으로 멈춰 그린다. 견본이 누름을 한 장으로 보여 줄 때만 쓴다(실제로는
/// 손가락이 누르는 동안만 눌린다).
class PListPressedPreview extends InheritedWidget {
  const PListPressedPreview({
    super.key,
    this.target = PListPreviewTarget.row,
    required super.child,
  });

  final PListPreviewTarget target;

  /// [target] 을 멈춰 그려야 하는가.
  static bool of(BuildContext context, PListPreviewTarget target) =>
      context
          .dependOnInheritedWidgetOfExactType<PListPressedPreview>()
          ?.target ==
      target;

  @override
  bool updateShouldNotify(PListPressedPreview oldWidget) =>
      target != oldWidget.target;
}

/// [PListPressedPreview] 가 멈춰 그리는 자리 — 줄 · 부모 줄의 꺾쇠 단추.
enum PListPreviewTarget { row, expandButton }

/// 줄이 읽히는 모습 — 보기만 하는 줄 · 누르는 줄(button) · 링크 줄(link)은 본문(제목 + 설명)이 하나의 노드이고, 컨트롤
/// 줄([wholeRow])은 줄 전체가 컨트롤 하나의 노드다(제목 + 설명이 이름, 마크는 읽지 않는다).
@immutable
class PListRowSemantics {
  const PListRowSemantics({
    this.button = false,
    this.link = false,
    this.wholeRow = false,
    this.checked,
    this.mixed,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.selected,
    this.hint,
  });

  final bool button;
  final bool link;

  /// 줄 전체가 하나의 컨트롤 노드(웹의 label — 줄이 라벨이라 제목 + 설명이 컨트롤의 이름이다).
  final bool wholeRow;
  final bool? checked;
  final bool? mixed;
  final bool? toggled;
  final bool inMutuallyExclusiveGroup;
  final bool? selected;
  final String? hint;
}

class _ActivateRowIntent extends Intent {
  const _ActivateRowIntent();
}

/// 줄 — 바탕 층 + 콘텐츠 층(앞 · 본문 · 뒤). 누르는 줄만 눌림 · 막힘이 있다.
///
/// 바탕 층은 줄지 않는다 — 누르면 좌우 6 들어오며 모서리가 10(`itemRadius`)으로 둥글어지고 누름 색으로 바뀐다(150ms).
/// 콘텐츠 층만 세로 2px 거리 줄어든다(기준 길이 max(높이, 폭 ÷ 4, 24) — 줄은 폭 ÷ 4 가 커서 세로로는 2px 보다 덜
/// 준다. 누르는 순간 줄을 잰다). 모션 줄이기면 축소를 뺀다 — 바탕 색 전환은 그대로.
/// 줄 전체가 누르는 영역이다 — 가장자리를 눌러도 눌린다. 줄 안의 작은 버튼 · 꺾쇠 단추는 [PListAction] 으로 감싸
/// 따로 눌린다(그 버튼이 눌리는 동안 줄은 눌린 모습이 되지 않는다).
class PListRowFrame extends StatefulWidget {
  const PListRowFrame({
    super.key,
    required this.title,
    this.detail,
    this.detailChild,
    this.titleColor,
    this.prefix,
    this.suffix,
    this.highlighted = false,
    this.align = PListAlign.center,
    this.nest,
    this.expandButton,
    this.interactive = false,
    this.onActivate,
    this.activateOnEnter = true,
    this.focusNode,
    this.semantics = const PListRowSemantics(),
  }) : assert(
         detail == null || detailChild == null,
         '설명은 글(detail)이나 위젯(detailChild) 하나만 준다',
       );

  final String title;
  final String? detail;

  /// 설명 자리에 글 대신 두는 위젯(Tag Group · 배지 줄) — 글자 모양은 설명(13 · 옅은 색)을 따른다.
  final Widget? detailChild;

  /// 제목 색을 덮는다 — 합계에 안 드는 줄(예정 · 환불)의 `fg-neutral-subtle`. 막힌 줄은 비활성 색이 이긴다.
  final Color? titleColor;
  final Widget? prefix;
  final Widget? suffix;
  final bool highlighted;
  final PListAlign align;

  /// null 이면 목록(PListScope)의 단계 — 부모 줄만 직접 준다.
  final PListNest? nest;

  /// 부모 줄 앞의 꺾쇠 단추(44) — 줄 위에 얹히고 줄과 따로 눌린다. 없으면 같은 폭의 빈 자리.
  final Widget? expandButton;

  /// 누르는 줄(누르는 · 링크 · 컨트롤 · 부모). false 면 보기만 하는 줄 — 눌림 · 포커스가 없다.
  final bool interactive;

  /// 누르면 하는 일 — interactive 인데 null 이면 막힌 줄이다.
  final VoidCallback? onActivate;

  /// Enter 로도 누른다(누르는 줄 · 스위치). 체크 · 라디오의 Enter 는 폼 제출에 둔다.
  final bool activateOnEnter;
  final FocusNode? focusNode;
  final PListRowSemantics semantics;

  @override
  State<PListRowFrame> createState() => _PListRowFrameState();
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

class _PListRowFrameState extends State<PListRowFrame> {
  static const Map<ShortcutActivator, Intent> _spaceOnly = {
    SingleActivator(LogicalKeyboardKey.space): _ActivateRowIntent(),
  };
  static const Map<ShortcutActivator, Intent> _spaceOrEnter = {
    SingleActivator(LogicalKeyboardKey.space): _ActivateRowIntent(),
    SingleActivator(LogicalKeyboardKey.enter): _ActivateRowIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): _ActivateRowIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = {
    _ActivateRowIntent: CallbackAction<_ActivateRowIntent>(
      onInvoke: (_) {
        widget.onActivate?.call();
        return null;
      },
    ),
  };

  final PListActionTracker _tracker = PListActionTracker();
  bool _pressed = false;

  /// 견본이 누름을 멈춰 그리는 중 — 줄 크기를 한 번 잰 뒤에 배율이 정해진다.
  bool _preview = false;
  bool _previewMeasured = false;
  bool _previewReady = false;

  /// 누름 축소의 기준 길이 max(높이, 폭 ÷ 4, 24) — 누르는 순간 그려진 크기에서 잰다.
  double _basis = 24;

  bool get _disabled => widget.interactive && widget.onActivate == null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) {
        _basis = math.max(size.height, math.max(size.width / 4, 24));
      }
    }
    setState(() => _pressed = value);
  }

  void _tapDown(TapDownDetails details) {
    // 안의 작은 버튼 · 꺾쇠 단추가 눌리는 중이면 줄은 눌린 모습이 되지 않는다
    if (_tracker.active) return;
    _setPressed(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preview = PListPressedPreview.of(context, PListPreviewTarget.row);
    if (_preview && !_previewMeasured) {
      _previewMeasured = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final size = context.size;
        if (size == null) return;
        setState(() {
          _basis = math.max(size.height, math.max(size.width / 4, 24));
          _previewReady = true;
        });
      });
    }
  }

  @override
  void didUpdateWidget(PListRowFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 사이 막히면 누름이 남지 않게
    if (_disabled) _pressed = false;
  }

  /// 본문 + 뒤 붙이개(porest-design Q-001 "값이 길 때") — 뒤 붙이개는 값의 종류로 갈린다.
  ///   글([Text]로 넘긴 값) — 본문이 최소 폭(1em + 뒤 여백 10)이 된 뒤에야 줄고, 줄 끝에서 끊어 본문 위로 넘치지 않는다.
  ///   위젯(금액 노드 · 화살표 · 컨트롤 · 작은 버튼) — 줄지 않고 본문이 양보한다. 큰 금액을 줄이는 건 화면 몫이다.
  Widget _bodyAndSuffix(Widget bodyNode, Color detailColor, Color arrowColor) {
    final suffix = widget.suffix;
    if (suffix == null) return bodyNode;
    final isText = suffix is Text;
    final styled = DefaultTextStyle(
      key: const ValueKey('plist-suffix'),
      style: PTypography.t5.copyWith(color: detailColor),
      child: IconTheme(
        data: IconThemeData(size: PSpacing.x4_5, color: arrowColor),
        child: suffix,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // 글 값이 쓸 수 있는 가장 넓은 폭 — 본문 최소 폭을 남긴다
        final textMax = math.max(
          0.0,
          constraints.maxWidth - kPListBodyMinWidth,
        );
        return Row(
          crossAxisAlignment: widget.align == PListAlign.top
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Expanded(child: bodyNode),
            if (isText)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: textMax),
                child: styled,
              )
            else
              styled,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scope = PListScope.of(context);
    final nest = widget.nest ?? scope.nest;
    final disabled = _disabled;
    final pressed = (_pressed || _preview) && !disabled;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // 강조 줄을 누르는 동안 — 짙은 강조 바탕 위라 설명 · 값 글자만 한 단계 짙다(화살표 · 제목은 그대로)
    final muted = widget.highlighted && pressed;

    final titleColor = disabled
        ? c.fgDisabled
        : (widget.titleColor ?? c.fgNeutral);
    final detailColor = disabled
        ? c.fgDisabled
        : muted
        ? c.fgNeutralMuted
        : c.fgNeutralSubtle;
    final iconColor = disabled ? c.fgDisabled : c.fgNeutral;
    final arrowColor = disabled ? c.fgDisabled : c.fgNeutralSubtle;

    final detailStyle = PTypography.t3.copyWith(color: detailColor);
    final detail = widget.detail;
    final body = Padding(
      key: const ValueKey('plist-body'),
      // 본문과 뒤 붙이개 사이
      padding: const EdgeInsetsDirectional.only(end: PSpacing.x2_5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PSpacing.x0_5,
        children: [
          Text(
            keepAll(widget.title),
            key: const ValueKey('plist-title'),
            semanticsLabel: widget.title,
            style: PTypography.t5.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (detail != null)
            Text(
              keepAll(detail),
              key: const ValueKey('plist-detail'),
              semanticsLabel: detail,
              style: detailStyle,
            ),
          if (widget.detailChild != null)
            DefaultTextStyle(
              key: const ValueKey('plist-detail'),
              style: detailStyle,
              child: widget.detailChild!,
            ),
        ],
      ),
    );

    // 본문 — 보기만 하는 줄 · 누르는 줄 · 링크 줄은 본문이 한 노드다. 컨트롤 줄은 줄 전체가 한 노드(아래).
    final sem = widget.semantics;
    Widget bodyNode = body;
    if (!sem.wholeRow) {
      bodyNode = Semantics(
        container: true,
        button: sem.button ? true : null,
        link: sem.link ? true : null,
        enabled: widget.interactive ? !disabled : null,
        onTap: widget.interactive && !disabled ? widget.onActivate : null,
        child: body,
      );
    }

    final start = switch (nest) {
      PListNest.none => PSpacing.globalGutter,
      PListNest.parent => PSpacing.x1,
      PListNest.child => kPListChildStart,
    };
    Widget row = Padding(
      padding: EdgeInsetsDirectional.only(
        start: start,
        end: PSpacing.globalGutter,
        top: PSpacing.x3,
        bottom: PSpacing.x3,
      ),
      child: Row(
        key: const ValueKey('plist-row'),
        crossAxisAlignment: widget.align == PListAlign.top
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (nest == PListNest.parent)
            const SizedBox(
              key: ValueKey('plist-expand-slot'),
              width: kPListExpandSlot,
              height: kPListExpandSlotHeight,
            ),
          if (widget.prefix != null)
            Padding(
              key: const ValueKey('plist-prefix'),
              padding: const EdgeInsetsDirectional.only(end: PSpacing.x3),
              child: IconTheme(
                data: IconThemeData(size: kPListIconSize, color: iconColor),
                child: widget.prefix!,
              ),
            ),
          Expanded(child: _bodyAndSuffix(bodyNode, detailColor, arrowColor)),
        ],
      ),
    );
    if (sem.wholeRow) {
      row = Semantics(
        container: true,
        enabled: !disabled,
        checked: sem.checked,
        mixed: sem.mixed,
        toggled: sem.toggled,
        selected: sem.selected,
        inMutuallyExclusiveGroup: sem.inMutuallyExclusiveGroup ? true : null,
        hint: sem.hint,
        onTap: !disabled ? widget.onActivate : null,
        child: row,
      );
    }

    // 꺾쇠 단추 — 콘텐츠 층 위에 얹혀(줄의 눌림에 함께 줄고, 눌림은 따로 받는다) 줄의 가운데(맞춤이 top 이면 위)에 선다
    final expand = widget.expandButton;
    Widget content = row;
    if (expand != null) {
      content = Stack(
        children: [
          row,
          if (widget.align == PListAlign.top)
            PositionedDirectional(
              top: PSpacing.x3 - PSpacing.x0_5,
              start: PSpacing.x1,
              child: expand,
            )
          else
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: PSpacing.x1),
                  child: expand,
                ),
              ),
            ),
        ],
      );
    }

    // 콘텐츠 층만 줄어든다 — 모션 줄이기면 축소 없이 색만
    // (멈춰 그리는 중에는 줄 크기를 잰 뒤에 줄어든다 — 틀린 배율로 먼저 줄지 않게)
    final shrink =
        pressed && !reduceMotion && (!_preview || _previewReady || _pressed);
    content = AnimatedScale(
      key: const ValueKey('plist-content'),
      scale: shrink ? (_basis - 2) / _basis : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: content,
    );

    // 바탕 층 — 줄지 않는다. 누르면 좌우 6 들어오며 모서리가 둥글어지고 누름 색이 된다
    final restColor = widget.highlighted
        ? c.bgBrandWeak
        : const Color(0x00000000);
    final pressedColor = widget.highlighted
        ? c.bgBrandWeakPressed
        : c.bgLayerDefaultPressed;
    final background = Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: pressed ? 1 : 0),
        duration: PDuration.colorTransition,
        curve: PEasing.easing,
        builder: (context, t, _) => Padding(
          padding: EdgeInsets.symmetric(horizontal: PSpacing.x1_5 * t),
          child: DecoratedBox(
            key: const ValueKey('plist-background'),
            decoration: BoxDecoration(
              color: _lerpPremultiplied(restColor, pressedColor, t),
              borderRadius: BorderRadius.circular(scope.itemRadius * t),
            ),
          ),
        ),
      ),
    );

    Widget result = Stack(
      key: const ValueKey('plist-item'),
      fit: StackFit.passthrough,
      children: [background, content],
    );

    if (widget.interactive) {
      if (!disabled) {
        result = GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: _tapDown,
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onActivate,
          child: result,
        );
      }
      result = MouseRegion(
        // 웹 cursor pointer · not-allowed
        cursor: disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: result,
      );
      Widget focus = Focus(
        focusNode: widget.focusNode,
        canRequestFocus: !disabled,
        child: result,
      );
      if (expand != null) {
        // Tab 은 꺾쇠 단추 → 그 줄(단추는 줄의 포커스 안에 얹혀 있어 위치로는 줄이 앞선다)
        focus = FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: focus,
          ),
        );
      }
      result = Shortcuts(
        shortcuts: widget.activateOnEnter ? _spaceOrEnter : _spaceOnly,
        child: Actions(actions: _actions, child: focus),
      );
    }

    return PListRowScope(
      pressed: pressed,
      disabled: disabled,
      tracker: _tracker,
      child: result,
    );
  }
}

/// 줄 안에서 따로 눌리는 것(작은 버튼 · 메뉴)을 감싼다 — 그 버튼이 눌리는 동안 줄은 눌린 모습이 되지 않는다.
///
/// 웹은 뒤 붙이개 안의 버튼 · 링크가 줄의 덮개 위(z-index 1)에 올라 따로 눌린다. Flutter 는 안쪽 버튼이 눌림을
/// 이기지만(줄의 onTap 은 불리지 않는다) 100ms 넘게 누르고 있으면 바깥 줄도 눌린 모습이 되므로, 이 감싸개가 그
/// 눌림을 알려 둔다. 한 줄에 따로 누르는 것(줄 자체 · 작은 버튼 · 메뉴)은 셋까지다.
class PListAction extends StatelessWidget {
  const PListAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = PListRowScope.maybeOf(context);
    if (scope == null) return child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => scope.tracker.down(e.pointer),
      onPointerUp: (e) => scope.tracker.up(e.pointer),
      onPointerCancel: (e) => scope.tracker.up(e.pointer),
      child: child,
    );
  }
}
