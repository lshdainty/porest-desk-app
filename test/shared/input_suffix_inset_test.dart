// 입력칸 접미 버튼의 치수를 **웹 구현 그대로** 고정한다
// (사용자 신고 2026-09-13 — 앱의 날짜·시각 아이콘만 안쪽으로 밀려 보인다).
//
// 고치기 전 원인은 패딩이 두 겹 얹힌 것이었다. 접미가 스스로 오른쪽 12 를 두는데
// InputDecoration 의 기본 suffixIconConstraints(minWidth/minHeight 48)가 그보다
// 작은 접미를 48 상자에 **가운데 정렬**해 16 을 더 얹었다 → 글리프가 끝에서 28.
//
// 기준값은 이 파일이 정한 것이 아니라 porest-desk-front 에서 읽어 온 것이다.
//
//   InputDatePicker / InputTimePicker (src/shared/ui/input-{date,time}-picker.tsx)
//     <Input className="pr-10" />                         → 글자는 끝에서 40 에 멈춤
//     <Button size="icon" className="right-1 size-7 p-0">  → 탭 28x28, 끝에서 4
//       <CalendarIcon className="size-3.5" />              → 글리프 14 → 끝에서 11
//
//   SecretField (src/features/subscription/ui/SecretField.tsx)
//     style={{ paddingRight: 40 }}                         → 글자는 끝에서 40
//     style={{ right: 4, width: 32, height: 32 }}          → 탭 32x32, 끝에서 4
//     <Eye size={16} />                                    → 글리프 16 → 끝에서 12
//
// 웹이 두 자리에서 서로 다른 크기를 쓰므로 앱도 그대로 다르게 둔다 — 하나로
// 통일하면 웹과 어긋난다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

Widget _host(Widget child) => MaterialApp(
  theme: PorestTheme.dark(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [child],
      ),
    ),
  ),
);

void main() {
  Future<void> pump(WidgetTester tester, Widget w) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(w));
    await tester.pumpAndSettle();
  }

  /// 칸 오른쪽 끝을 0 으로 본 각 요소의 위치.
  ({double glyph, double button, double text, Size tap}) measure(
    WidgetTester tester,
    IconData icon,
  ) {
    final right = tester.getRect(find.byType(TextField)).right;
    // 버튼 상자 = GestureDetector. PInputSuffixButton 자체는 바깥 패딩까지 포함해
    // 오른쪽 끝이 칸 안쪽 선과 붙으므로 위치를 재는 기준이 못 된다.
    final box = tester.getRect(
      find
          .descendant(
            of: find
                .ancestor(
                  of: find.byIcon(icon),
                  matching: find.byType(PInputSuffixButton),
                )
                .first,
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    return (
      glyph: right - tester.getRect(find.byIcon(icon)).right,
      button: right - box.right,
      text: right - tester.getRect(find.byType(EditableText)).right,
      tap: box.size,
    );
  }

  testWidgets('날짜 칸 — 웹 InputDatePicker 와 같은 치수', (tester) async {
    await pump(
      tester,
      PDateInput(value: DateTime(2026, 9, 12), onChanged: (_) {}),
    );
    final m = measure(tester, LucideIcons.calendar);

    expect(m.glyph, closeTo(11, 0.5), reason: 'size-3.5 가 size-7 가운데 → 4+7');
    expect(m.button, closeTo(4, 0.5), reason: 'right-1');
    expect(m.tap.width, closeTo(28, 0.5), reason: 'size-7');
    expect(m.tap.height, closeTo(28, 0.5), reason: 'size-7');
    expect(m.text, closeTo(40, 0.5), reason: 'pr-10 — 글자가 버튼 밑으로 안 들어간다');
    // 칸 자체는 웹 h-10 과 같아야 하고, 이번 변경으로 밀리지 않아야 한다.
    expect(tester.getRect(find.byType(TextField)).height, closeTo(40, 0.5));
  });

  testWidgets('시각 칸도 같다', (tester) async {
    await pump(
      tester,
      PTimeInput(
        value: const TimeOfDay(hour: 22, minute: 16),
        onChanged: (_) {},
      ),
    );
    final m = measure(tester, LucideIcons.clock);
    expect(m.glyph, closeTo(11, 0.5));
    expect(m.button, closeTo(4, 0.5));
    expect(m.tap.width, closeTo(28, 0.5));
    expect(m.text, closeTo(40, 0.5));
  });

  testWidgets('글리프는 14 — 웹 size-3.5. 앱 기본 16 을 쓰면 안 된다', (tester) async {
    await pump(
      tester,
      PDateInput(value: DateTime(2026, 9, 12), onChanged: (_) {}),
    );
    expect(
      tester.getRect(find.byIcon(LucideIcons.calendar)).width,
      closeTo(14, 0.5),
    );
  });

  testWidgets('지우기 버튼이 붙어도 달력 버튼은 여전히 끝에서 4', (tester) async {
    await pump(
      tester,
      PDateInput(
        value: DateTime(2026, 9, 12),
        onChanged: (_) {},
        allowClear: true,
      ),
    );
    final m = measure(tester, LucideIcons.calendar);
    expect(m.button, closeTo(4, 0.5));
    expect(m.glyph, closeTo(11, 0.5));
  });

  testWidgets('비밀값 보기는 웹 SecretField 치수 — 32 / 글리프 16', (tester) async {
    // 웹이 날짜(28/14)와 다르게 쓰는 자리다. 공용 버튼이 크기를 받는지 확인한다.
    await pump(
      tester,
      PTextInput(
        controller: TextEditingController(text: 'secret'),
        suffix: PInputSuffixButton(
          size: 32,
          onTap: () {},
          child: const Icon(LucideIcons.eye, size: 16),
        ),
      ),
    );
    final m = measure(tester, LucideIcons.eye);
    expect(m.button, closeTo(4, 0.5), reason: 'right: 4');
    expect(m.tap.width, closeTo(32, 0.5), reason: 'width: 32');
    expect(m.glyph, closeTo(12, 0.5), reason: '4 + (32-16)/2');
    expect(m.text, closeTo(40, 0.5), reason: 'paddingRight: 40');
  });
}
