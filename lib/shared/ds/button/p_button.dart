import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/ds/progress_circle/p_progress_circle.dart';

/// 변형 — 한 화면의 강조 버튼(Solid)은 하나.
enum PButtonVariant {
  /// 브랜드 색 채움 — 서비스 핵심 액션 하나(Desk 거래 추가)
  brandSolid,

  /// 짙은 회색 채움 — 대부분의 CTA(저장 · 확인 · 다음). 기본값
  neutralSolid,

  /// 옅은 회색 채움 — 대부분의 액션, CTA 옆 보조(취소)
  neutralWeak,

  /// 빨강 채움 — 되돌릴 수 없는 작업의 확정(주로 Alert Dialog)
  criticalSolid,

  /// 테두리 + 브랜드 글자 — neutralOutline 과 짝
  brandOutline,

  /// 테두리 + 본문 글자 — 가장 낮은 위계
  neutralOutline,

  /// 배경 없음 — 메뉴 · 툴바 · 목록의 가벼운 액션. 글자색은 [PButtonGhostColor]
  ghost,
}

/// 크기 — 이름이 아니라 높이로 고른다. xsmall 32(알약) · small 36 · medium 40(기본) · large 48.
enum PButtonSize { xsmall, small, medium, large }

/// ghost 의 글자색(SEED ghost 의 color) — 배경 · 누름은 ghost 그대로.
enum PButtonGhostColor { neutral, neutralSubtle, brand, critical }

/// 가장자리 맞춤(SEED bleed) — 그 방향 가로 여백만 0. ghost 는 텍스트 버튼이 되어 배경 없이 글자색으로만 반응한다.
enum PButtonFlush { left, right }

/// Button — 구조는 SEED Action Button(2026-09-30). 수치 원본은 porest-design `specs/components/button.yaml`
/// (값은 `test/fixtures/design_spec/button.json` — 테스트가 위젯이 그 값과 같은지 본다). 웹(desk-front
/// `src/shared/ds/button`)과 같은 값이다.
///
///   [PButton] — 글자, 앞 또는 뒤 아이콘 하나까지(둘 다는 쓰지 않는다)
///   [PButton.icon] — 아이콘만, 정사각. 이름(semanticLabel)이 반드시 있다
///
/// 상태 — 누르면 누름 색 + 세로 2px 거리 축소(배율 = (기준 − 2) ÷ 기준, 기준 = max(높이, 폭 ÷ 4, 24) — 모션
///   줄이기면 축소하지 않는다). loading 은 누름 색 위 로딩 원(라벨 자리는 그대로 — 글자 · 아이콘만 투명하게)이고
///   누르기를 삼킨다(두 번 제출 방지). onPressed 가 없으면 비활성 — 전용 색이고 흐리게 하지 않는다.
///   올림 · 포커스 링은 웹 상태라 앱에는 없다.
/// 누르는 영역은 보이는 크기와 따로 44 × 44 까지 넓힌다 — 놓인 자리를 넓히지 않는다(부모 상자 안에서만 받는다).
class PButton extends StatefulWidget {
  const PButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.variant = PButtonVariant.neutralSolid,
    this.size = PButtonSize.medium,
    this.ghostColor = PButtonGhostColor.neutral,
    this.prefixIcon,
    this.suffixIcon,
    this.flush,
    this.loading = false,
  }) : assert(
         prefixIcon == null || suffixIcon == null,
         '앞 · 뒤 아이콘은 하나만 쓴다(button.yaml layout withText)',
       ),
       icon = null,
       semanticLabel = null;

  /// 아이콘만 — 정사각. [semanticLabel] 이 이 버튼의 이름이다.
  const PButton.icon({
    super.key,
    required IconData this.icon,
    required String this.semanticLabel,
    required this.onPressed,
    this.variant = PButtonVariant.neutralSolid,
    this.size = PButtonSize.medium,
    this.ghostColor = PButtonGhostColor.neutral,
    this.loading = false,
  }) : label = null,
       prefixIcon = null,
       suffixIcon = null,
       flush = null;

  final String? label;
  final IconData? icon;
  final String? semanticLabel;

  /// 없으면 비활성.
  final VoidCallback? onPressed;
  final PButtonVariant variant;
  final PButtonSize size;
  final PButtonGhostColor ghostColor;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final PButtonFlush? flush;

  /// 누름 색 위 로딩 원 + 누르기 막기.
  final bool loading;

  bool get _iconOnly => icon != null;

  @override
  State<PButton> createState() => _PButtonState();
}

/// 크기마다의 값(button.yaml 크기 · 크기 × 배치).
class _SizeSpec {
  const _SizeSpec({
    required this.height,
    required this.radius,
    required this.circle,
    required this.paddingX,
    required this.paddingY,
    required this.gap,
    required this.text,
    required this.textIcon,
    required this.iconOnlyPadding,
    required this.iconOnlyIcon,
  });

  final double height;
  final double radius;
  final double circle;
  final double paddingX;
  final double paddingY;
  final double gap;
  final TextStyle text;
  final double textIcon;
  final double iconOnlyPadding;
  final double iconOnlyIcon;
}

const Map<PButtonSize, _SizeSpec> _sizes = {
  PButtonSize.xsmall: _SizeSpec(
    height: 32,
    radius: PRounded.full,
    circle: 14,
    paddingX: PSpacing.x3_5,
    paddingY: PSpacing.x1_5,
    gap: PSpacing.x1,
    text: PTypography.t3,
    textIcon: 14,
    iconOnlyPadding: PSpacing.x1_5,
    iconOnlyIcon: 14,
  ),
  PButtonSize.small: _SizeSpec(
    height: 36,
    radius: PRounded.r2,
    circle: 14,
    paddingX: PSpacing.x3_5,
    paddingY: PSpacing.x2,
    gap: PSpacing.x1,
    text: PTypography.t4,
    textIcon: 14,
    iconOnlyPadding: PSpacing.x2,
    iconOnlyIcon: 16,
  ),
  PButtonSize.medium: _SizeSpec(
    height: 40,
    radius: PRounded.r2,
    circle: 16,
    paddingX: PSpacing.x4,
    paddingY: PSpacing.x2_5,
    gap: PSpacing.x1_5,
    text: PTypography.t4,
    textIcon: 16,
    iconOnlyPadding: PSpacing.x2_5,
    iconOnlyIcon: 18,
  ),
  // SEED large 는 52 — porest 는 48(사용자 결정)
  PButtonSize.large: _SizeSpec(
    height: 48,
    radius: PRounded.r3,
    circle: 18,
    paddingX: PSpacing.x5,
    paddingY: PSpacing.x3,
    gap: PSpacing.x2,
    text: PTypography.t6,
    textIcon: 22,
    iconOnlyPadding: PSpacing.x3,
    iconOnlyIcon: 22,
  ),
};

/// 변형 · 상태의 색 — 바탕 · 글자 · 테두리 · 로딩 원(button.yaml 변형별 색).
typedef PButtonColors = ({
  Color background,
  Color foreground,
  Color? border,
  Color circleTrack,
  Color circleRange,
});

/// 스펙의 상태 — 웹의 hovered · focused 는 앱에 없다.
enum PButtonState { enabled, pressed, loading, disabled }

/// 변형 · ghost 글자색 · 가장자리 맞춤 · 상태의 색 — 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
PButtonColors resolvePButtonColors(
  PColors c, {
  required PButtonVariant variant,
  required PButtonState state,
  PButtonGhostColor ghostColor = PButtonGhostColor.neutral,
  PButtonFlush? flush,
}) {
  final pressedLike =
      state == PButtonState.pressed || state == PButtonState.loading;
  final outline =
      variant == PButtonVariant.brandOutline ||
      variant == PButtonVariant.neutralOutline;
  final (
    Color bg,
    Color bgPressed,
    Color fg,
    Color track,
    Color range,
  ) = switch (variant) {
    PButtonVariant.brandSolid => (
      c.bgBrandSolid,
      c.bgBrandSolidPressed,
      c.staticWhite,
      c.staticWhite.withValues(alpha: 0.3),
      c.staticWhite,
    ),
    PButtonVariant.neutralSolid => (
      c.bgNeutralInverted,
      c.bgNeutralInvertedPressed,
      c.fgNeutralInverted,
      c.fgNeutralInverted.withValues(alpha: 0.3),
      c.fgNeutralInverted,
    ),
    PButtonVariant.neutralWeak => (
      c.bgNeutralWeak,
      c.bgNeutralWeakPressed,
      c.fgNeutral,
      c.gray500,
      c.fgNeutral,
    ),
    PButtonVariant.criticalSolid => (
      c.bgCriticalSolid,
      c.bgCriticalSolidPressed,
      c.staticWhite,
      c.staticWhite.withValues(alpha: 0.3),
      c.staticWhite,
    ),
    PButtonVariant.brandOutline => (
      const Color(0x00000000),
      c.bgLayerDefaultPressed,
      c.fgBrand,
      c.bgBrandWeakPressed,
      c.bgBrandSolid,
    ),
    PButtonVariant.neutralOutline => (
      const Color(0x00000000),
      c.bgLayerDefaultPressed,
      c.fgNeutral,
      c.gray500,
      c.fgNeutral,
    ),
    PButtonVariant.ghost => (
      const Color(0x00000000),
      c.bgLayerDefaultPressed,
      switch (ghostColor) {
        PButtonGhostColor.neutral => c.fgNeutral,
        PButtonGhostColor.neutralSubtle => c.fgNeutralSubtle,
        PButtonGhostColor.brand => c.fgBrand,
        PButtonGhostColor.critical => c.fgCritical,
      },
      c.gray500,
      c.fgNeutral,
    ),
  };
  final border = outline ? c.strokeNeutralWeak : null;

  if (state == PButtonState.disabled) {
    // 전용 색 — 흐리게 하지 않는다. 테두리 · ghost 는 바탕이 없다
    return (
      background: outline || variant == PButtonVariant.ghost
          ? const Color(0x00000000)
          : c.bgDisabled,
      foreground: c.fgDisabled,
      border: border,
      circleTrack: track,
      circleRange: range,
    );
  }

  // 가장자리에 맞춘 ghost 는 텍스트 버튼 — 바탕 없이 글자색으로만 반응한다(흐린 글자 → 누르면 본문 글자)
  if (variant == PButtonVariant.ghost && flush != null) {
    return (
      background: const Color(0x00000000),
      foreground: pressedLike ? c.fgNeutral : c.fgNeutralSubtle,
      border: null,
      circleTrack: track,
      circleRange: range,
    );
  }

  return (
    // 테두리 버튼은 로딩에 누름 색을 깔지 않는다(button.yaml 에 loading 바탕이 없다)
    background: switch (state) {
      PButtonState.pressed => bgPressed,
      PButtonState.loading => outline ? bg : bgPressed,
      _ => bg,
    },
    foreground: fg,
    border: border,
    circleTrack: track,
    circleRange: range,
  );
}

class _PButtonState extends State<PButton> {
  bool _pressed = false;

  /// 누름 축소의 기준 길이 max(높이, 폭 ÷ 4, 24) — 누르는 순간 그려진 크기에서 잰다.
  double _pressBasis = 24;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) {
        _pressBasis = math.max(size.height, math.max(size.width / 4, 24));
      }
    }
    setState(() => _pressed = value);
  }

  void _activate() {
    // 로딩 중엔 누르기를 삼킨다 — 두 번 제출 방지
    if (!_enabled || widget.loading) return;
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _sizes[widget.size]!;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final state = !_enabled
        ? PButtonState.disabled
        : widget.loading
        ? PButtonState.loading
        : _pressed
        ? PButtonState.pressed
        : PButtonState.enabled;
    final colors = resolvePButtonColors(
      c,
      variant: widget.variant,
      state: state,
      ghostColor: widget.ghostColor,
      flush: widget.flush,
    );

    final iconOnly = widget._iconOnly;
    final padding = iconOnly
        ? EdgeInsets.all(s.iconOnlyPadding)
        : EdgeInsets.only(
            left: widget.flush == PButtonFlush.left ? 0 : s.paddingX,
            right: widget.flush == PButtonFlush.right ? 0 : s.paddingX,
            top: s.paddingY,
            bottom: s.paddingY,
          );

    Widget content = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: colors.foreground),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, fg, _) {
        final iconSize = iconOnly ? s.iconOnlyIcon : s.textIcon;
        Widget glyph(IconData data) => Icon(data, size: iconSize, color: fg);
        if (iconOnly) return glyph(widget.icon!);
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: s.gap,
          children: [
            if (widget.prefixIcon != null) glyph(widget.prefixIcon!),
            Text(
              widget.label!,
              maxLines: 1,
              softWrap: false,
              style: s.text.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
            if (widget.suffixIcon != null) glyph(widget.suffixIcon!),
          ],
        );
      },
    );
    if (widget.loading) {
      // 라벨 자리는 그대로 — 글자 · 아이콘만 투명하게 하고 그 위에 로딩 원. 이름은 계속 읽는다
      content = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, alwaysIncludeSemantics: true, child: content),
          PProgressCircle.inherit(
            diameter: s.circle,
            thickness: 2,
            trackColor: colors.circleTrack,
            rangeColor: colors.circleRange,
          ),
        ],
      );
    }

    // 바탕색만 바뀐다(color-transition) — 크기 · 여백은 움직이지 않는다
    final box = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: colors.background),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, background, child) => Container(
        height: s.height,
        width: iconOnly ? s.height : null,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(s.radius),
          border: colors.border == null
              ? null
              : Border.all(color: colors.border!, width: 1),
        ),
        child: child,
      ),
      // 가로는 내용만큼(부모가 폭을 정하면 그 폭의 가운데), 세로는 상자 가운데
      child: Align(widthFactor: iconOnly ? null : 1, child: content),
    );

    // 누름 축소 — 기준 길이에서 2px. 모션 줄이기 · 로딩 · 비활성이면 없다
    final shrink = state == PButtonState.pressed && !reduceMotion;
    final pressedBox = AnimatedScale(
      scale: shrink ? (_pressBasis - 2) / _pressBasis : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: box,
    );

    final l10n = AppLocalizations.of(context);
    // 누르는 영역 상자가 가장 바깥이다 — 안쪽 상자는 제 크기 밖에서 누른 것을 받지 않는다
    return _TouchTarget(
      minSize: PTouch.min,
      child: Semantics(
        container: true,
        button: true,
        enabled: _enabled,
        label: iconOnly ? widget.semanticLabel : null,
        // 웹의 aria-busy — 바쁘다는 것을 이름 뒤에 읽는다
        value: widget.loading ? l10n.dsProgressCircleLabel : null,
        onTap: _enabled && !widget.loading ? _activate : null,
        excludeSemantics: iconOnly,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled && !widget.loading
              ? (_) => _setPressed(true)
              : null,
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _enabled ? _activate : null,
          excludeFromSemantics: true,
          child: MouseRegion(
            cursor: !_enabled
                ? SystemMouseCursors.forbidden
                : widget.loading
                ? SystemMouseCursors.progress
                : SystemMouseCursors.click,
            child: pressedBox,
          ),
        ),
      ),
    );
  }
}

/// 누르는 영역을 보이는 크기와 따로 [minSize] 까지 넓힌다 — 놓인 자리(레이아웃)는 그대로다.
///
/// 넓힌 자리에서 누르면 상자 가운데를 누른 것으로 친다(Material 의 탭 영역 패딩과 같은 방법).
/// 부모 상자 밖은 받을 수 없다 — Flutter 는 부모 안에서만 자식에게 묻는다.
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
    // 넓힌 자리에서 누르면 상자 가운데를 누른 것으로 친다(Material 의 탭 영역 패딩과 같다)
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
