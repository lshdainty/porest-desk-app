// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dutch_pay.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DutchPay _$DutchPayFromJson(Map<String, dynamic> json) => _DutchPay(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  sourceExpenseRowId: (json['sourceExpenseRowId'] as num?)?.toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  totalAmount: (json['totalAmount'] as num).toInt(),
  currency: json['currency'] as String?,
  splitMethod: json['splitMethod'] as String?,
  dutchPayDate: json['dutchPayDate'] as String?,
  isSettled: json['isSettled'] as bool? ?? false,
  participants:
      (json['participants'] as List<dynamic>?)
          ?.map((e) => DutchPayParticipant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DutchPayParticipant>[],
  createAt: json['createAt'] as String?,
);

Map<String, dynamic> _$DutchPayToJson(_DutchPay instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'sourceExpenseRowId': instance.sourceExpenseRowId,
  'title': instance.title,
  'description': instance.description,
  'totalAmount': instance.totalAmount,
  'currency': instance.currency,
  'splitMethod': instance.splitMethod,
  'dutchPayDate': instance.dutchPayDate,
  'isSettled': instance.isSettled,
  'participants': instance.participants,
  'createAt': instance.createAt,
};

_DutchPayParticipant _$DutchPayParticipantFromJson(Map<String, dynamic> json) =>
    _DutchPayParticipant(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      participantName: json['participantName'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] as String?,
    );

Map<String, dynamic> _$DutchPayParticipantToJson(
  _DutchPayParticipant instance,
) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'participantName': instance.participantName,
  'amount': instance.amount,
  'isPaid': instance.isPaid,
  'paidAt': instance.paidAt,
};
