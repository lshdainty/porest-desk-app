import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/widgets/p_modal.dart';

/// 자산 추가 · 수정 폼의 표면을 여는 곳(I-17 A 4) — 세 폼(계좌 · 카드 · 투자)이 같은 껍데기로 시트를 띄운다.
///
/// 몸([builder] 가 돌려주는 본문)은 각 폼 파일이 그대로 갖는다. 표면을 바꾸는 일은 이 파일에서만 한다.
Future<void> showAssetFormSurface(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required Widget Function(
    BuildContext context,
    ScrollController scrollController,
    PSheetController controller,
  )
  builder,
}) {
  final controller = PSheetController();
  return showPSheet<void>(
    context,
    title: title,
    contentBuilder: (ctx, scrollCtrl) => builder(ctx, scrollCtrl, controller),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: submitLabel),
  ).whenComplete(controller.dispose);
}
