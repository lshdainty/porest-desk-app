// 통계 화면 시험 · 렌더 하네스 데이터(I-08 08-2) — 웹 mock 과 같은 시나리오(worst · normal · empty). 이름은 지어낸 것.
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';

enum Scenario { worst, normal, empty, fail }

final now = DateTime.now();

ExpenseCategory _c(
  int id,
  String name,
  String? color,
  String icon, [
  int? parent,
]) => ExpenseCategory(
  rowId: id,
  categoryName: name,
  icon: icon,
  color: color,
  expenseType: 'EXPENSE',
  sortOrder: id,
  parentRowId: parent,
);

final cats = [
  _c(1, '식비', '#2C70BF', 'utensils').copyWith(hasChildren: true),
  _c(11, '외식', null, 'utensils', 1),
  _c(12, '장보기', null, 'shopping-cart', 1),
  _c(2, '카페·간식·디저트 모임 지출 항목', '#F59E0B', 'coffee'),
  _c(3, '주거·관리비·공과금·통신 요금 자동이체 묶음', '#10B981', 'house'),
  _c(4, '교통', '#8B5CF6', 'bus'),
  _c(5, '쇼핑', null, 'shopping-bag'),
  _c(6, '의료', '#123456', 'heart-pulse'),
  _c(7, '문화', null, 'film'),
  _c(8, '여행', null, 'plane'),
  _c(9, '교육', null, 'book-open'),
  _c(10, '경조사', null, 'gift'),
  _c(13, '반려동물', null, 'paw-print'),
  _c(14, '구독', null, 'repeat'),
];

const _worstAmt = [
  1234567890,
  987654321,
  123456789,
  45678901,
  23456789,
  9876543,
  5432100,
  2100000,
  1500000,
  900000,
  400000,
];

List<CategoryBreakdown> breakdown(Scenario s, {double scale = 1}) {
  if (s == Scenario.empty) return const [];
  final list = s == Scenario.worst
      ? <List<int>>[
          [11, 700000000],
          [12, 534567890],
          [2, _worstAmt[1]],
          [3, _worstAmt[2]],
          [4, _worstAmt[3]],
          [5, _worstAmt[4]],
          [6, _worstAmt[5]],
          [7, _worstAmt[6]],
          [8, _worstAmt[7]],
          [9, _worstAmt[8]],
          [10, _worstAmt[9]],
          [13, _worstAmt[10]],
          [14, 300000],
        ]
      : <List<int>>[
          [11, 400000],
          [12, 223000],
          [2, 450000],
          [3, 210000],
          [4, 150000],
          [5, 98000],
        ];
  return [
    for (final e in list)
      () {
        final c = cats.firstWhere((x) => x.rowId == e[0]);
        final par = c.parentRowId == null
            ? null
            : cats.firstWhere((x) => x.rowId == c.parentRowId);
        final amt = (e[1] * scale).round();
        return CategoryBreakdown(
          categoryRowId: c.rowId,
          categoryName: c.categoryName,
          parentCategoryRowId: par?.rowId,
          parentCategoryName: par?.categoryName,
          expenseType: 'EXPENSE',
          totalAmount: amt,
          fixedAmount: (c.rowId == 3 || c.rowId == 14)
              ? amt
              : c.rowId == 2
              ? (amt * 0.4).round()
              : 0,
        );
      }(),
  ];
}

List<({int year, int month})> months() => [
  for (var i = 0; i < 6; i++)
    () {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return (year: d.year, month: d.month);
    }(),
];

bool isCurrent(String start) =>
    start.startsWith('${now.year}-${now.month.toString().padLeft(2, '0')}');

RangeSummary summary(Scenario s, String start, String end) {
  final cur = isCurrent(start);
  final scale = cur ? 1.0 : 0.82;
  final bd = breakdown(s, scale: scale);
  final total = bd.fold<int>(0, (a, b) => a + b.totalAmount);
  final fixed = bd.fold<int>(0, (a, b) => a + b.fixedAmount);
  final w = s == Scenario.worst;
  final multi = start.substring(0, 7) != end.substring(0, 7);
  final single = !multi;
  final buckets = s == Scenario.empty
      ? <RangeMonthlyBucket>[]
      : [
          for (final (i, m)
              in (single
                      ? [
                          (
                            year: int.parse(start.substring(0, 4)),
                            month: int.parse(start.substring(5, 7)),
                          ),
                        ]
                      : months())
                  .indexed)
            RangeMonthlyBucket(
              year: m.year,
              month: m.month,
              totalIncome: w ? 450000000 + i * 20000000 : 3200000,
              totalExpense: (total * (0.7 + (i % 3) * 0.15)).round(),
              fixedIncome: w ? 300000000 : 3000000,
              fixedExpense: (fixed * 0.9).round(),
              categoryExpenses: [
                CategoryAmount(
                  categoryRowId: 11,
                  amount: (total * 0.2 * (1 + i / 10)).round(),
                ),
                CategoryAmount(categoryRowId: 2, amount: (total * 0.1).round()),
                CategoryAmount(
                  categoryRowId: 4,
                  amount: (total * 0.05 * (1 + (i % 2))).round(),
                ),
              ],
            ),
        ];
  return RangeSummary(
    startDate: start,
    endDate: end,
    totalIncome: s == Scenario.empty ? 0 : (w ? 1350000000 : 3200000),
    totalExpense: total,
    fixedIncome: w ? 900000000 : 3000000,
    fixedExpense: fixed,
    categoryBreakdown: bd,
    monthlyBuckets: buckets,
  );
}

List<MerchantSummary> merchants(Scenario s) {
  if (s == Scenario.empty) return const [];
  const names = [
    '숲길 커피 중앙점 아주 긴 가맹점 이름 테스트 지점 2호점',
    '다온배달',
    '가람마트',
    '지하철',
    '가온마트 대형점 대량 구매 결제 건',
    '점심 식사 동료들과 함께',
  ];
  return [
    for (final (i, n) in names.indexed)
      MerchantSummary(
        merchant: n,
        totalAmount: s == Scenario.worst
            ? 123456789 - i * 9000000
            : 90000 - i * 9000,
        count: 20 - i,
      ),
  ];
}

List<HeatmapCell> heat(Scenario s) {
  if (s == Scenario.empty) return const [];
  const hours = [7, 12, 15, 19, 23, 3];
  return [
    for (var i = 0; i < 42; i++)
      HeatmapCell(
        dayOfWeek: (i % 7) + 1,
        hour: hours[i ~/ 7],
        totalAmount:
            (s == Scenario.worst ? 36000000 : 10000) * ((i * 7) % 11 + 1),
      ),
  ];
}

List<MonthlyTrend> trend(Scenario s) => [
  for (final (i, m) in months().indexed)
    MonthlyTrend(
      year: m.year,
      month: m.month,
      totalIncome: s == Scenario.worst ? 450000000 : 3200000,
      totalExpense: s == Scenario.worst ? 650000000 + i * 1000000 : 1500000,
      fixedIncome: s == Scenario.worst ? 300000000 : 3000000,
      fixedExpense: s == Scenario.worst ? 400000000 : 900000,
    ),
];

/// 거래 — 기간 안 날마다 몇 건. 요일 비교 · 일별 추이 · 지표용.
List<Expense> expenses(Scenario s, String start, String end) {
  if (s == Scenario.empty) return const [];
  final f = DateTime.parse(start);
  final t = DateTime.parse(end);
  final out = <Expense>[];
  var id = 1;
  final w = s == Scenario.worst;
  for (var d = f; !d.isAfter(t); d = d.add(const Duration(days: 1))) {
    if (d.isAfter(now)) break;
    final iso =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00';
    out.add(
      Expense(
        rowId: id++,
        expenseType: 'EXPENSE',
        amount: (w ? 21000000 : 30000) * (1 + d.weekday % 4),
        expenseDate: iso,
      ),
    );
    if (d.day % 7 == 0) {
      out.add(
        Expense(
          rowId: id++,
          expenseType: 'INCOME',
          amount: w ? 99000000 : 300000,
          expenseDate: iso,
        ),
      );
    }
  }
  return out;
}
