/// 가계부 필터의 모양·기본값·평가 규칙 — 웹 `features/expense/model/filter.ts` 미러.
///
/// **진리표는 양쪽이 같은 표를 쓴다**(`filter-combos.md` 의 15줄). 한쪽만 고치면
/// 같은 필터가 두 화면에서 다른 결과를 낸다 — 그래서 테스트 이름에 조합 번호를
/// 박아 두었다.
library;

/// 포함 조건들을 모두 만족(all) / 하나라도 만족(any). 기간·제외는 항상 AND.
enum MatchMode { all, any }

enum FilterPeriodPreset { week, month, threeMonth, custom }

/// 기간 한 칸. preset 이 custom 이 아니어도 start·end 를 계산해 채워 둔다.
class FilterPeriodRange {
  const FilterPeriodRange({
    required this.preset,
    required this.start,
    required this.end,
  });

  final FilterPeriodPreset preset;

  /// 'YYYY-MM-DD'
  final String start;
  final String end;

  FilterPeriodRange copyWith({
    FilterPeriodPreset? preset,
    String? start,
    String? end,
  }) => FilterPeriodRange(
    preset: preset ?? this.preset,
    start: start ?? this.start,
    end: end ?? this.end,
  );
}

/// 칩 3상태 — 고르면 include, 한 번 더 누르면 exclude, 또 누르면 해제.
class IncludeExclude {
  const IncludeExclude({this.include = const {}, this.exclude = const {}});

  final Set<int> include;
  final Set<int> exclude;

  bool get isEmpty => include.isEmpty && exclude.isEmpty;

  /// 고름 → 빼고 → 해제.
  IncludeExclude cycle(int id) {
    if (include.contains(id)) {
      return IncludeExclude(
        include: {...include}..remove(id),
        exclude: {...exclude, id},
      );
    }
    if (exclude.contains(id)) {
      return IncludeExclude(
        include: include,
        exclude: {...exclude}..remove(id),
      );
    }
    return IncludeExclude(include: {...include, id}, exclude: exclude);
  }

  IncludeExclude copyWith({Set<int>? include, Set<int>? exclude}) =>
      IncludeExclude(
        include: include ?? this.include,
        exclude: exclude ?? this.exclude,
      );
}

/// 금액 구간 한 칸. null 은 '제한 없음'.
class AmountRange {
  const AmountRange({this.min, this.max});
  final int? min;
  final int? max;
}

class ExpenseFilter {
  const ExpenseFilter({
    this.match = MatchMode.all,
    this.periods = const [],
    this.types = const {'EXPENSE', 'INCOME'},
    this.categories = const IncludeExclude(),
    this.assets = const IncludeExclude(),
    this.amountRanges = const [],
  });

  final MatchMode match;

  /// 1~3칸. 칸 사이는 OR 이고, 기간 자체는 **항상** 다른 조건과 AND 다.
  final List<FilterPeriodRange> periods;
  final Set<String> types;
  final IncludeExclude categories;
  final IncludeExclude assets;

  /// 0~3칸, 칸 사이 OR.
  final List<AmountRange> amountRanges;

  static const int maxPeriods = 3;
  static const int maxAmountRanges = 3;

  bool get isEmpty =>
      categories.isEmpty &&
      assets.isEmpty &&
      types.length == 2 &&
      amountRanges.isEmpty &&
      periods.length <= 1;

  ExpenseFilter copyWith({
    MatchMode? match,
    List<FilterPeriodRange>? periods,
    Set<String>? types,
    IncludeExclude? categories,
    IncludeExclude? assets,
    List<AmountRange>? amountRanges,
  }) => ExpenseFilter(
    match: match ?? this.match,
    periods: periods ?? this.periods,
    types: types ?? this.types,
    categories: categories ?? this.categories,
    assets: assets ?? this.assets,
    amountRanges: amountRanges ?? this.amountRanges,
  );
}

/// 필터가 판정하는 한 줄. 거래와 이체를 **같은 모양으로** 눕혀 하나의 술어로 본다.
///
/// - [type] 이 null 이면 이체다. 종류·카테고리 조건은 이체에 거짓이 된다.
/// - [categoryIds] 에는 거래 카테고리와 **분할 항목 카테고리**가 함께 들어간다.
///   그래서 포함은 "하나라도 맞으면", 제외는 "하나라도 걸리면" 이 자연히 된다.
/// - [assetIds] 는 거래면 한 개, 이체면 보내는 쪽·받는 쪽 두 개다.
class FilterRow {
  const FilterRow({
    required this.date,
    required this.amount,
    required this.type,
    this.categoryIds = const [],
    this.assetIds = const [],
  });

  /// 'YYYY-MM-DD'
  final String date;
  final int amount;
  final String? type;
  final List<int> categoryIds;
  final List<int> assetIds;
}

bool _overlaps(Iterable<int> a, Set<int> b) =>
    b.isNotEmpty && a.any(b.contains);

bool _inAnyPeriod(String date, List<FilterPeriodRange> periods) {
  if (periods.isEmpty) return true;
  return periods.any(
    (p) =>
        (p.start.isEmpty || date.compareTo(p.start) >= 0) &&
        (p.end.isEmpty || date.compareTo(p.end) <= 0),
  );
}

bool _inAnyAmountRange(int amount, List<AmountRange> ranges) => ranges.any((r) {
  if (r.min != null && amount < r.min!) return false;
  if (r.max != null && amount > r.max!) return false;
  return true;
});

/// 종류 조건은 **하나만 고른 경우에만** 활성이다(둘 다 = 조건 없음).
bool _typeActive(Set<String> types) => types.length == 1;

/// 지금 켜져 있는 포함 조건의 개수 — 배지와 '하나라도' 세그먼트 활성에 쓴다.
int activeConditionCount(ExpenseFilter f) {
  var n = 0;
  if (_typeActive(f.types)) n += 1;
  if (f.categories.include.isNotEmpty) n += 1;
  if (f.assets.include.isNotEmpty) n += 1;
  if (f.amountRanges.isNotEmpty) n += 1;
  return n;
}

/// 한 줄이 필터를 통과하는가.
///
/// 순서가 규칙이다.
///   ① 기간 — periods 중 하나에 들어야 한다. **항상 AND.**
///   ② 제외 — 카테고리·계좌 exclude 에 하나라도 걸리면 뺀다. **항상 AND.**
///   ③ 포함 — 켜져 있는 조건만 본다. match=all 이면 전부, any 면 하나라도.
///      켜진 조건이 하나도 없으면 통과다.
bool matchesFilter(FilterRow row, ExpenseFilter f) {
  if (!_inAnyPeriod(row.date, f.periods)) return false;

  if (_overlaps(row.categoryIds, f.categories.exclude)) return false;
  if (_overlaps(row.assetIds, f.assets.exclude)) return false;

  final checks = <bool>[];
  if (_typeActive(f.types)) {
    // 이체(type null)는 종류 개념이 없다 — 거짓.
    checks.add(row.type != null && f.types.contains(row.type));
  }
  if (f.categories.include.isNotEmpty) {
    // 이체는 카테고리가 없으므로 categoryIds 가 비어 자연히 거짓이다.
    checks.add(_overlaps(row.categoryIds, f.categories.include));
  }
  if (f.assets.include.isNotEmpty) {
    checks.add(_overlaps(row.assetIds, f.assets.include));
  }
  if (f.amountRanges.isNotEmpty) {
    checks.add(_inAnyAmountRange(row.amount, f.amountRanges));
  }

  if (checks.isEmpty) return true;
  return f.match == MatchMode.all
      ? checks.every((x) => x)
      : checks.any((x) => x);
}

/// 조회에 쓸 바깥 범위 — periods 의 최소 시작 ~ 최대 종료.
({String start, String end})? filterSpan(ExpenseFilter f) {
  final withRange = f.periods
      .where((p) => p.start.isNotEmpty && p.end.isNotEmpty)
      .toList();
  if (withRange.isEmpty) return null;
  var start = withRange.first.start;
  var end = withRange.first.end;
  for (final p in withRange) {
    if (p.start.compareTo(start) < 0) start = p.start;
    if (p.end.compareTo(end) > 0) end = p.end;
  }
  return (start: start, end: end);
}

String _pad(int n) => n.toString().padLeft(2, '0');
String _ymd(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

/// 프리셋을 실제 범위로 바꾼다 — 웹 `resolvePeriod` 미러.
///
/// v1 은 프리셋 이름만 들고 다니다 화면에서 범위를 계산했다. v2 는 기간이 여러
/// 칸이라 **칸마다 범위를 확정해 둔다** — 조회 범위(최소~최대)를 한 번에 내려면
/// 프리셋이 아니라 날짜가 필요하다.
FilterPeriodRange resolvePeriod(FilterPeriodPreset preset) {
  final today = DateTime.now();
  final end = _ymd(today);
  switch (preset) {
    case FilterPeriodPreset.week:
      // 월요일 시작.
      final s = today.subtract(Duration(days: today.weekday - 1));
      return FilterPeriodRange(preset: preset, start: _ymd(s), end: end);
    case FilterPeriodPreset.month:
      return FilterPeriodRange(
        preset: preset,
        start: _ymd(DateTime(today.year, today.month, 1)),
        end: end,
      );
    case FilterPeriodPreset.threeMonth:
      return FilterPeriodRange(
        preset: preset,
        start: _ymd(DateTime(today.year, today.month - 3, today.day)),
        end: end,
      );
    case FilterPeriodPreset.custom:
      return FilterPeriodRange(
        preset: preset,
        start: _ymd(DateTime(today.year, today.month - 1, today.day)),
        end: end,
      );
  }
}
