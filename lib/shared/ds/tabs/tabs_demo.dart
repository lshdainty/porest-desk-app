import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/tabs/p_tabs.dart';

PTab<String> _tab(
  String value,
  String label, {
  bool enabled = true,
  bool notification = false,
}) => PTab<String>(
  value: value,
  label: label,
  enabled: enabled,
  notification: notification,
  notificationLabel: notification ? '새 소식' : null,
);

/// 값을 쥐고 [builder] 에 주는 견본 — 눌러서 고른다.
class _Live extends StatefulWidget {
  const _Live({required this.initial, required this.builder});

  final String initial;
  final Widget Function(String value, ValueChanged<String> onChanged) builder;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (next) => setState(() => _value = next));
}

const List<String> _hugNames = [
  '전체',
  '식비',
  '교통',
  '쇼핑',
  '의료',
  '문화',
  '교육',
  '통신',
  '주거',
];

/// 카탈로그(/dev/ds) — Line(Fill · Hug × small · medium), 폭(2 ~ 5개 Fill · 6개 이상 Hug · 긴 글), 알림 점 · 막힌 탭, Chip
/// Tabs(Solid · Outline × medium · large · 알림 점 · 칩 12개 가로 스크롤), 두 단과 내용 칸(밀어 넘기기). 눌러서 고르고 · 화살표로
/// 옮겨 본다 — 누름(탭 2px 축소)은 직접 눌러 본다.
class TabsDemo extends StatelessWidget {
  const TabsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: 'Line — 레이아웃 × 크기. 글은 700 고정, 고르면 글자색만 바뀌고 막대가 미끄러진다',
          children: [
            for (final size in PTabsSize.values)
              for (final layout in PTabsLayout.values)
                DemoRow(
                  label: '${layout.name} · ${size.name}',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _Live(
                        initial: 'trend',
                        builder: (value, onChanged) => PTabs<String>(
                          value: value,
                          onChanged: onChanged,
                          semanticLabel: '통계',
                          layout: layout,
                          size: size,
                          items: [
                            _tab('category', '카테고리'),
                            _tab('trend', '추이'),
                            _tab('compare', '비교'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
        DemoBlock(
          title:
              '폭 — 2 ~ 5개는 Fill(막대 = 탭 폭 − 32), 6개 이상 · 긴 글은 Hug(가로 스크롤 · 가장자리 16)',
          children: [
            for (final count in [2, 4, 5])
              DemoRow(
                label: 'fill · $count개',
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _Live(
                      initial: 't0',
                      builder: (value, onChanged) => PTabs<String>(
                        value: value,
                        onChanged: onChanged,
                        semanticLabel: '$count개',
                        items: [
                          for (var i = 0; i < count; i++)
                            _tab('t$i', _hugNames[i + 1]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            DemoRow(
              label: 'hug · 9개 — 넘치면 가로 스크롤, 고른 탭이 밖이면 따라간다',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _Live(
                    initial: 'v8',
                    builder: (value, onChanged) => PTabs<String>(
                      value: value,
                      onChanged: onChanged,
                      semanticLabel: '카테고리',
                      layout: PTabsLayout.hug,
                      items: [
                        for (var i = 0; i < _hugNames.length; i++)
                          _tab('v$i', _hugNames[i]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            DemoRow(
              label: 'hug · 긴 글 — 줄바꿈 · 말줄임 없이 탭이 넓어진다',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _Live(
                    initial: 'a',
                    builder: (value, onChanged) => PTabs<String>(
                      value: value,
                      onChanged: onChanged,
                      semanticLabel: '긴 글',
                      layout: PTabsLayout.hug,
                      size: PTabsSize.medium,
                      items: [
                        _tab('a', '신한카드 마이 포인트 플러스'),
                        _tab('b', '월 구독료와 정기 결제 모음'),
                        _tab('c', '외식'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '알림 점(한 탭에만, 고르면 사라진다) · 막힌 탭(건너뛴다) · 목록 전체 막힘',
          children: [
            DemoRow(
              label: 'fill — 알림 점 · 막힌 탭',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _Live(
                    initial: 'a',
                    builder: (value, onChanged) => PTabs<String>(
                      value: value,
                      onChanged: onChanged,
                      semanticLabel: '진행',
                      items: [
                        _tab('a', '진행 중'),
                        _tab('b', '완료', notification: true),
                        _tab('c', '친구', enabled: false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            DemoRow(
              label: 'hug — 알림 점',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _Live(
                    initial: 'a',
                    builder: (value, onChanged) => PTabs<String>(
                      value: value,
                      onChanged: onChanged,
                      semanticLabel: '알림',
                      layout: PTabsLayout.hug,
                      items: [
                        _tab('a', '전체'),
                        _tab('b', '공지', notification: true),
                        _tab('c', '이벤트'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '목록 전체 막힘 — 고른 탭의 막대도 회색',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PTabs<String>(
                    value: 'b',
                    onChanged: null,
                    semanticLabel: '막힘',
                    items: [_tab('a', '카테고리'), _tab('b', '추이')],
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              'Chip Tabs — Solid(화면 전체를 바꾸는 2차 탭, 흰 표면 위) · Outline(일부 내용) × medium 36 · large 40, 알림 점은 글 뒤 6',
          children: [
            for (final variant in PChipTabsVariant.values)
              for (final size in PChipTabsSize.values)
                DemoRow(
                  label: '${variant.name} · ${size.name}',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _Live(
                        initial: 'holding',
                        builder: (value, onChanged) => PChipTabs<String>(
                          value: value,
                          onChanged: onChanged,
                          semanticLabel: '자산',
                          variant: variant,
                          size: size,
                          items: [
                            _tab('all', '전체'),
                            _tab('holding', '보유', notification: true),
                            _tab('watch', '관심'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            DemoRow(
              label: '칩 12개 · 가로 스크롤(양 끝 흐림) — 고른 탭이 밖이면 여백 24 를 두고 따라간다',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _Live(
                    initial: 'c11',
                    builder: (value, onChanged) => PChipTabs<String>(
                      value: value,
                      onChanged: onChanged,
                      semanticLabel: '카테고리 12개',
                      items: [
                        for (var i = 0; i < 12; i++)
                          _tab('c$i', i == 0 ? '전체' : '카테고리 $i'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '막힌 탭',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _Live(
                    initial: 'a',
                    builder: (value, onChanged) => PChipTabs<String>(
                      value: value,
                      onChanged: onChanged,
                      semanticLabel: '막힘',
                      items: [
                        _tab('a', '진행 중'),
                        _tab('b', '완료', enabled: false),
                        _tab('c', '전체'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '두 단 + 내용 칸 — 1차 Line · 2차 Chip Tabs, 내용은 바로 바뀌고 상태를 남긴다. 내용을 옆으로 밀어도 넘어간다(폰 1차 탭)',
          children: [
            SizedBox(
              width: double.infinity,
              child: _Live(
                initial: 'category',
                builder: (value, onChanged) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PTabs<String>(
                      value: value,
                      onChanged: onChanged,
                      semanticLabel: '통계',
                      items: [
                        _tab('category', '카테고리'),
                        _tab('trend', '추이'),
                        _tab('compare', '비교'),
                      ],
                    ),
                    PTabPanels<String>(
                      value: value,
                      onChanged: onChanged,
                      swipe: true,
                      panels: const [
                        PTabPanel(
                          value: 'category',
                          child: _Pane('카테고리 — 두 단'),
                        ),
                        PTabPanel(value: 'trend', child: _Pane('추이')),
                        PTabPanel(value: 'compare', child: _Pane('비교')),
                      ],
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

/// 내용 칸 견본 — 눌러서 세는 숫자(칸을 오가도 남는다), 카테고리 칸은 2차 탭을 품는다.
class _Pane extends StatefulWidget {
  const _Pane(this.title);

  final String title;

  @override
  State<_Pane> createState() => _PaneState();
}

class _PaneState extends State<_Pane> {
  int _count = 0;
  String _second = 'expense';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title.startsWith('카테고리'))
          PChipTabs<String>(
            value: _second,
            onChanged: (next) => setState(() => _second = next),
            semanticLabel: '거래 종류',
            variant: PChipTabsVariant.solid,
            items: [_tab('expense', '지출'), _tab('income', '수입')],
          ),
        GestureDetector(
          onTap: () => setState(() => _count++),
          child: Padding(
            padding: const EdgeInsets.all(PSpacing.x4),
            child: Text(
              '${widget.title} · 눌러서 센다 $_count — 다른 탭을 다녀와도 그대로',
              style: PTypography.t4.copyWith(color: c.fgNeutral),
            ),
          ),
        ),
      ],
    );
  }
}
