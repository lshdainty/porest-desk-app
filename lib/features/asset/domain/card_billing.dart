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

/// 다가오는 회차에 빠지는 할부 한 건 — 명세서의 "원금·N개월 중 k회차" 표시용.
@freezed
abstract class InstallmentDue with _$InstallmentDue {
  const factory InstallmentDue({
    required int expenseRowId,
    String? merchant,
    String? description,

    /// 할부 원금(거래 전액).
    required int principalAmount,

    /// 총 회차 수(N).
    required int installmentMonths,

    /// 이번이 몇 회차인지(1-base).
    required int sequence,

    /// 이번 회차에 빠지는 금액. 나머지는 1회차에 몰린다(카드사 관행).
    required int amount,

    /// 중도 전액 상환으로 남은 원금을 몰아 받은 회차인지 —
    /// "남은 원금 정리" 배지를 달고 정리 버튼 대신 되돌리기를 보여준다.
    @Default(false) bool paidOff,
  }) = _InstallmentDue;

  factory InstallmentDue.fromJson(Map<String, dynamic> json) =>
      _$InstallmentDueFromJson(json);
}

/// 신용카드 청구 사이클 요약 — 백엔드 GET /v1/asset/{id}/billing 응답 매핑.
@freezed
abstract class CardBilling with _$CardBilling {
  const factory CardBilling({
    required int cardAssetRowId,
    // 다가오는 결제 회차의 결제예정액 = 청구 기간(결제일의 전월 1일~말일)
    // 순사용액 − 같은 회차 기결제액(선결제 차감). 결제일 미설정 시 잔액 전액.
    required int upcomingAmount,

    /// 회차 내 일시불 순사용액(환불 상계, 음수 가능). 옛 서버 호환으로 옵셔널.
    int? upcomingLumpSumAmount,

    /// 같은 회차에 이미 낸 금액(선결제 차감분).
    int? upcomingAlreadyPaidAmount,

    /// 이 회차에 빠지는 할부 구성. 예정액이 이용 내역 합과 다를 때 그 차이를 설명한다.
    @Default(<InstallmentDue>[]) List<InstallmentDue> upcomingInstallments,
    String? upcomingPeriodStart, // 회차 청구 기간 'yyyy-MM-dd' | null
    String? upcomingPeriodEnd,
    String? nextPaymentDate, // 'yyyy-MM-dd' | null
    int? paymentDay, // 1~31 | null
    int? paymentAssetRowId,
    @Default(<BillingItem>[]) List<BillingItem> history,

    /// 다가오는 회차의 다음 회차 — 지금 쌓이고 있는 이용분(당월 1일~말일, 다음 달 결제일).
    /// 결제일 미설정이거나 옛 서버면 null.
    UpcomingCycle? nextCycle,
  }) = _CardBilling;

  factory CardBilling.fromJson(Map<String, dynamic> json) =>
      _$CardBillingFromJson(json);
}

/// 회차 하나 — 청구 응답의 nextCycle. 결제일·청구 기간·예정액(선결제 차감 후)·할부 구성.
@freezed
abstract class UpcomingCycle with _$UpcomingCycle {
  const factory UpcomingCycle({
    required String paymentDate, // 'yyyy-MM-dd'
    required String periodStart,
    required String periodEnd,
    required int amount,
    int? lumpSumAmount,
    int? alreadyPaidAmount,
    @Default(<InstallmentDue>[]) List<InstallmentDue> installments,
  }) = _UpcomingCycle;

  factory UpcomingCycle.fromJson(Map<String, dynamic> json) =>
      _$UpcomingCycleFromJson(json);
}
