import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

/// 그림 크기 — 틀 높이의 50%, 16 이상 160 이하. 틀 폭이 그보다 좁으면 폭에 맞춘다(content-placeholder.yaml glyph).
@visibleForTesting
double contentPlaceholderGlyphSize(Size frame) {
  final byHeight = (frame.height * 0.5).clamp(16.0, 160.0);
  return byHeight > frame.width ? frame.width : byHeight;
}

/// Content Placeholder — 이미지가 없거나 불러오지 못했을 때 그 자리를 채우는 대체 그림. 구조는 SEED Content
/// Placeholder(2026-10-03), 수치 원본은 porest-design `specs/components/content-placeholder.yaml`(값은
/// `test/fixtures/design_spec/content-placeholder.json`). 웹(desk-front `src/shared/ds/content-placeholder`)과 같은 값이다.
///
/// 옅은 면(bg-neutral-weak — Skeleton 면과 같은 색) + 가운데 선 아이콘(기본 image, 선 1.5 — lucide 300 굵기,
/// stroke-neutral-weak). 담는 틀을 채우고 제 모서리가 없다 — 모서리는 담는 틀이 자른다. 불러오는 동안에는 쓰지 않는다
/// (그건 같은 모서리의 Skeleton 이다). 장식이라 읽지 않는다 — 무엇이 없는지는 담는 틀의 대체 글이 말한다.
class PContentPlaceholder extends StatelessWidget {
  const PContentPlaceholder({super.key, this.icon = LucideIcons.image300});

  /// 무엇이 없는지 말하는 선 아이콘 — lucide 의 300 굵기(선 1.5)를 쓴다.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.bgNeutralWeak),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = contentPlaceholderGlyphSize(constraints.biggest);
            return SizedBox.expand(
              child: Center(
                child: Icon(icon, size: size, color: c.strokeNeutralWeak),
              ),
            );
          },
        ),
      ),
    );
  }
}
