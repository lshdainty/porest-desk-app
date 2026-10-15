import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

// 피드백 묶음(카탈로그 "11 피드백" — Snackbar · Callout · Page Banner · Result Section)이 함께 쓰는 부품. 눌리는 것이
// 모두 같은 규칙이다 — 누르면 세로 2px 거리 축소(기준 max(높이, 폭 ÷ 4, 24)), 누르는 영역은 보이는 것보다 넓다.
// 화면에서 직접 쓰지 않는다 — PCallout · PPageBanner · PSnackbar 가 쓴다.
//
// Callout · Page Banner 의 닫기 · 버튼은 PButton 이 아니다. 스펙이 이 자리의 값을 따로 적는다 — 글자색 · 누름 바탕이
// 톤을 따르고(fg-*-contrast · bg-*-weak-pressed) 크기가 40 × 40 · 글 버튼 18 이다. PButton(ghost)은 글자색 넷 ·
// 누름 바탕 하나 · 높이 36/40 이라 이 값을 낼 수 없고, 웹도 Button 이 아니라 제 요소를 쓴다(callout.tsx · page-banner.tsx).
// Result Section 의 두 버튼만 스펙이 "Button" 이라 적어 PButton 을 그대로 쓴다.

/// 누르는 영역을 보이는 크기와 따로 넓힌다 — 놓인 자리(레이아웃)는 그대로다.
///
/// [slop] 은 사방으로 얼마나, [minWidth] · [minHeight] 는 적어도 얼마까지(가운데 기준)다. 넓힌 자리에서 누르면 상자
/// 가운데를 누른 것으로 친다(Material 의 탭 영역 패딩과 같은 방법). **부모 상자 안에서만 받는다** — Flutter 는 부모가
/// 받아 준 자리에서만 자식에게 묻는다. 그래서 쓰는 쪽이 줄 전체(Row)가 이 자리를 품도록 짠다.
class FeedbackHitSlop extends SingleChildRenderObjectWidget {
  const FeedbackHitSlop({
    super.key,
    this.slop = EdgeInsets.zero,
    this.minWidth = 0,
    this.minHeight = 0,
    required super.child,
  });

  final EdgeInsets slop;
  final double minWidth;
  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitSlop(slop, minWidth, minHeight);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHitSlop)
      ..slop = slop
      ..minWidth = minWidth
      ..minHeight = minHeight;
  }
}

class _RenderHitSlop extends RenderProxyBox {
  _RenderHitSlop(this.slop, this.minWidth, this.minHeight);

  EdgeInsets slop;
  double minWidth;
  double minHeight;

  /// 누를 수 있는 자리 — 보이는 상자 + [slop], 그래도 [minWidth] × [minHeight] 에 못 미치면 가운데 기준으로 더 넓힌다.
  Rect get area {
    var rect = slop.inflateRect(Offset.zero & size);
    final extraW = math.max(0.0, minWidth - rect.width);
    final extraH = math.max(0.0, minHeight - rect.height);
    rect = Rect.fromLTRB(
      rect.left - extraW / 2,
      rect.top - extraH / 2,
      rect.right + extraW / 2,
      rect.bottom + extraH / 2,
    );
    return rect;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
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

/// 눌렀을 때의 축소 — 가운데를 기준으로 줄고 놓인 자리는 그대로다. 모션 줄이기면 줄지 않는다([FeedbackPress] 가
/// 그 경우 배율 1 을 준다).
class FeedbackScale extends StatelessWidget {
  const FeedbackScale({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: child,
    );
  }
}

/// 눌리는 것 하나 — 누름 상태 · 누름 축소 배율 · 키보드 · 이름을 맡는다. 모양은 [builder] 가 그린다.
///
///   누름 — 누르는 동안 [builder] 에 pressed 와 배율을 준다. 배율 = (기준 − 2) ÷ 기준, 기준 = max(높이, 폭 ÷ 4, 24)
///     — 누르는 순간 그려진 크기에서 잰다([basisInflate] 는 그 크기에 더한다 — 보이는 상자 밖으로 번진 누르는 자리까지
///     한 상자로 치는 버튼). 모션 줄이기면 배율 1.
///   누르는 영역 — [slop] · [minWidth] · [minHeight] 로 넓힌다(FeedbackHitSlop).
///   키보드 — 포커스를 받고 Enter · Space 로 누른다. 포커스 링은 웹 상태라 그리지 않는다.
///   이름 — [semanticLabel] 이 있으면 그 이름, 없으면 안쪽 글이 이름이다([link] 면 링크로 읽는다).
///   [onPressed] 가 없으면 눌리지 않는다.
class FeedbackPress extends StatefulWidget {
  const FeedbackPress({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.link = false,
    this.slop = EdgeInsets.zero,
    this.minWidth = 0,
    this.minHeight = 0,
    this.basisInflate = EdgeInsets.zero,
    this.focusNode,
    this.excludeChildSemantics = false,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, bool pressed, double scale)
  builder;
  final String? semanticLabel;
  final bool link;
  final EdgeInsets slop;
  final double minWidth;
  final double minHeight;
  final EdgeInsets basisInflate;
  final FocusNode? focusNode;

  /// 안쪽 글을 읽지 않는다 — [semanticLabel] 만 이름이다(아이콘만 있는 버튼).
  final bool excludeChildSemantics;

  @override
  State<FeedbackPress> createState() => _FeedbackPressState();
}

class _FeedbackPressState extends State<FeedbackPress> {
  bool _pressed = false;
  double _basis = 24;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) {
        final inflated = widget.basisInflate.inflateSize(size);
        _basis = math.max(inflated.height, math.max(inflated.width / 4, 24));
      }
    }
    setState(() => _pressed = value);
  }

  void _activate() => widget.onPressed?.call();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scale = _pressed && !reduceMotion ? (_basis - 2) / _basis : 1.0;
    Widget content = widget.builder(context, _pressed, scale);
    if (widget.excludeChildSemantics) {
      content = ExcludeSemantics(child: content);
    }

    return FeedbackHitSlop(
      slop: widget.slop,
      minWidth: widget.minWidth,
      minHeight: widget.minHeight,
      child: Semantics(
        container: true,
        button: !widget.link,
        link: widget.link,
        enabled: _enabled,
        label: widget.semanticLabel,
        onTap: _enabled ? _activate : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _enabled ? _activate : null,
          excludeFromSemantics: true,
          child: MouseRegion(
            cursor: _enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: FocusableActionDetector(
              enabled: _enabled,
              focusNode: widget.focusNode,
              includeFocusSemantics: false,
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _activate();
                    return null;
                  },
                ),
              },
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// 닫은 뒤 키보드 초점 — 닫기에 초점이 있었으면 다음 요소로 보낸다(뒤에 없으면 맨 앞 — 초점을 잃은 채 두지 않는다).
/// 상자가 걷힌 뒤에는 닫기가 없으므로 닫기 전에 부른다. 터치로 눌렀으면 초점이 없어 아무것도 하지 않는다.
void moveFocusAfterDismiss(FocusNode? dismissNode) {
  if (dismissNode == null || !dismissNode.hasPrimaryFocus) return;
  dismissNode.nextFocus();
}

/// 글 한 줄이 줄을 안 바꿀 때의 너비 — 한 줄에 들어가는지 잴 때(Page Banner 의 글 · 버튼).
double measureTextWidth(BuildContext context, InlineSpan span) {
  final painter = TextPainter(
    text: span,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
