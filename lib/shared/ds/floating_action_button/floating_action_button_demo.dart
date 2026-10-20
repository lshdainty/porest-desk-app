import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/p_floating_action_button.dart';

/// 폰 화면 하나 — 목록이 스크롤되고 떠 있는 버튼이 그 위에 앉는다. 안전 영역([bottom])과 바닥 고정 요소([bottomBar])를 흉내 낸다.
class _Screen extends StatelessWidget {
  const _Screen({
    required this.icon,
    required this.label,
    this.bottom = 0,
    this.bottomBar = 0,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final double bottom;
  final double bottomBar;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgLayerBasement,
        border: Border.all(color: c.strokeNeutralSubtle),
        borderRadius: BorderRadius.circular(PRounded.r2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.r2),
        child: SizedBox(
          height: 240 + bottomBar,
          child: MediaQuery(
            data: media.copyWith(padding: EdgeInsets.only(bottom: bottom)),
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: bottomBar + bottom,
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    // 마지막 줄이 버튼에 가리지 않게 — 56 + 20 + 20
                    padding: const EdgeInsets.fromLTRB(
                      PSpacing.x4,
                      PSpacing.x4,
                      PSpacing.x4,
                      kFabSize + kFabMargin * 2,
                    ),
                    children: [
                      for (var i = 1; i <= 6; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: PSpacing.x2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.bgLayerDefault,
                              borderRadius: BorderRadius.circular(PRounded.r2),
                            ),
                            child: SizedBox(
                              height: 52,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: PSpacing.x4,
                                  ),
                                  child: Text(
                                    '항목 $i',
                                    style: PTypography.t4.copyWith(
                                      color: c.fgNeutral,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (bottomBar > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottom,
                    height: bottomBar,
                    child: ColoredBox(color: c.bgLayerDefault),
                  ),
                PFloatingActionButton(
                  icon: icon,
                  label: label,
                  offsetBottom: bottomBar,
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 카탈로그(/dev/ds) — 할 일 · 더치페이(탭 바 없는 화면)의 떠 있는 버튼. 아이콘 둘(+ · 사람 추가), 안전 영역(홈 표시줄 34), 바닥
/// 고정 버튼 위 20, 누름(직접 눌러 본다 — bg-brand-solid-pressed + 2px 축소), 막힘 없음(스펙에 없다).
class FloatingActionButtonDemo extends StatelessWidget {
  const FloatingActionButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '기본 — 오른쪽 아래 · 화면 끝 20 · 아래 20',
          children: [
            _Screen(
              icon: LucideIcons.plus500,
              label: '할 일 추가',
              onPressed: noop,
            ),
          ],
        ),
        DemoBlock(
          title: '아이콘',
          children: [
            _Screen(
              icon: LucideIcons.userPlus500,
              label: '더치페이 만들기',
              onPressed: noop,
            ),
          ],
        ),
        DemoBlock(
          title: '안전 영역 — 홈 표시줄 34 위로 20 더 띄운다',
          children: [
            _Screen(
              icon: LucideIcons.plus500,
              label: '할 일 추가',
              bottom: 34,
              onPressed: noop,
            ),
          ],
        ),
        DemoBlock(
          title: '바닥 고정 요소(높이 64) 위 20',
          children: [
            _Screen(
              icon: LucideIcons.plus500,
              label: '할 일 추가',
              bottom: 34,
              bottomBar: 64,
              onPressed: noop,
            ),
          ],
        ),
      ],
    );
  }
}
