import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/notification.dart';

class NotificationRepository {
  NotificationRepository(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> list({bool? unread, int? limit}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {
          'unread': ?unread,
          'limit': ?limit,
        },
      );
      return _unwrapList(res, 'notifications', AppNotification.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data!['count'] as int?) ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.patch<dynamic>('/notification/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch<dynamic>('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/notification/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<T> _unwrapList<T>(
    Response<Map<String, dynamic>> res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data ?? const {},
      (raw) => raw! as Map<String, dynamic>,
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    final list = (body.data![listKey] as List<dynamic>?) ?? const [];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
