import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/memo/domain/memo_tag.dart';

/// 메모 태그 마스터 조회 — `TodoTagRepository` 미러.
///
/// **읽기만 있다.** 앱에는 메모 태그 관리 화면이 없어 등록·수정·삭제를 부를 곳이
/// 없다(서버에는 `POST/PUT/DELETE /memo-tag` 가 다 있다). 부를 데 없는 메서드를
/// 미리 깔아 두면 서버가 바뀌어도 아무도 안 깨져 낡은 채로 남는다 — 관리 화면을
/// 앱에 붙이는 PR 에서 그때 같이 넣는다.
class MemoTagRepository {
  MemoTagRepository(this._dio);
  final Dio _dio;

  Future<List<MemoTag>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/memo-tags');
      return _unwrapList(res, 'tags', MemoTag.fromJson);
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
