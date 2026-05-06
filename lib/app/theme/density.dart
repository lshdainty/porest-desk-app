/// porest-desk-front `data-density` 토큰 (compact / comfortable / spacious) 매핑.
///
/// 사용자 환경설정(`pd-density` localStorage)으로 전체 행/카드 패딩이 바뀐다.
/// Phase 5에서 Riverpod Provider로 노출 예정.
enum PDensity {
  compact(rowPadY: 10, cardPad: 16),
  comfortable(rowPadY: 12, cardPad: 20),
  spacious(rowPadY: 14, cardPad: 20);

  const PDensity({required this.rowPadY, required this.cardPad});

  final double rowPadY;
  final double cardPad;
}
