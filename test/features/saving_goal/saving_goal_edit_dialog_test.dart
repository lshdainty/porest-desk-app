// 저축목표 이름 정책 — 길이 상한·중복 안내(QA #52).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';
import 'package:porest_desk_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _existing = SavingGoal(rowId: 1, title: '비상금', targetAmount: 1000000);

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<void> _open(WidgetTester tester, {SavingGoal? edit}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        savingGoalListProvider.overrideWith((ref) async => [_existing]),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showSavingGoalEditDialog(ctx, edit: edit),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('이름 카운터가 0/12 로 시작한다', (tester) async {
    await _open(tester);
    expect(find.text('0/12'), findsOneWidget);
  });

  testWidgets('12자 초과는 안내가 뜨고 저장이 막힌다', (tester) async {
    await _open(tester);
    await tester.enterText(_field(l.savingGoalNameHint), 'ㄱ' * 13);
    await tester.enterText(_field('0').first, '1000');
    await tester.pumpAndSettle();
    expect(find.text(l.nameTooLong(12)), findsOneWidget);
    expect(
      tester.widget<PButton>(_submitButton(l.savingGoalSubmitAdd)).onPressed,
      isNull,
    );
  });

  testWidgets('12자 정각은 통과한다', (tester) async {
    await _open(tester);
    await tester.enterText(_field(l.savingGoalNameHint), 'ㄱ' * 12);
    await tester.enterText(_field('0').first, '1000');
    await tester.pumpAndSettle();
    expect(find.text('12/12'), findsOneWidget);
    expect(
      tester.widget<PButton>(_submitButton(l.savingGoalSubmitAdd)).onPressed,
      isNotNull,
    );
  });

  testWidgets('같은 이름 목표는 안내가 뜨고 저장이 막힌다', (tester) async {
    await _open(tester);
    await tester.enterText(_field(l.savingGoalNameHint), '비상금');
    await tester.enterText(_field('0').first, '1000');
    await tester.pumpAndSettle();
    expect(find.text(l.savingGoalNameDuplicate), findsOneWidget);
    expect(
      tester.widget<PButton>(_submitButton(l.savingGoalSubmitAdd)).onPressed,
      isNull,
    );
  });

  testWidgets('편집에서 자기 이름을 그대로 두면 중복이 아니다', (tester) async {
    await _open(tester, edit: _existing);
    await tester.enterText(_field(l.savingGoalNameHint), '비상금');
    await tester.pumpAndSettle();
    expect(find.text(l.savingGoalNameDuplicate), findsNothing);
    expect(
      tester.widget<PButton>(_submitButton(l.actionEdit)).onPressed,
      isNotNull,
    );
  });
}
