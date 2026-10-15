import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/collapsible/p_collapsible.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

const String _longTitle =
    '연회비 · 카드 발급 후 첫 달 실적 기준으로 산정하며 전월 이용 실적이 기준에 못 미치면 청구 할인이 적용되지 않으니 꼭 확인해 주세요';

/// 카탈로그(/dev/ds) — 놓인 면(standard · card · warning) × 펼침 × 설명 × 펼친 내용(text · rows) · 상태(막힘) · 쥐고 다루는 펼침 ·
/// 가장 나쁜 값(긴 이름 · 긴 설명 · 펼친 채 내용이 늘어남). 웹 `collapsible.demo.tsx` 와 같은 구성이다. 경고 상자는 화면이
/// 그리는 것이라 견본이 상자(바탕 · 테두리 · 모서리 12 · 경고 글)를 같이 그린다.
class CollapsibleDemo extends StatelessWidget {
  const CollapsibleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_MatrixDemo(), _StateDemo(), _ControlledDemo(), _WorstDemo()],
    );
  }
}

/// 면 — standard 는 흰 면, card 는 회색 바닥 위(카드가 면을 그린다), warning 은 경고 상자(바탕 · 테두리 · 모서리 12 · 경고 글
/// 위 14 · 좌우 16 · 아래 12 — 화면이 그린다).
class _Stage extends StatelessWidget {
  const _Stage({required this.surface, required this.child});

  final PCollapsibleSurface surface;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    switch (surface) {
      case PCollapsibleSurface.standard:
        return ColoredBox(color: c.bgLayerDefault, child: child);
      case PCollapsibleSurface.card:
        return ColoredBox(
          color: c.bgLayerBasement,
          child: Padding(
            padding: const EdgeInsets.all(PSpacing.x4),
            child: child,
          ),
        );
      case PCollapsibleSurface.warning:
        return Padding(
          padding: const EdgeInsets.all(PSpacing.x4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.bgWarningWeak,
              border: Border.all(color: c.strokeWarningWeak),
              borderRadius: BorderRadius.circular(PRounded.r3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PRounded.r3 - 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PSpacing.x4,
                      PSpacing.x3_5,
                      PSpacing.x4,
                      PSpacing.x3,
                    ),
                    child: Text(
                      '분할 합계가 거래 금액과 달라요',
                      style: PTypography.t4.copyWith(
                        color: c.fgWarning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        );
    }
  }
}

const Map<PCollapsibleSurface, String> _titles = {
  PCollapsibleSurface.standard: '분할 내역',
  PCollapsibleSurface.card: '상세 검색 조건',
  PCollapsibleSurface.warning: '맞지 않는 내역 보기',
};

Widget _content(PCollapsibleLayout layout) {
  if (layout == PCollapsibleLayout.rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in ['식비 · 12,000원', '교통 · 4,500원', '쇼핑 · 30,000원'])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpacing.x3),
            child: Text(row, style: PTypography.t5),
          ),
      ],
    );
  }
  return Text(
    keepAll('분할한 금액의 합이 거래 금액과 같아야 저장할 수 있어요. 남은 금액은 마지막 칸에 채워 보세요.'),
    style: PTypography.articleNote,
  );
}

class _MatrixDemo extends StatelessWidget {
  const _MatrixDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title: '놓인 면 × 펼침 × 설명 × 펼친 내용 — 접힘 54 · 설명 있으면 74, 줄 목록은 아래 8(카드는 24)',
      children: [
        for (final surface in PCollapsibleSurface.values)
          for (final open in [false, true])
            for (final shown in [false, true])
              for (final layout
                  in open
                      ? PCollapsibleLayout.values
                      : [PCollapsibleLayout.text])
                DemoRow(
                  label:
                      '${surface.name} · ${open ? 'expanded' : 'collapsed'} · ${shown ? '설명' : '이름만'} · ${layout.name}',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _Stage(
                        surface: surface,
                        child: PCollapsible(
                          surface: surface,
                          layout: layout,
                          defaultOpen: open,
                          title: _titles[surface]!,
                          description: shown ? '합계 123,456원' : null,
                          child: _content(layout),
                        ),
                      ),
                    ),
                  ],
                ),
      ],
    );
  }
}

class _StateDemo extends StatelessWidget {
  const _StateDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '상태 — 막힘은 제목 · 설명 · 꺾쇠가 모두 fg-disabled(흐리게 하지 않는다). 누름은 손가락으로 눌러 본다',
      children: [
        for (final surface in PCollapsibleSurface.values)
          DemoRow(
            label: '${surface.name} · disabled',
            children: [
              SizedBox(
                width: double.infinity,
                child: _Stage(
                  surface: surface,
                  child: PCollapsible(
                    surface: surface,
                    disabled: true,
                    title: _titles[surface]!,
                    description: '합계 123,456원',
                    child: _content(PCollapsibleLayout.text),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ControlledDemo extends StatefulWidget {
  const _ControlledDemo();

  @override
  State<_ControlledDemo> createState() => _ControlledDemoState();
}

class _ControlledDemoState extends State<_ControlledDemo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title: '쥐고 다루는 펼침(open · onOpenChange)',
      children: [
        _Stage(
          surface: PCollapsibleSurface.standard,
          child: PCollapsible(
            open: _open,
            onOpenChange: (v) => setState(() => _open = v),
            title: '내역 분할 6개',
            description: _open ? '펼침' : '접힘',
            child: _content(PCollapsibleLayout.text),
          ),
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
      title: '가장 나쁜 값 — 긴 이름 · 긴 설명은 줄을 바꿔 다 보이고, 펼친 채 내용이 늘어나도 트리거는 그 자리',
      children: [
        for (final surface in PCollapsibleSurface.values)
          DemoRow(
            label: surface.name,
            children: [
              SizedBox(
                width: double.infinity,
                child: _Stage(
                  surface: surface,
                  child: PCollapsible(
                    surface: surface,
                    defaultOpen: true,
                    title: _longTitle,
                    description: '$_longTitle — 합계 1,234,567,890원',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 6; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: PSpacing.x2),
                            child: _content(PCollapsibleLayout.text),
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
