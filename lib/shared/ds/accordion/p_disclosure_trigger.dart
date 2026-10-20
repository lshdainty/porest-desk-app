import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 누름 바탕의 색 — layer(기본, `bg-layer-default-pressed`) · warning(경고 상자 안의 Collapsible,
/// `bg-warning-weak-pressed`).
enum PDisclosurePressed { layer, warning }

/// 펼치는 줄의 틀 — [PAccordionItem](accordion) 과 [PCollapsible] 이 같이 쓰는 트리거 한 줄. 화면에서 직접 쓰지 않는다.
/// 수치 원본은 groo-design `accordion.yaml` · `collapsible.yaml`(트리거는 Accordion 항목 하나의 모양), 웹은 desk-front
/// `src/shared/ds/accordion/accordion-variants.ts`(`accordionTrigger*`)다.
///
/// 줄 전체가 누르는 자리 — 위아래 16 · 좌우 [paddingX](24, 경고 상자 16), 앞 아이콘 22 · 본문 · 꺾쇠 20 사이 12.
/// 제목 16 / 22 · 500 `fg-neutral`, 설명 13 / 18 · 500 `fg-neutral-subtle`(제목 아래 2) — 늘 줄을 바꾸고(낱말 단위, 말줄임
/// 없음) 높이는 제목만이면 54, 설명이 있으면 74. 두 층이다 — 바탕 층(누르면 좌우 6 들어오며 모서리 10, 줄지 않는다)과 콘텐츠 층
/// (누르는 동안 기준 max(높이, 폭 ÷ 4, 24)에서 2px 거리 축소 — 모션 줄이기면 하지 않는다). 꺾쇠는 접히면 아래, 펼치면 위
/// (300ms, 모션 줄이기면 바로). 막힘은 아이콘 · 제목 · 설명 · 꺾쇠가 모두 `fg-disabled` 다(흐리게 하지 않는다).
///
/// 읽는 모습 — 머리말([headingLevel], 웹 `h3`) 안의 단추. 이름은 "제목 + 설명", 펼침은 expanded 로 읽힌다. 키보드 —
/// 포커스에서 Enter · Space. 호버 · 포커스 링은 웹 전용이라 앱에는 없다(키보드 포커스는 [focusNode] 로 받는다).
class PDisclosureTrigger extends StatefulWidget {
  const PDisclosureTrigger({
    super.key,
    required this.title,
    required this.open,
    required this.onToggle,
    this.description,
    this.prefixIcon,
    this.disabled = false,
    this.paddingX = PSpacing.globalGutter,
    this.pressed = PDisclosurePressed.layer,
    this.headingLevel = 3,
    this.controlsId,
    this.focusNode,
  });

  final String title;
  final String? description;

  /// 앞 아이콘 — 22, 있을 때만(Accordion). 색은 제목과 같다.
  final IconData? prefixIcon;

  final bool open;
  final VoidCallback onToggle;
  final bool disabled;

  /// 좌우 여백 — 24(화면 가장자리 규칙), 경고 상자 안은 16.
  final double paddingX;
  final PDisclosurePressed pressed;

  /// 머리말 단계(웹 `as` — 기본 3, 시트 · 대화상자 · 카드 제목(h2) 아래).
  final int headingLevel;

  /// 펼치는 내용의 식별자(웹 aria-controls).
  final String? controlsId;
  final FocusNode? focusNode;

  /// 앞 아이콘 크기 — 간격 토큰에 22 가 없다(accordion.yaml prefixIcon.size).
  static const double prefixIconSize = 22;

  /// 꺾쇠 크기 — 20([PSpacing.x5]).
  static const double chevronSize = PSpacing.x5;

  @override
  State<PDisclosureTrigger> createState() => _PDisclosureTriggerState();
}

class _ActivateIntent extends Intent {
  const _ActivateIntent();
}

class _PDisclosureTriggerState extends State<PDisclosureTrigger> {
  static const Map<ShortcutActivator, Intent> _keys = {
    SingleActivator(LogicalKeyboardKey.space): _ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.enter): _ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): _ActivateIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = {
    _ActivateIntent: CallbackAction<_ActivateIntent>(
      onInvoke: (_) {
        if (!widget.disabled) widget.onToggle();
        return null;
      },
    ),
  };

  bool _pressed = false;

  /// 누름 축소의 기준 길이 max(높이, 폭 ÷ 4, 24) — 누르는 순간 그려진 크기에서 잰다.
  double _basis = 24;

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

  @override
  void didUpdateWidget(PDisclosureTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 사이 막히면 누름이 남지 않게
    if (widget.disabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final disabled = widget.disabled;
    final pressed = _pressed && !disabled;
    final tall = widget.description != null;

    final titleColor = disabled ? c.fgDisabled : c.fgNeutral;
    final subtleColor = disabled ? c.fgDisabled : c.fgNeutralSubtle;

    // 콘텐츠 층 — 앞 아이콘 · 본문(제목 + 설명) · 꺾쇠
    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.paddingX,
        vertical: PSpacing.x4,
      ),
      child: Row(
        spacing: PSpacing.x3,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.prefixIcon != null)
            SizedBox.square(
              key: const ValueKey('pdisc-prefix'),
              dimension: PDisclosureTrigger.prefixIconSize,
              child: Icon(
                widget.prefixIcon,
                size: PDisclosureTrigger.prefixIconSize,
                color: titleColor,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x0_5,
              children: [
                Text(
                  keepAll(widget.title),
                  key: const ValueKey('pdisc-title'),
                  style: PTypography.t5.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.description != null)
                  Text(
                    keepAll(widget.description!),
                    key: const ValueKey('pdisc-description'),
                    style: PTypography.t3.copyWith(
                      color: subtleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedRotation(
            key: const ValueKey('pdisc-chevron'),
            turns: widget.open ? 0.5 : 0,
            duration: reduceMotion ? Duration.zero : PDuration.d6,
            curve: PEasing.easing,
            child: Icon(
              LucideIcons.chevronDown,
              size: PDisclosureTrigger.chevronSize,
              color: subtleColor,
            ),
          ),
        ],
      ),
    );

    // 콘텐츠 층만 줄어든다 — 모션 줄이기면 축소 없이 색만
    content = AnimatedScale(
      key: const ValueKey('pdisc-content'),
      scale: pressed && !reduceMotion ? (_basis - 2) / _basis : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: content,
    );

    // 바탕 층 — 줄지 않는다. 누르면 좌우 6 들어오며 모서리 10 이 되고 누름 색이 된다
    final pressedColor = switch (widget.pressed) {
      PDisclosurePressed.layer => c.bgLayerDefaultPressed,
      PDisclosurePressed.warning => c.bgWarningWeakPressed,
    };
    final background = Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: pressed ? 1 : 0),
        duration: PDuration.colorTransition,
        curve: PEasing.easing,
        builder: (context, t, _) => Padding(
          padding: EdgeInsets.symmetric(horizontal: PSpacing.x1_5 * t),
          child: DecoratedBox(
            key: const ValueKey('pdisc-background'),
            decoration: BoxDecoration(
              color: Color.lerp(
                pressedColor.withValues(alpha: 0),
                pressedColor,
                t,
              ),
              borderRadius: BorderRadius.circular(PRounded.r2_5 * t),
            ),
          ),
        ),
      ),
    );

    Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: tall ? 74 : 54),
      child: Stack(
        key: const ValueKey('pdisc-trigger'),
        fit: StackFit.passthrough,
        children: [background, content],
      ),
    );

    if (!disabled) {
      row = GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onToggle,
        child: row,
      );
    }
    row = MouseRegion(
      // 웹 cursor pointer · not-allowed
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: row,
    );
    row = Shortcuts(
      shortcuts: _keys,
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: widget.focusNode,
          canRequestFocus: !disabled,
          child: row,
        ),
      ),
    );

    // 이름은 "제목 + 설명", 펼침은 expanded — 머리말 안의 단추
    final label = widget.description == null
        ? widget.title
        : '${widget.title}\n${widget.description}';
    return Semantics(
      container: true,
      header: true,
      headingLevel: widget.headingLevel,
      child: Semantics(
        container: true,
        button: true,
        enabled: !disabled,
        expanded: widget.open,
        label: label,
        controlsNodes: widget.controlsId == null ? null : {widget.controlsId!},
        onTap: disabled ? null : widget.onToggle,
        excludeSemantics: true,
        child: row,
      ),
    );
  }
}
