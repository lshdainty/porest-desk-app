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

/// 결제일이 [paymentDate] 인 회차의 이용 달(`yyyy-MM`) — 결제일의 전달이다.
String cycleMonthOfPaymentDate(String paymentDate) {
  final y = int.parse(paymentDate.substring(0, 4));
  final m = int.parse(paymentDate.substring(5, 7));
  return m == 1 ? '${y - 1}-12' : '$y-${_pad2(m - 1)}';
}

/// 거래 날짜가 속한 회차의 **실제** 결제일 — 결제일 변경이 대기 중이어도 맞게(D5).
///
/// 결제일을 바꾸면 바꿀 때 아직 결제 전이던 회차는 옛 결제일로 나간다. 그 회차의 실제
/// 결제일은 서버가 자산 응답에 [nextPaymentDate] 로 내려 준다(결제일 이력 반영). 거래
/// 날짜가 그 회차(= [nextPaymentDate] 의 전달)에 들면 그 값을, 아니면 지금 결제일
/// [paymentDay] 로 센다([cardCyclePaymentDate]) — 그 뒤 회차는 새 결제일로 나간다.
String cyclePaymentDate(
  String dateKey,
  int paymentDay,
  String? nextPaymentDate,
) {
  if (nextPaymentDate != null &&
      nextPaymentDate.length >= 10 &&
      dateKey.substring(0, 7) == cycleMonthOfPaymentDate(nextPaymentDate)) {
    return nextPaymentDate.substring(0, 10);
  }
  return cardCyclePaymentDate(dateKey, paymentDay);
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

/// 결제일을 바꿔도 **옛 결제일로 결제되는 회차** — 확인창 "N월분은 M월 D일에
/// 결제돼요" 의 재료(D5).
///
/// 결제일 변경은 다음 회차부터다. 바꾸는 시점에 아직 결제 전인 가장 가까운 회차는 옛
/// 결제일에 결제된다. 서버가 그 회차의 실제 결제일을 [nextPaymentDate] 로 내려 주면
/// 그대로 쓴다 — 결제일을 이미 한 번 바꿔 둔 카드는 그 회차가 지금 결제일이 아니라 더
/// 옛 결제일로 나간다(QA 26 4). 없으면(옛 서버) 서버가 내려 준 `cardClosedThrough`(닫힌
/// 회차 경계)의 다음 달 회차를 옛 결제일로 센다. 경계도 없으면 오늘 기준으로 결제일이
/// 아직 안 온 첫 회차다(D2 — 결제일 당일부터 닫힌다).
///
/// 돌려주는 [month] 는 그 회차의 이용 달(`8월분`), [paymentDate] 는 `yyyy-MM-dd`.
({int year, int month, String paymentDate}) pendingCycleOnOldDay({
  required int oldPaymentDay,
  required String? cardClosedThrough,
  required String todayKey,
  String? nextPaymentDate,
}) {
  if (nextPaymentDate != null && nextPaymentDate.length >= 10) {
    final cycle = cycleMonthOfPaymentDate(nextPaymentDate);
    return (
      year: int.parse(cycle.substring(0, 4)),
      month: int.parse(cycle.substring(5, 7)),
      paymentDate: nextPaymentDate.substring(0, 10),
    );
  }
  int y;
  int m;
  if (cardClosedThrough != null && cardClosedThrough.length >= 7) {
    final cy = int.parse(cardClosedThrough.substring(0, 4));
    final cm = int.parse(cardClosedThrough.substring(5, 7));
    y = cm == 12 ? cy + 1 : cy;
    m = cm == 12 ? 1 : cm + 1;
  } else {
    final ty = int.parse(todayKey.substring(0, 4));
    final tm = int.parse(todayKey.substring(5, 7));
    // 지난달 회차는 이번 달에 결제된다 — 그 결제일이 아직 안 왔으면 그 회차다.
    y = tm == 1 ? ty - 1 : ty;
    m = tm == 1 ? 12 : tm - 1;
    if (cardCyclePaymentDate(
          '$y-${_pad2(m)}-01',
          oldPaymentDay,
        ).compareTo(todayKey) <=
        0) {
      y = ty;
      m = tm;
    }
  }
  return (
    year: y,
    month: m,
    paymentDate: cardCyclePaymentDate('$y-${_pad2(m)}-01', oldPaymentDay),
  );
}

String _pad2(int n) => n.toString().padLeft(2, '0');
