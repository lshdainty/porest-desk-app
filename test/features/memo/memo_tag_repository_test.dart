// 메모 태그 마스터 CRUD — 서버 계약(`MemoTagApiController`)에 맞는 곳을 두드리는지.
//
// 경로·본문·응답이 `/todo-tag` 와 같은 모양이다(서버가 그렇게 맞춰 뒀다). 앱에는
// 이 레포지토리에 목록 조회밖에 없어서 **앱만 쓰는 사람은 메모 태그를 만들 수
// 없었다.** 여기서 고정하는 것은 메서드·경로·본문 세 가지다 — 이 셋이 어긋나면
// 화면은 멀쩡히 뜨고 저장만 조용히 실패한다.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/memo/data/memo_tag_repository.dart';

typedef _Call = ({String method, String path, Object? body});

(Dio, List<_Call> calls) _capturingDio(Map<String, dynamic> data) {
  final calls = <_Call>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        calls.add((
          method: options.method,
          path: options.path,
          body: options.data,
        ));
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': data,
            },
          ),
        );
      },
    ),
  );
  return (dio, calls);
}

void main() {
  const tagJson = {'rowId': 5, 'tagName': '아이디어', 'usageCount': 0};

  test('등록은 POST /memo-tag 에 이름과 색을 싣는다', () async {
    final (dio, calls) = _capturingDio(tagJson);

    final tag = await MemoTagRepository(
      dio,
    ).create(tagName: '아이디어', color: '#2c70bf');

    expect(calls.single.method, 'POST');
    expect(calls.single.path, '/memo-tag');
    expect((calls.single.body! as Map)['tagName'], '아이디어');
    expect((calls.single.body! as Map)['color'], '#2c70bf');
    expect(tag.rowId, 5);
  });

  test('색을 안 고르면 color 키가 빠진다 — 서버 기본값에 맡긴다', () async {
    final (dio, calls) = _capturingDio(tagJson);

    await MemoTagRepository(dio).create(tagName: '아이디어');

    expect((calls.single.body! as Map).containsKey('color'), isFalse);
  });

  test('수정은 PUT /memo-tag/{id} 다', () async {
    final (dio, calls) = _capturingDio(tagJson);

    await MemoTagRepository(dio).update(id: 5, tagName: '메모', color: '#2c70bf');

    expect(calls.single.method, 'PUT');
    expect(calls.single.path, '/memo-tag/5');
    expect((calls.single.body! as Map)['tagName'], '메모');
  });

  test('삭제는 DELETE /memo-tag/{id} 다', () async {
    final (dio, calls) = _capturingDio(tagJson);

    await MemoTagRepository(dio).delete(5);

    expect(calls.single.method, 'DELETE');
    expect(calls.single.path, '/memo-tag/5');
  });

  test('목록은 GET /memo-tags — 태그 관리가 붙어도 그대로다', () async {
    final (dio, calls) = _capturingDio({
      'tags': [tagJson],
    });

    final tags = await MemoTagRepository(dio).list();

    expect(calls.single.method, 'GET');
    expect(calls.single.path, '/memo-tags');
    expect(tags.single.tagName, '아이디어');
  });
}
