// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RefundPreview _$RefundPreviewFromJson(Map<String, dynamic> json) =>
    _RefundPreview(
      applies: json['applies'] as bool? ?? false,
      refundAmount: (json['refundAmount'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
    );

Map<String, dynamic> _$RefundPreviewToJson(_RefundPreview instance) =>
    <String, dynamic>{
      'applies': instance.applies,
      'refundAmount': instance.refundAmount,
      'reason': instance.reason,
    };
