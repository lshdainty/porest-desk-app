/// 백엔드 `UserCalendarApiDto.Response` 매핑.
///
/// 사용자가 만든 다중 캘린더 (예: '개인', '회사', '가족').
/// `isDefault=true` 면 기본 캘린더 (단일).
/// `isVisible` 토글로 캘린더 화면에 표시/숨김.
/// 공유: 소유자(ownerRowId) + 초대코드(inviteCode) + 내 권한(myRole) + 멤버수.
class UserCalendar {
  const UserCalendar({
    required this.rowId,
    this.ownerRowId,
    this.ownerName,
    required this.calendarName,
    this.color,
    this.sortOrder,
    this.isDefault = false,
    this.isVisible = true,
    this.inviteCode,
    this.isShared = false,
    this.isOwner = true,
    this.myRole = 'OWNER',
    this.memberCount = 1,
  });

  final int rowId;
  final int? ownerRowId;
  final String? ownerName;
  final String calendarName;
  final String? color;
  final int? sortOrder;
  final bool isDefault;
  final bool isVisible;
  final String? inviteCode;
  final bool isShared;
  final bool isOwner;
  final String myRole; // 'OWNER' | 'EDIT' | 'READ'
  final int memberCount;

  factory UserCalendar.fromJson(Map<String, dynamic> json) => UserCalendar(
        rowId: (json['rowId'] as num).toInt(),
        ownerRowId: (json['ownerRowId'] as num?)?.toInt(),
        ownerName: json['ownerName'] as String?,
        calendarName: (json['calendarName'] as String?) ?? '',
        color: json['color'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt(),
        isDefault: (json['isDefault'] as bool?) ?? false,
        isVisible: (json['isVisible'] as bool?) ?? true,
        inviteCode: json['inviteCode'] as String?,
        isShared: (json['isShared'] as bool?) ?? false,
        isOwner: (json['isOwner'] as bool?) ?? true,
        myRole: (json['myRole'] as String?) ?? 'OWNER',
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 1,
      );
}

/// 캘린더 공유 멤버 — 백엔드 `UserCalendarApiDto.MemberResponse` 매핑.
class CalendarMember {
  const CalendarMember({
    required this.rowId,
    this.userRowId,
    required this.userName,
    this.userEmail,
    required this.permission,
    this.joinedAt,
  });

  final int rowId;
  final int? userRowId;
  final String userName;
  final String? userEmail;
  final String permission; // 'OWNER' | 'EDIT' | 'READ'
  final String? joinedAt;

  factory CalendarMember.fromJson(Map<String, dynamic> json) => CalendarMember(
        rowId: (json['rowId'] as num).toInt(),
        userRowId: (json['userRowId'] as num?)?.toInt(),
        userName: (json['userName'] as String?) ?? '',
        userEmail: json['userEmail'] as String?,
        permission: (json['permission'] as String?) ?? 'READ',
        joinedAt: json['joinedAt'] as String?,
      );
}
