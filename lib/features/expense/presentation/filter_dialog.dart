import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/expense/domain/expense_filter.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/filter_bodies.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

/// 폰 거르기 — ds Bottom Sheet 하나에 조건 본문 여섯을 차례로 쌓는다(I-07 18 · 구조 그대로: 조건을 한 시트에서 함께 고친다).
///
/// 폼 시트라 바깥을 눌러도 닫히지 않고, 머리 ✕ 는 바꾼 것을 버리고 닫는다. 바닥은 "초기화"(왼쪽) · "필터 적용"(오른쪽) 반씩 —
/// bottom-sheet.md "둘을 나란히 둘 때는 보조(초기화)를 왼쪽, 주 버튼을 오른쪽에 반씩". 기간이 틀리면(시작 > 끝) "필터 적용" 이
/// 막힌다. 본문이 넘치면 본문만 스크롤하고 끝은 Scroll Fog 가 흐린다.
Future<ExpenseFilter?> showFilterDialog(
  BuildContext context,
  ExpenseFilter current, {

  /// 보고 있는 달의 기간 — 처음 열 때와 초기화에 쓴다(`monthPeriodOf`). 없으면 이번 달.
  FilterPeriodRange? defaultPeriod,
}) {
  return PBottomSheet.show<ExpenseFilter>(
    context,
    form: true,
    builder: (_) =>
        _FilterSheet(initial: current, defaultPeriod: defaultPeriod),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, this.defaultPeriod});

  final ExpenseFilter initial;
  final FilterPeriodRange? defaultPeriod;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late MatchMode _match;
  late List<FilterPeriodRange> _periods;
  late Set<String> _types;
  late IncludeExclude _cats;
  late IncludeExclude _accs;
  late List<AmountRange> _amounts;

  /// 초기화 때 올려 금액 본문의 칸 글을 새로 만든다.
  int _epoch = 0;

  FilterPeriodRange get _defaultPeriod =>
      widget.defaultPeriod ?? resolvePeriod(FilterPeriodPreset.month);

  @override
  void initState() {
    super.initState();
    _match = widget.initial.match;
    _periods = widget.initial.periods.isEmpty
        ? [_defaultPeriod]
        : [...widget.initial.periods];
    _types = {...widget.initial.types};
    _cats = widget.initial.categories;
    _accs = widget.initial.assets;
    _amounts = [...widget.initial.amountRanges];
  }

  bool get _badPeriod => _periods.any(FilterPeriodBody.isBad);

  ExpenseFilter _draft() => ExpenseFilter(
    match: _match,
    periods: _periods,
    // 둘 다 끄면 둘 다 켠 것과 같다 — 빈 집합을 내보내지 않는다.
    types: _types.isEmpty ? const {'EXPENSE', 'INCOME'} : _types,
    categories: _cats,
    assets: _accs,
    amountRanges: _amounts,
  );

  /// 켜진 포함 조건 수 — 조건이 하나 이하면 모두 · 하나라도가 같은 결과라 조건 맞추기를 막는다.
  int get _conditionCount => activeConditionCount(_draft());

  void _reset() {
    setState(() {
      _match = MatchMode.all;
      _periods = [_defaultPeriod];
      _types = {'EXPENSE', 'INCOME'};
      _cats = const IncludeExclude();
      _accs = const IncludeExclude();
      _amounts = [];
      _epoch++;
    });
  }

  void _apply(BuildContext sheetContext) {
    final d = _draft();
    // 조건이 하나 이하면 any 를 골라 둔 것이 의미가 없다 — all 로 굳혀 보낸다.
    PBottomSheet.of(
      sheetContext,
    ).close(_conditionCount <= 1 ? d.copyWith(match: MatchMode.all) : d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const gap = SizedBox(height: PSpacing.x6);
    return PBottomSheetContent(
      title: l.expFilter,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterMatchBody(
            value: _match,
            conditionCount: _conditionCount,
            onChanged: (v) => setState(() => _match = v),
          ),
          gap,
          FilterPeriodBody(
            periods: _periods,
            onChanged: (v) => setState(() => _periods = v),
          ),
          gap,
          FilterTypeBody(
            types: _types,
            onChanged: (v) => setState(() => _types = v),
          ),
          gap,
          FilterCategoryBody(
            value: _cats,
            onChanged: (v) => setState(() => _cats = v),
          ),
          gap,
          FilterAssetBody(
            value: _accs,
            onChanged: (v) => setState(() => _accs = v),
          ),
          gap,
          FilterAmountBody(
            key: ValueKey('amount-$_epoch'),
            initial: _amounts,
            onChanged: (v) => setState(() => _amounts = v),
          ),
        ],
      ),
      footer: [
        PButton(
          label: l.actionReset,
          size: PButtonSize.large,
          variant: PButtonVariant.neutralWeak,
          onPressed: _reset,
        ),
        PButton(
          label: l.expFilterApply,
          size: PButtonSize.large,
          onPressed: _badPeriod ? null : () => _apply(context),
        ),
      ],
    );
  }
}
