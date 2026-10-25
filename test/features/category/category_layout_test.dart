// 카테고리 관리 틈 · 끝까지 닿기 · 글자 200% 겹침 — 360 폭 위젯 측정(I-20 T1 ~ T8 · 10-24 화면 끝까지 닿기 · K2 K3).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/category/presentation/category_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';

class _Repo extends ExpenseRepository {
  _Repo() : super(Dio());
}

const _cats = [
  ExpenseCategory(
    rowId: 1,
    categoryName: '카페·간식·디저트 모임',
    expenseType: 'EXPENSE',
    sortOrder: 0,
    icon: 'coffee',
    color: '#c73838',
    hasChildren: true,
  ),
  ExpenseCategory(
    rowId: 2,
    categoryName: '점심 회사 근처 식당가',
    expenseType: 'EXPENSE',
    sortOrder: 0,
    parentRowId: 1,
    color: '#9E9E9E',
    icon: 'not-a-real-icon',
  ),
  ExpenseCategory(
    rowId: 3,
    categoryName: '교통',
    expenseType: 'EXPENSE',
    sortOrder: 1,
    icon: 'bus',
    color: '#2c70bf',
  ),
];

Future<void> _open(
  WidgetTester tester, {
  double scale = 1,
  Brightness mode = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => _Repo()),
        categoriesProvider.overrideWith((ref) async => _cats),
        recurringListProvider.overrideWith(
          (ref) async => <RecurringTransaction>[],
        ),
      ],
      child: MaterialApp(
        theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const CategoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _plain(String s) =>
    s.replaceAll('⁠', '').replaceAll('​', '').replaceAll('￼', '');

Finder _t(String s) => find.byWidgetPredicate(
  (w) => w is Text && _plain(w.data ?? w.textSpan?.toPlainText() ?? '') == s,
  description: 'Text "$s"',
);

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('360 폭 · 글자 ${scale * 100}% — 끝까지 닿기 · 틈', (tester) async {
      await _open(tester, scale: scale);
      final body = tester.getRect(
        find.byKey(const ValueKey('screen-band-body')),
      );
      // 흰 면 하나가 폭 끝까지
      expect(body.left, 0);
      expect(body.right, 360);
      // 탭 — 화면 폭 끝까지, 머리 바로 아래(T1 0)
      final tabs = tester.getRect(find.byType(PTabs<int>));
      expect(tabs.left, 0);
      expect(tabs.right, 360);
      expect(tabs.top, body.top);
      // 검색칸 — 탭 아래 8(T2), 좌우 24, 높이 40
      final input = tester.getRect(find.byType(PInput).first);
      expect(input.top - tabs.bottom, 8);
      expect(input.left, 24);
      expect(input.right, 336);
      if (scale == 1) expect(input.height, 40);
      // 목록 제목 — 검색 줄 바로 아래(T3) · 제목과 첫 줄 사이 틈 0(T4)
      final header = tester.getRect(find.byType(PListHeader));
      expect(header.top - input.bottom, 8);
      final firstRow = tester.getRect(find.byKey(const ValueKey('p-1')));
      expect(header.left, 0);
      expect(header.right, 360);
      expect(firstRow.top - header.bottom, 0);
      // 줄은 폭 끝까지, 줄 사이 틈 0
      expect(firstRow.left, 0);
      expect(firstRow.right, 360);
      final second = tester.getRect(find.byKey(const ValueKey('p-3')));
      final lastChild = tester.getRect(find.byKey(const ValueKey('c-2')));
      expect(second.top, lastChild.bottom);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('꺾쇠 단추 44 · 부모 타일 52 · 하위 타일 104 · 타일 40 (글자 100%)', (
    tester,
  ) async {
    await _open(tester);
    final chevron = tester.getRect(
      find.byKey(const ValueKey('plist-expand-button')),
    );
    expect(chevron.size, const Size(44, 44));
    expect(chevron.left, 4);
    final tiles = tester.widgetList<PListTile>(find.byType(PListTile)).length;
    expect(tiles, 3);
    final tileRects = [
      for (final e in find.byType(PListTile).evaluate())
        tester.getRect(find.byElementPredicate((x) => x == e)),
    ];
    for (final r in tileRects) {
      expect(r.size, const Size(40, 40));
    }
    expect(tileRects[0].left, 52); // 부모
    expect(tileRects[1].left, 104); // 하위
    expect(tileRects[2].left, 52); // 부모(하위 없음도 꺾쇠 자리를 비운다)
  });

  testWidgets('목록 마지막 줄 아래 흰 면 안 24 (T8)', (tester) async {
    await _open(tester);
    final last = tester.getRect(find.byKey(const ValueKey('p-3')));
    final list = tester.getRect(find.byType(ListView).last);
    expect(list.bottom - last.bottom, greaterThanOrEqualTo(24));
  });

  for (final mode in [Brightness.light, Brightness.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '수정 시트 머리 — 제목 · ⋮ · 닫기 겹침 0 · 사이 4 (${mode.name} · ${scale * 100}%)',
        (tester) async {
          await _open(tester, scale: scale, mode: mode);
          await tester.tap(_t('카페·간식·디저트 모임'));
          await tester.pumpAndSettle();
          final title = tester.getRect(
            find.byKey(const ValueKey('p-bottom-sheet-title')),
          );
          final action = tester.getRect(
            find.descendant(
              of: find.byKey(const ValueKey('p-bottom-sheet-header-action')),
              matching: find.byType(PButton),
            ),
          );
          final close = tester.getRect(
            find.byKey(const ValueKey('p-bottom-sheet-close-circle')),
          );
          expect(title.overlaps(action), isFalse);
          expect(title.overlaps(close), isFalse);
          expect(action.overlaps(close), isFalse);
          // 시트 ≤ 화면의 90%
          final sheet = tester.getRect(
            find.byKey(const ValueKey('p-bottom-sheet-root')),
          );
          expect(sheet.height, lessThanOrEqualTo(780 * 0.9 + 0.01));
          expect(sheet.left, 0);
          expect(sheet.right, 360);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('수정 시트 줄 칸은 폭 끝까지 · 사이 선 없음 · 맨 위 칸과 첫 줄 사이 8 (T14)', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(_t('교통'));
    await tester.pumpAndSettle();
    final rows = find.descendant(
      of: find.byKey(const ValueKey('p-bottom-sheet-root')),
      matching: find.byType(PickerRow),
    );
    expect(rows, findsNWidgets(4));
    for (final e in rows.evaluate()) {
      final r = tester.getRect(find.byElementPredicate((x) => x == e));
      expect(r.left, 0);
      expect(r.right, 360);
    }
    final tile = tester.getRect(
      find.byKey(const ValueKey('category-preview-tile')),
    );
    expect(tile.size, const Size(52, 52));
    expect(tile.left, 24);
    // 맨 위 칸(이름) ↔ 첫 줄 칸 8 (T14) · 줄 사이 0
    final nameField = tester.getRect(find.byType(PField).first);
    final rowRects = [
      for (final e in rows.evaluate())
        tester.getRect(find.byElementPredicate((x) => x == e)),
    ]..sort((a, b) => a.top.compareTo(b.top));
    expect(rowRects.first.top - nameField.bottom, 8);
    for (var i = 1; i < rowRects.length; i++) {
      expect(rowRects[i].top, rowRects[i - 1].bottom);
    }
  });
}
