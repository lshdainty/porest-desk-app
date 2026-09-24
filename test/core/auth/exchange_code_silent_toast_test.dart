// 로그인 코드 교환 실패는 전역 오류 토스트에 안 뜬다(QA 28 1).
//
// 해지한 계정으로 다시 로그인하면 서버가 `POST /auth/exchange-code` 에 403 USER_021 을
// 준다. 라우터는 해지 완료 화면으로 보내는데(withdrawn_screen_test), 전역 그물
// (`ErrorToastInterceptor`)이 값을 바꾸는 요청의 실패라며 같은 오류를 빨간 토스트로
// 한 번 더 띄워 완료 화면 위에 겹쳤다. 다른 교환 실패도 로그인 화면이 자기 에러 줄에
// 그리므로 토스트는 늘 중복이다.
//
// withdrawn_screen_test 는 인터셉터를 태우지 않아 이걸 못 봤다. 여기서는 진짜 Dio
// 체인(가짜 서버 → 인터셉터)을 태우고, 같은 오류가 다른 POST 에서는 뜨는지(대조군)도 본다.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/auth/auth_repository.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _withdrawnMessage = '이용을 해지한 계정이에요';

/// 어떤 요청이든 403 USER_021 로 답하는 가짜 서버.
class _WithdrawnServer implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'success': false,
      'code': 'USER_021',
      'message': _withdrawnMessage,
    }),
    403,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late AuthRepository repo;

  Future<void> pumpHost(WidgetTester tester) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    registerErrorToastMessenger(key);
    resetGlobalErrorToastState();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = _WithdrawnServer()
      ..interceptors.add(ErrorToastInterceptor());
    repo = AuthRepository(dio);
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
  }

  Future<Object?> call(WidgetTester tester, Future<void> Function() f) async {
    Object? caught;
    await tester.runAsync(() async {
      try {
        await f();
      } catch (e) {
        caught = e;
      }
    });
    // 스낵바가 올라올 때까지.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return caught;
  }

  testWidgets('해지한 계정의 코드 교환 실패 — 토스트 없이 USER_021 만 올라간다', (tester) async {
    await pumpHost(tester);

    final e = await call(
      tester,
      () => repo.exchangeCode(
        code: 'c',
        codeVerifier: 'v',
        redirectUri: 'porest://callback',
      ),
    );

    expect(e, isA<ApiException>());
    expect(
      (e! as ApiException).isWithdrawn,
      isTrue,
      reason: '라우터가 이걸 보고 완료 화면으로 보낸다',
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(_withdrawnMessage), findsNothing);
  });

  // 대조군 — 같은 가짜 서버·같은 그물에서 다른 POST 는 토스트가 뜬다. 이게 안 뜨면
  // 위 테스트는 아무것도 증명하지 못한다.
  testWidgets('대조군: 같은 오류라도 다른 POST 는 전역 토스트가 뜬다', (tester) async {
    await pumpHost(tester);

    final e = await call(tester, () => repo.logout());

    expect(e, isA<ApiException>());
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(_withdrawnMessage), findsOneWidget);
  });
}
