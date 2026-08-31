import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 필터 기간 옵션 — front `FilterPeriod` 미러.
enum FilterPeriod { week, month, threeMonth, custom }

/// 거래 필터 — front `FilterValue` 미러.
///
/// v0.1: 클라이언트 사이드 필터 (월간 조회 결과를 화면에서 필터). 빈 값이면 "전체".
/// v0.2 에서 백엔드 query param 으로 이전 예정.
class ExpenseFilter {
  const ExpenseFilter({
    this.period = FilterPeriod.custom,
    this.startDate,
    this.endDate,
    this.types = const {'EXPENSE', 'INCOME'},
    this.categoryIds = const {},
    this.assetIds = const {},
    this.min,
    this.max,
  });

  final FilterPeriod period;
  final String? startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD
  final Set<String> types; // {'EXPENSE','INCOME'}
  final Set<int> categoryIds;
  final Set<int> assetIds;
  final int? min;
  final int? max;

  bool get isEmpty =>
      categoryIds.isEmpty &&
      assetIds.isEmpty &&
      types.length == 2 &&
      min == null &&
      max == null;

  ExpenseFilter copyWith({
    FilterPeriod? period,
    String? startDate,
    String? endDate,
    Set<String>? types,
    Set<int>? categoryIds,
    Set<int>? assetIds,
    int? min,
    int? max,
  }) => ExpenseFilter(
    period: period ?? this.period,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    types: types ?? this.types,
    categoryIds: categoryIds ?? this.categoryIds,
    assetIds: assetIds ?? this.assetIds,
    min: min ?? this.min,
    max: max ?? this.max,
  );
}

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
  late FilterPeriod _period;
  late String? _startDate;
  late String? _endDate;
  late Set<String> _types;
  late Set<int> _categoryIds;
  late Set<int> _assetIds;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _today() {
    final d = DateTime.now();
    return '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
  }

  String _today1MonthAgo() {
    final d = DateTime.now();
    final m = DateTime(d.year, d.month - 1, d.day);
    return '${m.year}-${_pad(m.month)}-${_pad(m.day)}';
  }

  @override
  void initState() {
    super.initState();
    _period = widget.initial.period;
    _startDate = widget.initial.startDate ?? _today1MonthAgo();
    _endDate = widget.initial.endDate ?? _today();
    _types = {...widget.initial.types};
    _categoryIds = {...widget.initial.categoryIds};
    _assetIds = {...widget.initial.assetIds};
    _minCtrl = TextEditingController(
      text: widget.initial.min?.toString() ?? '',
    );
    _maxCtrl = TextEditingController(
      text: widget.initial.max?.toString() ?? '',
    );
    widget.controller.onSubmit = () async => _apply();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.setCanSubmit(!_customInvalid),
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  bool get _customInvalid =>
      _period == FilterPeriod.custom &&
      (_startDate?.isNotEmpty ?? false) &&
      (_endDate?.isNotEmpty ?? false) &&
      (_startDate ?? '').compareTo(_endDate ?? '') > 0;

  void _reset() {
    setState(() {
      _period = FilterPeriod.custom;
      _startDate = '';
      _endDate = '';
      _types = {'EXPENSE', 'INCOME'};
      _categoryIds.clear();
      _assetIds.clear();
      _minCtrl.text = '';
      _maxCtrl.text = '';
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      ExpenseFilter(
        period: _period,
        startDate: _period == FilterPeriod.custom ? _startDate : null,
        endDate: _period == FilterPeriod.custom ? _endDate : null,
        types: _types,
        categoryIds: _categoryIds,
        assetIds: _assetIds,
        min: int.tryParse(_minCtrl.text),
        max: int.tryParse(_maxCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(!_customInvalid);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
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

  Widget _label(String text, PorestTokens t, {String? badge}) {
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
        ],
      ),
    );
  }

  Widget _periodSection(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l.expFilterPeriod, t),
        PTabs<FilterPeriod>(
          value: _period,
          onChanged: (v) => setState(() => _period = v),
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: [
            PTabItem(value: FilterPeriod.week, label: l.expPeriodWeek),
            PTabItem(value: FilterPeriod.month, label: l.expThisMonth),
            PTabItem(value: FilterPeriod.threeMonth, label: l.expPeriod3Month),
            PTabItem(value: FilterPeriod.custom, label: l.expPeriodCustom),
          ],
        ),
        if (_period == FilterPeriod.custom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PDateInput(
                  value: (_startDate?.isNotEmpty ?? false)
                      ? DateTime.tryParse(_startDate!)
                      : null,
                  onChanged: (d) {
                    if (d != null) {
                      setState(
                        () => _startDate =
                            '${d.year}-${_pad(d.month)}-${_pad(d.day)}',
                      );
                    }
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
                  value: (_endDate?.isNotEmpty ?? false)
                      ? DateTime.tryParse(_endDate!)
                      : null,
                  onChanged: (d) {
                    if (d != null) {
                      setState(
                        () => _endDate =
                            '${d.year}-${_pad(d.month)}-${_pad(d.day)}',
                      );
                    }
                  },
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  placeholder: l.expEndDate,
                ),
              ),
            ],
          ),
          if (_customInvalid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.expDateRangeError,
                style: PTypo.caption.copyWith(color: t.statusDangerFg),
              ),
            ),
        ],
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
          badge: _categoryIds.isEmpty
              ? null
              : '· ${l.expNSelected(_categoryIds.length)}',
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
                      active: _categoryIds.contains(c.rowId),
                      onTap: () => setState(() {
                        if (_categoryIds.contains(c.rowId)) {
                          _categoryIds.remove(c.rowId);
                        } else {
                          _categoryIds.add(c.rowId);
                        }
                      }),
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
          badge: _assetIds.isEmpty
              ? null
              : '· ${l.expNSelected(_assetIds.length)}',
        ),
        // 다중선택 필터 칩 — spec toggle.md: outline PToggle + radius-md(둥근 사각형). pill 아님.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in assets)
              PToggle(
                label: a.assetName,
                variant: PToggleVariant.outline,
                size: PToggleSize.sm,
                pressed: _assetIds.contains(a.rowId),
                onChanged: (_) => setState(() {
                  if (_assetIds.contains(a.rowId)) {
                    _assetIds.remove(a.rowId);
                  } else {
                    _assetIds.add(a.rowId);
                  }
                }),
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
        Row(
          children: [
            Expanded(
              child: PTextInput(
                controller: _minCtrl,
                placeholder: l.expMinAmount,
                numbersOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            Text('~', style: PTypo.body.copyWith(color: t.fgTertiary)),
            const SizedBox(width: 8),
            Expanded(
              child: PTextInput(
                controller: _maxCtrl,
                placeholder: l.expMaxAmount,
                numbersOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
