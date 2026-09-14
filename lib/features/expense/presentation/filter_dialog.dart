import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_category_tile.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/shared/widgets/p_toggle.dart';
import 'package:porest_desk_app/shared/widgets/p_type_chip.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_filter.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

Future<ExpenseFilter?> showFilterDialog(
  BuildContext context,
  ExpenseFilter current,
) async {
  final controller = PSheetController();
  final formKey = GlobalKey<_FilterBodyState>();
  final l = AppLocalizations.of(context);
  return showPSheet<ExpenseFilter>(
    context,
    title: l.expFilter,
    contentBuilder: (ctx, scrollCtrl) => _FilterBody(
      key: formKey,
      initial: current,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    // 표준 PSheetFooter — 좌측이 삭제가 아니라 '초기화'(비파괴)라 leftSlot 으로 주입.
    // 취소는 빼고 우상단 X 에 맡긴다 — [초기화][적용] 2개(spec drawer.md 액션 구성).
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.expFilterApply,
      leftSlot: PButton(
        label: l.actionReset,
        // ghost 는 배경이 없어 전체 폭 배치에서 버튼으로 안 보인다 — 테두리 없는
        // 회색 채움(spec button.md Migration notes 2026-08).
        variant: PButtonVariant.secondary,
        size: PButtonSize.lg,
        fullWidth: true,
        onPressed: () => formKey.currentState?._reset(),
      ),
    ),
  ).whenComplete(controller.dispose);
}

class _FilterBody extends ConsumerStatefulWidget {
  const _FilterBody({
    super.key,
    required this.initial,
    required this.scrollController,
    required this.controller,
  });
  final ExpenseFilter initial;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends ConsumerState<_FilterBody> {
  late MatchMode _match;
  late List<FilterPeriodRange> _periods;
  late Set<String> _types;
  late IncludeExclude _cats;
  late IncludeExclude _accs;

  /// 금액 구간 칸마다 컨트롤러 두 개(최소·최대).
  late List<(TextEditingController, TextEditingController)> _amounts;

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _ymd(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  @override
  void initState() {
    super.initState();
    _match = widget.initial.match;
    _periods = widget.initial.periods.isEmpty
        ? [resolvePeriod(FilterPeriodPreset.month)]
        : [...widget.initial.periods];
    _types = {...widget.initial.types};
    _cats = widget.initial.categories;
    _accs = widget.initial.assets;
    _amounts = [
      for (final r in widget.initial.amountRanges)
        (
          TextEditingController(text: r.min?.toString() ?? ''),
          TextEditingController(text: r.max?.toString() ?? ''),
        ),
    ];
    widget.controller.onSubmit = () async => _apply();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.setCanSubmit(!_badPeriod),
    );
  }

  @override
  void dispose() {
    for (final (mn, mx) in _amounts) {
      mn.dispose();
      mx.dispose();
    }
    super.dispose();
  }

  bool get _badPeriod => _periods.any(
    (p) =>
        p.start.isNotEmpty && p.end.isNotEmpty && p.start.compareTo(p.end) > 0,
  );

  /// 켜진 포함 조건 수 — 조건이 하나뿐이면 all/any 가 같은 결과라 세그먼트를 잠근다.
  int get _conditionCount => activeConditionCount(_draft());

  ExpenseFilter _draft() => ExpenseFilter(
    match: _match,
    periods: _periods,
    types: _types,
    categories: _cats,
    assets: _accs,
    amountRanges: [
      for (final (mn, mx) in _amounts)
        AmountRange(min: int.tryParse(mn.text), max: int.tryParse(mx.text)),
    ],
  );

  void _reset() {
    setState(() {
      _match = MatchMode.all;
      _periods = [resolvePeriod(FilterPeriodPreset.month)];
      _types = {'EXPENSE', 'INCOME'};
      _cats = const IncludeExclude();
      _accs = const IncludeExclude();
      for (final (mn, mx) in _amounts) {
        mn.dispose();
        mx.dispose();
      }
      _amounts = [];
    });
  }

  void _apply() {
    final d = _draft();
    Navigator.of(context).pop(
      // 조건이 하나뿐이면 any 를 골라 둔 것이 의미가 없다 — all 로 굳혀 보낸다.
      _conditionCount <= 1 ? d.copyWith(match: MatchMode.all) : d,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(!_badPeriod);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        _matchSection(t),
        const SizedBox(height: PSpace.x16),
        _periodSection(t),
        const SizedBox(height: PSpace.x16),
        _typeSection(t),
        const SizedBox(height: PSpace.x16),
        _categorySection(t),
        const SizedBox(height: PSpace.x16),
        _assetSection(t),
        const SizedBox(height: PSpace.x16),
        _amountSection(t),
      ],
    );
  }

  Widget _label(
    String text,
    PorestTokens t, {
    String? badge,
    String? exclBadge,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: PTypo.bodySm.copyWith(
              color: t.fgSecondary,
              fontWeight: PFontWeight.semi,
            ),
          ),
          if (badge != null && badge.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              badge,
              style: PTypo.bodySm.copyWith(
                color: t.fgBrandStrong,
                fontWeight: PFontWeight.semi,
              ),
            ),
          ],
          if (exclBadge != null && exclBadge.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              exclBadge,
              style: PTypo.bodySm.copyWith(
                color: t.fgExpense,
                fontWeight: PFontWeight.semi,
              ),
            ),
          ],
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hint,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 조건을 어떻게 묶을지 — 기간·'빼고' 는 여기에 안 걸린다(항상 함께 적용).
  Widget _matchSection(PorestTokens t) {
    final l = AppLocalizations.of(context);
    final locked = _conditionCount <= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.expFilterMatch, t),
        Opacity(
          opacity: locked ? 0.5 : 1,
          child: IgnorePointer(
            ignoring: locked,
            child: PTabs<MatchMode>(
              value: locked ? MatchMode.all : _match,
              onChanged: (v) => setState(() => _match = v),
              variant: PTabsVariant.container,
              size: PTabsSize.sm,
              expand: true,
              items: [
                PTabItem(value: MatchMode.all, label: l.expFilterMatchAll),
                PTabItem(value: MatchMode.any, label: l.expFilterMatchAny),
              ],
            ),
          ),
        ),
        if (locked)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.expFilterMatchHint,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ),
      ],
    );
  }

  Widget _periodSection(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.expFilterPeriod, t),
        for (var i = 0; i < _periods.length; i++) ...[
          if (i > 0) const SizedBox(height: PSpace.x12),
          Row(
            children: [
              Expanded(
                child: PTabs<FilterPeriodPreset>(
                  value: _periods[i].preset,
                  onChanged: (v) =>
                      setState(() => _periods[i] = resolvePeriod(v)),
                  variant: PTabsVariant.container,
                  size: PTabsSize.sm,
                  expand: true,
                  items: [
                    PTabItem(
                      value: FilterPeriodPreset.week,
                      label: l.expPeriodWeek,
                    ),
                    PTabItem(
                      value: FilterPeriodPreset.month,
                      label: l.expThisMonth,
                    ),
                    PTabItem(
                      value: FilterPeriodPreset.threeMonth,
                      label: l.expPeriod3Month,
                    ),
                    PTabItem(
                      value: FilterPeriodPreset.custom,
                      label: l.expPeriodCustom,
                    ),
                  ],
                ),
              ),
              if (_periods.length > 1)
                IconButton(
                  icon: Icon(LucideIcons.x, size: 16, color: t.fgTertiary),
                  tooltip: l.expFilterRemoveRow,
                  onPressed: () => setState(() => _periods.removeAt(i)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PDateInput(
                  value: DateTime.tryParse(_periods[i].start),
                  onChanged: (d) {
                    if (d == null) return;
                    setState(
                      () => _periods[i] = _periods[i].copyWith(
                        preset: FilterPeriodPreset.custom,
                        start: _ymd(d),
                      ),
                    );
                  },
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  placeholder: l.expStartDate,
                ),
              ),
              const SizedBox(width: 8),
              Text('~', style: PTypo.body.copyWith(color: t.fgTertiary)),
              const SizedBox(width: 8),
              Expanded(
                child: PDateInput(
                  value: DateTime.tryParse(_periods[i].end),
                  onChanged: (d) {
                    if (d == null) return;
                    setState(
                      () => _periods[i] = _periods[i].copyWith(
                        preset: FilterPeriodPreset.custom,
                        end: _ymd(d),
                      ),
                    );
                  },
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  placeholder: l.expEndDate,
                ),
              ),
            ],
          ),
        ],
        if (_badPeriod)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.expDateRangeError,
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.expFilterPeriodAlwaysAnd,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ),
              if (_periods.length < ExpenseFilter.maxPeriods)
                PButton(
                  label: l.expFilterAddPeriod,
                  variant: PButtonVariant.ghost,
                  size: PButtonSize.sm,
                  onPressed: () => setState(
                    () => _periods.add(resolvePeriod(FilterPeriodPreset.month)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeSection(PorestTokens t) {
    void toggle(String code) => setState(() {
      if (_types.contains(code)) {
        _types.remove(code);
      } else {
        _types.add(code);
      }
    });
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.expTxType, t),
        Row(
          children: [
            Expanded(
              child: PTypeChip(
                label: l.expTypeExpense,
                active: _types.contains('EXPENSE'),
                activeColor: t.fgExpense,
                onTap: () => toggle('EXPENSE'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PTypeChip(
                label: l.expTypeIncome,
                active: _types.contains('INCOME'),
                activeColor: t.fgIncome,
                onTap: () => toggle('INCOME'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categorySection(PorestTokens t) {
    final l = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final parents = categories.where((c) => c.parentRowId == null).toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    if (parents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(
          l.expCategory,
          t,
          badge: _cats.include.isEmpty
              ? null
              : '· ${l.expNSelected(_cats.include.length)}',
          exclBadge: _cats.exclude.isEmpty
              ? null
              : '· ${l.expFilterExcluded(_cats.exclude.length)}',
          hint: l.expFilterChipLegend,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 6.0;
            const columns = 5;
            final cellWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final c in parents)
                  SizedBox(
                    width: cellWidth,
                    child: PCategoryTile(
                      name: c.categoryName,
                      color: resolveChartColor(
                        context,
                        c.color,
                        fallback: t.fgBrand,
                      ),
                      icon: lucideByName(c.icon, fallback: LucideIcons.tag),
                      active: _cats.include.contains(c.rowId),
                      excluded: _cats.exclude.contains(c.rowId),
                      onTap: () => setState(() => _cats = _cats.cycle(c.rowId)),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _assetSection(PorestTokens t) {
    final l = AppLocalizations.of(context);
    final assets = ref.watch(assetsProvider).value ?? const [];
    if (assets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(
          l.expAccountCard,
          t,
          badge: _accs.include.isEmpty
              ? null
              : '· ${l.expNSelected(_accs.include.length)}',
          exclBadge: _accs.exclude.isEmpty
              ? null
              : '· ${l.expFilterExcluded(_accs.exclude.length)}',
          hint: l.expFilterChipLegend,
        ),
        // 다중선택 필터 칩 — spec toggle.md: outline PToggle + radius-md(둥근 사각형). pill 아님.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in assets)
              // '빼고' 는 PToggle 에 상태가 없어 이름에 취소선으로 표시한다.
              if (_accs.exclude.contains(a.rowId))
                GestureDetector(
                  onTap: () => setState(() => _accs = _accs.cycle(a.rowId)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PSpace.x12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: t.statusDangerSubtle,
                      border: Border.all(color: t.statusDanger),
                      borderRadius: PRadius.brMd,
                    ),
                    child: Text(
                      a.assetName,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgExpense,
                        fontWeight: PFontWeight.semi,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: t.fgExpense,
                      ),
                    ),
                  ),
                )
              else
                PToggle(
                  label: a.assetName,
                  variant: PToggleVariant.outline,
                  size: PToggleSize.sm,
                  pressed: _accs.include.contains(a.rowId),
                  onChanged: (_) =>
                      setState(() => _accs = _accs.cycle(a.rowId)),
                ),
          ],
        ),
      ],
    );
  }

  Widget _amountSection(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.expAmountRange, t),
        for (var i = 0; i < _amounts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: PTextInput(
                    controller: _amounts[i].$1,
                    placeholder: l.expMinAmount,
                    numbersOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                Text('~', style: PTypo.body.copyWith(color: t.fgTertiary)),
                const SizedBox(width: 8),
                Expanded(
                  child: PTextInput(
                    controller: _amounts[i].$2,
                    placeholder: l.expMaxAmount,
                    numbersOnly: true,
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 16, color: t.fgTertiary),
                  tooltip: l.expFilterRemoveRow,
                  onPressed: () => setState(() {
                    final (mn, mx) = _amounts.removeAt(i);
                    mn.dispose();
                    mx.dispose();
                  }),
                ),
              ],
            ),
          ),
        if (_amounts.length < ExpenseFilter.maxAmountRanges)
          PButton(
            label: l.expFilterAddAmountRange,
            variant: PButtonVariant.ghost,
            size: PButtonSize.sm,
            onPressed: () => setState(
              () => _amounts.add((
                TextEditingController(),
                TextEditingController(),
              )),
            ),
          ),
      ],
    );
  }
}
