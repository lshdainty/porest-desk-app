import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 홈이 아닌 셸 branch 의 첫 화면에서 기기 뒤로가기를 받아 홈으로 보낸다.
///
/// 화면 안 ← 버튼과 같은 곳으로 간다. 홈(branch 0)에는 걸지 않는다 — 거기서
/// 뒤로가기는 앱을 끄는 게 맞다.
///
/// ## 왜 셸이 아니라 화면에 거는가
///
/// 안드로이드에는 뒤로가기가 두 갈래로 온다.
///
/// - **옛 방식** — OS 가 `flutter/navigation` 채널로 `popRoute` 를 보내고
///   Flutter 가 위에서부터 `maybePop` 한다.
/// - **예측형(OnBackInvokedCallback)** — OS 가 먼저 "프레임워크가 뒤로가기를
///   받을 수 있나" 를 묻는다(`SystemNavigator.setFrameworkHandlesBack`).
///   앱이 **false** 라고 답해 둔 상태면 OS 는 Flutter 를 부르지 않고
///   **액티비티를 그냥 끝낸다.**
///
/// targetSdk 36(Flutter 3.44 기본)이고 매니페스트에 `enableOnBackInvokedCallback`
/// 지정이 없어, 안드로이드 16 기기에서는 예측형이 기본으로 켜진다.
///
/// 이 PopScope 를 **셸(루트 네비게이터)** 에 걸면 그 값이 false 로 남는다.
/// Navigator 는 자기 이력이 바뀔 때 `NavigationNotification(canHandlePop)` 을
/// 위로 올리고, 위 Navigator 는 **자기가 pop 할 게 있을 때만** true 로 바꿔
/// 올린다(`navigator.dart:3743-3753, 5916-5928`). 통계로 가면 branch 네비게이터가
/// (한 페이지·PopScope 없음) false 를 올리고, 루트 네비게이터는 페이지가 하나라
/// `canPop()` 이 false 여서 그대로 통과시킨다 — 셸 PopScope 가 앞서 낸 true 는
/// 이미 지나갔고 **마지막 값이 false** 가 된다. OS 는 그 false 를 믿고 앱을 끈다.
///
/// 그래서 **branch 네비게이터의 맨 위 라우트**에 건다. 그러면 그 네비게이터가
/// 이력이 바뀔 때마다 `routeBlocksPop = true` 로 true 를 올리고, 루트는 true 를
/// 그대로 전파한다(`navigator.dart:5920`). 두 갈래 모두 Flutter 로 들어온다.
///
/// ## 걸지 말아야 하는 곳
///
/// branch 안에 **push 되는 하위 라우트**(거래 상세 등)에는 걸지 않는다. 걸면
/// 상세에서 뒤로가기가 상세를 닫는 대신 홈으로 튄다.
///
/// 시트·다이얼로그는 루트 네비게이터에 셸 페이지보다 위로 얹히므로 뒤로가기가
/// 그것부터 닫는다 — go_router 의 `popRoute` 가 깊은 네비게이터부터 `maybePop`
/// 하고, Navigator 는 맨 위 라우트에게만 묻기 때문이다.
///
/// 위 규칙은 `test/shared/mobile_scaffold_back_test.dart`(옛 방식)와
/// `test/shared/predictive_back_test.dart`(예측형)가 함께 고정한다.
class BranchBackToHome extends StatelessWidget {
  const BranchBackToHome({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        StatefulNavigationShell.of(context).goBranch(0);
      },
      child: child,
    );
  }
}
