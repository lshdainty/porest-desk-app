import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';

/// 견본은 칸 셋 — 상태를 보이는 칸은 가운데 칸("이번 주")이다.
const String _middle = 'week';

PSegmentedItem<String> _item(
  String value,
  String label, {
  bool enabled = true,
  bool notification = false,
}) => PSegmentedItem<String>(
  value: value,
  label: label,
  enabled: enabled,
  notification: notification,
);

/// 카탈로그(/dev/ds) — 고름 × 상태(기본 · 비활성), 알림 점, 칸 수 2 ~ 4 · 긴 글 · 트랙 전체 막힘. 눌러서 고르고 · 화살표로
/// 옮겨 본다 — 누름(칸 바탕 + 글 2px 축소)은 직접 눌러 본다.
class SegmentedControlDemo extends StatelessWidget {
  const SegmentedControlDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '고름 × 상태 — 가운데 칸(이번 주)을 잰다. 누름은 직접 눌러 본다',
          children: [
            for (final (label, enabled) in const [
              ('enabled', true),
              ('disabled — 가운데 칸 막힘', false),
            ])
              DemoRow(
                label: label,
                children: [
                  for (final selected in const [false, true])
                    SizedBox(
                      width: double.infinity,
                      child: _LiveControl(
                        label: '할 일 보기',
                        initial: selected ? _middle : 'today',
                        items: [
                          _item('today', '오늘'),
                          _item(
                            _middle,
                            '이번 주',
                            enabled: enabled,
                            // 알림 점은 안 고른 칸에만 — 막히면 점도 없다
                            notification: !selected && enabled,
                          ),
                          _item('all', '전체'),
                        ],
                      ),
                    ),
                ],
              ),
            const DemoRow(
              label: 'disabled(트랙) — 고른 채 막힘',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _LiveControl(
                    label: '할 일 보기',
                    initial: _middle,
                    disabled: true,
                    items: [
                      PSegmentedItem(value: 'today', label: '오늘'),
                      PSegmentedItem(value: _middle, label: '이번 주'),
                      PSegmentedItem(value: 'all', label: '전체'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '칸 수 2 ~ 4 — 칸이 트랙 폭을 똑같이 나눈다(폰 콘텐츠 폭 312)',
          children: [
            DemoRow(
              label: '2',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _LiveControl(
                    label: '거래 보기',
                    initial: 'expense',
                    items: [_item('expense', '지출'), _item('income', '수입')],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '4',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _LiveControl(
                    label: '할 일 보기',
                    initial: 'today',
                    items: [
                      _item('today', '오늘'),
                      _item('week', '이번 주'),
                      _item('all', '전체'),
                      _item('done', '완료', notification: true),
                    ],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '긴 글 — 줄이 바뀌면 모든 칸이 가장 높은 칸에 맞춘다',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _LiveControl(
                    label: '프리셋 정렬',
                    initial: 'most',
                    items: [
                      _item('most', '많이 쓴 순'),
                      _item('recent', '최근에 사용한 프리셋'),
                      _item('name', '이름순'),
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

/// 눌러서 고르는 트랙 — 값을 이 위젯이 쥐고 [PSegmentedControl] 에 준다.
class _LiveControl extends StatefulWidget {
  const _LiveControl({
    required this.label,
    required this.initial,
    required this.items,
    this.disabled = false,
  });

  final String label;
  final String initial;
  final List<PSegmentedItem<String>> items;
  final bool disabled;

  @override
  State<_LiveControl> createState() => _LiveControlState();
}

class _LiveControlState extends State<_LiveControl> {
  late String _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpacing.x1),
      child: PSegmentedControl<String>(
        value: _value,
        onChanged: widget.disabled
            ? null
            : (next) => setState(() => _value = next),
        semanticLabel: widget.label,
        items: widget.items,
      ),
    );
  }
}
