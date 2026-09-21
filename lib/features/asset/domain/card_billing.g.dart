// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_billing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillingItem _$BillingItemFromJson(Map<String, dynamic> json) => _BillingItem(
  rowId: (json['rowId'] as num).toInt(),
  cardAssetRowId: (json['cardAssetRowId'] as num).toInt(),
  paymentAssetRowId: (json['paymentAssetRowId'] as num?)?.toInt(),
  billingAmount: (json['billingAmount'] as num).toInt(),
  periodStart: json['periodStart'] as String,
  periodEnd: json['periodEnd'] as String,
  paymentDate: json['paymentDate'] as String,
  status: json['status'] as String,
  transferRowId: (json['transferRowId'] as num?)?.toInt(),
  failureReason: json['failureReason'] as String?,
);

Map<String, dynamic> _$BillingItemToJson(_BillingItem instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'cardAssetRowId': instance.cardAssetRowId,
      'paymentAssetRowId': instance.paymentAssetRowId,
      'billingAmount': instance.billingAmount,
      'periodStart': instance.periodStart,
      'periodEnd': instance.periodEnd,
      'paymentDate': instance.paymentDate,
      'status': instance.status,
      'transferRowId': instance.transferRowId,
      'failureReason': instance.failureReason,
    };

_InstallmentDue _$InstallmentDueFromJson(Map<String, dynamic> json) =>
    _InstallmentDue(
      expenseRowId: (json['expenseRowId'] as num).toInt(),
      merchant: json['merchant'] as String?,
      description: json['description'] as String?,
      principalAmount: (json['principalAmount'] as num).toInt(),
      installmentMonths: (json['installmentMonths'] as num).toInt(),
      sequence: (json['sequence'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
      paidOff: json['paidOff'] as bool? ?? false,
    );

Map<String, dynamic> _$InstallmentDueToJson(_InstallmentDue instance) =>
    <String, dynamic>{
      'expenseRowId': instance.expenseRowId,
      'merchant': instance.merchant,
      'description': instance.description,
      'principalAmount': instance.principalAmount,
      'installmentMonths': instance.installmentMonths,
      'sequence': instance.sequence,
      'amount': instance.amount,
      'paidOff': instance.paidOff,
    };

_CardBilling _$CardBillingFromJson(Map<String, dynamic> json) => _CardBilling(
  cardAssetRowId: (json['cardAssetRowId'] as num).toInt(),
  upcomingAmount: (json['upcomingAmount'] as num).toInt(),
  upcomingLumpSumAmount: (json['upcomingLumpSumAmount'] as num?)?.toInt(),
  upcomingAlreadyPaidAmount: (json['upcomingAlreadyPaidAmount'] as num?)
      ?.toInt(),
  upcomingInstallments:
      (json['upcomingInstallments'] as List<dynamic>?)
          ?.map((e) => InstallmentDue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <InstallmentDue>[],
  upcomingPeriodStart: json['upcomingPeriodStart'] as String?,
  upcomingPeriodEnd: json['upcomingPeriodEnd'] as String?,
  nextPaymentDate: json['nextPaymentDate'] as String?,
  paymentDay: (json['paymentDay'] as num?)?.toInt(),
  paymentAssetRowId: (json['paymentAssetRowId'] as num?)?.toInt(),
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => BillingItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BillingItem>[],
  nextCycle: json['nextCycle'] == null
      ? null
      : UpcomingCycle.fromJson(json['nextCycle'] as Map<String, dynamic>),
  closedCycles: (json['closedCycles'] as List<dynamic>?)
      ?.map((e) => ClosedCycle.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CardBillingToJson(_CardBilling instance) =>
    <String, dynamic>{
      'cardAssetRowId': instance.cardAssetRowId,
      'upcomingAmount': instance.upcomingAmount,
      'upcomingLumpSumAmount': instance.upcomingLumpSumAmount,
      'upcomingAlreadyPaidAmount': instance.upcomingAlreadyPaidAmount,
      'upcomingInstallments': instance.upcomingInstallments,
      'upcomingPeriodStart': instance.upcomingPeriodStart,
      'upcomingPeriodEnd': instance.upcomingPeriodEnd,
      'nextPaymentDate': instance.nextPaymentDate,
      'paymentDay': instance.paymentDay,
      'paymentAssetRowId': instance.paymentAssetRowId,
      'history': instance.history,
      'nextCycle': instance.nextCycle,
      'closedCycles': instance.closedCycles,
    };

_ClosedCycle _$ClosedCycleFromJson(Map<String, dynamic> json) => _ClosedCycle(
  periodStart: json['periodStart'] as String,
  periodEnd: json['periodEnd'] as String,
  paymentDate: json['paymentDate'] as String,
  paidAmount: (json['paidAmount'] as num?)?.toInt() ?? 0,
  recordedOnlyAmount: (json['recordedOnlyAmount'] as num?)?.toInt() ?? 0,
  preRegistration: json['preRegistration'] as bool? ?? false,
  refundableUntil: json['refundableUntil'] as String?,
);

Map<String, dynamic> _$ClosedCycleToJson(_ClosedCycle instance) =>
    <String, dynamic>{
      'periodStart': instance.periodStart,
      'periodEnd': instance.periodEnd,
      'paymentDate': instance.paymentDate,
      'paidAmount': instance.paidAmount,
      'recordedOnlyAmount': instance.recordedOnlyAmount,
      'preRegistration': instance.preRegistration,
      'refundableUntil': instance.refundableUntil,
    };

_UpcomingCycle _$UpcomingCycleFromJson(Map<String, dynamic> json) =>
    _UpcomingCycle(
      paymentDate: json['paymentDate'] as String,
      periodStart: json['periodStart'] as String,
      periodEnd: json['periodEnd'] as String,
      amount: (json['amount'] as num).toInt(),
      lumpSumAmount: (json['lumpSumAmount'] as num?)?.toInt(),
      alreadyPaidAmount: (json['alreadyPaidAmount'] as num?)?.toInt(),
      installments:
          (json['installments'] as List<dynamic>?)
              ?.map((e) => InstallmentDue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <InstallmentDue>[],
    );

Map<String, dynamic> _$UpcomingCycleToJson(_UpcomingCycle instance) =>
    <String, dynamic>{
      'paymentDate': instance.paymentDate,
      'periodStart': instance.periodStart,
      'periodEnd': instance.periodEnd,
      'amount': instance.amount,
      'lumpSumAmount': instance.lumpSumAmount,
      'alreadyPaidAmount': instance.alreadyPaidAmount,
      'installments': instance.installments,
    };
