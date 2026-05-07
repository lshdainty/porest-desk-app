import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_category_tile.dart';
import '../../../shared/widgets/p_segmented.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../../shared/widgets/p_type_chip.dart';
import '../../asset/application/asset_providers.dart';
import '../application/expense_providers.dart';

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
  }) =>
      ExpenseFilter(
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
    BuildContext context, ExpenseFilter current) async {
  return showModalBottomSheet<ExpenseFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).extension<PorestTokens>()?.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => _FilterBody(
        initial: current,
        scrollController: scrollCtrl,
      ),
    ),
  );
}

class _FilterBody extends ConsumerStatefulWidget {
  const _FilterBody({required this.initial, required this.scrollController});
  final ExpenseFilter initial;
  final ScrollController scrollController;

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
    _minCtrl =
        TextEditingController(text: widget.initial.min?.toString() ?? '');
    _maxCtrl =
        TextEditingController(text: widget.initial.max?.toString() ?? '');
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
    Navigator.of(context).pop(ExpenseFilter(
      period: _period,
      startDate: _period == FilterPeriod.custom ? _startDate : null,
      endDate: _period == FilterPeriod.custom ? _endDate : null,
      types: _types,
      categoryIds: _categoryIds,
      assetIds: _assetIds,
      min: int.tryParse(_minCtrl.text),
      max: int.tryParse(_maxCtrl.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: t.borderSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x20, PSpace.x12, PSpace.x12, PSpace.x12),
          child: Row(
            children: [
              Text('필터',
                  style: TextStyle(
                      color: t.fgPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.34)),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.x, color: t.fgSecondary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(
                PSpace.x20, 0, PSpace.x20, PSpace.x16),
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x16),
          child: Row(
            children: [
              TextButton(
                onPressed: _reset,
                child: Text('초기화',
                    style: PTypo.body.copyWith(color: t.fgSecondary)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('취소',
                    style: PTypo.body.copyWith(color: t.fgSecondary)),
              ),
              const SizedBox(width: PSpace.x8),
              FilledButton(
                onPressed: _customInvalid ? null : _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: t.bgBrand,
                  foregroundColor: t.fgOnBrand,
                ),
                child: const Text('필터 적용'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text, PorestTokens t, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(text,
              style: PTypo.bodySm.copyWith(
                  color: t.fgSecondary, fontWeight: FontWeight.w600)),
          if (badge != null && badge.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(badge,
                style: PTypo.bodySm.copyWith(
                    color: t.fgBrandStrong, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _periodSection(PorestTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('기간', t),
        PSegmented<FilterPeriod>(
          value: _period,
          onChanged: (v) => setState(() => _period = v),
          options: const [
            PSegmentOption(value: FilterPeriod.week, label: '이번 주'),
            PSegmentOption(value: FilterPeriod.month, label: '이번 달'),
            PSegmentOption(
                value: FilterPeriod.threeMonth, label: '3개월'),
            PSegmentOption(
                value: FilterPeriod.custom, label: '직접 선택'),
          ],
        ),
        if (_period == FilterPeriod.custom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _datePill(
                      t, _startDate, (v) => setState(() => _startDate = v),
                      '시작일')),
              const SizedBox(width: 8),
              Text('~', style: PTypo.body.copyWith(color: t.fgTertiary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _datePill(
                      t, _endDate, (v) => setState(() => _endDate = v),
                      '종료일')),
            ],
          ),
          if (_customInvalid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('시작일이 종료일보다 늦을 수 없습니다.',
                  style:
                      PTypo.caption.copyWith(color: t.statusDangerFg)),
            ),
        ],
      ],
    );
  }

  Widget _datePill(PorestTokens t, String? value, ValueChanged<String> onChanged,
      String hint) {
    return InkWell(
      onTap: () async {
        final init = DateTime.tryParse(value ?? '') ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(
              '${picked.year}-${_pad(picked.month)}-${_pad(picked.day)}');
        }
      },
      borderRadius: PRadius.brSm,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x12),
        decoration: BoxDecoration(
          color: t.bgSurface,
          borderRadius: PRadius.brSm,
          border: Border.all(color: t.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                (value ?? '').isEmpty ? hint : value!,
                style: PTypo.bodySm.copyWith(
                    color:
                        (value ?? '').isEmpty ? t.fgTertiary : t.fgPrimary),
              ),
            ),
            Icon(LucideIcons.calendar, size: 14, color: t.fgSecondary),
          ],
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('거래 종류', t),
        Row(
          children: [
            Expanded(
              child: PTypeChip(
                label: '지출',
                active: _types.contains('EXPENSE'),
                activeColor: t.statusDangerFg,
                onTap: () => toggle('EXPENSE'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PTypeChip(
                label: '수입',
                active: _types.contains('INCOME'),
                activeColor: t.statusSuccessFg,
                onTap: () => toggle('INCOME'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categorySection(PorestTokens t) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final parents = categories.where((c) => c.parentRowId == null).toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    if (parents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('카테고리', t,
            badge:
                _categoryIds.isEmpty ? null : '· ${_categoryIds.length}개 선택'),
        GridView.count(
          crossAxisCount: 5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.85,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final c in parents)
              PCategoryTile(
                name: c.categoryName,
                color: parseColor(c.color, fallback: t.fgBrand),
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
          ],
        ),
      ],
    );
  }

  Widget _assetSection(PorestTokens t) {
    final assets = ref.watch(assetsProvider).value ?? const [];
    if (assets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('계좌·카드', t,
            badge: _assetIds.isEmpty ? null : '· ${_assetIds.length}개 선택'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in assets)
              GestureDetector(
                onTap: () => setState(() {
                  if (_assetIds.contains(a.rowId)) {
                    _assetIds.remove(a.rowId);
                  } else {
                    _assetIds.add(a.rowId);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: PSpace.x12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _assetIds.contains(a.rowId)
                        ? t.bgBrandSubtle
                        : t.bgMuted,
                    border: Border.all(
                        color: _assetIds.contains(a.rowId)
                            ? t.borderBrand
                            : t.borderSubtle),
                    borderRadius: PRadius.brPill,
                  ),
                  child: Text(a.assetName,
                      style: PTypo.caption.copyWith(
                        color: _assetIds.contains(a.rowId)
                            ? t.fgBrandStrong
                            : t.fgSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _amountSection(PorestTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('금액 범위', t),
        Row(
          children: [
            Expanded(
                child: PTextInput(
                    controller: _minCtrl,
                    placeholder: '최소 금액',
                    numbersOnly: true)),
            const SizedBox(width: 8),
            Text('~', style: PTypo.body.copyWith(color: t.fgTertiary)),
            const SizedBox(width: 8),
            Expanded(
                child: PTextInput(
                    controller: _maxCtrl,
                    placeholder: '최대 금액',
                    numbersOnly: true)),
          ],
        ),
      ],
    );
  }
}
