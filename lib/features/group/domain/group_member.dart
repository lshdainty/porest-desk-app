/// 백엔드 `UserGroupApiDto.MemberResponse` 매핑.
///
/// freezed 코드젠 회피 — 신규 모델을 추가할 때 build_runner 실행이 부담스러우면
/// plain class 로 두고 추후 동일 모듈을 freezed 로 옮기는 것을 권장.
class GroupMember {
  const GroupMember({
    required this.rowId,
    this.userRowId,
    required this.userName,
    this.userEmail,
    required this.role, // 'OWNER' | 'ADMIN' | 'MEMBER'
    this.joinedAt,
  });

  final int rowId;
  final int? userRowId;
  final String userName;
  final String? userEmail;
  final String role;
  final String? joinedAt;

  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      userName: (json['userName'] as String?) ?? '',
      userEmail: json['userEmail'] as String?,
      role: (json['role'] as String?) ?? 'MEMBER',
      joinedAt: json['joinedAt'] as String?,
    );
  }
}

/// 같은 그룹에 속한 다른 사용자 — `getSiblingMembers` 응답.
class SiblingMember {
  const SiblingMember({
    required this.userRowId,
    required this.userName,
    this.userEmail,
    this.sharedGroupRowIds = const [],
  });

  final int userRowId;
  final String userName;
  final String? userEmail;
  final List<int> sharedGroupRowIds;

  factory SiblingMember.fromJson(Map<String, dynamic> json) {
    final ids = (json['sharedGroupRowIds'] as List?) ?? const [];
    return SiblingMember(
      userRowId: (json['userRowId'] as num).toInt(),
      userName: (json['userName'] as String?) ?? '',
      userEmail: json['userEmail'] as String?,
      sharedGroupRowIds:
          ids.map((e) => (e as num).toInt()).toList(growable: false),
    );
  }
}

/// 그룹 상세 — 그룹 메타 + 멤버 리스트.
class GroupDetail {
  const GroupDetail({
    required this.rowId,
    required this.groupName,
    this.description,
    this.groupTypeId,
    this.groupTypeName,
    this.groupTypeColor,
    this.inviteCode,
    required this.members,
    this.createAt,
  });

  final int rowId;
  final String groupName;
  final String? description;
  final int? groupTypeId;
  final String? groupTypeName;
  final String? groupTypeColor;
  final String? inviteCode;
  final List<GroupMember> members;
  final String? createAt;

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    final raw = (json['members'] as List?) ?? const [];
    return GroupDetail(
      rowId: (json['rowId'] as num).toInt(),
      groupName: (json['groupName'] as String?) ?? '',
      description: json['description'] as String?,
      groupTypeId: (json['groupTypeId'] as num?)?.toInt(),
      groupTypeName: json['groupTypeName'] as String?,
      groupTypeColor: json['groupTypeColor'] as String?,
      inviteCode: json['inviteCode'] as String?,
      members: raw
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      createAt: json['createAt'] as String?,
    );
  }
}
