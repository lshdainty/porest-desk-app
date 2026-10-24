import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 자식을 폭에 묶지 않고(폭 무제한) 가운데에 놓는다 — 자식이 부모 폭보다 넓으면 양쪽으로 똑같이 넘친다(웹의 `inline-flex` 가
/// 칸보다 넓어지는 것과 같다). 크기는 부모 폭 안으로 맞춘 자식 크기다. 글자를 줄이지 않고 넘치게 두는 자리(큰 글자의 날 숫자 ·
/// 아이콘 단추의 누르는 영역)에 쓴다.
///
/// 넘친 조각도 눌린다 — Flutter 는 기본으로 부모 크기 밖을 누르면 받지 않아, 넘친 자식의 바깥 조각이 아래 층의 누름이 된다.
class POverflowCenter extends SingleChildRenderObjectWidget {
  const POverflowCenter({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverflowCenter();
}

class _RenderOverflowCenter extends RenderShiftedBox {
  _RenderOverflowCenter() : super(null);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(
      child.getDryLayout(
        constraints.copyWith(minWidth: 0, maxWidth: double.infinity),
      ),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(
      constraints.copyWith(minWidth: 0, maxWidth: double.infinity),
      parentUsesSize: true,
    );
    size = constraints.constrain(child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final offset = (child.parentData! as BoxParentData).offset;
    return result.addWithPaintOffset(
      offset: offset,
      position: position,
      hitTest: (r, p) => child.hitTest(r, position: p),
    );
  }
}
