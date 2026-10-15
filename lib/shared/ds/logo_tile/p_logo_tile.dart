import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/aspect_ratio/p_aspect_ratio.dart';
import 'package:porest_desk_app/shared/ds/avatar/p_avatar.dart';
import 'package:porest_desk_app/shared/ds/image_frame/image_loader.dart';
import 'package:porest_desk_app/shared/ds/image_frame/p_card_art.dart';
import 'package:porest_desk_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:porest_desk_app/shared/ds/institution_colors/institution_colors.dart';

/// 크기 — 32 · 40(기본, 목록 줄 — List 타일과 같다) · 48(상세 머리). 이 밖의 크기를 만들지 않는다.
enum PLogoTileSize { s32, s40, s48 }

/// 면 — institution(기관 이름, 기관 색 표에서 찾고 없으면 이름 색) · name(표를 보지 않고 이름 색).
/// 사용자가 지은 자산 이름 · 회사 이름은 name 이다 — 짧은 별칭("우리" · "하나")이 "우리 아이 적금" · "하나투어" 에 걸리지 않게.
enum PLogoTileFace { institution, name }

/// 그림의 종류 — logo(흰 판 위 잘리지 않게) · card(옅은 판 위 카드 전체).
enum PLogoTileImageType { logo, card }

/// 크기마다의 값(logo-tile.yaml) — 한 변 · 모서리(× 0.3) · 첫 글자(40%) · 카드 그림 폭(크기 − 8).
({double box, double radius, double initial, double card}) logoTileMetrics(
  PLogoTileSize size,
) => switch (size) {
  PLogoTileSize.s32 => (
    box: 32,
    radius: PRounded.r2_5,
    initial: 13,
    card: 32 - 2 * PSpacing.x1,
  ),
  PLogoTileSize.s40 => (
    box: 40,
    radius: PRounded.r3,
    initial: 16,
    card: 40 - 2 * PSpacing.x1,
  ),
  PLogoTileSize.s48 => (
    box: 48,
    radius: PRounded.r3_5,
    initial: 19,
    card: 48 - 2 * PSpacing.x1,
  ),
};

/// Logo Tile — 물건 하나(은행 · 증권 · 카드 · 코인 · 금 자산 · 회사)를 보이는 각진 타일. porest 에만 있는 부품(SEED 는 업체를
/// 원 Avatar 로 그린다), 수치 원본은 porest-design `specs/components/logo-tile.yaml`(값은
/// `test/fixtures/design_spec/logo-tile.json`), 기관 색은 `institution-colors.yaml`. 웹(desk-front
/// `src/shared/ds/logo-tile`)과 같은 값 · 같은 규칙이다.
///
/// - 모양 — 정사각, 모서리 크기 × 0.3(32 → 10 · 40 → 12 · 48 → 14). 안쪽 1px 투명 윤곽이 면 · 판 · 그림 위에 늘 있다.
/// - 면 — 기관 색(institution — 표의 color, 모드를 따르지 않는다) 위에 표의 글자색, 또는 이름 색(name · 표에 없는 기관 —
///   Avatar 와 같은 [avatarHueColor]) 위에 fg-neutral-inverted. 저장된 자산 색(asset.color)을 읽지 않는다.
/// - 첫 글자 — Avatar 의 [avatarInitial] · 700 · 줄 높이 1 · 크기의 40%(글자 크기 설정을 따르지 않는 px). 이름이 비면 글자
///   없이 chart-gray.
/// - 그림 — 첫 글자를 먼저 그리고(스켈레톤 없음), 다 받으면 판과 그림이 덮는다(전환 없이 바로). 못 받으면 첫 글자 그대로.
///   판 안쪽 4. logo 는 흰 판 위 contain, card 는 옅은 판 위에 폭 = 크기 − 8 의 카드 비율(1.586) 그림(모서리는 그 폭으로,
///   세로 그림은 90° 돌려 채운다).
/// - 이름 — 이름 옆 타일은 장식이라 타일 전체를 숨긴다([decorative] 기본 true). 혼자면 `decorative: false` — 이름을 가진
///   그림 하나로 읽는다(그림이 있어도 실패해도 같은 이름).
///
/// 누르지 않는다 — 누르는 자리는 감싼 줄 · 버튼.
class PLogoTile extends StatelessWidget {
  const PLogoTile({
    super.key,
    required this.name,
    this.face = PLogoTileFace.institution,
    this.size = PLogoTileSize.s40,
    this.image,
    this.imageType = PLogoTileImageType.logo,
    this.decorative = true,
  });

  /// 필수 — 기관 이름, 없으면 자산 이름. 첫 글자 · 기관 색 찾기 · 이름 색 · 읽는 이름.
  final String name;
  final PLogoTileFace face;
  final PLogoTileSize size;

  /// 그림 — 없으면 첫 글자만.
  final ImageProvider? image;
  final PLogoTileImageType imageType;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = name.trim();
    final institution = face == PLogoTileFace.institution
        ? PInstitutionColors.find(shown)
        : null;
    final m = logoTileMetrics(size);
    final hidden = decorative || shown.isEmpty;

    final initial = ColoredBox(
      color: institution?.color ?? avatarHueColor(c, shown),
      child: Center(
        child: Text(
          avatarInitial(shown),
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: PTypography.fontFamily,
            fontSize: m.initial,
            height: 1,
            fontWeight: FontWeight.w700,
            color: institution == null
                ? c.fgNeutralInverted
                : institutionTextColor(context, institution.text),
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
    // 이름이 비면 글자 없이 chart-gray — avatarHueColor('') 는 코드 포인트 합 0 → blue 라 따로 gray 로 둔다
    final base = shown.isEmpty ? ColoredBox(color: c.chartGray) : initial;

    final source = image;
    final tile = SizedBox(
      width: m.box,
      height: m.box,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(m.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            base,
            if (source != null)
              PImageLoader(
                image: source,
                builder: (context, status, portrait, reveal) =>
                    status == PImageStatus.loaded
                    ? _Plate(
                        type: imageType,
                        image: source,
                        portrait: portrait,
                        card: m.card,
                      )
                    : const SizedBox.shrink(),
              ),
            PImageStroke(radius: m.radius),
          ],
        ),
      ),
    );
    if (hidden) return ExcludeSemantics(child: tile);
    return Semantics(
      container: true,
      image: true,
      label: shown,
      child: ExcludeSemantics(child: tile),
    );
  }
}

/// 판 — 그림이 다 오면 첫 글자를 덮는다. 그림은 판 안쪽 4.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.type,
    required this.image,
    required this.portrait,
    required this.card,
  });

  final PLogoTileImageType type;
  final ImageProvider image;
  final bool portrait;
  final double card;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isCard = type == PLogoTileImageType.card;
    return ColoredBox(
      key: ValueKey('logo-tile-plate-${type.name}'),
      color: isCard ? c.bgNeutralWeak : c.staticWhite,
      child: Padding(
        padding: const EdgeInsets.all(PSpacing.x1),
        child: Center(
          child: isCard
              ? _CardPicture(image: image, portrait: portrait, width: card)
              : Image(
                  key: const ValueKey('logo-tile-image'),
                  image: image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
      ),
    );
  }
}

/// 카드 그림 — 폭 = 크기 − 8, 카드 비율, 모서리는 그 폭으로, 투명 윤곽. 세로 그림은 90° 돌려 채운다.
class _CardPicture extends StatelessWidget {
  const _CardPicture({
    required this.image,
    required this.portrait,
    required this.width,
  });

  final ImageProvider image;
  final bool portrait;
  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = imageFrameRadius(width);
    Widget picture = Image(
      image: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
    if (portrait) picture = RotatedBox(quarterTurns: 1, child: picture);
    return SizedBox(
      key: const ValueKey('logo-tile-card'),
      width: width,
      child: AspectRatio(
        aspectRatio: PAspectRatioValue.card.ratio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              picture,
              PImageStroke(radius: radius),
            ],
          ),
        ),
      ),
    );
  }
}
