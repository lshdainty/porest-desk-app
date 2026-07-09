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
        // 정상 에러는 서버가 로케일(ko/en) 메시지를 body.message 로 내려주므로 그대로 사용.
        // 아래 fallback 은 서버가 message 를 안 준 예외적 경우만 → 기본값 영어 하드코딩.
        return ApiException(
          code: body['code']?.toString() ?? 'HTTP_${res.statusCode}',
          message: body['message']?.toString() ?? 'Server error',
          statusCode: res.statusCode,
          cause: e,
        );
      }
      // non-JSON 응답(게이트웨이 502 등) — 서버 메시지 없음, 영어 기본값.
      return ApiException(
        code: 'HTTP_${res.statusCode}',
        message: 'Server error (${res.statusCode})',
        statusCode: res.statusCode,
        cause: e,
      );
    }
    // 네트워크 무응답 — 서버 응답 자체가 없어 서버 메시지 불가, 영어 기본값.
    return ApiException(
      code: 'NETWORK',
      message: 'Network connection failed. Please try again.',
      cause: e,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
