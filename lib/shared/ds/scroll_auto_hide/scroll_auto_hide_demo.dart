import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

/// 카탈로그(/dev/ds) — 다 드러남(맨 위) · 직접 스크롤(내린 만큼 숨고 올린 만큼 드러나며 멈추면 절반 기준으로 200ms 스냅) · 가장 나쁜
/// 값(키 큰 머리 + 짧은 목록). 웹 `scroll-auto-hide.demo.tsx` 와 같은 구성이다. 모션 줄이기를 켜면 늘 보인다.
class ScrollAutoHideDemo extends StatelessWidget {
  const ScrollAutoHideDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_LiveDemo(), _WorstDemo()],
    );
  }
}

/// 폰 가계부 원장 머리 — 월 · 총액 · 주 달력 한 줄.
class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({this.tall = false});

  final bool tall;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.x6,
        vertical: PSpacing.x4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PSpacing.x2,
        children: [
          Text(
            '2026년 10월',
            style: PTypography.t5.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '이번 달 쓴 돈 1,240,000원',
            style: PTypography.t4.copyWith(color: c.fgNeutralMuted),
          ),
          Row(
            spacing: PSpacing.x2,
            children: [
              for (final d in ['월', '화', '수', '목', '금', '토', '일'])
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ),
            ],
          ),
          if (tall) const SizedBox(height: 140),
        ],
      ),
    );
  }
}

Widget _list(ScrollController controller, double headerHeight, int count) =>
    ListView.builder(
      controller: controller,
      padding: EdgeInsets.only(top: headerHeight),
      itemCount: count,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpacing.x6,
          vertical: PSpacing.x3_5,
        ),
        child: Text(
          keepAll('10월 ${i + 1}일 · 거래 ${i + 1}'),
          style: PTypography.t5.copyWith(color: context.colors.fgNeutral),
        ),
      ),
    );

class _Phone extends StatelessWidget {
  const _Phone({required this.child, this.height = 360});

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
        child: SizedBox(height: height, width: double.infinity, child: child),
      ),
    );
  }
}

class _LiveDemo extends StatelessWidget {
  const _LiveDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '직접 스크롤 — 내린 만큼 숨고 올린 만큼 드러나며 멈추면 절반 기준으로 200ms 스냅. 높이는 그대로, 위로 옮기기만 한다',
      children: [
        DemoRow(
          label: 'shown · hidden — 목록을 끌어 본다',
          children: [
            SizedBox(
              width: double.infinity,
              child: _Phone(
                child: PScrollAutoHide(
                  header: const _LedgerHeader(),
                  builder: (context, controller, h) => _list(controller, h, 40),
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
      title: '가장 나쁜 값 — 키 큰 머리 + 짧은 목록(스크롤이 거의 없다)',
      children: [
        _Phone(
          height: 300,
          child: PScrollAutoHide(
            header: const _LedgerHeader(tall: true),
            builder: (context, controller, h) => _list(controller, h, 4),
          ),
        ),
      ],
    );
  }
}
