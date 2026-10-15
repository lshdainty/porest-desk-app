import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

/// 겹침(Alert Dialog · Bottom Sheet)이 함께 쓰는 도구 — 딤과 라우트를 띄울 때 테마를 잇는 법.
///
/// 앱은 겹침을 Flutter 라우트(Navigator)로 띄운다. 웹의 z-index 층(시트 L2 · 확인창 L5, specs/z-index.md)은
/// 라우트가 쌓이는 차례가 대신한다 — 시트 위에서 연 확인창이 그 위에 뜬다.

/// 딤 — 겹침 뒤 화면 전체. 색은 라이트 0.50 · 다크 0.65([PColors.overlayDim]).
///
/// 딤의 나타남 · 사라짐은 [PDimLayer.animated] 의 애니메이션이, 끌어 내릴 때처럼 따로 계산하는 값은 기본 생성자의
/// [repaint] · [opacityOf] 가 정한다. [onTap] 이 없으면 눌러도 아무 일이 없다(Alert Dialog) — 뒤 화면으로 누름이 새지
/// 않는다. 보조 기술에는 보이지 않는다.
class PDimLayer extends StatelessWidget {
  const PDimLayer({
    super.key,
    required this.repaint,
    required this.opacityOf,
    this.onTap,
  });

  /// 애니메이션 하나가 정하는 딤.
  PDimLayer.animated({
    Key? key,
    required Animation<double> opacity,
    VoidCallback? onTap,
  }) : this(
         key: key,
         repaint: opacity,
         opacityOf: () => opacity.value,
         onTap: onTap,
       );

  /// 이 신호가 오면 [opacityOf] 를 다시 읽는다.
  final Listenable repaint;
  final double Function() opacityOf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.overlayDim;
    return Positioned.fill(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: repaint,
          builder: (context, child) =>
              Opacity(opacity: opacityOf().clamp(0.0, 1.0), child: child),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap ?? () {},
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );
  }
}

/// 라우트가 뜰 자리(Navigator)에서도 연 자리의 테마를 쓰게 감싼다 — 카탈로그의 다크 판처럼 하위 요소에만 걸린 테마도
/// 따라온다(`showDialog` 의 `InheritedTheme.capture` 와 같다).
CapturedThemes captureOverlayThemes(
  BuildContext from,
  NavigatorState navigator,
) => InheritedTheme.capture(from: from, to: navigator.context);
