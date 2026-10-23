import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/brand/groo_tree_painter.dart';

/// 그루 나무 로고 — 높이 [height] 에 보기 상자 비율(154 : 166)로 폭이 정해진다.
///
/// 칠은 시안 고정값이고 라이트 · 다크가 같다(DESIGN.md "그룹 색 · 로고 칠"). 나무는 장식이라
/// 의미 트리에서 뺀다 — 이름은 옆의 글("그루 담다")이 말한다.
class GrooTree extends StatelessWidget {
  const GrooTree({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: height * kGrooTreeAspect,
        height: height,
        child: const CustomPaint(
          key: ValueKey('groo-tree'),
          painter: GrooTreePainter(),
        ),
      ),
    );
  }
}
