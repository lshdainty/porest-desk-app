/// 백엔드 공통 응답 래퍼.
///
/// porest-desk-back / porest-sso-back 모두 다음 포맷:
/// ```json
/// { "success": true, "code": "COMMON_200", "message": "OK", "data": <T|null> }
/// ```
///
/// 제네릭 데이터 부분은 직접 [fromJsonT] 를 받아 디코딩 — Freezed 의 generic 코드젠 부담을 피한다.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.code,
    required this.message,
    required this.data,
  });

  final bool success;
  final String code;
  final String message;
  final T? data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? '',
      data: json['data'] == null ? null : fromJsonT(json['data']),
    );
  }
}

/// 페이지네이션 응답 (`PageResponse<T>`).
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.size,
    required this.hasNext,
    required this.hasPrevious,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int size;
  final bool hasNext;
  final bool hasPrevious;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return PageResponse<T>(
      content: (json['content'] as List<dynamic>).map(fromJsonT).toList(),
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }
}
