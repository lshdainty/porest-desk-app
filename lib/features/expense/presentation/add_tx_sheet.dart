import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/date.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';

/// 거래 추가 시트.
///
/// porest-desk-front `AddTxSheet` 모바일 모드 매핑:
/// - 거래 유형 세그먼트 (지출/수입/이체)
/// - 금액
/// - 카테고리 선택
/// - 자산 선택
/// - 날짜
/// - 메모 (선택)
///
/// v0.1: 저장 시 in-memory mock 에 push (백엔드 연결은 Phase 7+).
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
  TxType _type = TxType.expense;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _categoryId;
  String? _assetId;
  late DateTime _date;

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
    return amount != null &&
        amount > 0 &&
        _categoryId != null &&
        _assetId != null;
  }

  void _submit() {
    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    ref.read(expensesProvider.notifier).add(Expense(
          id: 'm${DateTime.now().millisecondsSinceEpoch}',
          date:
              '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
          amount: amount,
          type: _type,
          categoryId: _categoryId!,
          assetId: _assetId!,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('거래가 추가되었습니다 (메모리)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categories = ref.watch(categoriesProvider);
    final assets = ref.watch(assetsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 거래 유형 세그먼트
          _TypeSegment(value: _type, onChanged: (v) => setState(() => _type = v), tokens: t),
          const SizedBox(height: PSpace.x16),

          // 금액
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

          // 카테고리
          _Label('카테고리'),
          const SizedBox(height: PSpace.x8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: PSpace.x8),
              itemBuilder: (_, i) {
                final c = categories[i];
                final selected = _categoryId == c.id;
                return GestureDetector(
                  onTap: () => setState(() => _categoryId = c.id),
                  child: Container(
                    width: 72,
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
                          child: Icon(c.icon, size: 16, color: c.color),
                        ),
                        const SizedBox(height: 4),
                        Text(c.name,
                            style: PTypo.micro.copyWith(
                                color: selected ? t.fgPrimary : t.fgSecondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 자산
          _Label('자산'),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (final a in assets)
                _Chip(
                  label: a.name,
                  selected: _assetId == a.id,
                  onTap: () => setState(() => _assetId = a.id),
                  tokens: t,
                ),
            ],
          ),
          const SizedBox(height: PSpace.x16),

          // 날짜
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
                  Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                      style: PTypo.body.copyWith(color: t.fgPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 메모
          _Label('메모 (선택)'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '예: 점심, 회식 등'),
          ),
          const SizedBox(height: PSpace.x24),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: const Text('저장'),
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
  final TxType value;
  final ValueChanged<TxType> onChanged;
  final PorestTokens tokens;

  static const _opts = [
    (TxType.expense, '지출'),
    (TxType.income, '수입'),
    (TxType.transfer, '이체'),
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
