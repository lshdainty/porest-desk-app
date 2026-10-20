import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 카탈로그 무대 — 겹침을 뜨기 전 화면 위에 딤 + 표면으로 정지시켜 그린다(웹 `OverlayStage` 의 앱 판).
/// debug 카탈로그 전용 — 실제로 띄우는 것은 라우트다(`PAlertDialog.show` · `PBottomSheet.show`).
///
/// 뒷 화면은 빈 면 + 줄 몇 개로 흉내 낸다. 안전 영역 · 키보드는 0 으로 두어 견본이 기기마다 달라지지 않는다.
class DsOverlayStage extends StatelessWidget {
  const DsOverlayStage({
    super.key,
    required this.height,
    required this.child,
    this.alignment = Alignment.center,
  });

  final double height;
  final Alignment alignment;

  /// 표면 — [PAlertDialogView] · 시트 표면.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.bgLayerDefault),
              Padding(
                padding: const EdgeInsets.all(PSpacing.x6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: PSpacing.x3,
                  children: [
                    for (final w in const [0.5, 0.9, 0.7, 0.8])
                      FractionallySizedBox(
                        widthFactor: w,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.bgNeutralWeak,
                            borderRadius: BorderRadius.circular(PRounded.r1),
                          ),
                          child: const SizedBox(height: 14),
                        ),
                      ),
                  ],
                ),
              ),
              ColoredBox(color: c.overlayDim),
              Align(alignment: alignment, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
