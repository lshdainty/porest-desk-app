// I-28 28-4 — 홈 "복사한 결제 문자" 안내를 List 강조 줄로 잰다(아이폰 경로).
//
//  - 줄 = PListButtonItem highlighted(list.md Highlight · bg-brand-weak) · 앞 클립보드 24 fg-brand
//  - 누르는 것 둘 — 줄 전체(가져오기 = 붙여넣기 화면) · 닫기(ghost 아이콘 버튼, 이름 "닫기")
//  - 안드로이드(힌트 없음)에서는 아무것도 그리지 않는다
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/plain_text.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/sms/data/clipboard_hint.dart';
import 'package:groo_damda_app/features/sms/data/clipboard_hint_provider.dart';
import 'package:groo_damda_app/features/sms/presentation/sms_clipboard_banner.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';

Future<void> _pump(
  WidgetTester t, {
  required ClipboardHint? hint,
  Object? Function(MethodCall)? clipboard,
  List<Object?>? pushed,
}) async {
  SharedPreferences.setMockInitialValues({});
  t.view.physicalSize = const Size(360 * 3, 800 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (c) async => clipboard?.call(c),
  );
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SmsClipboardBanner()),
      ),
      GoRoute(
        path: '/sms-paste',
        builder: (_, state) {
          pushed?.add(state.extra);
          return const Scaffold(body: Text('paste-screen'));
        },
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clipboardHintReaderProvider.overrideWithValue(() async => hint),
      ],
      child: MaterialApp.router(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

const _hint = ClipboardHint(changeCount: 7, hasText: true);
const _sms = '[Web발신] 카드 승인 12,000원 일시불';

void main() {
  testWidgets('아이폰 경로 — 강조 줄 하나, 클립보드 24 fg-brand, 제목 · 설명 문구', (t) async {
    await _pump(t, hint: _hint);
    final row = find.byType(PListButtonItem);
    expect(row, findsOneWidget);
    expect(t.widget<PListButtonItem>(row).highlighted, isTrue);
    expect(findPlain('복사한 결제 문자가 있어요'), findsOneWidget);
    expect(findPlain('붙여넣어 지출로 기록할 수 있어요.'), findsOneWidget);
    // 화면 폭 흰 면(PScreenBandBody) 안 — 바깥 여백 없음
    final body = find.byType(PScreenBandBody);
    expect(body, findsOneWidget);
    expect(t.getRect(body).left, 0);
    expect(t.getRect(body).width, 360);
    final icon = t.widget<Icon>(find.byIcon(LucideIcons.clipboard));
    expect(icon.size, 24);
    final ctx = t.element(row);
    expect(icon.color, ctx.colors.fgBrand);
    // 옛 알림 상자 · 작은 [기록하기] 버튼은 없다
    expect(find.text('기록하기'), findsNothing);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('누르는 곳은 둘 — 줄 전체 · 닫기(이름 "닫기", ghost 아이콘 버튼)', (t) async {
    await _pump(t, hint: _hint);
    final close = find.byType(PButton);
    expect(close, findsOneWidget);
    final b = t.widget<PButton>(close);
    expect(b.variant, PButtonVariant.ghost);
    expect(b.semanticLabel, '닫기');
    expect(find.bySemanticsLabel('닫기'), findsWidgets);
    expect(find.byType(PListButtonItem), findsOneWidget);
  });

  testWidgets('줄을 누르면 클립보드를 읽어 붙여넣기 화면으로 간다(_open)', (t) async {
    final pushed = <Object?>[];
    await _pump(
      t,
      hint: _hint,
      pushed: pushed,
      clipboard: (c) => c.method == 'Clipboard.getData' ? {'text': _sms} : null,
    );
    await t.tap(findPlain('복사한 결제 문자가 있어요'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('paste-screen'), findsOneWidget);
    expect(pushed, [_sms]);
  });

  testWidgets('닫기를 누르면 줄이 사라지고 같은 복사본은 다시 권하지 않는다(_dismiss)', (t) async {
    final pushed = <Object?>[];
    await _pump(t, hint: _hint, pushed: pushed);
    await t.tap(find.byIcon(LucideIcons.x));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(PListButtonItem), findsNothing);
    expect(pushed, isEmpty); // 줄 누르기(_open)는 일어나지 않았다
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('pd-sms-clip-dismissed'), 7);
  });

  testWidgets('안드로이드(힌트 없음)에서는 아무것도 그리지 않는다', (t) async {
    await _pump(t, hint: null);
    expect(find.byType(PListButtonItem), findsNothing);
    expect(find.byType(PScreenBandBody), findsNothing);
    expect(find.byType(SmsClipboardBanner), findsOneWidget);
    expect(t.getSize(find.byType(SmsClipboardBanner)).height, 0);
  });
}
