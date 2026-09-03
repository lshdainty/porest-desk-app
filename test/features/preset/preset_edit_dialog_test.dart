// 프리셋 이름 정책 — 길이 상한·중복 안내(QA #54).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/features/preset/domain/expense_template.dart';
import 'package:porest_desk_app/features/preset/presentation/preset_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _category = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _existing = ExpenseTemplate(
  rowId: 5,
  templateName: '점심 도시락',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
);

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<void> _open(WidgetTester tester, {ExpenseTemplate? edit}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith((ref) async => [_existing]),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => <Asset>[]),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showPresetEditDialog(ctx, edit: edit),
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
    await tester.enterText(_field(l.expPresetNamePlaceholder), 'ㄱ' * 13);
    await tester.pumpAndSettle();
    await tester.tap(find.text('식비'));
    await tester.pumpAndSettle();
    expect(find.text(l.nameTooLong(12)), findsOneWidget);
    expect(
      tester.widget<PButton>(_submitButton(l.presetSubmitAdd)).onPressed,
      isNull,
    );
  });

  testWidgets('같은 이름 프리셋은 안내가 뜨고 저장이 막힌다', (tester) async {
    await _open(tester);
    await tester.enterText(_field(l.expPresetNamePlaceholder), '점심 도시락');
    await tester.pumpAndSettle();
    await tester.tap(find.text('식비'));
    await tester.pumpAndSettle();
    expect(find.text(l.presetNameDuplicate), findsOneWidget);
    expect(
      tester.widget<PButton>(_submitButton(l.presetSubmitAdd)).onPressed,
      isNull,
    );
  });

  testWidgets('편집에서 자기 이름을 그대로 두면 중복이 아니다', (tester) async {
    await _open(tester, edit: _existing);
    await tester.enterText(_field(l.expPresetNamePlaceholder), '점심 도시락');
    await tester.pumpAndSettle();
    expect(find.text(l.presetNameDuplicate), findsNothing);
    expect(
      tester.widget<PButton>(_submitButton(l.actionSave)).onPressed,
      isNotNull,
    );
  });
}
