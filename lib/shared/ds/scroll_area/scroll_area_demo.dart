import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/scroll_area/p_scroll_area.dart';
import 'package:porest_desk_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

/// 카탈로그(/dev/ds) — 놓인 자리(page · overlay · row) × 초점 가는 것(이름 있는 상자 · 안에 누르는 것이 있는 상자) · 가장 나쁜 값
/// (시트 안 상자 안의 상자). 웹 `scroll-area.demo.tsx` 와 같은 구성이다. 막대는 앱에서 스크롤할 때만 보이는 플랫폼 스크롤바라
/// 견본은 멈춰 보인다(`thumbVisibility`) — 모양은 전역 ScrollbarTheme(`stroke-neutral-solid` · 6 · 알약)다.
class ScrollAreaDemo extends StatelessWidget {
  const ScrollAreaDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_ContextDemo(), _WorstDemo()],
    );
  }
}

const List<String> _policy = [
  '연차는 입사일 기준으로 발생해요.',
  '반차는 오전 · 오후로 나눠 쓸 수 있어요.',
  '병가는 증빙을 내면 연차에서 빼지 않아요.',
  '경조사 휴가는 사유에 따라 일수가 달라요.',
  '쓰지 않은 연차는 연말에 정산해요.',
  '휴가 신청은 사용일 3일 전까지 올려요.',
  '승인은 팀장 · 인사 담당자 순으로 이어져요.',
  '취소는 사용일 전날까지 할 수 있어요.',
];

Widget _text() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    for (final line in _policy)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpacing.x1_5),
        child: Text(keepAll(line), style: PTypography.t4),
      ),
  ],
);

/// 흰 면 위 상자 — 높이를 정한다.
class _Box extends StatelessWidget {
  const _Box({required this.child, this.height = 140});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgLayerDefault,
        border: Border.all(color: c.strokeNeutralWeak),
        borderRadius: BorderRadius.circular(PRounded.r3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.r3 - 1),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x4),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ContextDemo extends StatelessWidget {
  const _ContextDemo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget chip(String text) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.x3_5,
        vertical: PSpacing.x1_5,
      ),
      decoration: BoxDecoration(
        color: c.bgNeutralWeak,
        borderRadius: BorderRadius.circular(PRounded.full),
      ),
      child: Text(text, style: PTypography.t3.copyWith(color: c.fgNeutral)),
    );
    return DemoBlock(
      title:
          '놓인 자리 × 초점 가는 것 — 막대는 전역 6px 알약. 이름 있는 상자는 상자가 이름을 받는다(안에 누르는 것이 없을 때만)',
      children: [
        DemoRow(
          label: 'page · 이름 있는 상자(label)',
          children: [
            SizedBox(
              width: double.infinity,
              child: _Box(
                child: PScrollArea(
                  label: '휴가 정책',
                  thumbVisibility: true,
                  child: _text(),
                ),
              ),
            ),
          ],
        ),
        DemoRow(
          label: 'page · 안에 누르는 것이 있는 상자(이름 없음)',
          children: [
            SizedBox(
              width: double.infinity,
              child: _Box(
                child: PScrollArea(
                  thumbVisibility: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final line in _policy)
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            onTap: () {},
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: PSpacing.x2_5,
                              ),
                              child: Text(keepAll(line), style: PTypography.t4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        DemoRow(
          label: 'overlay · 시트 · 대화상자 안(끝에서 튀지 않는다)',
          children: [
            SizedBox(
              width: double.infinity,
              child: _Box(
                child: PScrollArea(
                  use: PScrollAreaUse.overlay,
                  label: '휴가 정책',
                  thumbVisibility: true,
                  child: _text(),
                ),
              ),
            ),
          ],
        ),
        DemoRow(
          label: 'row · 가로 줄(스크롤바 없음, 끝은 Scroll Fog row 흐림)',
          children: [
            SizedBox(
              width: double.infinity,
              height: 40,
              child: PScrollFog(
                use: PScrollFogUse.row,
                child: Row(
                  spacing: PSpacing.betweenChips,
                  children: [
                    for (final t in [
                      '전체',
                      '식비',
                      '교통',
                      '쇼핑',
                      '주거',
                      '의료',
                      '여가',
                      '교육',
                    ])
                      chip(t),
                  ],
                ),
              ),
            ),
          ],
        ),
        DemoRow(
          label: 'both · 가로 · 세로 모두',
          children: [
            SizedBox(
              width: double.infinity,
              child: _Box(
                child: PScrollArea(
                  orientation: PScrollAreaOrientation.both,
                  label: '표',
                  thumbVisibility: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in _policy)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: PSpacing.x1_5,
                          ),
                          child: Text(
                            '$line $line',
                            softWrap: false,
                            style: PTypography.t4,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorstDemo extends StatelessWidget {
  const _WorstDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title: '가장 나쁜 값 — 시트 안 상자 안의 상자(중첩 스크롤). 안쪽 끝에서 바깥이 따라오지 않는다',
      children: [
        _Box(
          height: 260,
          child: PScrollArea(
            use: PScrollAreaUse.overlay,
            label: '시트 본문',
            thumbVisibility: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _text(),
                SizedBox(
                  height: 120,
                  child: PScrollArea(
                    use: PScrollAreaUse.overlay,
                    label: '안쪽 상자',
                    thumbVisibility: true,
                    child: _text(),
                  ),
                ),
                _text(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
