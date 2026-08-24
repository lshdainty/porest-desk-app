import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_session.freezed.dart';
part 'device_session.g.dart';

/// 기기 형태 — 아이콘을 고르는 데만 쓴다.
///
/// 서버(`UserAgentParser.DeviceKind`)가 정해 내려준다. 기기 이름을 화면에서 다시
/// 뜯지 않는 이유는 그 표가 앱·웹 두 곳에 복제되면 서버 파서를 고칠 때 둘 다
/// 따라오지 않기 때문이다.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DeviceKind {
  mobile,
  tablet,
  desktop,

  /// 서버가 기기를 못 알아봤거나, 우리가 모르는 값이 왔다.
  @JsonValue('UNKNOWN')
  unknown,
}

/// "로그인된 기기" 한 줄.
@freezed
abstract class DeviceSession with _$DeviceSession {
  const factory DeviceSession({
    /// 로그아웃 요청에 그대로 쓴다.
    required String sessionId,

    /// `iPhone · Safari`. 서버가 UA 를 못 알아봤으면 null — 화면이 "알 수 없는 기기" 로 그린다.
    String? deviceLabel,

    @JsonKey(unknownEnumValue: DeviceKind.unknown)
    @Default(DeviceKind.unknown)
    DeviceKind deviceKind,

    /// [UTC] 마지막으로 토큰을 새로 받은 시각. 한 번도 없었으면 null.
    String? lastUsedAt,

    /// [UTC] 로그인 시각.
    String? createAt,

    /// 지금 이 앱이 쓰고 있는 세션인지.
    @Default(false) bool current,
  }) = _DeviceSession;

  factory DeviceSession.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionFromJson(json);
}

extension DeviceSessionX on DeviceSession {
  /// 목록에 쓸 시각 — 마지막 사용이 없으면 로그인 시각으로 대신한다.
  String? get activeAt => lastUsedAt ?? createAt;
}
