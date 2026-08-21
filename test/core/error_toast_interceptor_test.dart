// 전역 에러 그물 — 아무도 처리 안 한 에러만 뜨고, 화면이 처리하면 안 뜬다.
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

  // 타이머 발화 + 스낵바 프레임. 한 번만 펌프하면 아직 안 그려져 있다.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('아무도 처리 안 하면 서버 메시지가 뜬다', (tester) async {
    await pumpHost(tester);
    fire(_err(500, '서버가 응답하지 않았어요'));
    await settle(tester);
    expect(find.text('서버가 응답하지 않았어요'), findsOneWidget);
  });

  testWidgets('화면이 자기 토스트를 띄우면 전역은 취소된다', (tester) async {
    await pumpHost(tester);
    fire(_err(500, '서버 원문'));
    // 화면의 catch 가 도는 시점 — grace window 안.
    showPSnackBar(screenCtx, '삭제 실패: 서버 원문',
        severity: PSnackSeverity.error);
    await settle(tester);

    expect(find.text('삭제 실패: 서버 원문'), findsOneWidget);
    expect(find.text('서버 원문'), findsNothing, reason: '두 개가 뜨면 안 된다');
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
