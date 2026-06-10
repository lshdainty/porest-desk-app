import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/expense_split/domain/expense_split.dart';

/// `/expense/{id}/splits` GET/PUT/DELETE.
class ExpenseSplitRepository {
  ExpenseSplitRepository(this._dio);
  final Dio _dio;

  Future<List<ExpenseSplit>> list(int expenseId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expense/$expenseId/splits',
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['splits'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ExpenseSplit>> replace(
    int expenseId, {
    required List<SplitInput> splits,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense/$expenseId/splits',
        data: {
          'splits': [
            for (final s in splits)
              {
                'categoryRowId': s.categoryRowId,
                'amount': s.amount,
                'label': ?s.label,
                'sortOrder': ?s.sortOrder,
              },
          ],
        },
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['splits'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteAll(int expenseId) async {
    try {
      await _dio.delete<void>('/expense/$expenseId/splits');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class SplitInput {
  const SplitInput({
    required this.categoryRowId,
    required this.amount,
    this.label,
    this.sortOrder,
  });
  final int categoryRowId;
  final int amount;
  final String? label;
  final int? sortOrder;
}
