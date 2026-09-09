/// 백엔드 `UserCalendarApiDto.Response` 매핑.
///
/// 사용자가 만든 다중 캘린더 (예: '개인', '회사', '가족').
/// `isDefault=true` 면 기본 캘린더 (단일).
/// `isVisible` 토글로 캘린더 화면에 표시/숨김 — **기본 캘린더는 예외**([isVisible] 참고).
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
    bool isVisible = true,
    this.inviteCode,
    this.isShared = false,
    this.isOwner = true,
    this.myRole = 'OWNER',
    this.memberCount = 1,
  }) : _isVisible = isVisible;

  final int rowId;
  final int? ownerRowId;
  final String? ownerName;
  final String calendarName;
  final String? color;
  final int? sortOrder;
  final bool isDefault;
  final bool _isVisible;
  final String? inviteCode;
  final bool isShared;
  final bool isOwner;
  final String myRole; // 'OWNER' | 'EDIT' | 'READ'
  final int memberCount;

  /// 캘린더 화면에 표시할지. **기본 캘린더는 언제나 참이다.**
  ///
  /// 기본 캘린더는 숨길 수 없다 — 서버가 표시 토글을 400 으로 막고, 필터 시트도
  /// 그 행에는 체크박스를 안 그린다. 그런데 막기 전에 이미 꺼 둔 사람이 있다.
  /// 저장된 값을 그대로 읽으면 그 사람의 기본 캘린더는 **영영 안 보인다** —
  /// 일정이 달력에서 사라지는데 되돌릴 스위치가 화면에 없고, 서버가 자동 대입하는
  /// 캘린더라 새로 저장한 일정도 곧바로 사라진다.
  ///
  /// 그래서 **읽는 자리 한 곳**에서 고정한다. 표시 여부를 보는 곳이
  /// (필터 시트 · 헤더 칩 · 월 그리드 · 일정 만들기 선택 목록) 넷이라,
  /// 화면마다 `isDefault ||` 를 붙이면 언젠가 한 곳이 빠진다.
  bool get isVisible => isDefault || _isVisible;

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
