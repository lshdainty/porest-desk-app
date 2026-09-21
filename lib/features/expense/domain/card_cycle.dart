import 'package:porest_desk_app/features/asset/domain/asset.dart';

/// 카드 회차 — 거래 날짜가 속한 회차(그 달 1일~말일)의 결제일.
///
/// 결제일은 **다음 달**의 결제일이고, 그 달에 없는 날이면 말일이다(서버 `CardCycleMath`
/// 와 같은 규칙, 웹 `card-cycle.ts` 미러). 고쳐 쓰기 확인창이 "새 거래는 N월 N일
/// 결제에 청구돼요" 를 말하는 데만 쓴다 — 돈을 얼마 움직일지는 서버만 안다.
///
/// [dateKey] 는 거래 날짜 `yyyy-MM-dd`, 돌려주는 값도 `yyyy-MM-dd`.
String cardCyclePaymentDate(String dateKey, int paymentDay) {
  final y = int.parse(dateKey.substring(0, 4));
  final m = int.parse(dateKey.substring(5, 7));
  final ny = m == 12 ? y + 1 : y;
  final nm = m == 12 ? 1 : m + 1;
  final last = DateTime(ny, nm + 1, 0).day;
  final day = paymentDay < last ? paymentDay : last;
  return '$ny-${_pad2(nm)}-${_pad2(day)}';
}

/// 결제가 끝난(닫힌) 회차에 얼마나 걸렸나 — 확인창의 한 문구를 고른다(D1·D2).
///
/// 닫힌 회차에 걸린 변경은 **전부 기록용**이다 — 통장·카드 빚·다음 청구가 안 움직인다.
/// 그래서 삭제·환불·저장 전에 "기록만 바뀌고 계좌 잔액은 그대로" 를 한 번 말한다.
enum ClosedCycleSpan {
  /// 열린 회차 — 평소대로 청구된다. 확인창에 덧붙일 말이 없다.
  none,

  /// 할부가 닫힌 회차와 열린 회차에 걸쳤다 — 지난 회차분만 기록으로 남는다.
  partial,

  /// 통째로 닫힌 회차 — 기록만 바뀌고 계좌 잔액은 그대로다.
  full,
}

/// 서버가 자산에 내려 준 `cardClosedThrough`(이 날짜 이하 거래는 닫힌 회차)로 가른다.
///
/// **서버에 묻지 않는다.** 회차 경계는 서버가 정하고(결제일 이력·서울 시계, D5·D11)
/// 클라이언트는 날짜만 견준다 — 회차를 여기서 다시 계산하면 결제일을 바꾼 카드에서
/// 서버와 어긋난다.
///
/// 할부는 마지막 회차 말일이 경계보다 뒤면 걸친 것이다(첫 회차 말일 ≤ 경계 < 마지막
/// 회차 말일).
ClosedCycleSpan closedCycleSpan({
  required String? cardClosedThrough,
  required String? dateKey,
  int? installmentMonths,
}) {
  if (cardClosedThrough == null || dateKey == null || dateKey.length < 10) {
    return ClosedCycleSpan.none;
  }
  final day = dateKey.substring(0, 10);
  if (day.compareTo(cardClosedThrough) > 0) return ClosedCycleSpan.none;
  final months = installmentMonths ?? 1;
  if (months <= 1) return ClosedCycleSpan.full;
  final y = int.parse(day.substring(0, 4));
  final m = int.parse(day.substring(5, 7));
  // 마지막 회차 = 거래 달 + (N−1) 달. DateTime 이 13월 이상을 다음 해로 굴린다.
  final lastEnd = DateTime(y, m + months, 0);
  final lastKey =
      '${lastEnd.year}-${_pad2(lastEnd.month)}-${_pad2(lastEnd.day)}';
  return lastKey.compareTo(cardClosedThrough) <= 0
      ? ClosedCycleSpan.full
      : ClosedCycleSpan.partial;
}

/// 그 자산에 단 거래가 닫힌 회차에 걸렸나 — 신용카드만 해당한다.
///
/// 계좌·체크카드·현금은 거래가 곧 잔액이라 "기록만" 이 없다. 서버도 신용카드에만
/// `cardClosedThrough` 를 내려 주지만 종류로 한 번 더 막는다.
ClosedCycleSpan closedCycleSpanFor(
  Asset? asset, {
  required String? dateKey,
  int? installmentMonths,
}) {
  if (asset == null || asset.assetType != 'CREDIT_CARD') {
    return ClosedCycleSpan.none;
  }
  return closedCycleSpan(
    cardClosedThrough: asset.cardClosedThrough,
    dateKey: dateKey,
    installmentMonths: installmentMonths,
  );
}

String _pad2(int n) => n.toString().padLeft(2, '0');
