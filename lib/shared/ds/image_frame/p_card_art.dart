import 'dart:math' as math;

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/aspect_ratio/p_aspect_ratio.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.dart';

/// 카드 면의 크기 — 틀의 폭으로 가른다(card-art.yaml size).
enum PCardArtSize {
  /// 폭 96 미만 — 회사 첫 글자만 가운데
  small,

  /// 96 ~ 239 — 왼쪽 아래 회사 + 카드 이름(한 줄)
  medium,

  /// 240 이상 — 한 단계 크게, 카드 이름 두 줄까지
  large,
}

/// 틀 폭 → 카드 면 크기.
PCardArtSize cardArtSizeFor(double width) => width < 96
    ? PCardArtSize.small
    : width < 240
    ? PCardArtSize.medium
    : PCardArtSize.large;

/// 작은 면의 첫 글자 크기 — 면 높이의 40%, 정수로 반올림하고 가장 작아도 10.
double cardArtInitialSize(double height) =>
    math.max(10, (height * 0.4).roundToDouble());

/// 회사 줄 + 카드 이름 한 줄이 면에 드는가 — 면 높이 ≥ (회사 줄 높이 + 카드 이름 한 줄 높이) × 글자 배율 + 아래 여백
/// (여백은 배율을 따르지 않는다). 안 들면 회사 첫 글자 면(small 과 같은 모양)으로 바꾼다(card-art.yaml label.fit,
/// 2026-10-17 사용자 결정 03-D 결정 3 A). 웹은 틀 높이 컨테이너 쿼리 — medium `calc(2.1875rem + 8px)` · large
/// `calc(2.5rem + 14px)`, 앱은 같은 식을 글자 배율로 잰다. small 은 늘 첫 글자라 묻지 않는다.
bool cardArtLabelFits({
  required double height,
  required PCardArtSize size,
  required TextScaler textScaler,
  required double issuerLine,
  required double nameLine,
}) {
  final bottom = size == PCardArtSize.large ? PSpacing.x3_5 : PSpacing.x2;
  final need =
      textScaler.scale(issuerLine) + textScaler.scale(nameLine) + bottom;
  return height >= need;
}

/// 단어 단위로 줄을 바꾼다 — 단어 안(공백 없는 글자 사이)에 U+2060(word joiner)을 끼워 글자 단위로 끊기지 않게 한다
/// (웹 `keep-all` 과 같다 · v114). 너무 긴 한 단어는 그래도 넘치면 끊긴다.
String keepWords(String text) =>
    text.split(' ').map((word) => word.characters.join('⁠')).join(' ');

/// Card Art — 카드 그림. 수치 원본은 groo-design `specs/components/card-art.yaml`(값은
/// `test/fixtures/design_spec/card-art.json`), 구조는 Image Frame(ratio card 1.586)이다. 웹(desk-front
/// `src/shared/ds/image-frame/card-art.tsx`)과 같은 규칙이다.
///
/// 그림이 없거나 실패하면 카드사([issuer])로 가른다.
/// - 아는 카드사(기관 색 표에 있다) — 카드 면: 기관 색 한 색(모드를 따르지 않는다) + 표의 글자색(white = static-white,
///   dark = 라이트 fg-neutral · 다크 fg-neutral-inverted). 광택 · 그라디언트 없이 한 색. 크기는 틀의 폭으로 —
///   small(96 미만: 회사 첫 글자만) · medium(96 ~ 239: 회사 t2 500 한 줄 + 카드 이름 t4 700 한 줄 · 좌우 10 · 아래 8) ·
///   large(240 이상: 회사 t3 + 카드 이름 t5 두 줄까지 · 좌우 16 · 아래 14).
/// - 모르는 카드사 — 대체 그림(credit-card). 브랜드 색 · 회색 면으로 회사 색인 척하지 않는다.
///
/// [decorative] 기본 true — 옆에 이름이 있을 때(그림 · 면을 읽지 않는다). false 면 "카드사 카드이름" 을 읽는다.
/// 상세에는 그림이 떠도 카드 이름을 화면에 글로 둔다 — 부르는 쪽이 한다.
class PCardArt extends StatelessWidget {
  const PCardArt({
    super.key,
    required this.issuer,
    required this.name,
    this.image,
    this.decorative = true,
    this.width,
    this.floaters = const [],
  });

  /// 카드사 이름 — 기관 색 · 첫 글자 · 모르는 회사 가르기.
  final String issuer;

  /// 카드 이름.
  final String name;

  /// 카드 그림 — 없거나 실패하면 카드 면(아는 카드사) · 대체 그림(모르는 카드사). 세로 그림은 90° 돌린다.
  final ImageProvider? image;

  final bool decorative;
  final double? width;
  final List<PImageFrameFloater> floaters;

  @override
  Widget build(BuildContext context) {
    final institution = PInstitutionColors.find(issuer);
    final label = [
      issuer.trim(),
      name.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    return PImageFrame(
      image: image,
      alt: decorative ? '' : label,
      ratio: PAspectRatioValue.card,
      width: width,
      fallbackIcon: LucideIcons.creditCard300,
      floaters: floaters,
      fallback: institution == null
          ? null
          : PCardFace(issuer: issuer, name: name, institution: institution),
    );
  }
}

/// 기관 표의 글자색 — white 는 static-white, dark 는 라이트 fg-neutral · 다크 fg-neutral-inverted.
Color institutionTextColor(BuildContext context, PInstitutionText text) {
  final c = context.colors;
  return switch (text) {
    PInstitutionText.white => c.staticWhite,
    PInstitutionText.dark =>
      Theme.brightnessOf(context) == Brightness.dark
          ? c.fgNeutralInverted
          : c.fgNeutral,
  };
}

/// 카드 면 — 틀을 채운다. 크기는 담긴 틀의 폭으로 정한다.
class PCardFace extends StatelessWidget {
  const PCardFace({
    super.key,
    required this.issuer,
    required this.name,
    required this.institution,
  });

  final String issuer;
  final String name;
  final PInstitutionColor institution;

  @override
  Widget build(BuildContext context) {
    final color = institutionTextColor(context, institution.text);
    return ColoredBox(
      color: institution.color,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = cardArtSizeFor(box.maxWidth);
          final large = size == PCardArtSize.large;
          final issuerStyle = (large ? PTypography.t3 : PTypography.t2)
              .copyWith(fontWeight: FontWeight.w500, color: color);
          final nameStyle = (large ? PTypography.t5 : PTypography.t4).copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          );
          // 글이 안 드는 면(큰 글자) — 회사 줄 + 카드 이름 한 줄(지금 글자 배율)과 아래 여백이 면 높이보다 크면 첫 글자 면
          final fits =
              size == PCardArtSize.small ||
              cardArtLabelFits(
                height: box.maxHeight,
                size: size,
                textScaler: MediaQuery.textScalerOf(context),
                issuerLine: issuerStyle.fontSize! * (issuerStyle.height ?? 1),
                nameLine: nameStyle.fontSize! * (nameStyle.height ?? 1),
              );
          if (size == PCardArtSize.small || !fits) {
            return Center(
              child: Text(
                avatarInitial(issuer),
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: PTypography.fontFamily,
                  fontSize: cardArtInitialSize(box.maxHeight),
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: color,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            );
          }
          return Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                large ? PSpacing.x4 : PSpacing.x2_5,
                0,
                large ? PSpacing.x4 : PSpacing.x2_5,
                large ? PSpacing.x3_5 : PSpacing.x2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issuer.trim(),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: issuerStyle,
                  ),
                  if (name.trim().isNotEmpty)
                    Text(
                      keepWords(name.trim()),
                      maxLines: large ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
