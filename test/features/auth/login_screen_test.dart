// 로그인 화면(I-05 5 ~ 10 · 75 · 86) — 실제 화면을 띄운 채로 잰다.
//
//  - 문구: ko · en 어디에도 "SSO" 가 없다 · "그루 계정으로 로그인"
//  - 마크: 나무 56 + 8 + 이름, 이름이 화면 제목(머리말 1단계), 나무는 의미 트리에 없다
//  - 버튼: ds Button large · neutralSolid, 바닥은 흰 면, 브라우저를 여는 동안 딤 · 원 덮개가 없다
//  - 실패: Callout(critical) 이 버튼 위에, 서버 글을 붙이지 않는다
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/auth/presentation/login_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/brand/groo_tree.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

class _FakeAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;

  void failLogin(Object e) => state = AsyncError(e, StackTrace.current);
}

Future<_FakeAuth> _pump(
  WidgetTester tester, {
  String locale = 'ko',
  bool dark = false,
  double width = 360,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final auth = _FakeAuth();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(() => auth)],
      child: MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pump();
  return auth;
}

void main() {
  for (final locale in ['ko', 'en']) {
    testWidgets('$locale — 화면의 모든 글에 SSO 가 없고 그루 계정을 말한다', (tester) async {
      await _pump(tester, locale: locale);
      final l = lookupAppLocalizations(Locale(locale));
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .join('\n');
      expect(texts, isNot(contains('SSO')));
      expect(l.authLoginPrompt, isNot(contains('SSO')));
      expect(l.authSsoLogin, isNot(contains('SSO')));
      expect(l.authLoginFailed, isNot(contains('SSO')));
      expect(l.authSecurityNotHttps, isNot(contains('SSO')));
      expect(texts, contains(l.authSsoLogin));
      expect(texts, contains(l.authLoginPrompt));
      expect(texts, contains(l.appTitle));
    });
  }

  testWidgets('ko 문구 — 그루 계정으로 로그인해주세요. · 그루 계정으로 로그인', (tester) async {
    await _pump(tester);
    expect(find.text('그루 계정으로 로그인해주세요.'), findsOneWidget);
    expect(find.text('그루 계정으로 로그인'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      '${dark ? "다크" : "라이트"} — 마크 나무 56 + 8 + 이름 · 바닥 흰 면 · 버튼 large',
      (tester) async {
        await _pump(tester, dark: dark);
        final c = (dark ? GrooTheme.dark() : GrooTheme.light())
            .extension<PColors>()!;
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          c.bgLayerDefault,
        );
        final tree = tester.getRect(find.byType(GrooTree));
        expect(tree.height, 56);
        final name = tester.getRect(find.text('그루 담다'));
        expect(name.left - tree.right, 8, reason: '나무 ↔ 이름 8');
        // 안내 = t5 · 400 · fg-neutral-muted, 마크 ↔ 안내 8 · 안내 ↔ 버튼 32
        final promptFinder = find.text('그루 계정으로 로그인해주세요.');
        final prompt = tester.widget<Text>(promptFinder).style!;
        expect(prompt.fontSize, 16);
        expect(prompt.fontWeight, FontWeight.w400);
        expect(prompt.color, c.fgNeutralMuted);
        final markBottom = tester.getRect(find.byType(GrooTree)).bottom;
        expect(
          tester.getRect(promptFinder).top - markBottom,
          closeTo(8, 1),
          reason: '마크 ↔ 안내 8',
        );
        expect(
          tester.getRect(find.byType(PButton)).top -
              tester.getRect(promptFinder).bottom,
          32,
          reason: '안내 ↔ 버튼 32',
        );
        final button = tester.widget<PButton>(find.byType(PButton));
        expect(button.size, PButtonSize.large);
        expect(button.variant, PButtonVariant.neutralSolid);
        expect(tester.getSize(find.byType(PButton)).height, 48);
        expect(
          tester.getSize(find.byType(PButton)).width,
          360.0 - 48,
          reason: '전체 폭(좌우 24)',
        );
        // 브라우저를 여는 동안의 덮개(딤 + 원)가 없다 — 로딩은 버튼 몫
        expect(
          find.descendant(
            of: find.byType(SafeArea),
            matching: find.byType(PProgressCircle),
          ),
          findsNothing,
        );
      },
    );
  }

  testWidgets('이름이 화면 제목(머리말 1단계)이고 나무는 의미 트리에 없다', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final node = tester.getSemantics(find.text('그루 담다'));
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(find.bySemanticsLabel('그루 담다'), findsOneWidget);
    handle.dispose();
  });

  // 글자 200% 에서는 ds Button 라벨(한 줄 고정, button.yaml)이 폭 360 에서 124 넘친다 — 부품 몫이라 결과표 질문으로 올렸다.
  testWidgets('글자 130% · 폭 360 — 넘치지 않는다', (tester) async {
    await _pump(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('그루 담다'), findsOneWidget);
  });

  testWidgets('실패는 버튼 위 Callout(critical) — 서버 글을 붙이지 않는다', (tester) async {
    final auth = await _pump(tester);
    auth.failLogin(
      ApiException(code: 'AUTH_099', message: '서버가 준 영어 error text'),
    );
    await tester.pump();
    final callout = find.byType(PCallout);
    expect(callout, findsOneWidget);
    expect(tester.widget<PCallout>(callout).tone, PCalloutTone.critical);
    expect(find.text('로그인하지 못했어요.'), findsOneWidget);
    expect(find.textContaining('서버가 준'), findsNothing);
    expect(
      tester.getRect(callout).bottom,
      lessThan(tester.getRect(find.byType(PButton)).top),
      reason: '자리는 버튼 위',
    );
  });
}
