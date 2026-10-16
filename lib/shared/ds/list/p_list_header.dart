import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

/// 목록 제목의 모양 — mediumWeak(기본: 14 · 500 · 옅은 색 — 줄보다 앞서지 않는다) · boldSolid(14 · 700 · 짙은 색 — 화면을
/// 크게 나누는 묶음에만).
enum PListHeaderVariant { mediumWeak, boldSolid }

/// List Header(목록 제목) — 목록 밖, 바로 위에 두는 제목. 수치 원본은 groo-design `specs/components/list-header.yaml`
/// (값은 `test/fixtures/design_spec/list-header.json`). 웹(desk-front `src/shared/ds/list`)과 같은 값이다.
///
/// 좌우 24(줄과 같다 — 제목과 줄의 왼쪽이 맞는다) · 위아래 8 · 제목과 오른쪽 작은 버튼(도움말 · 전체 보기) 사이 10.
/// 제목은 글(String)이고 낱말 단위로 줄을 바꾼다. 화면 맨 위 제목 · 카드 제목은 목록 제목이 아니다.
///
/// 읽기 — 제목은 머리말(header)로 읽는다. 목록 이름에는 제목 글만 쓴다 — 웹의 `aria-labelledby`(목록 → 제목 글에만 id)
/// 대신 [PList.semanticLabel] 에 같은 제목 글을 준다(오른쪽 버튼 글이 목록 이름에 섞이지 않는다). 오른쪽 버튼은 따로
/// 읽힌다.
class PListHeader extends StatelessWidget {
  const PListHeader({
    super.key,
    required this.title,
    this.variant = PListHeaderVariant.mediumWeak,
    this.action,
  });

  final String title;
  final PListHeaderVariant variant;

  /// 오른쪽 글 버튼([PTextButton]) — 있을 때만(전체 보기).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final strong = variant == PListHeaderVariant.boldSolid;
    final style = PTypography.t4.copyWith(
      color: strong ? c.fgNeutral : c.fgNeutralSubtle,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
    );
    return PTouchTargetScope(
      child: Padding(
        key: const ValueKey('plist-header'),
        padding: EdgeInsets.symmetric(
          horizontal: PSpacing.globalGutter,
          // 글 버튼(36)이 있으면 그 36 이 줄 높이다 — 위아래 8 + 20 과 같다(스펙 marginY −8)
          vertical: action == null ? PSpacing.x2 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: PSpacing.x2_5,
          children: [
            Flexible(
              child: Semantics(
                header: true,
                headingLevel: 2,
                container: true,
                label: title,
                child: ExcludeSemantics(
                  child: Text(
                    keepAll(title),
                    key: const ValueKey('plist-header-title'),
                    style: style,
                  ),
                ),
              ),
            ),
            if (action != null)
              Transform.translate(
                offset: const Offset(kTextButtonPaddingX, 0),
                child: action,
              ),
          ],
        ),
      ),
    );
  }
}
