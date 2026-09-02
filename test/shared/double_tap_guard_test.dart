// 저장·확인 버튼을 따닥 누르면 같은 요청이 두 번 나갔다(웹 QA 2026-09-02, 앱은 위젯
// 테스트로 같은 틈 확인 2026-09-03). submitting/loading 으로 버튼이 죽는 건 다음 프레임
// 뒤라, 같은 프레임 안에 들어온 두 번째 탭은 공용 진입점이 동기적으로 버려야 한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

Widget _app(Widget home) => MaterialApp(
  theme: PorestTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

void main() {
  testWidgets('시트 푸터 — 같은 프레임 안 두 번 탭해도 onSubmit 은 한 번', (tester) async {
    var calls = 0;
    final controller = PSheetController()
      ..canSubmit = true
      ..onSubmit = () async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      };
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: PSheetFooter(controller: controller, submitLabel: '저장'),
        ),
      ),
    );
    await tester.tap(find.text('저장'));
    await tester.tap(find.text('저장')); // pump 없이 — 같은 프레임
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);

    // 끝난 뒤엔 다시 눌린다 — 검증 실패로 요청이 안 나간 경우 재시도가 돼야 한다.
    await tester.tap(find.text('저장'));
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 2);
  });

  testWidgets('시트 푸터 — 삭제도 같은 프레임 두 번 탭에 한 번', (tester) async {
    var calls = 0;
    final controller = PSheetController()
      ..onDelete = () async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      };
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: PSheetFooter(controller: controller, submitLabel: '저장'),
        ),
      ),
    );
    await tester.tap(find.text('삭제'));
    await tester.tap(find.text('삭제'));
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
  });

  testWidgets('확인 다이얼로그 — 같은 프레임 안 두 번 탭해도 onConfirm 은 한 번', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showPConfirmDialog(
              ctx,
              title: 't',
              message: 'm',
              confirmLabel: '확인',
              onConfirm: () async {
                calls++;
                await Future<void>.delayed(const Duration(milliseconds: 300));
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.tap(find.text('확인'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
