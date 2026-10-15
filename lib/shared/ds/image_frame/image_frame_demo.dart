import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/aspect_ratio/p_aspect_ratio.dart';
import 'package:porest_desk_app/shared/ds/badge/p_badge.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/image_frame/image_frame_samples.dart';
import 'package:porest_desk_app/shared/ds/image_frame/p_card_art.dart';
import 'package:porest_desk_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:porest_desk_app/shared/ds/institution_colors/institution_colors.dart';

const _photo = PSampleImage(PSampleKind.photo);
const _photoTall = PSampleImage(PSampleKind.photoTall);
const _white = PSampleImage(PSampleKind.white);
const _dark = PSampleImage(PSampleKind.dark);
const _cardWide = PSampleImage(PSampleKind.cardWide);
const _cardTall = PSampleImage(PSampleKind.cardTall);
const _logo = PSampleImage(PSampleKind.logo);
const _broken = PBrokenImage();
const _never = PNeverImage();

/// 견본 아래 이름표.
class _Labeled extends StatelessWidget {
  const _Labeled(this.caption, this.child);

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: PSpacing.x1_5,
    children: [
      child,
      Text(
        caption,
        style: PTypography.t2.copyWith(color: context.colors.fgNeutralSubtle),
      ),
    ],
  );
}

Widget _wrap(List<Widget> children) => Wrap(
  spacing: PSpacing.x4,
  runSpacing: PSpacing.x4,
  crossAxisAlignment: WrapCrossAlignment.start,
  children: children,
);

final _floaters = [
  const PImageFrameFloater(
    placement: PImageFramePlacement.topStart,
    child: PBadge(label: '단종', variant: PBadgeVariant.solid),
  ),
  const PImageFrameFloater(
    placement: PImageFramePlacement.bottomEnd,
    child: PImageFrameIndicator(text: '1 / 12', label: '사진 12장 중 1번째'),
  ),
];

/// 카탈로그(/dev/ds) — 비율 여덟 · 모서리(폭으로) · 윤곽 · 맞춤 · 세 상태 · 그림 위 요소 · 카드 그림(세로 돌리기) · 카드 면.
/// 그림은 칠한 대역이다(밖으로 요청을 보내지 않는다).
class ImageFrameDemo extends StatelessWidget {
  const ImageFrameDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final noTable = PInstitutionColors.table.entries.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '비율 여덟 가지 — 폭 120(모서리 8), 안쪽 1px 투명 윤곽',
          children: [
            _wrap([
              for (final (ratio, label) in [
                (PAspectRatioValue.r1x1, '정사각'),
                (PAspectRatioValue.r2x1, '넓은 띠'),
                (PAspectRatioValue.r16x9, '동영상'),
                (PAspectRatioValue.r4x3, '기본'),
                (PAspectRatioValue.r6x7, '조금 세로'),
                (PAspectRatioValue.r4x5, '세로'),
                (PAspectRatioValue.r2x3, '긴 세로'),
                (PAspectRatioValue.card, '카드 1.586'),
              ])
                _Labeled(
                  '${ratio.id} — $label',
                  PImageFrame(
                    ratio: ratio,
                    width: 120,
                    image: ratio == PAspectRatioValue.card ? _cardWide : _photo,
                    alt: '',
                  ),
                ),
            ]),
          ],
        ),
        DemoBlock(
          title: '모서리 — 폭으로 고른다(24 이하 4 · 48 이하 6 · 그 위 8 · 화면 폭 0)',
          children: [
            _wrap([
              for (final w in [24.0, 40.0, 48.0, 56.0])
                _Labeled(
                  '폭 ${w.round()} → ${imageFrameRadius(w).round()}',
                  PImageFrame(
                    ratio: PAspectRatioValue.r1x1,
                    width: w,
                    image: _photo,
                    alt: '',
                  ),
                ),
              _Labeled(
                '폭 150 → 8',
                PImageFrame(width: 150, image: _photo, alt: ''),
              ),
              _Labeled(
                '부모 폭(180) → 8',
                SizedBox(
                  width: 180,
                  child: PImageFrame(image: _photo, alt: ''),
                ),
              ),
              _Labeled(
                '화면 폭 bleed → 0, 윤곽은 그대로',
                SizedBox(
                  width: 180,
                  child: PImageFrame(bleed: true, image: _photo, alt: ''),
                ),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title: '윤곽 — 흰 그림이 흰 바탕에 묻히지 않고, 어두운 그림 둘레에는 테가 생기지 않는다',
          children: [
            _wrap([
              _Labeled('흰 그림', PImageFrame(width: 150, image: _white, alt: '')),
              _Labeled(
                '어두운 그림',
                PImageFrame(width: 150, image: _dark, alt: ''),
              ),
              _Labeled(
                '흰 그림 · 작게 56',
                PImageFrame(
                  ratio: PAspectRatioValue.r1x1,
                  width: 56,
                  image: _white,
                  alt: '',
                ),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title:
              '맞춤 — cover(사진 · 카드 그림, 가운데를 남겨 자른다) · contain(로고 — 잘리지 않게, 둘레는 흰 판)',
          children: [
            _wrap([
              _Labeled(
                'cover',
                PImageFrame(
                  ratio: PAspectRatioValue.r1x1,
                  width: 120,
                  image: _photoTall,
                  alt: '',
                ),
              ),
              _Labeled(
                'contain',
                PImageFrame(
                  ratio: PAspectRatioValue.r1x1,
                  width: 120,
                  fit: PImageFit.contain,
                  image: _logo,
                  alt: '',
                ),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title: '세 상태 — 받는 중(스켈레톤, 같은 모서리) · 다 받음 · 없음 · 못 불러옴(대체 그림)',
          children: [
            _wrap([
              _Labeled(
                'loading',
                PImageFrame(
                  width: 150,
                  image: _never,
                  alt: '',
                  // 견본이 스켈레톤을 보이려고 붙잡아 둔다 — 실제로는 10초 뒤 실패로 바뀐다
                  timeout: const Duration(days: 1),
                ),
              ),
              _Labeled(
                'loaded',
                PImageFrame(width: 150, image: _photo, alt: ''),
              ),
              _Labeled('fallback — 그림 없음', PImageFrame(width: 150, alt: '')),
              _Labeled(
                'fallback — 못 불러옴(alt 가 이름)',
                PImageFrame(width: 150, image: _broken, alt: '제주 바다 사진'),
              ),
              _Labeled(
                'loading · 40(작은 틀도 같은 모서리 6)',
                PImageFrame(
                  ratio: PAspectRatioValue.r1x1,
                  width: 40,
                  image: _never,
                  alt: '',
                  timeout: const Duration(days: 1),
                ),
              ),
              _Labeled(
                'fallback · 40',
                PImageFrame(ratio: PAspectRatioValue.r1x1, width: 40, alt: ''),
              ),
              _Labeled(
                'fallback · 카드',
                PImageFrame(ratio: PAspectRatioValue.card, width: 150, alt: ''),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title:
              '그림 위 요소 — 네 모서리 · 둘까지 · 짧은 변 80 이상일 때만(왼쪽 160 에는 배지 · Indicator, 오른쪽 56 은 그리지 않는다)',
          children: [
            _wrap([
              _Labeled(
                '위 시작 배지 · 아래 끝 Indicator',
                PImageFrame(
                  width: 160,
                  image: _photo,
                  alt: '',
                  floaters: _floaters,
                ),
              ),
              _Labeled(
                '흰 그림 위 Indicator',
                PImageFrame(
                  width: 160,
                  image: _white,
                  alt: '',
                  floaters: const [
                    PImageFrameFloater(
                      placement: PImageFramePlacement.topEnd,
                      child: PImageFrameIndicator(
                        text: '+9',
                        label: '사진 9장 더 있음',
                      ),
                    ),
                    PImageFrameFloater(
                      placement: PImageFramePlacement.bottomStart,
                      child: PBadge(
                        label: '단종',
                        variant: PBadgeVariant.solid,
                        tone: PBadgeTone.critical,
                      ),
                    ),
                  ],
                ),
              ),
              _Labeled(
                '56 — 요소를 그리지 않는다',
                PImageFrame(
                  ratio: PAspectRatioValue.r1x1,
                  width: 56,
                  image: _photo,
                  alt: '',
                  floaters: _floaters,
                ),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title: '카드 그림 — 세로 그림은 시계 방향으로 90° 돌려 채운다(가로 틀 · 1.586)',
          children: [
            _wrap([
              _Labeled(
                '가로 그림 · 그대로',
                PImageFrame(
                  ratio: PAspectRatioValue.card,
                  width: 150,
                  image: _cardWide,
                  alt: '',
                ),
              ),
              _Labeled(
                '세로 그림 · 돌림',
                PImageFrame(
                  ratio: PAspectRatioValue.card,
                  width: 150,
                  image: _cardTall,
                  alt: '',
                ),
              ),
              _Labeled(
                '세로 그림 · 목록 56',
                PImageFrame(
                  ratio: PAspectRatioValue.card,
                  width: 56,
                  image: _cardTall,
                  alt: '',
                ),
              ),
              _Labeled(
                '세로 사진을 4:3 에 — 돌리지 않는다(cover)',
                PImageFrame(width: 150, image: _cardTall, alt: ''),
              ),
            ]),
            DemoRow(
              label: '여러 장 · 가로 줄',
              children: [
                for (var i = 0; i < 3; i++)
                  PImageFrame(
                    ratio: PAspectRatioValue.r4x5,
                    width: 96,
                    image: _photoTall,
                    alt: '',
                  ),
              ],
            ),
          ],
        ),
        if (noTable)
          DemoBlock(
            title: '기관 색 표가 비어 있다',
            children: [
              Text(
                '앱에는 스펙 JSON 을 Dart 로 만드는 생성 단계가 아직 없어 기관 색 표가 비어 있다 — 아는 카드사도 대체 그림으로 '
                '나온다(표가 생기면 아래 카드 면이 그려진다).',
                style: PTypography.t3.copyWith(
                  color: context.colors.fgNeutralMuted,
                ),
              ),
            ],
          ),
        DemoBlock(
          title:
              '카드 면 — 그림이 없는 아는 카드사(작게 56 — 첫 글자 · 가운데 160 — 회사 + 카드 이름 · 크게 282 — 한 단계 크게)',
          children: [
            _wrap([
              _Labeled(
                'small · 56 (신한카드)',
                const PCardArt(issuer: '신한카드', name: 'Deep Dream', width: 56),
              ),
              _Labeled(
                'small · 44 (KB국민카드)',
                const PCardArt(issuer: 'KB국민카드', name: '노리2', width: 44),
              ),
              _Labeled(
                'medium · 160 (NH농협카드)',
                const PCardArt(issuer: 'NH농협카드', name: '올원 카드', width: 160),
              ),
              _Labeled(
                'medium · 96 (삼성카드)',
                const PCardArt(issuer: '삼성카드', name: 'taptap O', width: 96),
              ),
              _Labeled(
                'large · 282 (현대카드)',
                const PCardArt(issuer: '현대카드', name: 'the Purple', width: 282),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title:
              '가장 나쁜 값 — 아주 긴 이름(한 줄 말줄임 · 두 줄까지) · 모르는 카드사(대체 그림) · 그림 못 불러옴 → 카드 면',
          children: [
            _wrap([
              _Labeled(
                'medium · 긴 회사 · 긴 카드 이름',
                const PCardArt(
                  issuer: 'NH농협카드 아주아주아주 긴 카드사 이름 확인용',
                  name: '이름이 아주아주 길어서 한 줄로 안 들어가는 카드 이름 확인용',
                  width: 160,
                ),
              ),
              _Labeled(
                'large · 두 줄까지',
                const PCardArt(
                  issuer: 'KB국민카드',
                  name: '이름이 아주아주 길어서 두 줄로도 안 들어가는 카드 이름 확인용 카드 이름 확인용 카드 이름',
                  width: 282,
                ),
              ),
              _Labeled(
                '모르는 카드사 · 대체 그림',
                const PCardArt(issuer: '어떤카드사', name: '이름 모르는 카드', width: 160),
              ),
              _Labeled(
                '그림 못 불러옴 → 카드 면',
                const PCardArt(
                  issuer: '롯데카드',
                  name: 'LOCA 365',
                  width: 160,
                  image: _broken,
                ),
              ),
              _Labeled(
                '혼자 있는 카드(decorative=false) — 이름을 읽는다',
                const PCardArt(
                  issuer: '우리카드',
                  name: '카드의정석',
                  width: 160,
                  decorative: false,
                ),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title: '그림이 있는 카드 — 가로 · 세로(돌림) · 그림 위 단종 배지 · 흰 카드',
          children: [
            _wrap([
              _Labeled(
                '가로 그림',
                const PCardArt(
                  issuer: '삼성카드',
                  name: 'PORTRAIT TEST',
                  width: 160,
                  image: _cardWide,
                ),
              ),
              _Labeled(
                '세로 그림 · 돌림 + 단종 배지',
                const PCardArt(
                  issuer: '삼성카드',
                  name: '세로 카드',
                  width: 160,
                  image: _cardTall,
                  floaters: [
                    PImageFrameFloater(
                      placement: PImageFramePlacement.topStart,
                      child: PBadge(label: '단종', variant: PBadgeVariant.solid),
                    ),
                  ],
                ),
              ),
              _Labeled(
                '흰 카드 · 윤곽',
                const PCardArt(
                  issuer: '신한카드',
                  name: 'SELECT',
                  width: 160,
                  image: _white,
                ),
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
