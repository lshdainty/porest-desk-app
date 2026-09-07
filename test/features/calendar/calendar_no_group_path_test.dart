// 서버에 없는 `/group/{id}/calendar/events` 를 부르던 걸 걷어냈다 (QA #92).
//
// 그룹 도메인은 2026-06-03 에 앱에서 통째로 지웠고(`45eca81`), 공유는 그때
// `user_calendar` + 멤버로 옮겨 갔다. 서버에도 group 라우트는 남아 있지 않다 —
// 캘린더 쪽 매핑은 `/calendar/**` 뿐이다. 그런데 지우는 손이 캘린더 리포지토리를
// 놓쳐 `groupEvents` 만 남았고, 나중에 keep-alive 갱신 목록에 그 provider 가
// 얹히기까지 했다. 아무도 watch 하지 않아 404 가 눈에 띄지 않았을 뿐이다.
//
// 대체가 필요 없다는 게 요점이다 — `GET /calendar/events` 가 이미 **소유 + 공유받은**
// 캘린더의 일정을 함께 내려준다(서버 `getAccessibleCalendarIds`).
//
// 여기서 고정하는 것은 둘이다.
//   ① 일정 목록 조회는 서버에 실재하는 `/calendar/events` 로 나간다
//   ② 리포지토리 어디에도 `/group/` 요청 경로가 없다 — 되살아나면 그 화면은 404 를 본다
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/calendar/data/calendar_repository.dart';

/// 요청 경로를 잡아 두고 빈 목록을 돌려주는 Dio.
(Dio, List<String> paths) _capturingDio() {
  final paths = <String>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        paths.add(options.path);
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: const {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': {'events': <dynamic>[]},
            },
          ),
        );
      },
    ),
  );
  return (dio, paths);
}

void main() {
  test('일정 목록은 /calendar/events 로 조회한다 — 공유 캘린더도 여기 함께 온다', () async {
    final (dio, paths) = _capturingDio();

    await CalendarRepository(
      dio,
    ).events(startDate: '2026-09-01T00:00:00', endDate: '2026-09-30T23:59:59');

    expect(paths.single, '/calendar/events');
  });

  test('앱 어디에도 /group/ 요청 경로가 없다 — 서버에 그 라우트가 없다', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('/group/')) {
          offenders.add('${entity.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '서버에 group 라우트가 없다. 공유 일정은 /calendar/events 가 이미 함께 내려준다:\n'
          '${offenders.join('\n')}',
    );
  });
}
