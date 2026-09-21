import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 자산 하나의 수정 폼으로 바로 가는 주소 — `/account-card-manage?edit=<id>`(D9).
///
/// 결제가 끝난 회차의 카드 거래를 환불·삭제·고쳐 쓰면 통장은 그대로다. 실제로 돈을
/// 돌려받았으면 사용자가 결제계좌 잔액을 고쳐야 하는데, 목록 → 계좌 → 연필을 거치면
/// 다섯 번 안팎을 눌러야 했다. [잔액 고치기]·자산 상세 [수정]이 이 주소로 온다.
String assetEditLocation(int assetRowId) =>
    '/account-card-manage?edit=$assetRowId';

/// [assetEditLocation] 으로 간다. 라우터 밖(테스트 등)이면 아무 일도 안 한다.
void pushAssetEdit(BuildContext context, int assetRowId) {
  GoRouter.maybeOf(context)?.push(assetEditLocation(assetRowId));
}
