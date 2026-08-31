import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// 릴리스 노트 — CI(`scripts/release_notes.sh`)가 만든 글을 그린다.
///
/// 예전엔 노트가 커밋 제목의 나열이라 줄마다 같은 무게로 그려도 됐다. 지금은 타입별로
/// 묶여 오므로 제목과 항목을 갈라 그리지 않으면 "새 기능" 이 항목 하나처럼 보인다.
///
/// 형식은 둘뿐이다.
/// ```
/// 새 기능          ← 그룹 제목(맨줄)
/// - 무엇을 했다     ← 항목('- ' 로 시작)
/// ```
///
/// 업데이트 게이트와 설정 > 업데이트가 같은 글을 그린다. 예전엔 두 화면이 각자
/// 파싱해서, 한쪽만 고치면 같은 노트가 서로 다르게 보였다.
class PReleaseNotes extends StatelessWidget {
  const PReleaseNotes({super.key, required this.notes});

  final String notes;

  /// 그릴 게 있는가 — 호출부가 섹션 제목까지 통째로 숨길 때 쓴다.
  static bool hasContent(String notes) => notes.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final lines = notes
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    final children = <Widget>[];
    for (final line in lines) {
      final isItem = line.startsWith('- ');
      if (isItem) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: PSpace.x8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 글머리를 따로 둔다 — 두 줄로 넘어가는 항목에서 둘째 줄이 글머리
                // 아래로 파고들지 않게.
                Text(
                  '· ',
                  style: PTypo.bodySm.copyWith(
                    color: t.fgTertiary,
                    height: 1.6,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: PTypo.bodySm.copyWith(
                      color: t.fgSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            // 첫 제목 위에는 여백을 두지 않는다 — 상자 안쪽 padding 과 겹쳐 뜬다.
            padding: EdgeInsets.only(
              top: children.isEmpty ? 0 : PSpace.x12,
              bottom: PSpace.x8,
            ),
            child: Text(
              line,
              style: PTypo.bodySm.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
