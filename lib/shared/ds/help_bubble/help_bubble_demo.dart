import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/p_help_bubble.dart';

const String _leaveTitle = '연차 사용 규정';
const String _leaveDescription = '입사 1년 미만은 한 달에 1일씩 생기고, 1년이 지나면 15일이 생겨요.';
const String _hideTitle = '금액을 가릴 수 있어요';
const String _hideDescription = '누르면 화면의 금액이 모두 가려져요.';

/// ⓘ 아이콘 버튼 — 말풍선의 트리거(button ghost · neutralSubtle · 아이콘만, 이름 "{무엇} 안내").
Widget _infoButton(String what, VoidCallback toggle) => PButton.icon(
  icon: LucideIcons.info,
  semanticLabel: '$what 안내',
  onPressed: toggle,
  variant: PButtonVariant.ghost,
  ghostColor: PButtonGhostColor.neutralSubtle,
);

/// 견본 무대 — 폭 300 · 높이 160 의 자기 오버레이. 말풍선은 가장 가까운 오버레이에 뜨므로 무대 안에서 자라고
/// 무대 밖으로 나가 다른 견본을 덮지 않는다(웹 견본의 container 와 같은 자리).
class _Stage extends StatefulWidget {
  const _Stage({required this.child});

  final Widget child;

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
      height: 160,
      child: ClipRect(child: Overlay(initialEntries: [_entry])),
    );
  }
}

/// 늘 열린 말풍선 — ⓘ 위(또는 [side])에 뜬다. 열림을 쥐고 있어 바깥을 눌러도 닫히지 않는다.
class _OpenBubble extends StatelessWidget {
  const _OpenBubble({
    required this.what,
    required this.title,
    this.description,
    this.showCloseButton = false,
    this.side = PHelpBubbleSide.top,
    this.alignment = Alignment.bottomCenter,
  });

  final String what;
  final String title;
  final String? description;
  final bool showCloseButton;
  final PHelpBubbleSide side;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Align(
        alignment: alignment,
        child: PHelpBubble(
          open: true,
          onOpenChange: (_) {},
          title: title,
          description: description,
          showCloseButton: showCloseButton,
          side: side,
          triggerBuilder: (context, toggle, open) => _infoButton(what, toggle),
        ),
      ),
    );
  }
}

/// 카탈로그(/dev/ds) — 열린 말풍선(제목만 · 제목 + 설명 · 닫기 버튼), 자리(뒤집기 · 밀기 · 아래 · 옆), 직접 열어 보기.
/// 툴팁(opens: hover)은 마우스를 올려 여는 것이다 — 앱에도 두되(마우스 · 키보드만) 이 견본은 눌러 여는 쪽만 그린다.
class HelpBubbleDemo extends StatelessWidget {
  const HelpBubbleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DemoBlock(
          title: '말풍선 — 화살표 끝 ↔ ⓘ 4, 최대 280 · 닫기 버튼은 남겨 둘 안내에만',
          children: [
            DemoRow(
              label: '제목만',
              children: [_OpenBubble(what: '금액 가리기', title: '금액 가리기')],
            ),
            DemoRow(
              label: '제목 + 설명',
              children: [
                _OpenBubble(
                  what: _leaveTitle,
                  title: _leaveTitle,
                  description: _leaveDescription,
                ),
              ],
            ),
            DemoRow(
              label: '닫기 버튼',
              children: [
                _OpenBubble(
                  what: '금액 가리기',
                  title: _hideTitle,
                  description: _hideDescription,
                  showCloseButton: true,
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title: '자리 — 기본은 위. 화면 가장자리 16 이 모자라면 반대편으로 뒤집고 옆으로 민다, 화살표는 늘 ⓘ 가운데',
          children: [
            DemoRow(
              label: '위가 모자라면 아래로 뒤집는다',
              children: [
                _OpenBubble(
                  what: _leaveTitle,
                  title: _leaveTitle,
                  description: _leaveDescription,
                  alignment: Alignment.topCenter,
                ),
              ],
            ),
            DemoRow(
              label: '왼쪽 가장자리 — 말풍선을 밀고 화살표는 ⓘ 를 가리킨다',
              children: [
                _OpenBubble(
                  what: _leaveTitle,
                  title: _leaveTitle,
                  description: _leaveDescription,
                  alignment: Alignment.bottomLeft,
                ),
              ],
            ),
            DemoRow(
              label: '아래',
              children: [
                _OpenBubble(
                  what: '금액 가리기',
                  title: _hideTitle,
                  description: _hideDescription,
                  side: PHelpBubbleSide.bottom,
                  alignment: Alignment.topCenter,
                ),
              ],
            ),
            DemoRow(
              label: '옆(오른쪽)',
              children: [
                _OpenBubble(
                  what: '금액 가리기',
                  title: _hideTitle,
                  description: _hideDescription,
                  side: PHelpBubbleSide.right,
                  alignment: Alignment.centerLeft,
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title:
              '직접 열어 보기 — ⓘ 누르기(다시 누르면 닫힘) · 바깥 누르기 · Esc, 닫기 버튼은 누르면 아이콘이 2px 준다',
          children: [
            DemoRow(label: 'ⓘ 규정 안내', children: [_TryInfo()]),
            DemoRow(label: '처음 쓰는 안내', children: [_TryAnchor()]),
          ],
        ),
      ],
    );
  }
}

/// 직접 눌러 여는 ⓘ — 처음엔 닫혀 있다. 화면 위 오버레이에 뜬다.
class _TryInfo extends StatelessWidget {
  const _TryInfo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: PSpacing.x1,
      children: [
        Text(
          '남은 연차 8.5일',
          style: PTypography.t5.copyWith(
            color: c.fgNeutral,
            fontWeight: FontWeight.w500,
          ),
        ),
        PHelpBubble(
          title: _leaveTitle,
          description: _leaveDescription,
          triggerBuilder: (context, toggle, open) =>
              _infoButton(_leaveTitle, toggle),
        ),
      ],
    );
  }
}

/// 처음부터 열어 두는 안내 — 다른 버튼(금액 가리기)에 자리만 붙이고(anchor) 닫기 버튼 · Esc · Tab 으로만 닫는다.
/// 카탈로그가 처음부터 열어 두면 다른 견본을 덮을 수 있어 "안내 열기" 로 연다(실제 화면은 defaultOpen).
class _TryAnchor extends StatefulWidget {
  const _TryAnchor();

  @override
  State<_TryAnchor> createState() => _TryAnchorState();
}

class _TryAnchorState extends State<_TryAnchor> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PButton(
            label: '안내 열기',
            onPressed: () => setState(() => _open = true),
            variant: PButtonVariant.neutralWeak,
            size: PButtonSize.small,
          ),
          PHelpBubble.anchor(
            open: _open,
            onOpenChange: (next) => setState(() => _open = next),
            title: _hideTitle,
            description: _hideDescription,
            showCloseButton: true,
            closeOnInteractOutside: false,
            side: PHelpBubbleSide.bottom,
            anchor: PButton.icon(
              icon: LucideIcons.eyeOff,
              semanticLabel: '금액 가리기',
              onPressed: () {},
              variant: PButtonVariant.ghost,
            ),
          ),
        ],
      ),
    );
  }
}
