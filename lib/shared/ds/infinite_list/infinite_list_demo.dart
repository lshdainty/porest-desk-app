import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/infinite_list/p_infinite_list.dart';

/// 카탈로그(/dev/ds) — 상태 셋(받는 중 · 못 불러옴 · 끝)과 끝 글 바꾸기, 글자 200% 에서 가장 좁은 폭.
/// 받는 시점(끝이 화면 아래에서 300 안)은 스크롤하는 목록이 있어야 보여서 견본이 아니라 테스트가 본다.
class InfiniteListDemo extends StatelessWidget {
  const InfiniteListDemo({super.key});

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    Widget framed(Widget child) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.strokeNeutralWeak),
        borderRadius: BorderRadius.circular(PRounded.r2),
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: 'loading — 1초가 지나야 원이 보인다(그 전에는 높이만)',
          children: [
            framed(const PInfiniteListEnd(status: PInfiniteListStatus.loading)),
          ],
        ),
        DemoBlock(
          title: 'error — 이미 받은 줄은 그대로, 글 + 다시 시도',
          children: [
            framed(
              const PInfiniteListEnd(
                status: PInfiniteListStatus.error,
                onRetry: _ignore,
              ),
            ),
          ],
        ),
        DemoBlock(
          title: 'end — 기본 글 · 목록마다 바꾼 글',
          children: [
            framed(const PInfiniteListEnd(status: PInfiniteListStatus.end)),
            framed(
              const PInfiniteListEnd(
                status: PInfiniteListStatus.end,
                endText: '카드를 모두 봤어요.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
