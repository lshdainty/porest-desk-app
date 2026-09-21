/// 카드 회차 — 거래 날짜가 속한 회차(그 달 1일~말일)의 결제일.
///
/// 결제일은 **다음 달**의 결제일이고, 그 달에 없는 날이면 말일이다(서버 `CardCycleMath`
/// 와 같은 규칙, 웹 `card-cycle.ts` 미러). 저장 확인창이 서버에 물어볼지 가르는 데만 쓴다
/// — 돈을 얼마 움직일지는 서버만 안다.
///
/// [dateKey] 는 거래 날짜 `yyyy-MM-dd`, 돌려주는 값도 `yyyy-MM-dd`.
String cardCyclePaymentDate(String dateKey, int paymentDay) {
  final y = int.parse(dateKey.substring(0, 4));
  final m = int.parse(dateKey.substring(5, 7));
  final ny = m == 12 ? y + 1 : y;
  final nm = m == 12 ? 1 : m + 1;
  final last = DateTime(ny, nm + 1, 0).day;
  final day = paymentDay < last ? paymentDay : last;
  String pad2(int n) => n.toString().padLeft(2, '0');
  return '$ny-${pad2(nm)}-${pad2(day)}';
}

/// 그 회차의 결제일이 이미 왔는가(당일 포함) — 닫힌 회차(기록만)거나 결제일 당일(그 자리
/// 결제)이라 저장 전에 한 번 물어야 하는 자리다(닫힌 회차 규칙 R1·R2·R3).
bool isCardCycleDue(String dateKey, int paymentDay, String todayKey) =>
    cardCyclePaymentDate(dateKey, paymentDay).compareTo(todayKey) <= 0;
