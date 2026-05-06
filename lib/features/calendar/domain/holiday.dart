/// 백엔드 `HolidayApiDto.Response` 매핑 — 공휴일/사용자 정의 휴일.
///
/// Jackson SnakeCaseStrategy 사용: JSON 키는 snake_case.
/// type: PUBLIC(공휴일) / SUBSTITUTE(대체공휴일) / CUSTOM(사용자정의).
class Holiday {
  const Holiday({
    required this.rowId,
    required this.holidayDate,
    required this.holidayName,
    this.holidayType = 'PUBLIC',
    this.isRecurring = false,
    this.createAt,
    this.modifyAt,
  });

  final int rowId;
  final String holidayDate; // YYYY-MM-DD
  final String holidayName;
  final String holidayType; // PUBLIC/SUBSTITUTE/CUSTOM
  final bool isRecurring;
  final String? createAt;
  final String? modifyAt;

  factory Holiday.fromJson(Map<String, dynamic> json) {
    int? n(String k) => (json[k] as num?)?.toInt();
    return Holiday(
      rowId: n('row_id') ?? n('rowId') ?? 0,
      holidayDate:
          (json['holiday_date'] as String?) ?? (json['holidayDate'] as String? ?? ''),
      holidayName:
          (json['holiday_name'] as String?) ?? (json['holidayName'] as String? ?? ''),
      holidayType:
          (json['holiday_type'] as String?) ?? (json['holidayType'] as String? ?? 'PUBLIC'),
      isRecurring: ((json['is_recurring'] ?? json['isRecurring']) is String)
          ? ((json['is_recurring'] ?? json['isRecurring']) == 'Y')
          : ((json['is_recurring'] ?? json['isRecurring']) as bool? ?? false),
      createAt: (json['create_at'] as String?) ?? json['createAt'] as String?,
      modifyAt: (json['modify_at'] as String?) ?? json['modifyAt'] as String?,
    );
  }
}
