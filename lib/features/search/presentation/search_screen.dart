import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_day_group.dart';
import 'package:porest_desk_app/shared/widgets/p_expense_row.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/tx_detail_dialog.dart';

/// 거래 통합 검색 — 키워드 + (선택) 유형/금액 범위.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _typeFilter; // null = 전체, 'EXPENSE', 'INCOME'
  int? _minAmount;
  int? _maxAmount;
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<Expense> _results = [];

  bool get _hasAdvanced =>
      _minAmount != null ||
      _maxAmount != null ||
      _startDate != null ||
      _endDate != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _showAdvancedSheet() async {
    final l = AppLocalizations.of(context);
    var min = _minAmount;
    var max = _maxAmount;
    var start = _startDate;
    var end = _endDate;
    final minCtrl = TextEditingController(text: min?.toString() ?? '');
    final maxCtrl = TextEditingController(text: max?.toString() ?? '');
    await showPSheet<void>(
      context,
      title: l.searchAdvancedFilter,
      contentBuilder: (sheetCtx, scrollCtrl) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final t = ctx.tokens;
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                PSpace.xl,
                0,
                PSpace.xl,
                PSpace.x16,
              ),
              children: [
                Text(
                  l.expAmountRange,
                  style: PTypo.caption.copyWith(color: t.fgSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: PTextInput(
                        controller: minCtrl,
                        numbersOnly: true,
                        placeholder: l.expFilterMin,
                        suffixText: wonUnit(),
                        onChanged: (v) => min = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('~'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PTextInput(
                        controller: maxCtrl,
                        numbersOnly: true,
                        placeholder: l.expFilterMax,
                        suffixText: wonUnit(),
                        onChanged: (v) => max = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l.expFilterPeriod,
                  style: PTypo.caption.copyWith(color: t.fgSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: PDateInput(
                        value: start,
                        onChanged: (d) {
                          if (d != null) setSheet(() => start = d);
                        },
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030, 12, 31),
                        placeholder: l.searchStartHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PDateInput(
                        value: end,
                        onChanged: (d) {
                          if (d != null) setSheet(() => end = d);
                        },
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030, 12, 31),
                        placeholder: l.searchEndHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PButton(
                        label: l.actionReset,
                        variant: PButtonVariant.outline,
                        fullWidth: true,
                        onPressed: () {
                          setSheet(() {
                            min = null;
                            max = null;
                            start = null;
                            end = null;
                            minCtrl.clear();
                            maxCtrl.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PButton(
                        label: l.actionApply,
                        fullWidth: true,
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          setState(() {
                            _minAmount = min;
                            _maxAmount = max;
                            _startDate = start;
                            _endDate = end;
                          });
                          _runSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _runSearch() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty && _typeFilter == null && !_hasAdvanced) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final list = await repo.search(
        keyword: q.isEmpty ? null : q,
        expenseType: _typeFilter,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        startDate: _startDate == null ? null : _fmtDate(_startDate!),
        endDate: _endDate == null ? null : _fmtDate(_endDate!),
      );
      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: PSearchField(
          hint: l.searchHint,
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _onChanged,
          trailing: _ctrl.text.isEmpty
              ? null
              : PButton.icon(
                  icon: LucideIcons.x,
                  size: PButtonSize.sm,
                  iconColor: t.fgTertiary,
                  onPressed: () {
                    _ctrl.clear();
                    _runSearch();
                  },
                ),
        ),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 20,
                  color: t.fgSecondary,
                ),
                if (_hasAdvanced)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: t.fgBrand,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.bgSurface, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: l.searchAdvancedFilter,
            onPressed: _showAdvancedSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpace.x24,
              0,
              PSpace.x24,
              PSpace.x8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PTabs<String?>(
                value: _typeFilter,
                onChanged: (v) {
                  setState(() => _typeFilter = v);
                  _runSearch();
                },
                variant: PTabsVariant.pills,
                size: PTabsSize.sm,
                items: [
                  PTabItem(value: null, label: l.expFilterAll),
                  PTabItem(value: 'EXPENSE', label: l.expFilterExpense),
                  PTabItem(value: 'INCOME', label: l.expFilterIncome),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(t, settings, categories),
    );
  }

  Widget _buildBody(PorestTokens t, AppSettings settings, List categories) {
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const _SearchLoadingSkeleton();
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(PSpace.x24),
        child: Center(
          child: Text(
            '${l.searchFailed}: $_error',
            style: PTypo.bodySm.copyWith(color: t.statusDanger),
          ),
        ),
      );
    }
    if (_ctrl.text.trim().isEmpty && _typeFilter == null) {
      return _EmptyHint(
        icon: LucideIcons.search,
        text: l.searchEmptyHint,
        tokens: t,
      );
    }
    if (_results.isEmpty) {
      return _EmptyHint(
        icon: LucideIcons.searchX,
        text: l.searchNoResults,
        tokens: t,
      );
    }
    // 가계부 목록과 **같은 조각**으로 그린다 — 행은 PExpenseRow, 날짜는 그룹 헤더.
    // 예전에는 자체 _ResultRow 에 부제로 날짜를 넣고 구분선을 그려, 같은 거래가
    // 두 화면에서 다르게 보였다(금액에 '원' 도 없었다).
    final flags = ref.watch(maskFlagsProvider('etc.search'));
    final groups = _groupByDay(_results);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x24,
        vertical: PSpace.x8,
      ),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final g = groups[i];
        return Padding(
          // 날짜 그룹 사이는 넓은 여백으로 구분한다(헤어라인·카드 없음) — 가계부 정합.
          padding: const EdgeInsets.only(top: PSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PDayHeader(date: g.date, items: g.items, flags: flags),
              const SizedBox(height: 6),
              for (final e in g.items)
                PExpenseRow(
                  expense: e,
                  masked: flags.of(
                    e.expenseType == 'INCOME'
                        ? MaskKind.income
                        : MaskKind.expense,
                  ),
                  categoryColorOverride: _catColor(categories, e.categoryRowId),
                  categoryIconOverride: _catIcon(categories, e.categoryRowId),
                  onTap: () => _openDetail(e),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 결과를 날짜별로 묶는다 — 최신 날짜가 위(서버 정렬과 같은 방향).
  List<({DateTime date, List<Expense> items})> _groupByDay(List<Expense> rows) {
    final byDay = <String, List<Expense>>{};
    for (final e in rows) {
      final d = e.expenseDate;
      if (d == null || d.length < 10) continue;
      byDay.putIfAbsent(d.substring(0, 10), () => []).add(e);
    }
    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (date: parseIsoDate(k), items: byDay[k]!)];
  }

  dynamic _findCategory(List categories, int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      try {
        if (c.rowId == rowId) return c;
      } catch (_) {}
    }
    return null;
  }

  /// 카테고리 목록에서 해석한 색 — 거래에 박힌 값보다 우선한다(옛 _ResultRow 규칙 그대로).
  String? _catColor(List categories, int? rowId) =>
      _findCategory(categories, rowId)?.color as String?;

  String? _catIcon(List categories, int? rowId) =>
      _findCategory(categories, rowId)?.icon as String?;

  void _openDetail(Expense e) => showTxDetailDialog(context, e);
}

/// 검색 결과 로딩 skeleton — 가계부와 같은 날짜 그룹 모양(구분선 없음).
class _SearchLoadingSkeleton extends StatelessWidget {
  const _SearchLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x24,
        vertical: PSpace.x8,
      ),
      itemCount: 2,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(top: PSpace.x16),
        child: PDayGroupSkeleton(rows: 3),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.text,
    required this.tokens,
  });
  final IconData icon;
  final String text;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: tokens.fgDisabled),
          const SizedBox(height: PSpace.x12),
          Text(text, style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
        ],
      ),
    );
  }
}
