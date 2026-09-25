// 가계부 필터 v2 의 **진리표** — filter-combos.md 의 15줄.
//
// 웹 `src/features/expense/model/filter.test.ts` 와 **같은 표**다. 한쪽만 고치면
// 같은 필터가 두 화면에서 다른 결과를 낸다 — 그래서 조합 번호를 이름에 박아 둔다.
//
// 규칙은 셋뿐이다.
//   ① 기간은 항상 AND (periods 안에서만 OR)
//   ② 제외(빼고)는 항상 AND — match 와 무관하게 먼저 걸러진다
//   ③ 포함 조건은 켜진 것만 보고, all 이면 전부 / any 면 하나라도
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/expense/domain/expense_filter.dart';

/// 식비(1)·카페(2) 카테고리, S통장(10)·S카드(11) 계좌를 쓴다.
FilterRow row({
  String date = '2026-09-10',
  int amount = 30000,
  String? type = 'EXPENSE',
  List<int> categoryIds = const [1],
  List<int> assetIds = const [10],
}) => FilterRow(
  date: date,
  amount: amount,
  type: type,
  categoryIds: categoryIds,
  assetIds: assetIds,
);

const sep = FilterPeriodRange(
  preset: FilterPeriodPreset.custom,
  start: '2026-09-01',
  end: '2026-09-30',
);
const aug = FilterPeriodRange(
  preset: FilterPeriodPreset.custom,
  start: '2026-08-01',
  end: '2026-08-31',
);

void main() {
  group('① 기간은 항상 AND', () {
    test('periods 가 비면 기간 조건 없음 — 통과', () {
      expect(matchesFilter(row(), const ExpenseFilter()), isTrue);
    });

    test('11 · 기간 여러 개 — 둘 중 하나에 들면 통과', () {
      const f = ExpenseFilter(periods: [sep, aug]);
      expect(matchesFilter(row(date: '2026-09-10'), f), isTrue);
      expect(matchesFilter(row(date: '2026-08-15'), f), isTrue);
      expect(matchesFilter(row(date: '2026-07-31'), f), isFalse);
    });

    test('any 여도 기간은 AND — 기간 밖이면 다른 조건이 맞아도 빠진다', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        periods: [sep],
        categories: IncludeExclude(include: {1}),
      );
      expect(matchesFilter(row(date: '2026-08-15'), f), isFalse);
    });
  });

  group('② 제외는 항상 AND', () {
    test('12 · 카테고리 빼고 — match 와 무관하게 빠진다', () {
      for (final m in MatchMode.values) {
        final f = ExpenseFilter(
          match: m,
          categories: const IncludeExclude(exclude: {1}),
        );
        expect(matchesFilter(row(categoryIds: const [1]), f), isFalse);
        expect(matchesFilter(row(categoryIds: const [2]), f), isTrue);
      }
    });

    test('12 · 계좌 빼고', () {
      const f = ExpenseFilter(assets: IncludeExclude(exclude: {10}));
      expect(matchesFilter(row(assetIds: const [10]), f), isFalse);
      expect(matchesFilter(row(assetIds: const [11]), f), isTrue);
    });

    test('분할은 항목 중 하나라도 제외면 뺀다', () {
      const f = ExpenseFilter(categories: IncludeExclude(exclude: {2}));
      // 거래는 식비(1)인데 분할 항목에 카페(2)가 섞여 있다.
      expect(matchesFilter(row(categoryIds: const [1, 2]), f), isFalse);
    });

    test('포함과 제외가 같이 걸리면 제외가 이긴다', () {
      const f = ExpenseFilter(
        categories: IncludeExclude(include: {1}, exclude: {2}),
      );
      expect(matchesFilter(row(categoryIds: const [1, 2]), f), isFalse);
    });
  });

  group('③ 포함 — all(모두 일치)', () {
    test('1 · 카테고리 여러 개는 칸 안에서 OR', () {
      const f = ExpenseFilter(categories: IncludeExclude(include: {1, 2}));
      expect(matchesFilter(row(categoryIds: const [2]), f), isTrue);
      expect(matchesFilter(row(categoryIds: const [3]), f), isFalse);
    });

    test('2 · 계좌 여러 개도 OR', () {
      const f = ExpenseFilter(assets: IncludeExclude(include: {10, 11}));
      expect(matchesFilter(row(assetIds: const [11]), f), isTrue);
      expect(matchesFilter(row(assetIds: const [12]), f), isFalse);
    });

    test('칸 사이는 AND — 카테고리와 계좌 둘 다 맞아야 한다', () {
      const f = ExpenseFilter(
        categories: IncludeExclude(include: {1}),
        assets: IncludeExclude(include: {10}),
      );
      expect(
        matchesFilter(row(categoryIds: const [1], assetIds: const [10]), f),
        isTrue,
      );
      expect(
        matchesFilter(row(categoryIds: const [1], assetIds: const [11]), f),
        isFalse,
      );
    });

    test('10 · 금액 구간 두 개 — 소액이거나 고액', () {
      const f = ExpenseFilter(
        amountRanges: [AmountRange(max: 5000), AmountRange(min: 100000)],
      );
      expect(matchesFilter(row(amount: 3000), f), isTrue);
      expect(matchesFilter(row(amount: 150000), f), isTrue);
      expect(matchesFilter(row(amount: 30000), f), isFalse);
    });

    test('종류는 하나만 골랐을 때만 조건이 된다', () {
      expect(matchesFilter(row(type: 'INCOME'), const ExpenseFilter()), isTrue);
      expect(
        matchesFilter(
          row(type: 'INCOME'),
          const ExpenseFilter(types: {'EXPENSE'}),
        ),
        isFalse,
      );
    });
  });

  group('③ 포함 — any(하나라도 일치)', () {
    final anyRow = row(
      categoryIds: const [2],
      assetIds: const [11],
      amount: 70000,
    );

    test('3 · 카테고리 또는 계좌', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        categories: IncludeExclude(include: {2}),
        assets: IncludeExclude(include: {99}),
      );
      expect(matchesFilter(anyRow, f), isTrue);
    });

    test('4 · 카테고리 또는 금액', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        categories: IncludeExclude(include: {1}),
        amountRanges: [AmountRange(min: 50000)],
      );
      // 카테고리는 안 맞지만(2) 금액이 맞는다(70000).
      expect(matchesFilter(anyRow, f), isTrue);
    });

    test('5 · 계좌 또는 금액', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        assets: IncludeExclude(include: {11}),
        amountRanges: [AmountRange(min: 1000000)],
      );
      expect(matchesFilter(anyRow, f), isTrue);
    });

    test('6 · 종류 또는 카테고리 — 수입 전부 + 지출 중 월세만', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        types: {'INCOME'},
        categories: IncludeExclude(include: {7}),
      );
      expect(
        matchesFilter(row(type: 'INCOME', categoryIds: const [3]), f),
        isTrue,
      );
      expect(
        matchesFilter(row(type: 'EXPENSE', categoryIds: const [7]), f),
        isTrue,
      );
      expect(
        matchesFilter(row(type: 'EXPENSE', categoryIds: const [3]), f),
        isFalse,
      );
    });

    test('7 · 종류 또는 계좌', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        types: {'INCOME'},
        assets: IncludeExclude(include: {11}),
      );
      expect(
        matchesFilter(row(type: 'EXPENSE', assetIds: const [11]), f),
        isTrue,
      );
    });

    test('8 · 종류 또는 금액', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        types: {'INCOME'},
        amountRanges: [AmountRange(min: 50000)],
      );
      expect(matchesFilter(row(type: 'EXPENSE', amount: 70000), f), isTrue);
      expect(matchesFilter(row(type: 'EXPENSE', amount: 1000), f), isFalse);
    });

    test('9 · 세 필드 이상 — 카페이거나 S카드이거나 5만원 이상', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        categories: IncludeExclude(include: {2}),
        assets: IncludeExclude(include: {11}),
        amountRanges: [AmountRange(min: 50000)],
      );
      expect(
        matchesFilter(
          row(categoryIds: const [9], assetIds: const [99], amount: 60000),
          f,
        ),
        isTrue,
      );
      expect(
        matchesFilter(
          row(categoryIds: const [9], assetIds: const [99], amount: 100),
          f,
        ),
        isFalse,
      );
    });
  });

  group('④ 이체 — 종류·카테고리 개념이 없다', () {
    FilterRow transfer() =>
        row(type: null, categoryIds: const [], assetIds: const [10, 11]);

    test('13 · all 에서 카테고리를 고르면 이체는 빠진다 — 규칙의 결과다', () {
      const f = ExpenseFilter(categories: IncludeExclude(include: {1}));
      expect(matchesFilter(transfer(), f), isFalse);
    });

    test('13 · any 에서는 계좌로 이체가 나온다', () {
      const f = ExpenseFilter(
        match: MatchMode.any,
        categories: IncludeExclude(include: {1}),
        assets: IncludeExclude(include: {11}),
      );
      expect(matchesFilter(transfer(), f), isTrue);
    });

    test('계좌 조건은 보내는 쪽·받는 쪽 둘 다 본다', () {
      expect(
        matchesFilter(
          transfer(),
          const ExpenseFilter(assets: IncludeExclude(include: {10})),
        ),
        isTrue,
      );
      expect(
        matchesFilter(
          transfer(),
          const ExpenseFilter(assets: IncludeExclude(include: {11})),
        ),
        isTrue,
      );
      expect(
        matchesFilter(
          transfer(),
          const ExpenseFilter(assets: IncludeExclude(include: {12})),
        ),
        isFalse,
      );
    });

    test('조건이 하나도 없으면 이체도 그대로 나온다', () {
      expect(matchesFilter(transfer(), const ExpenseFilter()), isTrue);
    });

    test('종류를 하나 고르면 이체는 빠진다', () {
      expect(
        matchesFilter(transfer(), const ExpenseFilter(types: {'EXPENSE'})),
        isFalse,
      );
    });
  });

  group('⑤ 14 · 분할 거래', () {
    test('분할 항목 중 하나라도 맞으면 나온다', () {
      const f = ExpenseFilter(categories: IncludeExclude(include: {2}));
      expect(matchesFilter(row(categoryIds: const [1, 2]), f), isTrue);
    });
  });

  group('배지·범위 계산', () {
    test('켜진 조건 수를 센다 — 종류는 하나만 골랐을 때만', () {
      expect(activeConditionCount(const ExpenseFilter()), 0);
      expect(activeConditionCount(const ExpenseFilter(types: {'EXPENSE'})), 1);
      expect(
        activeConditionCount(
          const ExpenseFilter(
            types: {'EXPENSE'},
            categories: IncludeExclude(include: {1}),
            assets: IncludeExclude(include: {10}),
            amountRanges: [AmountRange(min: 1)],
          ),
        ),
        4,
      );
    });

    test('제외만 걸린 것은 조건 수에 안 센다 — 포함 조건이 아니다', () {
      expect(
        activeConditionCount(
          const ExpenseFilter(categories: IncludeExclude(exclude: {1})),
        ),
        0,
      );
    });

    test('조회 범위는 기간들의 최소~최대', () {
      final span = filterSpan(const ExpenseFilter(periods: [sep, aug]));
      expect(span?.start, '2026-08-01');
      expect(span?.end, '2026-09-30');
      expect(filterSpan(const ExpenseFilter()), isNull);
    });
  });

  group('칩 3상태', () {
    test('고름 → 빼고 → 해제', () {
      var v = const IncludeExclude();
      v = v.cycle(1);
      expect(v.include, {1});
      v = v.cycle(1);
      expect(v.include, isEmpty);
      expect(v.exclude, {1});
      v = v.cycle(1);
      expect(v.isEmpty, isTrue);
    });
  });

  // 필터의 기본 기간은 보고 있는 달이다(QA 30 10, 웹 monthPeriodOf 와 같다). 기간 하나만 바꿔
  // 걸어도 배지가 뜨려면 "보고 있는 달과 같은가" 를 날짜로 비교할 수 있어야 한다.
  group('보고 있는 달의 기본 기간', () {
    test('지난 달이면 그 달 1일~말일(직접 입력 기간)', () {
      final p = monthPeriodOf(DateTime(2000, 2, 1));
      expect(p.preset, FilterPeriodPreset.custom);
      expect((p.start, p.end), ('2000-02-01', '2000-02-29'));
    });

    test('이번 달이면 종전과 같은 "이번 달"(1일~오늘)', () {
      final now = DateTime.now();
      final p = monthPeriodOf(DateTime(now.year, now.month, 1));
      expect(p.preset, FilterPeriodPreset.month);
      expect(samePeriod(p, resolvePeriod(FilterPeriodPreset.month)), isTrue);
    });

    test('같은 날들이면 프리셋 이름이 달라도 같은 기간이다', () {
      const a = FilterPeriodRange(
        preset: FilterPeriodPreset.month,
        start: '2026-09-01',
        end: '2026-09-25',
      );
      const b = FilterPeriodRange(
        preset: FilterPeriodPreset.custom,
        start: '2026-09-01',
        end: '2026-09-25',
      );
      expect(samePeriod(a, b), isTrue);
    });
  });
}
