import 'package:dio/dio.dart';

/// 백엔드/네트워크 에러를 사용자 메시지로 변환할 수 있는 단일 형태.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.cause,
  });

  /// 백엔드 도메인 에러 코드 (예: `AUTH_001`, `EXPENSE_404`) 또는 클라이언트 자체 코드.
  final String code;

  /// 사용자에게 표시 가능한 메시지 (백엔드 message 또는 fallback).
  final String message;

  final int? statusCode;
  final Object? cause;

  bool get isUnauthorized => statusCode == 401 || code == 'AUTH_001';
  bool get isForbidden => statusCode == 403 || code == 'AUTH_003';

  /// DioException 을 ApiException 으로 정규화.
  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res != null) {
      final body = res.data;
      if (body is Map<String, dynamic>) {
        return ApiException(
          code: body['code']?.toString() ?? 'HTTP_${res.statusCode}',
          message: body['message']?.toString() ?? '서버 오류',
          statusCode: res.statusCode,
          cause: e,
        );
      }
      return ApiException(
        code: 'HTTP_${res.statusCode}',
        message: '서버 오류 (${res.statusCode})',
        statusCode: res.statusCode,
        cause: e,
      );
    }
    return ApiException(
      code: 'NETWORK',
      message: '네트워크 연결을 확인해주세요',
      cause: e,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
