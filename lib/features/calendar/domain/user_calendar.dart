/// 백엔드 `UserCalendarApiDto.Response` 매핑.
///
/// 사용자가 만든 다중 캘린더 (예: '개인', '회사', '가족').
/// `isDefault=true` 면 기본 캘린더 (단일).
/// `isVisible` 토글로 캘린더 화면에 표시/숨김.
class UserCalendar {
  const UserCalendar({
    required this.rowId,
    required this.calendarName,
    this.color,
    this.sortOrder,
    this.isDefault = false,
    this.isVisible = true,
  });

  final int rowId;
  final String calendarName;
  final String? color;
  final int? sortOrder;
  final bool isDefault;
  final bool isVisible;

  factory UserCalendar.fromJson(Map<String, dynamic> json) => UserCalendar(
        rowId: (json['rowId'] as num).toInt(),
        calendarName: (json['calendarName'] as String?) ?? '',
        color: json['color'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt(),
        isDefault: (json['isDefault'] as bool?) ?? false,
        isVisible: (json['isVisible'] as bool?) ?? true,
      );
}
