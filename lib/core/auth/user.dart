import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:porest_desk_app/core/format/date.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required int rowId,
    required String userId,
    required String userName,
    required String userEmail,
    String? timezone,
    // 가입일시 — 백엔드 /auth/check 의 joinedAt(User.createAt). 미조회 시 null.
    //
    // 생성기 기본값인 DateTime.parse 는 시간대 표시가 없는 값을 로컬로 읽어 UTC 를
    // 9시간(KST) 당겨 버린다 — 월초·월말 가입이면 "가입 2026년 8월" 이 7월로 보인다.
    // user.g.dart 는 build_runner 가 덮어쓰므로 보정은 여기 fromJson 으로만 걸 수 있다.
    //
    // toJson 도 같이 지정해 왕복을 닫는다. parseServerUtc 는 isUtc=false 인 로컬
    // DateTime 을 주는데 생성기 기본값 toIso8601String() 은 로컬이면 오프셋을 안 붙인다
    // — 그 문자열을 다시 fromJson 으로 읽으면 UTC 로 오해해 왕복마다 +9 씩 밀린다.
    // 지금은 User.toJson() 호출부가 없지만, 캐시·로그로 한 번 쓰는 순간 조용히 틀린다.
    @JsonKey(fromJson: parseServerUtc, toJson: toServerUtc) DateTime? joinedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
