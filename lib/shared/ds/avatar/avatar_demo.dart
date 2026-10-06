import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/avatar/p_avatar.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';

/// 카탈로그(/dev/ds) — 크기 10단계, 이름 색 10, 사진(흰 사진의 테두리 · 실패하면 이니셜), 묶음(앞 4명 + "+N").
class AvatarDemo extends StatelessWidget {
  const AvatarDemo({super.key});

  // 이름 색 차례 0 ~ 9 가 하나씩 나오는 이름(코드 포인트 합 % 10)
  static const _hueNames = [
    '김민수', // blue
    '박지훈', // green
    '한지민', // orange
    '박지유', // violet
    '조현우', // pink
    '정다은', // indigo
    '윤서아', // red
    '송지아', // yellow
    '이서연', // brown
    '황민재', // gray
  ];

  // 사진 대신 — 흰 8 × 8(테두리가 흰 바탕과 가르는지) · 16 × 16 그라디언트 · 깨진 바이트(이니셜로 돌아간다)
  static final _white = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAD0lEQVR42mP4jwMwDC0JALoev0GJ6La7AAAAAElFTkSuQmCC',
    ),
  );
  static final _photo = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAZUlEQVR42pXCsQpAQAAG4P+xTSaTDDLIIIMMuqIruqIruiJFV3SlTCbP4Rn+rw+e+Kjwm5eKQD5UhJ2jIlaWinTYqMi1oaKcNBW1UVS0i6Si3wQV415RMduCivXMqDhcQsV1R9Qfnz4en1rCExsAAAAASUVORK5CYII=',
    ),
  );
  static final _broken = MemoryImage(base64Decode('AAECAw=='));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final people = [
      for (final n in ['김민수', '이서연', '박지훈', '최유진', '정다은', '한지민'])
        (name: n, image: null),
    ];
    Widget caption(String text) =>
        Text(text, style: PTypography.t3.copyWith(color: c.fgNeutralMuted));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '크기 — 20 · 24 · 36 · 42 · 48(기본) · 56 · 64 · 80 · 96 · 108',
          children: [
            Wrap(
              spacing: PSpacing.x3,
              runSpacing: PSpacing.x3,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final size in PAvatarSize.values)
                  PAvatar(name: '김민수', size: size),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '이름 색 — 코드 포인트 합 % 10, 웹 · 앱 어디서나 같은 사람은 같은 색',
          children: [
            DemoRow(
              label:
                  'blue · green · orange · violet · pink · indigo · red · '
                  'yellow · brown · gray',
              children: [
                for (final name in _hueNames)
                  PAvatar(name: name, size: PAvatarSize.s36),
              ],
            ),
            DemoRow(
              label: '로마자는 대문자 · 숫자는 그대로',
              children: [
                const PAvatar(name: 'kim minsu', size: PAvatarSize.s36),
                const PAvatar(name: '7월 모임', size: PAvatarSize.s36),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '사진 — 원을 채운다, 흰 사진도 안쪽 1px 선이 가른다, 실패하면 이니셜',
          children: [
            DemoRow(
              label: '흰 사진 · 사진 · 깨진 사진',
              children: [
                PAvatar(name: '김민수', image: _white),
                PAvatar(name: '이서연', image: _photo),
                PAvatar(name: '박지훈', image: _broken),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '묶음 — 앞 4명 + "+N", 지름의 1/4 겹침 · 바탕색 링, 옆에 전체 수를 글로',
          children: [
            Row(
              spacing: PSpacing.x2,
              children: [
                PAvatarStack(people: people),
                caption('6명 · 412,000원'),
              ],
            ),
            Row(
              spacing: PSpacing.x2,
              children: [
                PAvatarStack(
                  people: people.take(3).toList(),
                  size: PAvatarSize.s36,
                ),
                caption('3명'),
              ],
            ),
            PAvatarStack(
              people: [
                for (var i = 0; i < 120; i++) (name: '참여자$i', image: null),
              ],
              size: PAvatarSize.s42,
              semanticsLabel: '참여자 120명',
            ),
          ],
        ),
      ],
    );
  }
}
