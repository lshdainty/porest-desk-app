import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/core/network/interceptors/error_toast_interceptor.dart';

/// 종별 건수 (체크박스 배지).
class ExportTypeCount {
  const ExportTypeCount({required this.type, required this.displayName, required this.count});
  final String type;
  final String displayName;
  final int count;

  factory ExportTypeCount.fromJson(Map<String, dynamic> json) => ExportTypeCount(
        type: json['type'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// 종별 미리보기 표 (상위 N행).
class ExportPreviewTable {
  const ExportPreviewTable({
    required this.type,
    required this.displayName,
    required this.headers,
    required this.rows,
    required this.totalCount,
  });
  final String type;
  final String displayName;
  final List<String> headers;
  final List<List<String>> rows;
  final int totalCount;

  factory ExportPreviewTable.fromJson(Map<String, dynamic> json) => ExportPreviewTable(
        type: json['type'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        headers: ((json['headers'] as List?) ?? []).map((e) => e.toString()).toList(),
        rows: ((json['rows'] as List?) ?? [])
            .map((r) => ((r as List?) ?? []).map((e) => e.toString()).toList())
            .toList(),
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      );
}

/// 데이터 내보내기 API. 다운로드는 dio stream → 임시파일로 점진 기록(대용량 대응).
class ExportRepository {
  ExportRepository(this._dio);
  final Dio _dio;

  Future<List<ExportTypeCount>> counts(Map<String, dynamic> body) async {
    try {
      // 화면 진입 시 건수 미리보기 — best-effort 라 실패해도 조용히 넘긴다.
      final res = await _dio.post<Map<String, dynamic>>('/export/counts',
          data: body, options: Options(extra: {kSilentErrorToast: true}));
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      final list = (api.data?['counts'] as List?) ?? [];
      return list.map((e) => ExportTypeCount.fromJson((e as Map).cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ExportPreviewTable>> preview(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/export/preview', data: body);
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      final list = (api.data?['tables'] as List?) ?? [];
      return list.map((e) => ExportPreviewTable.fromJson((e as Map).cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 파일 생성 → 임시파일에 스트림 기록. 생성된 File 반환(호출처가 Share).
  Future<File> download({
    required Map<String, dynamic> body,
    required String filename,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      final res = await _dio.post<ResponseBody>(
        '/export',
        data: body,
        options: Options(responseType: ResponseType.stream),
        onReceiveProgress: onReceiveProgress,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      final sink = file.openWrite();
      try {
        await for (final chunk in res.data!.stream) {
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      return file;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final exportRepositoryProvider = FutureProvider<ExportRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ExportRepository(dio);
});
