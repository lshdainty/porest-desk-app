import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/avatar/p_avatar.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/swipe_actions/p_swipe_actions.dart';

/// 카탈로그(/dev/ds) — 종류 3 × 상태(동작 칸 하나: 기본 · 누름 · 막힘), 크기(칸 폭 · 트레이 폭, 열린 모습), 직접 밀어 보기
/// (한 번에 한 줄 · 스크롤하면 닫힘 · 끝까지 밀어도 실행하지 않음 · 줄 끝 ⋮), RTL, 768 이상(enabled=false). 웹 견본과 같은
/// 구성이다 — 호버 · 포커스는 웹 상태라 앱에는 없다.
class SwipeActionsDemo extends StatefulWidget {
  const SwipeActionsDemo({super.key});

  @override
  State<SwipeActionsDemo> createState() => _SwipeActionsDemoState();
}

const _kinds = [
  (PSwipeActionKind.neutral, '고정', LucideIcons.pin),
  (PSwipeActionKind.primary, '수정', LucideIcons.pencil),
  (PSwipeActionKind.destructive, '삭제', LucideIcons.trash2),
];

void _noop() {}

const _pin = PSwipeAction(
  kind: PSwipeActionKind.neutral,
  label: '고정',
  icon: LucideIcons.pin,
  onSelect: _noop,
);
const _edit = PSwipeAction(
  kind: PSwipeActionKind.primary,
  label: '수정',
  icon: LucideIcons.pencil,
  onSelect: _noop,
);
const _del = PSwipeAction(
  kind: PSwipeActionKind.destructive,
  label: '삭제',
  icon: LucideIcons.trash2,
  onSelect: _noop,
);

/// 줄 — 높이 56 이상(스펙: 칸은 줄을 따르되 56 보다 낮으면 56). 줄의 모양은 이 컴포넌트가 정하지 않는다.
class _Row extends StatelessWidget {
  const _Row({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: PSpacing.x16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpacing.x6,
          vertical: PSpacing.x3,
        ),
        child: Row(
          spacing: PSpacing.x3,
          children: [
            PAvatar(name: title, size: PAvatarSize.s36),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypography.t5.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 폰 화면 틀 — 모서리 12 · 1px 테두리 · 면.
class _Phone extends StatelessWidget {
  const _Phone({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bgLayerDefault,
          borderRadius: BorderRadius.circular(PRounded.r3),
          border: Border.all(color: c.strokeNeutralWeak),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PRounded.r3 - 1),
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// 열린 모습 — 트레이가 드러난 자리를 손으로 그린다(밀어 열면 이 모습이다 — 줄이 트레이 폭만큼 물러난다).
class _OpenPreview extends StatelessWidget {
  const _OpenPreview({required this.actions});

  final List<PSwipeAction> actions;

  @override
  Widget build(BuildContext context) {
    final tray = swipeTrayWidth(actions.length);
    final reversed = actions.reversed.toList();
    return _Phone(
      children: [
        ClipRect(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: tray,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < reversed.length; i++)
                      PSwipeActionCell(
                        action: reversed[i],
                        index: i,
                        rowLabel: '스타벅스',
                      ),
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(-tray, 0),
                child: ColoredBox(
                  color: context.colors.bgLayerDefault,
                  child: const _Row(title: '스타벅스', meta: '식비 · 오늘'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwipeActionsDemoState extends State<SwipeActionsDemo> {
  String _picked = '—';

  List<PSwipeAction> _act(String title) => [
    for (final a in const [_pin, _edit, _del])
      PSwipeAction(
        kind: a.kind,
        label: a.label,
        icon: a.icon,
        onSelect: () => setState(() => _picked = '${a.label}: $title'),
      ),
  ];

  Widget _liveRow(String title) {
    final actions = _act(title);
    return PSwipeActions(
      actions: actions,
      rowLabel: title,
      child: Row(
        children: [
          Expanded(
            child: _Row(title: title, meta: '식비 · 오늘'),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: PSpacing.x3),
            child: PSwipeActionsMore(actions: actions, rowLabel: title),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '종류 × 상태 — 동작 칸 하나(배지 36 · 아이콘 18 · 라벨 12 / 700). 색은 배지만, 누름은 밝기 88%, 막히면 전용 색',
          children: [
            for (final (kind, label, icon) in _kinds)
              DemoRow(
                label: kind.name,
                children: [
                  for (final state in const ['enabled', 'pressed', 'disabled'])
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.bgLayerDefault,
                        borderRadius: BorderRadius.circular(PRounded.r2),
                      ),
                      child: Column(
                        spacing: PSpacing.x1,
                        children: [
                          PSwipeActionCell(
                            action: PSwipeAction(
                              kind: kind,
                              label: label,
                              icon: icon,
                              disabled: state == 'disabled',
                              onSelect: _noop,
                            ),
                            rowLabel: '스타벅스',
                            previewPressed: state == 'pressed',
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: PSpacing.x1),
                            child: Text(
                              state,
                              style: PTypography.t1.copyWith(
                                color: c.fgNeutralSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title:
              '크기 — 첫 칸 앞 20 · 칸 사이 12 · 마지막 칸은 화면 끝, 트레이 56 · 104 · 152. 열린 모습(삭제는 가장 안쪽)',
          children: [
            const DemoRow(
              label: '동작 1개',
              children: [
                _OpenPreview(actions: [_del]),
              ],
            ),
            const DemoRow(
              label: '동작 2개',
              children: [
                _OpenPreview(actions: [_edit, _del]),
              ],
            ),
            const DemoRow(
              label: '동작 3개',
              children: [
                _OpenPreview(actions: [_pin, _edit, _del]),
              ],
            ),
            const DemoRow(
              label: '막힌 동작 · 보관',
              children: [
                _OpenPreview(
                  actions: [
                    PSwipeAction(
                      kind: PSwipeActionKind.neutral,
                      label: '보관',
                      icon: LucideIcons.archive,
                      disabled: true,
                      onSelect: _noop,
                    ),
                    _edit,
                    _del,
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '직접 밀어 보기 — 줄을 왼쪽으로 민다. 한 번에 한 줄 · 스크롤하면 닫힘 · 끝까지 밀어도 실행하지 않음. 줄 끝 ⋮ 는 같은 동작',
          children: [
            PSwipeActionsProvider(
              child: _Phone(
                children: [
                  for (final t in const ['스타벅스', '쿠팡', '지하철']) _liveRow(t),
                ],
              ),
            ),
            Text(
              '마지막으로 고른 동작 — $_picked',
              key: const ValueKey('swipe-demo-picked'),
              style: PTypography.t3.copyWith(color: c.fgNeutralMuted),
            ),
          ],
        ),
        DemoBlock(
          title: 'RTL — 미는 방향이 뒤집힌다(오른쪽으로 밀고 트레이는 왼쪽에서 나온다). 동작 차례는 그대로',
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: PSwipeActionsProvider(
                child: _Phone(
                  children: [
                    PSwipeActions(
                      actions: _act('스타벅스'),
                      rowLabel: '스타벅스',
                      child: const _Row(title: '스타벅스', meta: '식비 · 오늘'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '768 이상 — enabled=false 로 줄만 그린다(트레이 없음, 동작은 줄 끝 ⋮)',
          children: [
            _Phone(
              children: [
                PSwipeActions(
                  actions: _act('스타벅스'),
                  enabled: false,
                  child: Row(
                    children: [
                      const Expanded(
                        child: _Row(title: '스타벅스', meta: '식비 · 오늘'),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: PSpacing.x3,
                        ),
                        child: PSwipeActionsMore(
                          actions: _act('스타벅스'),
                          rowLabel: '스타벅스',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
