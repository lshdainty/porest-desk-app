// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceSession _$DeviceSessionFromJson(Map<String, dynamic> json) =>
    _DeviceSession(
      sessionId: json['sessionId'] as String,
      deviceLabel: json['deviceLabel'] as String?,
      deviceKind:
          $enumDecodeNullable(
            _$DeviceKindEnumMap,
            json['deviceKind'],
            unknownValue: DeviceKind.unknown,
          ) ??
          DeviceKind.unknown,
      lastUsedAt: json['lastUsedAt'] as String?,
      createAt: json['createAt'] as String?,
      current: json['current'] as bool? ?? false,
    );

Map<String, dynamic> _$DeviceSessionToJson(_DeviceSession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'deviceLabel': instance.deviceLabel,
      'deviceKind': _$DeviceKindEnumMap[instance.deviceKind]!,
      'lastUsedAt': instance.lastUsedAt,
      'createAt': instance.createAt,
      'current': instance.current,
    };

const _$DeviceKindEnumMap = {
  DeviceKind.mobile: 'MOBILE',
  DeviceKind.tablet: 'TABLET',
  DeviceKind.desktop: 'DESKTOP',
  DeviceKind.unknown: 'UNKNOWN',
};
