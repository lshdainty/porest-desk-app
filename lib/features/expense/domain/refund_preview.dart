import 'package:freezed_annotation/freezed_annotation.dart';

part 'refund_preview.freezed.dart';
part 'refund_preview.g.dart';

/// 카드 환급 미리보기 — 지우거나 고치면 결제계좌로 얼마가 돌아오는지(설계 13-1).
///
/// 금액은 서버만 안다. 회차마다 "실제 낸 이체액 − 다시 계산한 청구액" 이라 거래 금액과
/// 다르고, 재료가 전부 서버 테이블에 있다.
///
/// [applies] 가 false 면 돌려줄 돈이 없다. [reason] 으로 화면이 문구를 고른다 —
/// `OK`(금액 줄) · `ALREADY_REFUNDED`("이미 환급된 거래") · 나머지(줄 없음).
@freezed
abstract class RefundPreview with _$RefundPreview {
  const factory RefundPreview({
    @Default(false) bool applies,
    @Default(0) int refundAmount,
    @Default('') String reason,
  }) = _RefundPreview;

  factory RefundPreview.fromJson(Map<String, dynamic> json) =>
      _$RefundPreviewFromJson(json);
}

extension RefundPreviewX on RefundPreview {
  /// 이미 환불 마크된 거래 — 환급은 그때 끝났다.
  bool get alreadyRefunded => reason == 'ALREADY_REFUNDED';

  /// 돌려줄 돈이 있다.
  bool get hasRefund => applies && refundAmount > 0;
}
