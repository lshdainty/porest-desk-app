import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/recurring_transaction.dart';

class RecurringRepository {
  RecurringRepository(this._dio);
  final Dio _dio;

  Future<List<RecurringTransaction>> list({bool? upcoming, int? limit}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/recurring-transactions',
        queryParameters: {'upcoming': ?upcoming, 'limit': ?limit},
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list =
          (body.data!['recurringTransactions'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> create({
    required int categoryRowId,
    required int assetRowId,
    int? sourceExpenseRowId,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek, // ISO 1=월 ~ 7=일
    int? dayOfMonth,
    required String startDate, // 'YYYY-MM-DD'
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/recurring-transaction',
        data: {
          'categoryRowId': categoryRowId,
          'assetRowId': assetRowId,
          'sourceExpenseRowId': ?sourceExpenseRowId,
          'expenseType': expenseType,
          'amount': amount,
          'frequency': frequency,
          'intervalValue': ?intervalValue,
          'dayOfWeek': ?dayOfWeek,
          'dayOfMonth': ?dayOfMonth,
          'startDate': startDate,
          'endDate': ?endDate,
          'maxOccurrences': ?maxOccurrences,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'autoLog': autoLog,
          'notifyDayBefore': notifyDayBefore,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> update({
    required int id,
    required int categoryRowId,
    required int assetRowId,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    required String startDate,
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/recurring-transaction/$id',
        data: {
          'categoryRowId': categoryRowId,
          'assetRowId': assetRowId,
          'expenseType': expenseType,
          'amount': amount,
          'frequency': frequency,
          'intervalValue': ?intervalValue,
          'dayOfWeek': ?dayOfWeek,
          'dayOfMonth': ?dayOfMonth,
          'startDate': startDate,
          'endDate': ?endDate,
          'maxOccurrences': ?maxOccurrences,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'autoLog': autoLog,
          'notifyDayBefore': notifyDayBefore,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/recurring-transaction/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// isActive 토글 (PATCH).
  Future<void> toggle(int id) async {
    try {
      await _dio.patch<dynamic>('/recurring-transaction/$id/toggle');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
