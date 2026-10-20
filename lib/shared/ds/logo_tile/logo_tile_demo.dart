import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/image_frame/image_frame_samples.dart';
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';

const _cardWide = PSampleImage(PSampleKind.cardWide);
const _cardTall = PSampleImage(PSampleKind.cardTall);
const _logo = PSampleImage(PSampleKind.logo);
const _broken = PBrokenImage();

const _sizes = [PLogoTileSize.s32, PLogoTileSize.s40, PLogoTileSize.s48];

int _px(PLogoTileSize s) => logoTileMetrics(s).box.round();

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

/// 줄 — 옆에 이름이 있으니 타일은 장식. 긴 이름은 줄이 말줄임.
class _Line extends StatelessWidget {
  const _Line({required this.tile, required this.title, required this.detail});

  final Widget tile;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      spacing: PSpacing.x3,
      children: [
        tile,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypography.t5.copyWith(color: c.fgNeutral),
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _wrap(List<Widget> children) => Wrap(
  spacing: PSpacing.x4,
  runSpacing: PSpacing.x4,
  crossAxisAlignment: WrapCrossAlignment.start,
  children: children,
);

/// 카탈로그(/dev/ds) — 크기 셋 · 면(기관 색 · 이름 색) · 그림(카드 · 로고 · 실패) · 줄 안 · 가장 나쁜 값 · 기관 색 표 전체.
class LogoTileDemo extends StatelessWidget {
  const LogoTileDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final table = PInstitutionColors.table.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (table.isEmpty)
          DemoBlock(
            title: '기관 색 표가 비어 있다',
            children: [
              Text(
                '앱에는 스펙 JSON 을 Dart 로 만드는 생성 단계가 아직 없어 기관 색 표가 비어 있다 — 기관 이름도 이름 색으로 '
                '나온다(표가 생기면 기관 색이 그려진다).',
                style: PTypography.t3.copyWith(
                  color: context.colors.fgNeutralMuted,
                ),
              ),
            ],
          ),
        DemoBlock(
          title:
              '크기 32 · 40 · 48 — 모서리는 크기 × 0.3(10 · 12 · 14), 첫 글자는 크기의 40%(13 · 16 · 19)',
          children: [
            DemoRow(
              label: '기관 색 · 흰 글자',
              children: [
                for (final s in _sizes)
                  _Labeled('${_px(s)} · 신한', PLogoTile(size: s, name: '신한')),
              ],
            ),
            DemoRow(
              label: '기관 색 · 짙은 글자',
              children: [
                for (final s in _sizes)
                  _Labeled(
                    '${_px(s)} · KB국민',
                    PLogoTile(size: s, name: 'KB국민'),
                  ),
              ],
            ),
            DemoRow(
              label: '이름 색(기관 없음)',
              children: [
                for (final s in _sizes)
                  _Labeled(
                    '${_px(s)} · 비상금',
                    PLogoTile(size: s, name: '비상금', face: PLogoTileFace.name),
                  ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '면과 첫 글자 — 표를 따로 보는 이름 · 표에 없는 기관 · 로마자 대문자 · 짧은 별칭이 걸리지 않게 face=name',
          children: [
            _wrap([
              _Labeled(
                'NH농협카드 올원 → 든 가장 긴 이름',
                const PLogoTile(name: 'NH농협카드 올원'),
              ),
              _Labeled('IBK기업은행', const PLogoTile(name: 'IBK기업은행')),
              _Labeled('Upbit → U', const PLogoTile(name: 'Upbit')),
              _Labeled('표에 없는 기관 → 이름 색', const PLogoTile(name: '어떤은행')),
              _Labeled(
                '우리 아이 적금 · face=name',
                const PLogoTile(name: '우리 아이 적금', face: PLogoTileFace.name),
              ),
              _Labeled(
                '하나투어 · face=name',
                const PLogoTile(name: '하나투어', face: PLogoTileFace.name),
              ),
              _Labeled(
                '이름이 비면 글자 없이 회색',
                const PLogoTile(name: '', face: PLogoTileFace.name),
              ),
            ]),
          ],
        ),
        DemoBlock(
          title:
              '그림 — 카드 그림(옅은 판 위 카드 전체, 세로는 90° 돌림) · 로고 그림(흰 판 위 contain) · 실패하면 첫 글자 그대로',
          children: [
            DemoRow(
              label: '카드 그림',
              children: [
                for (final s in _sizes)
                  _Labeled(
                    '${_px(s)} · 가로',
                    PLogoTile(
                      size: s,
                      name: '삼성카드',
                      image: _cardWide,
                      imageType: PLogoTileImageType.card,
                    ),
                  ),
                for (final s in _sizes)
                  _Labeled(
                    '${_px(s)} · 세로',
                    PLogoTile(
                      size: s,
                      name: '삼성카드',
                      image: _cardTall,
                      imageType: PLogoTileImageType.card,
                    ),
                  ),
              ],
            ),
            DemoRow(
              label: '로고 그림',
              children: [
                for (final s in _sizes)
                  _Labeled(
                    '${_px(s)} · 흰 판',
                    PLogoTile(
                      size: s,
                      name: '포레스트컴퍼니',
                      face: PLogoTileFace.name,
                      image: _logo,
                    ),
                  ),
              ],
            ),
            DemoRow(
              label: '못 불러옴',
              children: [
                _Labeled(
                  '로고 실패 → 첫 글자',
                  const PLogoTile(
                    name: '새회사',
                    face: PLogoTileFace.name,
                    image: _broken,
                  ),
                ),
                _Labeled(
                  '카드 실패 → 기관 색 첫 글자',
                  const PLogoTile(
                    name: '현대카드',
                    image: _broken,
                    imageType: PLogoTileImageType.card,
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '줄 안에서 — 옆에 이름이 있으니 타일은 장식(첫 글자 · 그림을 읽지 않는다). 긴 이름은 줄이 말줄임',
          children: [
            const _Line(
              tile: PLogoTile(name: '신한'),
              title: '신한 주거래 우대통장',
              detail: '신한 · 입출금',
            ),
            const _Line(
              tile: PLogoTile(name: '카카오뱅크'),
              title: '카카오뱅크 세이프박스',
              detail: '카카오뱅크 · 예금',
            ),
            const _Line(
              tile: PLogoTile(
                name: '삼성카드',
                image: _cardTall,
                imageType: PLogoTileImageType.card,
              ),
              title: '삼성카드 taptap O 아주 아주 긴 카드 이름 확인용 아주 아주 긴 카드 이름',
              detail: '신용 · 삼성카드',
            ),
            const _Line(
              tile: PLogoTile(name: '비상금', face: PLogoTileFace.name),
              title: '비상금',
              detail: '현금',
            ),
          ],
        ),
        DemoBlock(
          title: '가장 나쁜 값 — 짙은 남색 · 노랑 타일이 표면에 묻히지 않는지(윤곽) · 아주 긴 이름도 첫 글자 하나',
          children: [
            _wrap([
              for (final n in ['케이뱅크', '현대카드', '삼성카드', '카카오뱅크', '카카오페이증권'])
                _Labeled(n, PLogoTile(name: n)),
              _Labeled(
                '아주 긴 기관 이름',
                const PLogoTile(
                  name: '이것은아주아주아주긴기관이름이라타일안에서넘치지않아야합니다',
                  face: PLogoTileFace.name,
                ),
              ),
              _Labeled(
                '그림 글자(가족)',
                const PLogoTile(name: '👨‍👩‍👧 우리집', face: PLogoTileFace.name),
              ),
            ]),
          ],
        ),
        if (table.isNotEmpty)
          DemoBlock(
            title:
                '기관 색 표 ${table.length}곳 — 한 색 · 표의 글자색(흰 글자가 4.5:1 에 못 미치면 짙은 글자)',
            children: [
              Wrap(
                spacing: PSpacing.x2,
                runSpacing: PSpacing.x2,
                children: [
                  for (final e in table)
                    PLogoTile(name: e.name, decorative: false),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
