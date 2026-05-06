import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import '../network/api_response.dart';
import 'user.dart';

/// 인증 관련 Desk 백엔드 호출을 모은 얇은 어댑터.
///
/// 모든 메서드는 성공 시 데이터 반환, 실패 시 [ApiException] throw.
/// 쿠키는 [Dio] 의 cookie_jar 가 자동으로 처리하므로 토큰을 직접 다루지 않는다.
class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  /// SSO 토큰을 desk 토큰으로 교환.
  /// 성공 시 응답 쿠키(`desk_access_token`)가 cookie_jar 에 저장된다.
  ///
  /// 백엔드 응답(`TokenExchangeDto.Response`)은 `(accessToken, userId, userName, userEmail)` 만
  /// 포함 — `rowId` 가 없어 [User] 디코딩 불가. 따라서 본 메서드는 쿠키 저장만 하고,
  /// 사용자 정보는 별도 [check] 호출로 가져온다.
  Future<void> exchangeToken(String ssoToken) async {
    try {
      await _dio.post<dynamic>(
        '/auth/exchange',
        data: {'ssoToken': ssoToken},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 현재 세션 유효성 확인. 성공 시 사용자 정보, 실패 시 401 throw.
  Future<User> check() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/check');
      final body = ApiResponse<User>.fromJson(
        res.data ?? const {},
        (raw) => User.fromJson(raw! as Map<String, dynamic>),
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 로그아웃. 백엔드가 쿠키 만료 처리, 클라이언트는 cookie_jar 도 비운다(상위에서).
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
