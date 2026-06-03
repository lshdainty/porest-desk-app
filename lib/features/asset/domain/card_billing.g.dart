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

_CardBilling _$CardBillingFromJson(Map<String, dynamic> json) => _CardBilling(
  cardAssetRowId: (json['cardAssetRowId'] as num).toInt(),
  upcomingAmount: (json['upcomingAmount'] as num).toInt(),
  nextPaymentDate: json['nextPaymentDate'] as String?,
  paymentDay: (json['paymentDay'] as num?)?.toInt(),
  paymentAssetRowId: (json['paymentAssetRowId'] as num?)?.toInt(),
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => BillingItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BillingItem>[],
);

Map<String, dynamic> _$CardBillingToJson(_CardBilling instance) =>
    <String, dynamic>{
      'cardAssetRowId': instance.cardAssetRowId,
      'upcomingAmount': instance.upcomingAmount,
      'nextPaymentDate': instance.nextPaymentDate,
      'paymentDay': instance.paymentDay,
      'paymentAssetRowId': instance.paymentAssetRowId,
      'history': instance.history,
    };
