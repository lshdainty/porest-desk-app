import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/chip/p_chip.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';

/// 견본의 칩 하나 — 눌러도 아무 일도 없다(누름 모습을 보이려고 활성으로 둔다). 막힌 견본은 onPressed 가 없다.
Widget _chip(
  String label, {
  PChipVariant variant = PChipVariant.outlineWeak,
  PChipSize size = PChipSize.medium,
  bool selected = false,
  bool enabled = true,
  IconData? prefixIcon,
  IconData? suffixIcon,
}) => PChip(
  label: label,
  variant: variant,
  size: size,
  selected: selected,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
  onPressed: enabled ? () {} : null,
);

/// 가장 나쁜 값 — 칩 20개.
const List<String> _names = [
  '식비',
  '교통',
  '쇼핑',
  '의료',
  '문화',
  '교육',
  '통신',
  '주거',
  '보험',
  '여행',
  '취미',
  '육아',
  '경조사',
  '반려동물',
  '구독',
  '세금',
  '저축',
  '투자',
  '기부',
  '기타',
];

/// 카탈로그(/dev/ds) — 변형 × 고름 × 상태, 크기, 아이콘, 고르기 · 필터 바 · 입력값, 묶음(줄바꿈 · 가로 스크롤 · 빈 묶음 ·
/// 칩 20개 · 긴 이름). 누름(누름 바탕 + 칩 전체 2px 축소)은 직접 눌러 본다.
class ChipDemo extends StatefulWidget {
  const ChipDemo({super.key});

  @override
  State<ChipDemo> createState() => _ChipDemoState();
}

class _ChipDemoState extends State<ChipDemo> {
  String _type = 'expense';
  final Set<String> _alarms = {'당일'};
  List<String> _people = ['김하나', '이둘', '박셋'];
  bool _period = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '변형 × 고름 × 상태 — medium 36. Solid 는 흰 표면 위에서만(회색 바탕에서는 사라진다)',
          children: [
            for (final variant in PChipVariant.values)
              for (final (state, enabled) in const [
                ('enabled', true),
                ('disabled', false),
              ])
                DemoRow(
                  label: '${variant.name} · $state',
                  children: [
                    _chip('교통', variant: variant, enabled: enabled),
                    _chip(
                      '식비',
                      variant: variant,
                      selected: true,
                      enabled: enabled,
                    ),
                  ],
                ),
          ],
        ),
        DemoBlock(
          title:
              '크기 × 변형 × 고름 — small 32 · medium 36 · large 40, 글은 모두 14 · 500',
          children: [
            for (final size in PChipSize.values)
              DemoRow(
                label: size.name,
                children: [
                  for (final variant in PChipVariant.values) ...[
                    _chip('안 고름', variant: variant, size: size),
                    _chip('고름', variant: variant, size: size, selected: true),
                  ],
                ],
              ),
          ],
        ),
        DemoBlock(
          title:
              '앞 · 뒤 아이콘 · 아이콘만 있는 칩(원 · 이름 필수) — 크기마다 14 · 16 · 16 / 14 · 14 · 16',
          children: [
            for (final size in PChipSize.values)
              DemoRow(
                label: size.name,
                children: [
                  _chip('태그', size: size, prefixIcon: LucideIcons.tag),
                  _chip(
                    '기간',
                    size: size,
                    variant: PChipVariant.solid,
                    suffixIcon: LucideIcons.chevronDown,
                  ),
                  PChip.icon(
                    icon: LucideIcons.rotateCcw,
                    semanticLabel: '필터 지우기',
                    size: size,
                    variant: PChipVariant.outlineStrong,
                    onPressed: () {},
                  ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '하나 고르기(라디오 · 화살표로 옮기면 고른다) · 여럿 고르기(체크박스) — Field 가 이름을 단다',
          children: [
            PField(
              label: '거래 종류',
              child: PChipRadioGroup<String>(
                semanticLabel: '거래 종류',
                value: _type,
                onChanged: (next) => setState(() => _type = next),
                children: const [
                  PChipRadio(
                    value: 'expense',
                    label: '지출',
                    variant: PChipVariant.outlineStrong,
                  ),
                  PChipRadio(
                    value: 'income',
                    label: '수입',
                    variant: PChipVariant.outlineStrong,
                  ),
                  PChipRadio(
                    value: 'transfer',
                    label: '이체',
                    variant: PChipVariant.outlineStrong,
                  ),
                ],
              ),
            ),
            PField(
              label: '알림',
              description: '고른 때마다 알려줘요.',
              child: PChipGroup(
                semanticLabel: '알림',
                children: [
                  for (final t in const ['당일', '1일 전', '3일 전', '1주 전'])
                    PChipToggle(
                      label: t,
                      checked: _alarms.contains(t),
                      onChanged: (on) => setState(
                        () => on ? _alarms.add(t) : _alarms.remove(t),
                      ),
                    ),
                ],
              ),
            ),
            DemoRow(
              label: '막힘 — 고른 채 막힘(짙은 1px) · 막힌 묶음',
              children: [
                for (final variant in PChipVariant.values)
                  PChipToggle(
                    label: variant.name,
                    checked: true,
                    onChanged: null,
                    variant: variant,
                  ),
              ],
            ),
            PChipRadioGroup<String>(
              semanticLabel: '막힌 묶음',
              value: 'b',
              onChanged: null,
              children: const [
                PChipRadio(value: 'a', label: '지출'),
                PChipRadio(value: 'b', label: '수입'),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '입력값 칩 — 넣은 값(Outline Weak 고른 모습) + 지우기. 칩은 누르지 않고 지우기만 눌린다',
          children: [
            for (final size in PChipSize.values)
              DemoRow(
                label: size.name,
                children: [
                  PInputChip(
                    label: '김하나',
                    removeLabel: '김하나 지우기',
                    size: size,
                    onRemove: () {},
                  ),
                  PInputChip(
                    label: '김하나',
                    removeLabel: '김하나 지우기',
                    size: size,
                    onRemove: null,
                  ),
                ],
              ),
            PField(
              label: '참여자',
              child: PChipGroup(
                semanticLabel: '참여자',
                children: [
                  for (final p in _people)
                    PInputChip(
                      key: ValueKey(p),
                      label: p,
                      removeLabel: '$p 지우기',
                      onRemove: () => setState(
                        () => _people = [
                          for (final x in _people)
                            if (x != p) x,
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const DemoRow(
              label: '빈 묶음 — 칩 한 줄(36) 높이를 남긴다',
              children: [PChipGroup(semanticLabel: '참여자 없음', children: [])],
            ),
          ],
        ),
        DemoBlock(
          title:
              '필터 바 — 조건마다 칩(뒤 화살표 · 걸린 조건은 고른 모습 + 값 요약), 걸리면 맨 앞에 지우기. 화면 끝까지 낸 한 줄 가로 스크롤 · 양 끝 흐림',
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: c.bgLayerDefault),
              child: PChipGroup(
                layout: PChipGroupLayout.scroll,
                semanticLabel: '거래 거르기',
                children: [
                  if (_period)
                    PChip.icon(
                      icon: LucideIcons.rotateCcw,
                      semanticLabel: '필터 지우기',
                      variant: PChipVariant.outlineStrong,
                      onPressed: () => setState(() => _period = false),
                    ),
                  PChip(
                    label: _period ? '이번 달' : '기간',
                    variant: PChipVariant.solid,
                    selected: _period,
                    suffixIcon: LucideIcons.chevronDown,
                    onPressed: () => setState(() => _period = !_period),
                  ),
                  _chip(
                    '식비 외 2개',
                    variant: PChipVariant.solid,
                    selected: true,
                    suffixIcon: LucideIcons.chevronDown,
                  ),
                  for (final t in const ['계좌', '금액', '결제 수단'])
                    _chip(
                      t,
                      variant: PChipVariant.solid,
                      suffixIcon: LucideIcons.chevronDown,
                    ),
                ],
              ),
            ),
            const DemoRow(label: '칩 20개 · 가로 스크롤', children: []),
            DecoratedBox(
              decoration: BoxDecoration(color: c.bgLayerDefault),
              child: PChipGroup(
                layout: PChipGroupLayout.scroll,
                semanticLabel: '카테고리 20개',
                children: [
                  for (final name in _names)
                    _chip(name, variant: PChipVariant.solid),
                ],
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '제안 — 고른 표시가 없다. 누르면 칸에 값을 넣는 버튼',
          children: [
            PChipGroup(
              semanticLabel: '빠른 금액',
              children: [
                for (final t in const ['10만', '30만', '50만'])
                  _chip(
                    t,
                    variant: PChipVariant.solid,
                    prefixIcon: LucideIcons.plus,
                  ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '묶음 — 줄바꿈(칩 사이 · 줄 사이 8), 가장 나쁜 값: 칩 20개 · 긴 이름(줄바꿈 · 말줄임 없이 글만큼 넓어진다)',
          children: [
            DemoRow(
              label: '줄바꿈 · 20개',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PChipGroup(
                    semanticLabel: '카테고리 20개',
                    children: [
                      for (var i = 0; i < _names.length; i++)
                        _chip(_names[i], selected: i % 4 == 1),
                    ],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '긴 이름',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PChipGroup(
                    semanticLabel: '긴 이름',
                    children: [
                      _chip('신한카드 마이 포인트 플러스 체크카드'),
                      _chip('월 구독료와 정기 결제 모음', selected: true),
                      _chip('외식'),
                    ],
                  ),
                ),
              ],
            ),
            const DemoRow(label: '긴 이름 · 스크롤', children: []),
            DecoratedBox(
              decoration: BoxDecoration(color: c.bgLayerDefault),
              child: PChipGroup(
                layout: PChipGroupLayout.scroll,
                semanticLabel: '긴 이름 스크롤',
                children: [
                  _chip('신한카드 마이 포인트 플러스 체크카드', variant: PChipVariant.solid),
                  _chip(
                    '월 구독료와 정기 결제 모음',
                    variant: PChipVariant.solid,
                    selected: true,
                  ),
                  _chip('외식', variant: PChipVariant.solid),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
