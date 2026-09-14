// 거래 행이 **날짜 헤더와 같은 지점에서 시작**하는지 고정한다
// (사용자 신고 2026-09-14 — 헤더 24 / 행 34 로 목록 전체가 오른쪽으로 밀려 보였다).
//
// 웹은 이 결정을 2026-08-19 에 했다 — `porest-desk-front` f8899d6
// "fix(ledger): 거래 행이 날짜 헤더와 같은 지점에서 시작하도록", `LedgerRow` 의
// `px-1 -mx-1` 로 좌우를 상쇄한다. 앱도 가계부 ExpenseRow 는 좌우 0 으로 따라갔는데
// **공용 PExpenseRow 만 10 을 들고 있었다.**
//
// 로딩 자리표시(PDayGroupSkeleton)는 처음부터 0 이었다. 그래서 10 인 채로 두면
// 데이터가 오는 순간 행이 10 튄다 — 그쪽 주석이 "실제 행과 같은 여백" 이라고
// 적고 있었는데 사실이 아니었다. 셋을 한 자리에서 같이 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_day_group.dart';
import 'package:porest_desk_app/shared/widgets/p_expense_row.dart';

const _pagePad = 24.0;

Expense _e({String type = 'EXPENSE'}) => Expense(
  rowId: 1,
  expenseType: type,
  amount: 3000,
  expenseDate: '2026-09-12T11:20:00',
  merchant: '스타벅스',
  categoryName: '식비',
  assetName: '신한카드',
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: PorestTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Padding(
          // 좌우 여백은 목록(페이지)이 쥔다 — 행은 여기에 더 얹지 않는다.
          padding: const EdgeInsets.symmetric(horizontal: _pagePad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [child],
          ),
        ),
      ),
    ),
  );
  // 스켈레톤 셔머는 끝나지 않으므로 pumpAndSettle 을 쓰지 않는다.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// 행 안 첫 Container = 40x40 카테고리 아이콘 상자. 그 왼쪽이 행의 시작점이다.
double _contentLeft(WidgetTester tester, Finder row) => tester
    .getRect(find.descendant(of: row, matching: find.byType(Container)).first)
    .left;

void main() {
  testWidgets('날짜 헤더와 공용 행이 같은 지점에서 시작한다', (tester) async {
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PDayHeader(
            date: DateTime(2026, 9, 12),
            items: [_e()],
            flags: const MaskFlags.cardOnly(false),
          ),
          PExpenseRow(expense: _e()),
        ],
      ),
    );
    final head = tester.getRect(find.textContaining('26. 9. 12')).left;
    expect(head, closeTo(_pagePad, 0.5));
    // 고치기 전에는 34 였다(= 24 + 행이 얹던 10).
    expect(_contentLeft(tester, find.byType(PExpenseRow)), closeTo(head, 0.5));
  });

  testWidgets('가계부 행도 같은 지점이다 — 두 행 위젯이 어긋나면 안 된다', (tester) async {
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PDayHeader(
            date: DateTime(2026, 9, 12),
            items: [_e()],
            flags: const MaskFlags.cardOnly(false),
          ),
          ExpenseRow(
            expense: _e(),
            category: null,
            flags: const MaskFlags.cardOnly(false),
          ),
        ],
      ),
    );
    final head = tester.getRect(find.textContaining('26. 9. 12')).left;
    expect(_contentLeft(tester, find.byType(ExpenseRow)), closeTo(head, 0.5));
  });

  testWidgets('스켈레톤도 같은 지점 — 데이터가 와도 행이 안 튄다', (tester) async {
    await _pump(tester, const PDayGroupSkeleton(rows: 2));
    final skeletonRow = tester
        .getRect(
          find
              .descendant(
                of: find.byType(PDayGroupSkeleton),
                matching: find.byType(Row),
              )
              .last,
        )
        .left;
    expect(skeletonRow, closeTo(_pagePad, 0.5));
  });

  testWidgets('행 금액은 지출·수입이 같은 색이다 (2026-07-27 73449cf)', (tester) async {
    // 색 구분은 날짜 헤더의 일 합계만 한다. 토큰 값을 직접 비교하면 테마가 바뀔 때
    // 같이 깨지므로, **두 종류가 같은 색인가**만 본다 — 그게 이 결정의 내용이다.
    // Color 객체는 같은 값이어도 == 가 아닐 수 있다 — 32비트 값으로 비교한다.
    final colors = <String, int?>{};
    for (final type in ['EXPENSE', 'INCOME']) {
      await _pump(
        tester,
        ExpenseRow(
          expense: _e(type: type),
          category: null,
          flags: const MaskFlags.cardOnly(false),
        ),
      );
      colors[type] = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(ExpenseRow),
              matching: find.textContaining('원'),
            ),
          )
          .style
          ?.color
          ?.toARGB32();
    }
    expect(colors['EXPENSE'], isNotNull);
    expect(
      colors['INCOME'],
      colors['EXPENSE'],
      reason: '행 금액이 종류별로 다른 색이면 가계부 규칙을 어긴 것이다',
    );
  });

  testWidgets('공용 PExpenseRow 는 종류 색을 쓴다 — 목록에 쓰면 안 되는 이유', (tester) async {
    // 이 차이를 기록해 둔다. 목록(가계부·검색)은 ExpenseRow 를, 요약 카드처럼
    // 색이 필요한 자리는 PExpenseRow 를 쓴다.
    // Color 객체는 같은 값이어도 == 가 아닐 수 있다 — 32비트 값으로 비교한다.
    final colors = <String, int?>{};
    for (final type in ['EXPENSE', 'INCOME']) {
      await _pump(tester, PExpenseRow(expense: _e(type: type)));
      colors[type] = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(PExpenseRow),
              matching: find.textContaining('원'),
            ),
          )
          .style
          ?.color
          ?.toARGB32();
    }
    expect(colors['INCOME'], isNot(colors['EXPENSE']));
  });
}
