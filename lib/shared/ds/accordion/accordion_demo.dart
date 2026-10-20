import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_accordion.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

typedef _Benefit = ({
  String id,
  String title,
  String summary,
  String detail,
  IconData icon,
});

const List<_Benefit> _benefits = [
  (
    id: 'coffee',
    title: '커피 할인',
    summary: '전 가맹점 30% 청구 할인',
    detail: '월 3회 · 건당 최대 3,000원까지 청구 할인돼요.\n전월 이용 실적 30만원 이상이면 받아요.',
    icon: LucideIcons.coffee,
  ),
  (
    id: 'fuel',
    title: '주유 할인',
    summary: '리터당 60원 청구 할인',
    detail: '주유소 · 충전소에서 월 2회까지 받아요. 일부 알뜰 주유소는 빠져요.',
    icon: LucideIcons.fuel,
  ),
  (
    id: 'transit',
    title: '대중교통 할인',
    summary: '버스 · 지하철 10% 청구 할인',
    detail: '교통카드 기능으로 결제한 건에 적용돼요. 택시는 대상이 아니에요.',
    icon: LucideIcons.trainFront,
  ),
  (
    id: 'mart',
    title: '마트 할인',
    summary: '대형마트 5% 청구 할인',
    detail: '월 1회 · 최대 5,000원까지 받아요.',
    icon: LucideIcons.shoppingCart,
  ),
];

const String _longTitle =
    '연회비 · 카드 발급 후 첫 달 실적 기준으로 산정하며 전월 이용 실적이 기준에 못 미치면 청구 할인이 적용되지 않으니 꼭 확인해 주세요';

/// 카탈로그(/dev/ds) — 변형 × 펼침 × 설명 × 상세(16) · 상태(막힘) · 목록 머리 · 모두 펼치기 · 화면 예시(혜택 상세 시트 =
/// separated · 카드 상세 혜택 = inline, Card body=accordion) · 가장 나쁜 값(항목 20개 · 긴 제목 · 펼친 채 내용 늘어남). 웹
/// `accordion.demo.tsx` 와 같은 구성이다. 올림 · 키보드 포커스 링은 웹 전용이라 앱에는 없다 — 눌러 보는 것은 손가락으로 누른다.
class AccordionDemo extends StatelessWidget {
  const AccordionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MatrixDemo(),
        _StateDemo(),
        _ExpandAllDemo(),
        _ScreensDemo(),
        _WorstDemo(),
      ],
    );
  }
}

/// 흰 면 — 아코디언은 늘 놓인 면 위에 둔다(시트 · 카드).
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.colors.bgLayerDefault, child: child);
}

class _MatrixDemo extends StatelessWidget {
  const _MatrixDemo();

  @override
  Widget build(BuildContext context) {
    Widget sample(
      PAccordionVariant variant, {
      required bool open,
      required bool shown,
      required bool detail,
      bool disabled = false,
    }) {
      final items = _benefits.take(2).toList();
      return _Frame(
        child: PAccordion(
          variant: variant,
          disabled: disabled,
          defaultValues: open ? [for (final b in items) b.id] : const [],
          children: [
            for (final b in items)
              if (detail)
                PAccordionItem(
                  value: b.id,
                  title: b.title,
                  description: shown ? b.summary : null,
                  prefixIcon: shown ? b.icon : null,
                  child: Text(keepAll(b.detail)),
                )
              else
                PAccordionPlainItem(
                  title: b.title,
                  description: shown ? b.summary : null,
                  prefixIcon: shown ? b.icon : null,
                ),
          ],
        ),
      );
    }

    return DemoBlock(
      title: '변형 × 펼침 × 설명 × 상세 — 항목 둘(사이 선 · 간격). 상세 없음은 그냥 줄(꺾쇠 · 바탕 없음)',
      children: [
        for (final variant in PAccordionVariant.values)
          for (final detail in [true, false])
            for (final open in detail ? [false, true] : [false])
              for (final shown in [false, true])
                DemoRow(
                  label:
                      '${variant.name} · ${detail ? 'expandable' : 'none'} · ${open ? 'expanded' : 'collapsed'} · ${shown ? '설명' : '제목만'}',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: sample(
                        variant,
                        open: open,
                        shown: shown,
                        detail: detail,
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
          '상태 — 막힘은 아이콘 · 제목 · 설명 · 꺾쇠가 모두 fg-disabled(흐리게 하지 않는다). 누름은 손가락으로 눌러 본다',
      children: [
        for (final variant in PAccordionVariant.values)
          DemoRow(
            label: '${variant.name} · disabled',
            children: [
              SizedBox(
                width: double.infinity,
                child: _Frame(
                  child: PAccordion(
                    variant: variant,
                    disabled: true,
                    children: [
                      PAccordionItem(
                        value: 'coffee',
                        title: _benefits[0].title,
                        description: _benefits[0].summary,
                        prefixIcon: _benefits[0].icon,
                        child: Text(_benefits[0].detail),
                      ),
                      PAccordionItem(
                        value: 'fuel',
                        title: _benefits[1].title,
                        child: Text(_benefits[1].detail),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ExpandAllDemo extends StatefulWidget {
  const _ExpandAllDemo();

  @override
  State<_ExpandAllDemo> createState() => _ExpandAllDemoState();
}

class _ExpandAllDemoState extends State<_ExpandAllDemo> {
  List<String> _open = const [];

  @override
  Widget build(BuildContext context) {
    final ids = [for (final b in _benefits) b.id];
    return DemoBlock(
      title: '목록 머리 · 모두 펼치기 — 보이는 32 · 누르는 44, 모두 펼치면 글이 모두 접기로',
      children: [
        _Frame(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x6,
              vertical: PSpacing.x2,
            ),
            child: PAccordionHeader(
              title: '혜택 상세 · ${_benefits.length}건',
              trailing: PAccordionExpandAll(
                values: _open,
                expandable: ids,
                onValuesChange: (v) => setState(() => _open = v),
                expandLabel: '모두 펼치기',
                collapseLabel: '모두 접기',
              ),
            ),
          ),
        ),
        _Frame(
          child: PAccordionExpandAll(
            values: ids,
            expandable: ids,
            onValuesChange: (_) {},
            expandLabel: '모두 펼치기',
            collapseLabel: '모두 접기',
          ),
        ),
      ],
    );
  }
}

class _ScreensDemo extends StatefulWidget {
  const _ScreensDemo();

  @override
  State<_ScreensDemo> createState() => _ScreensDemoState();
}

class _ScreensDemoState extends State<_ScreensDemo> {
  List<String> _open = const [];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ids = [for (final b in _benefits) b.id];
    return DemoBlock(
      title:
          '화면 예시 — 혜택 상세 시트(separated) · 카드 상세 혜택(inline, Card body=accordion)',
      children: [
        DemoRow(
          label: '혜택 상세 시트 — separated + 목록 머리',
          children: [
            SizedBox(
              width: double.infinity,
              child: _Frame(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PSpacing.x6,
                    PSpacing.x2,
                    PSpacing.x6,
                    PSpacing.x6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PAccordionHeader(
                        title: '혜택 상세 · ${_benefits.length}건',
                        trailing: PAccordionExpandAll(
                          values: _open,
                          expandable: ids,
                          onValuesChange: (v) => setState(() => _open = v),
                          expandLabel: '모두 펼치기',
                          collapseLabel: '모두 접기',
                        ),
                      ),
                      PAccordion(
                        variant: PAccordionVariant.separated,
                        values: _open,
                        onValuesChange: (v) => setState(() => _open = v),
                        children: [
                          for (final b in _benefits)
                            PAccordionItem(
                              value: b.id,
                              title: b.title,
                              description: b.summary,
                              prefixIcon: b.icon,
                              child: Text(keepAll(b.detail)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        DemoRow(
          label: '카드 상세 — 혜택(inline, Card body=accordion · 카드 아래 8)',
          children: [
            SizedBox(
              width: double.infinity,
              child: ColoredBox(
                color: c.bgLayerBasement,
                child: Padding(
                  padding: const EdgeInsets.all(PSpacing.x4),
                  child: PCard(
                    body: PCardBody.accordion,
                    children: [
                      const PCardHeader(title: '혜택 · 12건'),
                      PAccordion(
                        children: [
                          for (final b in _benefits)
                            PAccordionItem(
                              value: b.id,
                              title: b.title,
                              description: b.summary,
                              child: Text(keepAll(b.detail)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        DemoRow(
          label: '카드 상세 — 유의사항(설명 없이 제목만)',
          children: [
            SizedBox(
              width: double.infinity,
              child: ColoredBox(
                color: c.bgLayerBasement,
                child: Padding(
                  padding: const EdgeInsets.all(PSpacing.x4),
                  child: PCard(
                    body: PCardBody.accordion,
                    children: [
                      const PCardHeader(title: '유의사항 · 3건'),
                      PAccordion(
                        children: [
                          for (var i = 1; i <= 3; i++)
                            PAccordionItem(
                              value: 'caution-$i',
                              title: '유의사항 $i',
                              child: const Text('실적에서 제외되는 가맹점이 있어요.'),
                            ),
                        ],
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
      title:
          '가장 나쁜 값 — 항목 20개 · 84자 제목은 줄을 바꿔 다 보인다 · 열린 항목이 여럿 · 펼친 채 내용이 늘어나도 트리거는 그 자리',
      children: [
        for (final variant in PAccordionVariant.values)
          DemoRow(
            label: variant.name,
            children: [
              SizedBox(
                width: double.infinity,
                child: _Frame(
                  child: PAccordion(
                    variant: variant,
                    defaultValues: const ['item-1', 'item-2', 'item-3'],
                    children: [
                      for (var i = 1; i <= 20; i++)
                        PAccordionItem(
                          value: 'item-$i',
                          title: i == 1 ? _longTitle : '유의사항 $i',
                          description: i == 2 ? '길어도 줄을 바꿔 다 보여요' : null,
                          prefixIcon: i == 2 ? LucideIcons.info : null,
                          child: Text(
                            keepAll(
                              i == 3
                                  ? '${_benefits[0].detail}\n${_benefits[1].detail}\n${_benefits[2].detail}\n${_benefits[3].detail}'
                                  : _benefits[i % 4].detail,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
