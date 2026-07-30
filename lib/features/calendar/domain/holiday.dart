/// 백엔드 `HolidayApiDto.Response` 매핑 — 공휴일.
///
/// JSON 키는 camelCase (desk 전역 컨벤션).
/// type: PUBLIC(공휴일) / SUBSTITUTE(대체공휴일) / CUSTOM(사내 휴무).
class Holiday {
  const Holiday({
    required this.rowId,
    required this.holidayDate,
    required this.holidayName,
    this.holidayType = 'PUBLIC',
    this.createAt,
    this.modifyAt,
  });

  final int rowId;
  final String holidayDate; // YYYY-MM-DD
  final String holidayName;
  final String holidayType; // PUBLIC/SUBSTITUTE/CUSTOM
  final String? createAt;
  final String? modifyAt;

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      rowId: (json['rowId'] as num?)?.toInt() ?? 0,
      holidayDate: json['holidayDate'] as String? ?? '',
      holidayName: json['holidayName'] as String? ?? '',
      holidayType: json['holidayType'] as String? ?? 'PUBLIC',
      createAt: json['createAt'] as String?,
      modifyAt: json['modifyAt'] as String?,
    );
  }
}
