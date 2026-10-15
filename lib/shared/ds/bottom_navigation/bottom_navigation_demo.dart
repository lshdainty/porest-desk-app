import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';

/// 탭 바가 놓인 폰 화면 — 목록 위에 바가 앉는다. [live] 면 스크롤로 줄고 펴지며 칸을 눌러 탭을 옮긴다. [bottom] 은 홈 표시줄.
class _Screen extends StatefulWidget {
  const _Screen({
    this.initial = 0,
    this.compact = false,
    this.badges = const {},
    this.addLabel = '거래 추가',
    this.bottom = 0,
    this.labels = const ['홈', '가계부', '캘린더', '전체'],
    this.width,
  });

  final int initial;
  final bool compact;
  final Set<int> badges;
  final String addLabel;
  final double bottom;
  final List<String> labels;
  final double? width;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  late final PBottomNavigationController _controller =
      PBottomNavigationController(compact: widget.compact);
  late int _current = widget.initial;

  static const _icons = [
    LucideIcons.house,
    LucideIcons.wallet,
    LucideIcons.calendar,
    LucideIcons.layoutGrid,
  ];
  static const _selectedIcons = [
    LucideIcons.house500,
    LucideIcons.wallet500,
    LucideIcons.calendar500,
    LucideIcons.layoutGrid500,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: widget.width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.bgLayerBasement,
            border: Border.all(color: c.strokeNeutralSubtle),
            borderRadius: BorderRadius.circular(PRounded.r2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PRounded.r2),
            child: SizedBox(
              height: 300,
              child: MediaQuery(
                data: media.copyWith(
                  padding: EdgeInsets.only(bottom: widget.bottom),
                ),
                child: Builder(
                  builder: (context) => Stack(
                    children: [
                      Positioned.fill(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _controller.handleScroll,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              PSpacing.x4,
                              PSpacing.x4,
                              PSpacing.x4,
                              // 본문 아래 여백 — 바의 아래 자리 + 66 + 24
                              bottomNavigationInset(context),
                            ),
                            children: [
                              for (var i = 1; i <= 12; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: PSpacing.x2,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: i == 3
                                          ? c.bgBrandSolid
                                          : c.bgLayerDefault,
                                      borderRadius: BorderRadius.circular(
                                        PRounded.r2,
                                      ),
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
                                            '내역 $i',
                                            style: PTypography.t4.copyWith(
                                              color: i == 3
                                                  ? c.staticWhite
                                                  : c.fgNeutral,
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
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: PBottomNavigation(
                          semanticLabel: '주 메뉴',
                          controller: _controller,
                          add: PBottomNavigationAdd(
                            label: widget.addLabel,
                            onPressed: () {},
                          ),
                          items: [
                            for (var i = 0; i < 4; i++)
                              PBottomNavigationItem(
                                icon: _icons[i],
                                selectedIcon: _selectedIcons[i],
                                label: widget.labels[i],
                                current: i == _current,
                                notification: widget.badges.contains(i),
                                notificationLabel: '새 소식',
                                onTap: () => setState(() => _current = i),
                                onReselect: () {},
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 카탈로그(/dev/ds) — 펼침 66 · 줄어듦 48(라벨 숨김 · 이름 남음), 지금 탭 넷, 가운데 + 의 이름(거래 추가 · 일정 추가), 알림 점 2칸,
/// 안전 영역(홈 표시줄 34), 가장 나쁜 값(라벨 5자 · 폭 360 미만), 그리고 스크롤하면 줄고 · 위로 올리면 펴지고 · 줄어든 바를 누르면
/// 펴지는 살아 있는 화면. 누름(칸 2px 축소 · + 누름 색)은 직접 눌러 본다.
class BottomNavigationDemo extends StatelessWidget {
  const BottomNavigationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '살아 있는 화면 — 목록을 아래로 밀면 줄고, 위로 밀면 펴진다. 칸을 누르면 탭이 옮겨진다',
          children: [_Screen()],
        ),
        DemoBlock(
          title: '펼침 66 · 지금 탭 — 홈 · 가계부 · 캘린더 · 전체',
          children: [
            _Screen(initial: 0),
            _Screen(initial: 1),
            _Screen(initial: 2, addLabel: '일정 추가'),
            _Screen(initial: 3),
          ],
        ),
        DemoBlock(
          title: '줄어듦 48 — 라벨은 숨기고 이름은 남는다 · + 36',
          children: [_Screen(compact: true, initial: 1)],
        ),
        DemoBlock(
          title: '알림 점 — 2칸까지(가계부 · 전체)',
          children: [
            _Screen(badges: {1, 3}),
            _Screen(badges: {1, 3}, compact: true),
          ],
        ),
        DemoBlock(
          title: '안전 영역 — 홈 표시줄 34(바 아래 28)',
          children: [_Screen(bottom: 34), _Screen(bottom: 34, compact: true)],
        ),
        DemoBlock(
          title: '가장 나쁜 값 — 라벨 5자 · 알림 점 둘 · 폭 320',
          children: [
            _Screen(
              labels: ['홈', '가계부가', '캘린더입', '전체보기'],
              badges: {1, 3},
              initial: 2,
              width: 320,
            ),
          ],
        ),
      ],
    );
  }
}
