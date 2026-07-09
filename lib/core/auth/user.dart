import 'package:freezed_annotation/freezed_annotation.dart';

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
    DateTime? joinedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
