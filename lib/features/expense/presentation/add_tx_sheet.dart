import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../asset/application/asset_providers.dart';
import '../application/expense_providers.dart';

/// 거래 추가 시트.
///
/// 백엔드 `POST /api/v1/expense` 직접 호출. 성공 시 현재 월 expensesProvider invalidate.
void showAddTxSheet(BuildContext context, {String? defaultDate}) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: const Text('거래 추가'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor: Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _AddTxBody(defaultDate: defaultDate),
      ),
    ],
  );
}

class _AddTxBody extends ConsumerStatefulWidget {
  const _AddTxBody({this.defaultDate});
  final String? defaultDate;

  @override
  ConsumerState<_AddTxBody> createState() => _AddTxBodyState();
}

class _AddTxBodyState extends ConsumerState<_AddTxBody> {
  String _type = 'EXPENSE'; // 'EXPENSE' | 'INCOME' | 'TRANSFER'
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _categoryRowId;
  int? _assetRowId;
  late DateTime _date;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _date = widget.defaultDate != null
        ? parseIsoDate(widget.defaultDate!)
        : DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    return !_submitting &&
        amount != null &&
        amount > 0 &&
        _categoryRowId != null &&
        _assetRowId != null;
  }

  Future<void> _submit() async {
    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.create(
        categoryRowId: _categoryRowId!,
        assetRowId: _assetRowId!,
        expenseType: _type,
        amount: amount,
        expenseDate:
            '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}T00:00:00',
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      // 현재 월 캐시 무효화
      ref.invalidate(monthExpensesProvider(
          (year: _date.year, month: _date.month)));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래가 추가되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeSegment(value: _type, onChanged: (v) => setState(() => _type = v), tokens: t),
          const SizedBox(height: PSpace.x16),

          _Label('금액'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: PTypo.h3.copyWith(color: t.fgPrimary),
            decoration: const InputDecoration(hintText: '0'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('카테고리'),
          const SizedBox(height: PSpace.x8),
          SizedBox(
            height: 80,
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('카테고리 로드 실패: $e',
                  style: PTypo.caption.copyWith(color: t.statusDanger)),
              data: (categories) {
                if (categories.isEmpty) {
                  return Text('등록된 카테고리가 없습니다',
                      style: PTypo.caption.copyWith(color: t.fgTertiary));
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: PSpace.x8),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    final selected = _categoryRowId == c.rowId;
                    final fg = parseColor(c.color, fallback: t.fgBrand);
                    final bg = softBg(fg);
                    return GestureDetector(
                      onTap: () => setState(() => _categoryRowId = c.rowId),
                      child: Container(
                        width: 76,
                        decoration: BoxDecoration(
                          color: selected ? t.bgBrandSubtle : t.bgSurface,
                          border: Border.all(
                            color: selected ? t.borderBrand : t.borderSubtle,
                            width: selected ? 1.5 : 1,
                          ),
                          borderRadius: PRadius.brMd,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                              child: Icon(lucideByName(c.icon), size: 16, color: fg),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(c.categoryName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PTypo.micro.copyWith(
                                      color: selected ? t.fgPrimary : t.fgSecondary)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('자산'),
          const SizedBox(height: PSpace.x8),
          assetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('자산 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (assets) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final a in assets)
                  _Chip(
                    label: a.assetName,
                    selected: _assetRowId == a.rowId,
                    onTap: () => setState(() => _assetRowId = a.rowId),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('날짜'),
          const SizedBox(height: PSpace.x4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030, 12, 31),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
                border: Border.all(color: t.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 18, color: t.fgSecondary),
                  const SizedBox(width: PSpace.x8),
                  Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                      style: PTypo.body.copyWith(color: t.fgPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('메모 (선택)'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '예: 점심, 회식 등'),
          ),
          const SizedBox(height: PSpace.x24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(text, style: PTypo.caption.copyWith(color: t.fgSecondary));
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment(
      {required this.value, required this.onChanged, required this.tokens});
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;

  static const _opts = [
    ('EXPENSE', '지출'),
    ('INCOME', '수입'),
    ('TRANSFER', '이체'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: tokens.bgMuted, borderRadius: PRadius.brMd),
      child: Row(
        children: [
          for (final o in _opts)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: o.$1 == value ? tokens.bgSurface : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(o.$2,
                      textAlign: TextAlign.center,
                      style: PTypo.bodySm.copyWith(
                        color: o.$1 == value ? tokens.fgPrimary : tokens.fgTertiary,
                        fontWeight:
                            o.$1 == value ? FontWeight.w600 : FontWeight.w500,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.tokens});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: PRadius.brMd,
        ),
        child: Text(label,
            style: PTypo.bodySm.copyWith(
                color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
