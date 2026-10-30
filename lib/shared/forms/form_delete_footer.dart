import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

/// 수정 폼의 바닥 줄 — 왼쪽 [삭제](ghost critical large 48, 빨간 글 · 글자만큼의 폭 — bottom-sheet.md 바닥 · button.md 시트 바닥) + 나머지 폭 [저장](large 48). 새로 만드는 폼에는 [삭제] 가 없다
/// (이 줄 대신 평소 바닥 버튼 하나를 쓴다).
///
/// 삭제는 확인 창이 따로 묻는다 — 이 줄의 [onDelete] 는 시트를 닫고 확인으로 넘기는 일만 한다. `flush` 를 주지 않는다(ghost 의
/// 빨간 글이 flush 에서는 회색으로 덮인다 — button.md). 웹 `shared/ui/groo/form-footer.tsx` 의 폰 모양과 같다.
///
/// [PBottomSheetContent.footerRow] 에 넣는다.
class PFormDeleteFooter extends StatelessWidget {
  PFormDeleteFooter({
    super.key,
    required this.deleteLabel,
    required this.onDelete,
    required this.save,
  }) : assert(save.size == PButtonSize.large, '저장은 large 48 이다');

  final String deleteLabel;
  final VoidCallback? onDelete;

  /// 오른쪽 주 버튼 — Button large.
  final PButton save;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: PSpacing.x2,
      children: [
        PButton(
          label: deleteLabel,
          variant: PButtonVariant.ghost,
          ghostColor: PButtonGhostColor.critical,
          size: PButtonSize.large,
          onPressed: onDelete,
        ),
        Expanded(child: save),
      ],
    );
  }
}
