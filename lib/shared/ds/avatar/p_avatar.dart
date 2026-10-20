import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

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

/// Avatar — 사람을 보이는 원. 구조는 SEED Avatar(2026-10-03), 수치 원본은 groo-design `specs/components/avatar.yaml`
/// (값은 `test/fixtures/design_spec/avatar.json`). 웹(desk-front `src/shared/ds/avatar`)과 같은 값 · 같은 이니셜 · 같은 색이다.
///
/// 사진이 원을 채우고(cover), 불러오는 동안 · 실패하면 이니셜(이름의 첫 글자 + 이름 색 바탕, 글자 fg-neutral-inverted ·
/// 700 · 줄 높이 1 · 글자 크기 설정을 따르지 않는다)이 보인다. 모든 크기에 안쪽 1px 테두리(stroke-neutral-overlay) —
/// 흰 사진이 흰 바탕에 묻히지 않게, 크기는 변하지 않는다. 누르지 않는다(누르는 자리는 감싼 버튼).
/// 옆에 이름이 있으면 읽지 않는다(기본). 이름 없이 아바타만 있으면 [decorative] false — 이름을 읽는다.
///
/// 사진 바꾸기 자리(avatar.yaml edit=photo · 상태 uploading)에서 올리는 중이면 [uploadProgress](0 ~ 1, 범위 밖은 끝에서
/// 멈춘다)를 준다 — 원 위 딤(라이트 50% · 다크 65%) 가운데 값 있는 Progress Circle 24(staticWhite, 이름 [uploadLabel],
/// 값 글 "40%"). 올리는 동안은 보조 기술에서 숨기지 않는다 — 이름이 있으면(decorative false) 이름을 가진 묶음으로 읽고
/// 안의 진행 원이 따로 읽힌다(웹 role="group").
class PAvatar extends StatelessWidget {
  const PAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = PAvatarSize.s48,
    this.decorative = true,
    this.uploadProgress,
    this.uploadLabel = '프로필 사진 올리는 중',
  });

  /// 표시 이름 — 이니셜 · 이름 색 · 읽는 이름.
  final String name;
  final ImageProvider? image;
  final PAvatarSize size;
  final bool decorative;

  /// 올리는 중 0 ~ 1 — 주면 원 위 딤 + 값 있는 원 24(staticWhite). 끝나면 null. 유한하지 않은 값은 주지 않은 것으로 본다.
  final double? uploadProgress;

  /// 올리는 중 진행 원의 이름 — 기본은 웹과 같은 "프로필 사진 올리는 중"(문구는 부르는 쪽이 바꿔 넘긴다).
  final String uploadLabel;

  bool get _uploading => uploadProgress != null && uploadProgress!.isFinite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = avatarMetrics(size);
    // 이니셜 글자는 읽지 않는다 — 이름은 바깥(Semantics)이 가진다(웹 aria-hidden)
    final initial = ColoredBox(
      color: avatarHueColor(c, name),
      child: Center(
        child: ExcludeSemantics(
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
          // 올리는 중 덮개 — 원 위 딤 + 값 있는 원 24. 위의 안쪽 테두리 아래에 깔린다
          if (_uploading)
            ColoredBox(
              key: const ValueKey('avatar-upload'),
              color: c.overlayDim,
              child: Center(
                child: PProgressCircle(
                  size: PProgressCircleSize.s24,
                  tone: PProgressCircleTone.staticWhite,
                  value: uploadProgress!.clamp(0.0, 1.0) * 100,
                  semanticsLabel: uploadLabel,
                ),
              ),
            ),
        ],
      ),
    );
    if (_uploading) {
      // 올리는 동안은 숨기지 않는다 — 진행 원이 읽혀야 한다. 이름이 있으면 이름을 가진 묶음, 장식이면 진행 원만
      return decorative
          ? face
          : Semantics(
              container: true,
              explicitChildNodes: true,
              label: name.trim(),
              child: face,
            );
    }
    if (decorative) return ExcludeSemantics(child: face);
    return Semantics(
      container: true,
      image: true,
      label: name.trim(),
      child: ExcludeSemantics(child: face),
    );
  }
}

/// 사진 바꾸기 — 아바타 + 늘 보이는 버튼 둘(avatar.yaml edit=photo). 마우스 올림에 기대는 덮개를 두지 않는다.
/// 아바타(기본 108 — HR 직원 정보 수정 · 앱 프로필 수정) 아래 16 에 "사진 바꾸기"(Button neutralWeak small) ·
/// "사진 지우기"(ghost small — 사진이 있을 때만), 사이 8 · 가운데 정렬 · 좁으면 줄을 바꾼다. 올리는 동안([uploadProgress]
/// 가 있을 때)은 두 버튼이 막힌다. 아바타는 옆에 이름이 없으니 늘 이름을 읽는다(decorative false).
///
/// 문구는 호출하는 쪽이 넘긴다. [onChange] 는 고르기 자리를 연다 — 스펙은 앱에서 Menu Sheet("사진 찍기 · 앨범에서 고르기")를
/// 열게 하지만 Menu Sheet 가 아직 없어 콜백만 받는다. 실패를 Field 오류 글로 알리는 것 · 파일을 고르는 창 · 올리는 일은
/// 부르는 쪽이 한다.
class PAvatarPhotoEdit extends StatelessWidget {
  const PAvatarPhotoEdit({
    super.key,
    required this.name,
    required this.changeLabel,
    required this.removeLabel,
    required this.onChange,
    required this.onRemove,
    this.image,
    this.size = PAvatarSize.s108,
    this.uploadProgress,
    this.uploadLabel = '프로필 사진 올리는 중',
  });

  /// 표시 이름 — 이니셜 · 이름 색 · 아바타를 읽는 이름.
  final String name;

  /// 사진 — 없으면 이니셜이고 "사진 지우기" 도 없다.
  final ImageProvider? image;
  final PAvatarSize size;

  /// 올리는 중 0 ~ 1 — 주면 원 위 딤 + 값 있는 원 · 두 버튼 막힘. 끝나면 null.
  final double? uploadProgress;
  final String changeLabel;
  final String removeLabel;
  final String uploadLabel;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final uploading = uploadProgress != null && uploadProgress!.isFinite;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      // 아바타 ↔ 버튼 줄 16
      spacing: PSpacing.x4,
      children: [
        PAvatar(
          name: name,
          image: image,
          size: size,
          decorative: false,
          uploadProgress: uploadProgress,
          uploadLabel: uploadLabel,
        ),
        Wrap(
          key: const ValueKey('avatar-edit-actions'),
          alignment: WrapAlignment.center,
          // 버튼 사이 8 — 좁아 줄이 바뀌어도 같다
          spacing: PSpacing.x2,
          runSpacing: PSpacing.x2,
          children: [
            PButton(
              label: changeLabel,
              variant: PButtonVariant.neutralWeak,
              size: PButtonSize.small,
              onPressed: uploading ? null : onChange,
            ),
            if (image != null)
              PButton(
                label: removeLabel,
                variant: PButtonVariant.ghost,
                size: PButtonSize.small,
                onPressed: uploading ? null : onRemove,
              ),
          ],
        ),
      ],
    );
  }
}

/// 묶음의 한 사람.
typedef PAvatarPerson = ({String name, ImageProvider? image});

/// Avatar Stack — 아바타를 가로로 겹쳐 놓는다(뒤에 오는 아바타가 위). 수치 원본은 groo-design
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
