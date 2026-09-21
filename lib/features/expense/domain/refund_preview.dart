import 'package:freezed_annotation/freezed_annotation.dart';

part 'refund_preview.freezed.dart';
part 'refund_preview.g.dart';

/// 카드 정산 미리보기 — 저장·삭제·수정·환불하면 돈이 어떻게 움직이는지(설계 13-1,
/// 닫힌 회차 R2·R3·R6).
///
/// 금액은 서버만 안다. 회차마다 "실제 낸 이체액 − 다시 계산한 청구액" 이라 거래 금액과
/// 다르고, 재료가 전부 서버 테이블에 있다.
///
/// [applies] 가 false 면 돌려줄 돈이 없다. [reason] 으로 화면이 문구를 고른다 —
/// `OK`·`RECORD_ONLY_OK`(금액 줄) · `ALREADY_REFUNDED`("이미 환급된 거래") ·
/// `REFUND_WINDOW_CLOSED`("결제한 달이 지나 기록만 정리돼요") · 나머지(줄 없음).
@freezed
abstract class RefundPreview with _$RefundPreview {
  const factory RefundPreview({
    @Default(false) bool applies,
    @Default(0) int refundAmount,
    @Default('') String reason,

    /// 이번 저장으로 기록만 남는 금액 — 결제가 끝난 회차에 떨어진 몫(R2). 옛 서버면 0.
    @Default(0) int newRecordAmount,

    /// 오늘이 결제일이라 결제계좌에서 추가로 빠질 금액(R3). 옛 서버면 0.
    @Default(0) int sameDayExtraPayment,
  }) = _RefundPreview;

  factory RefundPreview.fromJson(Map<String, dynamic> json) =>
      _$RefundPreviewFromJson(json);
}

extension RefundPreviewX on RefundPreview {
  /// 이미 환불 마크된 거래 — 환급은 그때 끝났다.
  bool get alreadyRefunded => reason == 'ALREADY_REFUNDED';

  /// 돌려줄 돈이 있다.
  bool get hasRefund => applies && refundAmount > 0;

  /// 결제한 달이 지나 돌려주지 않는다 — 기록만 정리된다(R6).
  bool get windowClosed => reason == 'REFUND_WINDOW_CLOSED';
}
