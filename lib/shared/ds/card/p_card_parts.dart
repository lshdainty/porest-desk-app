import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

/// Card 의 부품 — 머리 · 본문 · 지표 · 증감 · 순자산 글. 규칙은 [PCard] 머리 설명이다.

const _tabular = [FontFeature.tabularFigures()];

/// 면 — standard(기본, 바닥 위 흰 면 + 1px 테두리) · hero(순자산 — 브랜드 채움 · 흰 글자, 한 화면에 하나).
enum PCardVariant { standard, hero }

/// 본문 — content(기본, 여백 24) · list(List 를 담는다 — 좌우 0, 카드 아래 12) · accordion([PAccordion] 을 담는다 —
/// 좌우 0, 카드 아래 8).
enum PCardBody { content, list, accordion }

/// 누름 — none(기본, 보기만) · whole(카드 전체가 한 곳 — 누름 색 + 2px 축소) · peers(카드를 누르면 열리고 안에 대등한
/// 동작이 더 있다 — 색만 바뀌고 안의 버튼이 따로 눌린다).
enum PCardPress { none, whole, peers }

/// 카드 안의 머리 · 증감이 읽는 값 — 면의 종류와 본문.
class PCardScope extends InheritedWidget {
  const PCardScope({
    super.key,
    required this.variant,
    required this.body,
    required super.child,
  });

  final PCardVariant variant;
  final PCardBody body;

  static PCardScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PCardScope>();

  @override
  bool updateShouldNotify(PCardScope oldWidget) =>
      variant != oldWidget.variant || body != oldWidget.body;
}

/// 누르는 순간 기준 길이 max(높이, 폭 ÷ 4, 24) — 넓은 카드도 세로 2px 만큼만 준다(Button · List 와 같은 식).
double cardPressBasis(Size size) =>
    math.max(size.height, math.max(size.width / 4, 24));

/// 누르는 영역을 보이는 크기와 따로 [minSize] 까지 넓힌다 — 놓인 자리(레이아웃)는 그대로다(Button 의 것과 같은 방법). 부모
/// 상자 밖은 받을 수 없어 세로는 머리 줄 안에서만 넓어진다. Card 머리 동작 · Accordion 모두 펼치기가 같이 쓴다.
class PTouchTarget extends SingleChildRenderObjectWidget {
  const PTouchTarget({super.key, required this.minSize, required super.child});

  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchTarget(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderProxyBox renderObject,
  ) {
    (renderObject as _RenderTouchTarget).minSize = minSize;
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

// ── 머리 ─────────────────────────────────────────────────────

/// 머리 — 제목과 오른쪽 동작 한 줄. 글 카드는 카드 여백 안 · 아래 8, 목록 · 아코디언 카드는 위 24 · 좌우 24 · 아래 4.
///
/// [actionLabel] · [onAction] 을 주면 오른쪽에 "전체 보기" 같은 동작이 선다 — 보이는 상자 32 · 누르는 영역 44, 읽는 이름은
/// "{제목} {글}"(무엇의 동작인지 넣는다 — 글은 부르는 쪽이 넘긴다).
class PCardHeader extends StatelessWidget {
  const PCardHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.headingLevel = 2,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         '동작은 글(actionLabel)과 누를 때(onAction)를 함께 준다',
       );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 제목 단계(웹 `as` — 기본 2, 화면 제목 아래 단계)
  final int headingLevel;

  @override
  Widget build(BuildContext context) {
    final body = PCardScope.maybeOf(context)?.body ?? PCardBody.content;
    final padding = switch (body) {
      PCardBody.content => const EdgeInsets.only(bottom: PSpacing.x2),
      PCardBody.list || PCardBody.accordion => const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x1,
      ),
    };
    return Padding(
      key: const ValueKey('card-header'),
      padding: padding,
      child: Row(
        spacing: PSpacing.x2,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              headingLevel: headingLevel,
              child: Text(
                keepAll(title),
                key: const ValueKey('card-title'),
                semanticsLabel: title,
                style: PTypography.t5.copyWith(
                  color: context.colors.fgNeutral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (actionLabel != null)
            _CardAction(
              label: actionLabel!,
              semanticLabel: '$title $actionLabel',
              onTap: onAction!,
            ),
        ],
      ),
    );
  }
}

class _CardAction extends StatefulWidget {
  const _CardAction({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_CardAction> createState() => _CardActionState();
}

class _CardActionState extends State<_CardAction> {
  bool _pressed = false;
  double _basis = 24;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) _basis = cardPressBasis(size);
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shrink = _pressed && !reduceMotion;
    // 보이는 상자 32 — 누르면 바탕 bg-layer-default-pressed + 2px 거리 축소(글 버튼만, 카드는 그대로)
    final box = TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: _pressed
            ? c.bgLayerDefaultPressed
            : c.bgLayerDefaultPressed.withValues(alpha: 0),
      ),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, background, child) => Container(
        key: const ValueKey('card-action-box'),
        height: 32,
        padding: const EdgeInsets.only(left: PSpacing.x2, right: PSpacing.x1),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(PRounded.r2),
        ),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: PSpacing.x0_5,
        children: [
          Text(
            widget.label,
            maxLines: 1,
            softWrap: false,
            style: PTypography.t4.copyWith(
              color: c.fgNeutralSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
          ExcludeSemantics(
            child: Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: c.fgNeutralSubtle,
            ),
          ),
        ],
      ),
    );
    return PTouchTarget(
      minSize: PTouch.min,
      child: Semantics(
        container: true,
        button: true,
        label: widget.semanticLabel,
        excludeSemantics: true,
        onTap: widget.onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          excludeFromSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedScale(
              scale: shrink ? (_basis - 2) / _basis : 1,
              duration: PDuration.pressedScale,
              curve: PEasing.pressedScale,
              child: box,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 본문 ─────────────────────────────────────────────────────

/// 본문 — 카드 여백 안, 요소 사이 12. 목록 카드는 이것 없이 [PList] 를 바로 넣는다.
class PCardContent extends StatelessWidget {
  const PCardContent({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: PSpacing.x3,
    children: children,
  );
}

// ── 증감 ─────────────────────────────────────────────────────

/// 증감의 방향 — 좋고 나쁨이 아니라 방향이다. up ▲ `fg-critical`(빨강) · down ▼ `fg-informative`(파랑) · flat 은 화살표
/// 없이 "변화 없음".
enum PDeltaDirection { up, down, flat }

/// 값 앞의 부호(+ − ± 와 공백)를 뗀다 — "+12%" · "−12%" · "+-12.5%" 를 화살표와 겹쳐 쓰지 않는다.
@visibleForTesting
String unsignedDelta(String value) =>
    value.replaceFirst(RegExp(r'^[\s+\-−±]+'), '');

/// 보조 기술이 읽는 기본 문장 — "{text} {value} 늘었어요 · 줄었어요"(flat 은 "{text} 변화가 없어요").
@visibleForTesting
String deltaSentence(PDeltaDirection direction, String? value, String? text) {
  final base = (text ?? '').trim();
  if (direction == PDeltaDirection.flat) {
    return [base, '변화가 없어요'].where((s) => s.isNotEmpty).join(' ');
  }
  final amount = unsignedDelta(value ?? '').trim();
  return [
    base,
    amount,
    direction == PDeltaDirection.up ? '늘었어요' : '줄었어요',
  ].where((s) => s.isNotEmpty).join(' ');
}

/// 증감 줄 — [direction] 에 따라 ▲ · ▼ + [value]("12%"), 뒤에 기준 [text]("지난달보다"). 13 · 500(값) · 400(글), 고정폭
/// 숫자. 순자산 카드 안에서는 모두 흰 글자(채움 위 빨강 · 파랑은 1.66 · 1.65 — 하나뿐인 예외).
///
/// 읽기 — 화면의 조각(화살표 · 값 · 글)은 읽지 않고 [srText] 한 문장을 읽는다. 기본은 방향에서 만든 문장이고, 좋고 나쁨을
/// 말하려면 직접 준다("지난달보다 12% 더 썼어요"). flat 은 "변화 없음" 만 보이고 기준 글은 읽는 문장에만 쓴다.
class PDelta extends StatelessWidget {
  const PDelta({
    super.key,
    required this.direction,
    this.value,
    this.text,
    this.srText,
  });

  final PDeltaDirection direction;

  /// 변화량 — "12%" · "1,240원". 부호는 화살표가 말한다(앞의 + − ± 는 뗀다).
  final String? value;

  /// 기준 — "지난달보다"
  final String? text;

  /// 읽는 문장 — 기본은 [deltaSentence]
  final String? srText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hero = PCardScope.maybeOf(context)?.variant == PCardVariant.hero;
    final tone = hero
        ? c.staticWhite
        : switch (direction) {
            PDeltaDirection.up => c.fgCritical,
            PDeltaDirection.down => c.fgInformative,
            PDeltaDirection.flat => c.fgNeutralSubtle,
          };
    final arrow = switch (direction) {
      PDeltaDirection.up => '▲',
      PDeltaDirection.down => '▼',
      PDeltaDirection.flat => null,
    };
    final shown = arrow == null
        ? '변화 없음'
        : '$arrow ${unsignedDelta(value ?? '')}'.trimRight();
    return Semantics(
      container: true,
      label: srText ?? deltaSentence(direction, value, text),
      excludeSemantics: true,
      child: Wrap(
        spacing: PSpacing.x1,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text(
            keepAll(shown),
            key: const ValueKey('delta-value'),
            style: PTypography.t3.copyWith(
              color: tone,
              fontWeight: FontWeight.w500,
              fontFeatures: _tabular,
            ),
          ),
          // flat 은 "변화 없음" 만 — "변화 없음 지난달보다" 가 되지 않게
          if (direction != PDeltaDirection.flat &&
              text != null &&
              text!.isNotEmpty)
            Text(
              keepAll(text!),
              key: const ValueKey('delta-text'),
              style: PTypography.t3.copyWith(
                color: hero ? c.staticWhite : c.fgNeutralSubtle,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

// ── 지표 ─────────────────────────────────────────────────────

/// 지표 크기 — large(기본, 24/32 — 폰은 카드 하나에 숫자 하나) · small(20/27 — 데스크톱 격자에 셋 · 넷씩).
enum PCardStatSize { large, small }

/// 지표 — [label](13 · 500 · 무엇의 숫자인지) · [value](700 · 고정폭 숫자, 위 4) · [delta](위 4).
///
/// 숫자는 쓰는 쪽이 원까지 만든다("1,240,000원" · 빼기는 U+2212) — 1억이 넘어도 줄이지 않고, 칸보다 길면 줄이 바뀐다.
/// 숫자가 굴러가는 애니메이션을 두지 않는다.
class PCardStat extends StatelessWidget {
  const PCardStat({
    super.key,
    required this.label,
    required this.value,
    this.size = PCardStatSize.large,
    this.delta,
  });

  final String label;
  final String value;
  final PCardStatSize size;
  final PDelta? delta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = size == PCardStatSize.large
        ? PTypography.t9
        : PTypography.t7;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keepAll(label),
            key: const ValueKey('card-stat-label'),
            semanticsLabel: label,
            style: PTypography.t3.copyWith(
              color: c.fgNeutralSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: PSpacing.x1),
            child: Text(
              keepAll(value),
              key: const ValueKey('card-stat-value'),
              semanticsLabel: value,
              style: valueStyle.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
                fontFeatures: _tabular,
              ),
            ),
          ),
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x1),
              child: delta,
            ),
        ],
      ),
    );
  }
}

// ── 순자산 ───────────────────────────────────────────────────

/// 순자산 카드의 라벨 — 13 · 500, 흰 글자(흐리게 두지 않는다).
class PCardHeroLabel extends StatelessWidget {
  const PCardHeroLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    keepAll(text),
    key: const ValueKey('card-hero-label'),
    semanticsLabel: text,
    style: PTypography.t3.copyWith(
      color: context.colors.staticWhite,
      fontWeight: FontWeight.w500,
    ),
  );
}

/// 순자산 카드의 금액 — 32/42 · 700 · 고정폭 숫자, 위 6, 흰 글자.
class PCardHeroAmount extends StatelessWidget {
  const PCardHeroAmount(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PSpacing.x1_5),
    child: Text(
      keepAll(text),
      key: const ValueKey('card-hero-amount'),
      semanticsLabel: text,
      style: PTypography.t12.copyWith(
        color: context.colors.staticWhite,
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
      ),
    ),
  );
}

/// 순자산 카드 아래 글 — 13 · 400, 위 4, 흰 글자. 글([text]) 대신 [PDelta] 같은 위젯([child])도 둔다.
class PCardHeroDetail extends StatelessWidget {
  const PCardHeroDetail({super.key, this.text, this.child})
    : assert((text == null) != (child == null), '글(text)이나 위젯(child) 하나만 준다');

  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PSpacing.x1),
    child:
        child ??
        Text(
          keepAll(text!),
          key: const ValueKey('card-hero-detail'),
          semanticsLabel: text,
          style: PTypography.t3.copyWith(
            color: context.colors.staticWhite,
            fontWeight: FontWeight.w400,
          ),
        ),
  );
}
