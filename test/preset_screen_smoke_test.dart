// 일회성 진단 — '!semantics.parentDataDirty' assertion 재현.
// 실제 PresetScreen + 프리셋 추가 시트를 semantics 활성 상태로 펌프/스크롤.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/features/preset/domain/expense_template.dart';
import 'package:porest_desk_app/features/preset/presentation/preset_screen.dart';

final _categories = <ExpenseCategory>[
  for (int g = 0; g < 6; g++) ...[
    ExpenseCategory(
      rowId: g * 10,
      categoryName: '그룹$g',
      expenseType: 'EXPENSE',
      sortOrder: g,
      icon: 'utensils',
      color: '#2c70bf',
    ),
    ExpenseCategory(
      rowId: g * 10 + 1,
      categoryName: '자식$g',
      expenseType: 'EXPENSE',
      sortOrder: 0,
      parentRowId: g * 10,
      icon: 'utensils',
      color: '#2c70bf',
    ),
  ],
];

final _presets = <ExpenseTemplate>[
  for (int i = 0; i < 8; i++)
    ExpenseTemplate(
      rowId: i,
      templateName: '프리셋 $i',
      expenseType: i.isEven ? 'EXPENSE' : 'INCOME',
      categoryRowId: (i % 6) * 10 + 1,
      amount: i.isEven ? 4500 : null,
      lockAmount: i.isEven ? 'Y' : 'N',
      useCount: i * 3,
      merchant: '가맹점 $i',
    ),
];

void main() {
  testWidgets('PresetScreen + 추가 시트 semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presetListProvider.overrideWith((ref) async => _presets),
          categoriesProvider.overrideWith((ref) async => _categories),
          assetsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: PorestTheme.dark(),
          home: const PresetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 리스트 스크롤 왕복
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pumpAndSettle();

    // 프리셋 추가 시트 열기 + 시트 스크롤 왕복
    await tester.tap(find.text('프리셋 추가'));
    await tester.pumpAndSettle();
    final scrollables = find.byType(Scrollable);
    await tester.drag(scrollables.last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(scrollables.last, const Offset(0, 300));
    await tester.pumpAndSettle();

    handle.dispose();
  });
}
