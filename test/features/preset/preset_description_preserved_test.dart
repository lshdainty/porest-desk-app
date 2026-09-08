// 프리셋 메모(description)가 앱 편집 한 번에 사라지지 않게 한다 (A1-④ · 서버 S2 의 앱 쪽).
//
// 서버 `ExpenseTemplate.updateTemplate` 은 이 칸을 **무조건 대입**한다. 앱 편집 시트엔
// 메모 칸이 없어 값을 안 실었고, 그래서 이름만 고쳐 저장해도 메모가 null 로 덮였다.
// 웹 프리셋 상세는 그 값을 그리고 생성 API 는 여전히 받는데, 되살릴 입력칸이
// 웹·앱 어디에도 없다 — 한 번 지워지면 끝이다.
//
// 앱에서 그 메모를 실제로 쓴다: 프리셋을 불러오면 거래 메모 칸에 그대로 들어간다
// (`_applyPreset` 의 `memoCtrl.text = p.description`). 지워지면 그 자동채움도 빈칸이 된다.
//
// 그래서 **읽은 값을 그대로 되돌려 보낸다.** 서버가 "키 없으면 유지" 로 바뀌어도
// 같은 값을 다시 쓸 뿐이라 안전하다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/features/preset/data/preset_repository.dart';
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

/// 웹에서 메모를 적어 둔 프리셋.
const _withMemo = ExpenseTemplate(
  rowId: 5,
  templateName: '점심 도시락',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
  description: '회사 근처 김밥천국',
);

/// 메모가 없는 프리셋 — 없는 값을 억지로 만들어 보내지 않는지 본다.
const _withoutMemo = ExpenseTemplate(
  rowId: 6,
  templateName: '커피',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
);

class _CapturingRepo extends PresetRepository {
  _CapturingRepo() : super(Dio());

  bool called = false;
  String? description;

  @override
  Future<ExpenseTemplate> update({
    required int id,
    required String templateName,
    int? categoryRowId,
    int? assetRowId,
    required String expenseType,
    int? amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool lockAmount = false,
  }) async {
    called = true;
    this.description = description;
    return _withMemo;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _open(WidgetTester tester, ExpenseTemplate edit) async {
  final repo = _CapturingRepo();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith(
          (ref) async => [_withMemo, _withoutMemo],
        ),
        presetRepositoryProvider.overrideWith((ref) async => repo),
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
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('이름만 고쳐 저장해도 메모가 그대로 실린다', (tester) async {
    final repo = await _open(tester, _withMemo);
    await tester.enterText(_field(l.expPresetNamePlaceholder), '점심');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(
      repo.description,
      '회사 근처 김밥천국',
      reason: '안 실으면 서버가 무조건 대입해 지운다 — 되살릴 입력칸이 없다',
    );
  });

  testWidgets('원래 메모가 없으면 없는 채로 둔다', (tester) async {
    final repo = await _open(tester, _withoutMemo);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다');
    expect(repo.description, isNull);
  });
}
