// API 에러 토스트는 여기 한 곳에서만 뜬다 — 웹 shared/api/base.ts 와 같은 구조.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

DioException _err(int status, String message) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: {'code': 'X_1', 'message': message},
      ),
    );

void main() {
  late GlobalKey<ScaffoldMessengerState> key;
  late BuildContext screenCtx; // 화면(Scaffold 아래) 컨텍스트 — 호출부 시늉용

  Future<void> pumpHost(WidgetTester tester) async {
    key = GlobalKey<ScaffoldMessengerState>();
    registerErrorToastMessenger(key);
    resetGlobalErrorToastState();
    await tester.pumpWidget(MaterialApp(
      scaffoldMessengerKey: key,
      theme: PorestTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: Builder(builder: (c) {
        screenCtx = c;
        return const SizedBox.expand();
      })),
    ));
  }

  // onError 는 handler.next 로 dio 체인을 잇는데, 체인 밖에서 부르면
  // InterceptorState 를 던진다. 예약 로직만 직접 부른다.
  void fire(DioException e) => ErrorToastInterceptor().schedule(e);

  // 스낵바가 그려질 때까지. 한 번만 펌프하면 아직 안 올라와 있다.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('서버 메시지를 그대로 띄운다', (tester) async {
    await pumpHost(tester);
    fire(_err(500, '서버가 응답하지 않았어요'));
    await settle(tester);
    expect(find.text('서버가 응답하지 않았어요'), findsOneWidget);
  });

  testWidgets('화면은 자기 에러 메시지를 띄우지 않는다 — 문구가 갈리지 않게', (tester) async {
    await pumpHost(tester);
    fire(_err(500, '권한이 없습니다'));
    await settle(tester);

    // 앱이 "삭제 실패: …" 처럼 접두를 붙이면 웹과 문구가 갈려 추적이 어렵다.
    // 서버 메시지 하나만 뜬다.
    expect(find.text('권한이 없습니다'), findsOneWidget);
    expect(find.textContaining('삭제 실패'), findsNothing);
  });

  testWidgets('401 은 그물에 안 걸린다 — 세션 만료는 로그인으로 보낸다', (tester) async {
    await pumpHost(tester);
    fire(_err(401, '인증이 만료되었습니다'));
    await settle(tester);
    expect(find.text('인증이 만료되었습니다'), findsNothing);
  });

  testWidgets('silent 를 준 요청은 건너뛴다', (tester) async {
    await pumpHost(tester);
    final e = DioException(
      requestOptions: RequestOptions(path: '/x', extra: {kSilentErrorToast: true}),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 500,
        data: {'message': '조용히'},
      ),
    );
    fire(e);
    await settle(tester);
    expect(find.text('조용히'), findsNothing);
  });

  testWidgets('같은 메시지가 연달아 오면 한 번만 뜬다', (tester) async {
    await pumpHost(tester);
    fire(_err(500, '중복 메시지'));
    await settle(tester);
    expect(find.text('중복 메시지'), findsOneWidget);

    fire(_err(500, '중복 메시지'));
    await settle(tester);
    expect(find.text('중복 메시지'), findsOneWidget, reason: 'throttle 안에선 추가로 안 뜬다');
  });
}
