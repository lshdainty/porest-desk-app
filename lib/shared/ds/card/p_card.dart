import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/card/p_card_parts.dart';

export 'package:porest_desk_app/shared/ds/card/p_card_parts.dart';

/// 순자산 카드의 135° 그라디언트 — 면 색(`brand-solid`)에서 끝 색으로. 끝은 모드마다 다른 단계다(라이트 brand-900,
/// 다크 brand-300 — 다크에서 brand-900 은 밝은 #7AA9F6 이라 쓰지 않는다). CSS 의 135deg 는 상자의 모서리에서 모서리까지
/// 정확히 닿도록 선 길이를 (폭 + 높이) ÷ √2 로 잡는다 — Flutter 의 topLeft → bottomRight 는 가로로 긴 상자에서 각도가
/// 달라지므로 [createShader] 에서 같은 식으로 선을 긋는다.
class PCardHeroGradient extends LinearGradient {
  PCardHeroGradient({required Color start, required Color end})
    : super(colors: [start, end]);

  factory PCardHeroGradient.of(PColors c, Brightness mode) => PCardHeroGradient(
    start: c.bgBrandSolid,
    end: mode == Brightness.dark ? c.brand300 : c.brand900,
  );

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    final half = (rect.width + rect.height) / 4;
    return ui.Gradient.linear(
      Offset(center.dx - half, center.dy - half),
      Offset(center.dx + half, center.dy + half),
      colors,
      stops,
      tileMode,
    );
  }
}

/// 순자산 장식 빛의 크기 · 위치(card.yaml 의 heroGlow) — 240 원, 오른쪽 −40 · 위 −80, 흰 22% → 70% 에서 투명.
const double kCardHeroGlowSize = 240;
const double kCardHeroGlowRight = -40;
const double kCardHeroGlowTop = -80;

/// Card — 같은 주제의 정보를 한 면으로 묶는다(머리 · 본문 · 목록 · 지표 · 순자산). SEED 에는 카드 컴포넌트가 없다 —
/// 바닥 위 흰 면 + 1px 테두리 · 그림자 없음 · 누름은 SEED Feedback 을, 머리 · 여백 · 지표 · 순자산 · 증감은 porest 가
/// 정했다. 수치 원본은 porest-design `specs/components/card.yaml`(값은 `test/fixtures/design_spec/card.json`). 웹(desk-front
/// `src/shared/ds/card`)과 같은 값이다.
///
///   [PCard]          카드 면 — [variant] · [body] · [press]. 면은 `bg-layer-default` + 1px `stroke-neutral-weak`,
///                    모서리 16, 그림자 없음. 카드는 늘 회색 바닥(`bg-layer-basement`) 위에 둔다 — 흰 바탕 위에 두지 않는다.
///                    위아래로 쌓인 카드 사이는 8(부르는 쪽 Column 의 spacing).
///   [PCardHeader]    머리 — 제목 16/22 · 700 과 오른쪽 동작("전체 보기", 보이는 32 · 누르는 44) 한 줄
///   [PCardContent]   본문 — 요소 사이 12. 목록 카드는 이것 없이 [PList] 를 바로 넣는다
///   [PCardStat]      지표 — 라벨 · 숫자(large 24/32 · small 20/27 · 700 · 고정폭) · [PDelta]
///   [PDelta]         증감 — ▲ 빨강 · ▼ 파랑 · 변화 없음. 읽는 문장은 따로
///   [PCardHeroLabel] · [PCardHeroAmount] · [PCardHeroDetail]  순자산 카드의 흰 글자 셋
///
/// 누름 — whole 은 [onTap] 을 주면 된다(press 를 안 줘도). 누르는 동안 면이 `bg-layer-default-pressed`, 카드 전체가
/// 기준 길이에서 2px 거리 줄어든다. 순자산 카드(채움)는 색 없이 축소만. peers 는 색만(축소 없음)이고 안의 버튼이 카드
/// 위에서 따로 눌린다 — [semanticLabel] 이 카드를 여는 자리의 이름(보통 카드 제목). 모션 줄이기면 축소하지 않는다.
/// 올림(hovered) · 포커스 링은 웹 상태라 앱에는 없다.
///
/// 불러오는 중 · 실패는 카드 안에 [PSkeleton] · [PResultSection](`placement` — 글 카드 `card` 0, 목록 카드 `listCard` 24)
/// 을 직접 넣는다. 폰에서 지표 카드는 한 줄에 하나다.
class PCard extends StatefulWidget {
  const PCard({
    super.key,
    required this.children,
    this.variant = PCardVariant.standard,
    this.body = PCardBody.content,
    this.press = PCardPress.none,
    this.onTap,
    this.semanticLabel,
    this.previewPressed = false,
  });

  /// 머리 · 본문. 순서대로 쌓는다(사이 간격은 각 부품이 가진다).
  final List<Widget> children;

  final PCardVariant variant;

  /// 순자산 카드는 늘 글 카드 여백(content)이다.
  final PCardBody body;

  /// peers 만 직접 준다. [onTap] 이 있고 peers 가 아니면 whole 이다.
  final PCardPress press;

  /// 카드를 누를 때 — whole 은 카드 전체, peers 는 카드 위의 누르는 자리.
  final VoidCallback? onTap;

  /// peers 카드를 여는 자리의 이름. 안의 다른 버튼과 따로 읽힌다.
  final String? semanticLabel;

  /// 카탈로그 전용 — 눌린 모습으로 멈춰 그린다(실제로는 손가락이 누르는 동안만 눌린다).
  final bool previewPressed;

  PCardPress get effectivePress => onTap == null
      ? PCardPress.none
      : press == PCardPress.peers
      ? PCardPress.peers
      : PCardPress.whole;

  PCardBody get effectiveBody =>
      variant == PCardVariant.hero ? PCardBody.content : body;

  @override
  State<PCard> createState() => _PCardState();
}

class _PCardState extends State<PCard> {
  bool _pressed = false;
  double _basis = 24;

  // peers — 손가락이 안의 버튼 위에 닿았는지(눌림 색은 카드 링크 자리에서만 받는다, Q-011-9)
  final GlobalKey _contentKey = GlobalKey();
  bool _downOnInner = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) _basis = cardPressBasis(size);
    }
    setState(() => _pressed = value);
  }

  /// 손가락이 닿은 점 아래에 안의 눌리는 것(버튼 · 줄)이 있나 — 카드 안쪽만 훑는다(바깥 GestureDetector 는 빼고). 글 ·
  /// 여백은 눌리는 것이 아니다. 카드 링크 자리(안의 버튼이 없는 곳)에서만 눌림 색이 난다.
  bool _innerTappableAt(Offset globalPosition) {
    final box = _contentKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(globalPosition));
    return result.path.any((e) => e.target is RenderPointerListener);
  }

  EdgeInsets _padding(PCardBody body) {
    final hasHeader = widget.children.any((w) => w is PCardHeader);
    return switch (body) {
      PCardBody.content => const EdgeInsets.all(PSpacing.x6),
      // 좌우 0 — 줄이 제 좌우 24 · 위아래 12 를 가진다. 머리가 없으면 위도 12(첫 줄 12 와 합쳐 보이는 24)
      PCardBody.list => EdgeInsets.only(
        top: hasHeader ? 0 : PSpacing.x3,
        bottom: PSpacing.x3,
      ),
      PCardBody.accordion => EdgeInsets.only(
        top: hasHeader ? 0 : PSpacing.x2,
        bottom: PSpacing.x2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mode = Theme.of(context).brightness;
    final hero = widget.variant == PCardVariant.hero;
    final body = widget.effectiveBody;
    final press = widget.effectivePress;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pressed = _pressed || widget.previewPressed;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.children,
    );
    content = DefaultTextStyle(
      style: PTypography.t4.copyWith(color: hero ? c.staticWhite : c.fgNeutral),
      child: PCardScope(
        variant: widget.variant,
        body: body,
        child: Padding(padding: _padding(body), child: content),
      ),
    );

    // 머리 동작의 누르는 영역 44 — 머리 줄(32) 밖 위아래 6 도 받는다(Q-011-8)
    content = PTouchTargetScope(child: content);

    final peers = press == PCardPress.peers;
    if (hero || peers) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          if (peers)
            // 카드 전체를 덮는 누르는 자리 — 눌림은 바깥 GestureDetector 가 받고, 여기는 읽는 이름 · 동작만 갖는다
            Positioned.fill(
              child: Semantics(
                key: const ValueKey('card-peers-link'),
                button: true,
                label: widget.semanticLabel,
                onTap: widget.onTap,
              ),
            ),
          if (hero)
            // 장식 빛 — 글자 뒤 맨 아래. 보조 기술에는 없다
            Positioned(
              key: const ValueKey('card-hero-glow'),
              right: kCardHeroGlowRight,
              top: kCardHeroGlowTop,
              width: kCardHeroGlowSize,
              height: kCardHeroGlowSize,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        // CSS 의 circle 기본 크기(farthest-corner)는 반지름 120·√2 — 70% 가 투명
                        radius: math.sqrt2 / 2,
                        colors: [
                          c.staticWhite.withValues(alpha: 0.22),
                          c.staticWhite.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          content,
        ],
      );
    }

    final face = hero
        ? BoxDecoration(
            gradient: PCardHeroGradient.of(c, mode),
            borderRadius: BorderRadius.circular(PRounded.r4),
          )
        : BoxDecoration(
            color: pressed && press != PCardPress.none
                ? c.bgLayerDefaultPressed
                : c.bgLayerDefault,
            borderRadius: BorderRadius.circular(PRounded.r4),
            border: Border.all(color: c.strokeNeutralWeak),
          );
    // 넘친 것(목록 줄의 누름 바탕 · 순자산 장식 빛)은 모서리에서 자른다. 테두리 안쪽 모서리는 16 − 1
    final clipRadius = hero ? PRounded.r4 : PRounded.r4 - 1;
    Widget surface = TweenAnimationBuilder<Decoration>(
      key: const ValueKey('card-surface'),
      tween: DecorationTween(end: face),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      // Container — 테두리 두께만큼 안쪽을 들인다(DecoratedBox 는 그리기만 한다)
      builder: (context, decoration, child) =>
          Container(decoration: decoration, child: child),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(clipRadius),
        child: KeyedSubtree(key: _contentKey, child: content),
      ),
    );

    if (press == PCardPress.none) return surface;

    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      // peers — 안의 버튼 위에 닿았으면 카드 면은 바뀌지 않는다(그 버튼이 제 눌림을 가진다)
      onTapDown: (_) {
        if (!(press == PCardPress.peers && _downOnInner)) _setPressed(true);
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      excludeFromSemantics: true,
      child: press == PCardPress.peers
          ? Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) => _downOnInner = _innerTappableAt(e.position),
              child: surface,
            )
          : surface,
    );
    if (press == PCardPress.peers) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: gesture),
      );
    }
    final shrink = pressed && !reduceMotion;
    return Semantics(
      container: true,
      button: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedScale(
          scale: shrink ? (_basis - 2) / _basis : 1,
          duration: PDuration.pressedScale,
          curve: PEasing.pressedScale,
          child: gesture,
        ),
      ),
    );
  }
}
