import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_billing.freezed.dart';
part 'card_billing.g.dart';

/// 신용카드 청구 1건 — 백엔드 `BillingItem` 1:1 매핑.
///
/// GET /v1/asset/{id}/billing 의 history[] 요소 및
/// POST /v1/asset/{id}/pay 응답 단건.
@freezed
abstract class BillingItem with _$BillingItem {
  const factory BillingItem({
    required int rowId,
    required int cardAssetRowId,
    int? paymentAssetRowId,
    required int billingAmount,
    required String periodStart, // 'yyyy-MM-dd'
    required String periodEnd, // 'yyyy-MM-dd'
    required String paymentDate, // 'yyyy-MM-dd'
    required String status, // 'PENDING' | 'COMPLETED' | 'FAILED' | 'SKIPPED'
    int? transferRowId,
    String? failureReason,
  }) = _BillingItem;

  factory BillingItem.fromJson(Map<String, dynamic> json) =>
      _$BillingItemFromJson(json);
}

/// 신용카드 청구 사이클 요약 — 백엔드 GET /v1/asset/{id}/billing 응답 매핑.
@freezed
abstract class CardBilling with _$CardBilling {
  const factory CardBilling({
    required int cardAssetRowId,
    // 다가오는 결제 회차의 결제예정액 = 청구 기간(결제일의 전월 1일~말일)
    // 순사용액 − 같은 회차 기결제액(선결제 차감). 결제일 미설정 시 잔액 전액.
    required int upcomingAmount,
    String? upcomingPeriodStart, // 회차 청구 기간 'yyyy-MM-dd' | null
    String? upcomingPeriodEnd,
    String? nextPaymentDate, // 'yyyy-MM-dd' | null
    int? paymentDay, // 1~31 | null
    int? paymentAssetRowId,
    @Default(<BillingItem>[]) List<BillingItem> history,
  }) = _CardBilling;

  factory CardBilling.fromJson(Map<String, dynamic> json) =>
      _$CardBillingFromJson(json);
}
