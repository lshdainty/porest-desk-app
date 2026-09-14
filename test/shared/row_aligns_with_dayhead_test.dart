// 거래 행이 **날짜 헤더와 같은 지점에서 시작**하는지 고정한다
// (사용자 신고 2026-09-14 — 헤더 24 / 행 34 로 목록 전체가 오른쪽으로 밀려 보였다).
//
// 웹은 이 결정을 2026-08-19 에 했다 — `porest-desk-front` f8899d6
// "fix(ledger): 거래 행이 날짜 헤더와 같은 지점에서 시작하도록".
// 앱에는 한동안 행 위젯이 둘이었고(가계부용 ExpenseRow / 공용 PExpenseRow),
// 이 결정이 가계부 쪽에만 들어가 있었다. 지금은 **하나로 합쳤다** — 가계부 ·
// 검색 · 거래상세 · 홈이 모두 ExpenseRow 를 쓴다.
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

const _pagePad = 24.0;

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}:00';

Expense _e({String type = 'EXPENSE', DateTime? date, int amount = 3000}) =>
    Expense(
      rowId: 1,
      expenseType: type,
      amount: amount,
      expenseDate: date == null ? '2026-09-12T11:20:00' : _iso(date),
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
  testWidgets('날짜 헤더와 행이 같은 지점에서 시작한다', (tester) async {
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
    expect(head, closeTo(_pagePad, 0.5));
    // 고치기 전에는 34 였다(= 24 + 행이 얹던 10).
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

  testWidgets('예정(미래) 거래만 흐려진다 — 지나간 거래는 또렷하다', (tester) async {
    // 회색으로 보이는 것은 금액 색이 아니라 **행 전체의 opacity 0.6** 이다.
    // 합계에도 안 들어가는 값이라 지나간 거래와 같은 무게로 보이면 안 된다.
    final past = DateTime.now().subtract(const Duration(days: 1));
    final future = DateTime.now().add(const Duration(days: 3));
    double opacityOf(WidgetTester t) => t
        .widget<Opacity>(
          find
              .descendant(
                of: find.byType(ExpenseRow),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    await _pump(
      tester,
      ExpenseRow(
        expense: _e(date: past),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    expect(opacityOf(tester), 1);

    await _pump(
      tester,
      ExpenseRow(
        expense: _e(date: future),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    expect(opacityOf(tester), lessThan(1));
  });

  testWidgets('행 금액의 마이너스는 U+2212 — 헤더 합계와 같은 기호다', (tester) async {
    // NumberFormat 이 음수에 찍는 ASCII 하이픈은 U+2212 와 폭이 달라, 같은 카드
    // 안에서 섞이면 tabular figures 정렬이 어긋난다(QA #22 가 잡았던 자리).
    // 행은 오래 ASCII 를 쓰고 있었는데, 헤더 합계만 손으로 U+2212 를 붙여
    // 가계부 목록이 내내 두 기호를 섞고 있었다.
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
    expect(find.text('−3,000원'), findsNWidgets(2)); // 헤더 합계 + 행
    expect(find.textContaining('-3,000'), findsNothing); // ASCII 하이픈
  });

  testWidgets('수입은 +, 0 원은 부호 없음', (tester) async {
    await _pump(
      tester,
      ExpenseRow(
        expense: _e(type: 'INCOME'),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    expect(find.text('+3,000원'), findsOneWidget);

    await _pump(
      tester,
      ExpenseRow(
        expense: _e(amount: 0),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    // 빈 계정에서 `−0원` 으로 보이던 자리(QA #1).
    expect(find.text('0원'), findsOneWidget);
  });
}
