import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/tooltip/p_tooltip.dart';

void _noop() {}

/// 아이콘 버튼 — 툴팁의 트리거. 이름은 버튼의 `semanticLabel`(웹 aria-label)에 있고 툴팁은 그 이름을 보여 줄 뿐이다.
Widget _iconButton(String name, IconData icon, {VoidCallback? onPressed}) =>
    PButton.icon(
      icon: icon,
      semanticLabel: name,
      onPressed: onPressed ?? _noop,
      variant: PButtonVariant.ghost,
      ghostColor: PButtonGhostColor.neutralSubtle,
    );

/// 견본 무대 — 폭 300 · 높이 [height] 의 자기 오버레이. 툴팁은 가장 가까운 오버레이에 뜨므로 무대 안에서 자라고 무대 밖으로
/// 나가 다른 견본을 덮지 않는다(Help Bubble 견본과 같은 자리).
class _Stage extends StatefulWidget {
  const _Stage({required this.child, this.height = 110});

  final Widget child;
  final double height;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  late final OverlayEntry _entry = OverlayEntry(builder: (_) => widget.child);

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: widget.height,
      child: ClipRect(child: Overlay(initialEntries: [_entry])),
    );
  }
}

class _Open extends StatelessWidget {
  const _Open({
    required this.message,
    this.side = PHelpBubbleSide.top,
    this.alignment = Alignment.bottomCenter,
    this.height = 110,
  });

  final String message;
  final PHelpBubbleSide side;
  final Alignment alignment;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      height: height,
      child: Align(
        alignment: alignment,
        child: PTooltip(
          pinnedOpen: true,
          message: message,
          side: side,
          child: _iconButton(message, LucideIcons.eye),
        ),
      ),
    );
  }
}

/// 카탈로그(/dev/ds) — 열어 둔 툴팁(한 줄 · 긴 글 · 자리 · 뒤집기)과 직접 열어 보기.
///
/// 툴팁은 보조다 — 손가락으로 누르면 열리지 않는다. 마우스를 올리거나(200ms) 키보드 Tab 으로 초점을 옮겨(바로) 열어 본다.
class TooltipDemo extends StatelessWidget {
  const TooltipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DemoBlock(
          title: '말풍선 — Help Bubble 과 같은 모양 · 글 하나(굵게) · 화살표 끝 ↔ 트리거 4',
          children: [
            DemoRow(
              label: '한 줄 — 아이콘 버튼의 이름',
              children: [_Open(message: '금액 가리기')],
            ),
            DemoRow(
              label: '긴 글 — 최대 280 에서 줄을 바꾼다(두 줄이 넘으면 Help Bubble)',
              children: [
                _Open(
                  message: '연차는 입사일 기준으로 계산하고 한 해가 지나면 새로 생겨요.',
                  height: 130,
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title: '자리 — 기본 위, 자리가 모자라면 반대편으로 뒤집고 옆으로 민다',
          children: [
            DemoRow(
              label: '아래',
              children: [
                _Open(
                  message: '검색',
                  side: PHelpBubbleSide.bottom,
                  alignment: Alignment.topCenter,
                ),
              ],
            ),
            DemoRow(
              label: '위가 모자라면 아래로 뒤집힌다',
              children: [
                _Open(message: '필터 초기화', alignment: Alignment.topCenter),
              ],
            ),
            DemoRow(
              label: '왼쪽 가장자리 — 옆으로 밀고 화살표는 트리거 가운데',
              children: [_Open(message: '알림', alignment: Alignment.bottomLeft)],
            ),
          ],
        ),
        DemoBlock(
          title:
              '직접 열어 보기 — 마우스를 올리면 200ms 뒤 · Tab 으로 초점이 오면 바로 · 손가락으로는 열리지 않는다',
          children: [
            DemoRow(
              label: '이어서 옆 트리거로 옮기면 기다리지 않고 모션 없이 바로(300ms 안)',
              children: [
                PTooltip(
                  message: '금액 가리기',
                  child: _iconButton('금액 가리기', LucideIcons.eye),
                ),
                PTooltip(
                  message: '알림',
                  child: _iconButton('알림', LucideIcons.bell),
                ),
                PTooltip(
                  message: '설정',
                  child: _iconButton('설정', LucideIcons.settings),
                ),
              ],
            ),
            Text(
              '막힌 버튼의 이유는 툴팁이 아니라 버튼 가까이 글로 둔다 — 막힌 버튼은 초점을 받지 못한다.',
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
        ),
      ],
    );
  }
}
