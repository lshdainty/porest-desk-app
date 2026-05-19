import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_date_input.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/presentation/tx_detail_dialog.dart';

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
    var min = _minAmount;
    var max = _maxAmount;
    var start = _startDate;
    var end = _endDate;
    final minCtrl = TextEditingController(text: min?.toString() ?? '');
    final maxCtrl = TextEditingController(text: max?.toString() ?? '');
    await showPSheet<void>(
      context,
      title: '고급 필터',
      contentBuilder: (sheetCtx, scrollCtrl) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final t = ctx.tokens;
          return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(
                PSpace.x20, 0, PSpace.x20, PSpace.x16),
            children: [
              Text('금액 범위',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: PTextInput(
                      controller: minCtrl,
                      numbersOnly: true,
                      placeholder: '최소',
                      suffixText: '원',
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
                      placeholder: '최대',
                      suffixText: '원',
                      onChanged: (v) => max = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('기간',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
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
                      placeholder: '시작',
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
                      placeholder: '종료',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PButton(
                      label: '초기화',
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
                      label: '적용',
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
        });
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
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: PTextInput(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _runSearch(),
          placeholder: '거래 검색...',
          suffix: _ctrl.text.isEmpty
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
          style: PTypo.body,
        ),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(LucideIcons.slidersHorizontal,
                    size: 20, color: t.fgSecondary),
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
            tooltip: '고급 필터',
            onPressed: _showAdvancedSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, 0, PSpace.x16, PSpace.x8),
            child: Row(
              children: [
                PChip(
                  label: '전체',
                  selected: _typeFilter == null,
                  onTap: () {
                    setState(() => _typeFilter = null);
                    _runSearch();
                  },
                ),
                const SizedBox(width: 6),
                PChip(
                  label: '지출',
                  selected: _typeFilter == 'EXPENSE',
                  onTap: () {
                    setState(() => _typeFilter = 'EXPENSE');
                    _runSearch();
                  },
                ),
                const SizedBox(width: 6),
                PChip(
                  label: '수입',
                  selected: _typeFilter == 'INCOME',
                  onTap: () {
                    setState(() => _typeFilter = 'INCOME');
                    _runSearch();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(t, settings, categories),
    );
  }

  Widget _buildBody(PorestTokens t, AppSettings settings, List categories) {
    if (_loading) {
      return const Center(child: PCircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(PSpace.x24),
        child: Center(
          child: Text('검색 실패: $_error',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
        ),
      );
    }
    if (_ctrl.text.trim().isEmpty && _typeFilter == null) {
      return _EmptyHint(
        icon: LucideIcons.search,
        text: '키워드, 가맹점, 메모로 검색하세요',
        tokens: t,
      );
    }
    if (_results.isEmpty) {
      return _EmptyHint(
        icon: LucideIcons.searchX,
        text: '결과가 없습니다',
        tokens: t,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20, vertical: PSpace.x24),
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          PDivider(indent: 60),
      itemBuilder: (_, i) => _ResultRow(
        expense: _results[i],
        category: _findCategory(categories, _results[i].categoryRowId),
        masked: settings.hideAmounts,
        tokens: t,
      ),
    );
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
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.expense,
    required this.category,
    required this.masked,
    required this.tokens,
  });
  final Expense expense;
  final dynamic category;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = resolveChartColor(
        context, category?.color as String? ?? expense.categoryColor,
        fallback: tokens.fgBrand);
    final bg = softBg(color);
    final isExpense = expense.expenseType == 'EXPENSE';
    final dayLabel = expense.expenseDate != null
        ? formatDay(parseIsoDate(expense.expenseDate!.substring(0, 10)))
        : null;

    return InkWell(
      onTap: () => showTxDetailDialog(context, expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(
                  lucideByName(
                      (category?.icon as String?) ?? expense.categoryIcon,
                      fallback: LucideIcons.tag),
                  size: 18,
                  color: color),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.merchant ??
                        expense.description ??
                        expense.categoryName ??
                        '거래',
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: PFontWeight.semi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      expense.categoryName,
                      if (dayLabel != null)
                        '${dayLabel.md} (${dayLabel.dow})',
                    ].whereType<String>().join(' · '),
                    style: PTypo.caption
                        .copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Text(
              '${isExpense ? '-' : '+'}${krwMasked(expense.amount, masked)}',
              style: PTypo.bodySm.copyWith(
                  color: isExpense
                      ? tokens.fgPrimary
                      : tokens.statusSuccess,
                  fontWeight: PFontWeight.bold),
            ),
          ],
        ),
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
          Text(text,
              style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
        ],
      ),
    );
  }
}
