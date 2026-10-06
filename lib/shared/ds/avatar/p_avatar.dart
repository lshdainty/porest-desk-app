import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

/// 크기 — 지름(px). 기본 48. 글 한 줄 안 20 · 줄 안 묶음 24 · 한 줄 목록 36 · 두 줄 목록 42 · 계정 화면 머리 80 …
enum PAvatarSize { s20, s24, s36, s42, s48, s56, s64, s80, s96, s108 }

/// 크기마다의 값(avatar.yaml · avatar-stack.yaml) — 지름 · 이니셜 글자 · 묶음 겹침 · 묶음 링 · "+N" 글자.
@visibleForTesting
({double diameter, double initial, double overlap, double ring, double more})
avatarMetrics(PAvatarSize size) => switch (size) {
  PAvatarSize.s20 => (diameter: 20, initial: 10, overlap: 5, ring: 1, more: 10),
  PAvatarSize.s24 => (diameter: 24, initial: 10, overlap: 6, ring: 1, more: 10),
  PAvatarSize.s36 => (diameter: 36, initial: 14, overlap: 8, ring: 2, more: 13),
  PAvatarSize.s42 => (
    diameter: 42,
    initial: 17,
    overlap: 10,
    ring: 2,
    more: 15,
  ),
  PAvatarSize.s48 => (
    diameter: 48,
    initial: 19,
    overlap: 12,
    ring: 2,
    more: 17,
  ),
  PAvatarSize.s56 => (
    diameter: 56,
    initial: 22,
    overlap: 13,
    ring: 3,
    more: 20,
  ),
  PAvatarSize.s64 => (
    diameter: 64,
    initial: 26,
    overlap: 16,
    ring: 3,
    more: 23,
  ),
  PAvatarSize.s80 => (
    diameter: 80,
    initial: 32,
    overlap: 20,
    ring: 4,
    more: 29,
  ),
  PAvatarSize.s96 => (
    diameter: 96,
    initial: 38,
    overlap: 24,
    ring: 5,
    more: 35,
  ),
  PAvatarSize.s108 => (
    diameter: 108,
    initial: 43,
    overlap: 27,
    ring: 5,
    more: 39,
  ),
};

/// 이니셜 — 표시 이름(앞뒤 공백만 뺀 글)의 첫 글자 하나(사용자가 보는 글자 단위). 로마자만 대문자로.
/// "김민수" → "김", "Kim Minsu" → "K". 웹 avatarInitial 과 같은 규칙이다.
String avatarInitial(String name) {
  final shown = name.trim();
  if (shown.isEmpty) return '';
  return shown.characters.first.toUpperCase();
}

/// 이름 색의 차례 — 표시 이름의 유니코드 코드 포인트(UTF-16 단위가 아니다)를 모두 더해 10 으로 나눈 나머지.
/// 차트 색 순서(v110): blue · green · orange · violet · pink · indigo · red · yellow · brown · gray. 웹 avatarHue 와 같다.
int avatarHueIndex(String name) =>
    name.trim().runes.fold(0, (sum, rune) => sum + rune) % 10;

/// 이름 색 — 차트 색(라이트 700 · 다크 800-dark). 색은 뜻이 없다(장식).
Color avatarHueColor(PColors c, String name) => [
  c.chartBlue,
  c.chartGreen,
  c.chartOrange,
  c.chartViolet,
  c.chartPink,
  c.chartIndigo,
  c.chartRed,
  c.chartYellow,
  c.chartBrown,
  c.chartGray,
][avatarHueIndex(name)];

/// Avatar — 사람을 보이는 원. 구조는 SEED Avatar(2026-10-03), 수치 원본은 porest-design `specs/components/avatar.yaml`
/// (값은 `test/fixtures/design_spec/avatar.json`). 웹(desk-front `src/shared/ds/avatar`)과 같은 값 · 같은 이니셜 · 같은 색이다.
///
/// 사진이 원을 채우고(cover), 불러오는 동안 · 실패하면 이니셜(이름의 첫 글자 + 이름 색 바탕, 글자 fg-neutral-inverted ·
/// 700 · 줄 높이 1 · 글자 크기 설정을 따르지 않는다)이 보인다. 모든 크기에 안쪽 1px 테두리(stroke-neutral-overlay) —
/// 흰 사진이 흰 바탕에 묻히지 않게, 크기는 변하지 않는다. 누르지 않는다(누르는 자리는 감싼 버튼).
/// 옆에 이름이 있으면 읽지 않는다(기본). 이름 없이 아바타만 있으면 [decorative] false — 이름을 읽는다.
class PAvatar extends StatelessWidget {
  const PAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = PAvatarSize.s48,
    this.decorative = true,
  });

  /// 표시 이름 — 이니셜 · 이름 색 · 읽는 이름.
  final String name;
  final ImageProvider? image;
  final PAvatarSize size;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = avatarMetrics(size);
    final initial = ColoredBox(
      color: avatarHueColor(c, name),
      child: Center(
        child: Text(
          avatarInitial(name),
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: PTypography.fontFamily,
            fontSize: m.initial,
            height: 1,
            fontWeight: FontWeight.w700,
            color: c.fgNeutralInverted,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
    final face = Container(
      width: m.diameter,
      height: m.diameter,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      // 안쪽 1px — 위에 그려 크기를 바꾸지 않는다
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.strokeNeutralOverlay, width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          initial,
          if (image != null)
            Image(
              image: image!,
              fit: BoxFit.cover,
              // 불러오는 동안 · 실패하면 이니셜이 보인다
              frameBuilder: (context, child, frame, wasSync) =>
                  frame == null && !wasSync ? const SizedBox.shrink() : child,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
    if (decorative) return ExcludeSemantics(child: face);
    return Semantics(
      container: true,
      image: true,
      label: name.trim(),
      child: ExcludeSemantics(child: face),
    );
  }
}

/// 묶음의 한 사람.
typedef PAvatarPerson = ({String name, ImageProvider? image});

/// Avatar Stack — 아바타를 가로로 겹쳐 놓는다(뒤에 오는 아바타가 위). 수치 원본은 porest-design
/// `specs/components/avatar-stack.yaml`. 앞 4명까지, 5명 이상이면 앞 4명 + "+N"(N = 전체 − 4, 99 를 넘으면 "+99").
/// 아바타마다 바깥 링(놓인 바탕색 — 크기를 바꾸지 않는다)이 앞 아바타를 끊는다. 시트 · 대화상자 안이면
/// [onFloating] — 링이 bg-layer-floating 이다.
/// [semanticsLabel] 을 주면 묶음 하나로 읽고("참여자 6명: 김민수, 이서연, 박지훈, 최유진 외 2명"), 없으면 읽지 않는다
/// (묶음 옆 글이 수를 말한다).
class PAvatarStack extends StatelessWidget {
  const PAvatarStack({
    super.key,
    required this.people,
    this.size = PAvatarSize.s24,
    this.onFloating = false,
    this.semanticsLabel,
  });

  final List<PAvatarPerson> people;
  final PAvatarSize size;
  final bool onFloating;
  final String? semanticsLabel;

  /// 보이는 사람 수 — 앞 4명까지.
  static const int maxShown = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = avatarMetrics(size);
    final ringColor = onFloating ? c.bgLayerFloating : c.bgLayerDefault;
    final shown = people.take(maxShown).toList();
    final rest = people.length - shown.length;
    final step = m.diameter - m.overlap;

    Widget ringed(Widget child) => DecoratedBox(
      // 바깥 링 — 퍼진 그림자로 그려 크기를 바꾸지 않는다
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: ringColor, spreadRadius: m.ring)],
      ),
      child: child,
    );

    final items = <Widget>[
      for (final person in shown)
        ringed(PAvatar(name: person.name, image: person.image, size: size)),
      if (rest > 0)
        ringed(
          Container(
            key: const ValueKey('avatar-stack-overflow'),
            width: m.diameter,
            height: m.diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.bgNeutralWeak,
            ),
            child: Text(
              '+${rest > 99 ? 99 : rest}',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: PTypography.fontFamily,
                fontSize: m.more,
                height: 1,
                fontWeight: FontWeight.w700,
                color: c.fgNeutralMuted,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
          ),
        ),
    ];

    final stack = SizedBox(
      width: items.isEmpty ? 0 : m.diameter + step * (items.length - 1),
      height: m.diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < items.length; i++)
            Positioned(left: step * i, top: 0, child: items[i]),
        ],
      ),
    );
    if (semanticsLabel == null) return ExcludeSemantics(child: stack);
    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(child: stack),
    );
  }
}
