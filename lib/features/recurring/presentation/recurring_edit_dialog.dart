import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../asset/application/asset_providers.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart' show Expense;
import '../application/recurring_providers.dart';
import '../domain/recurring_transaction.dart';

/// 반복 거래 추가/수정.
///
/// [fromExpense] 가 주어지면 해당 거래를 기반으로 신규 반복 만들기 (sourceExpenseRowId 연결).
void showRecurringEditDialog(
  BuildContext context, {
  RecurringTransaction? edit,
  Expense? fromExpense,
}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '반복 설정' : '반복 거래 수정',
    contentBuilder: (ctx, scrollCtrl) => _RecurringEditBody(
      edit: edit,
      fromExpense: fromExpense,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? '추가' : '수정',
    ),
  );
}

class _RecurringEditBody extends ConsumerStatefulWidget {
  const _RecurringEditBody({
    this.edit,
    this.fromExpense,
    required this.scrollController,
    required this.controller,
  });
  final RecurringTransaction? edit;
  final Expense? fromExpense;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_RecurringEditBody> createState() => _RecurringEditBodyState();
}

class _RecurringEditBodyState extends ConsumerState<_RecurringEditBody> {
  late String _type; // EXPENSE/INCOME/TRANSFER
  late String _frequency; // DAILY/WEEKLY/MONTHLY/YEARLY
  late int _intervalValue;
  late int _dayOfWeek; // ISO 1=월 ~ 7=일
  late int _dayOfMonth; // 1~31
  late DateTime _startDate;
  DateTime? _endDate;
  int? _categoryRowId;
  int? _assetRowId;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _merchantCtrl;
  late bool _autoLog;
  late bool _notifyDayBefore;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final r = widget.edit;
    final fe = widget.fromExpense;
    _type = r?.expenseType ?? fe?.expenseType ?? 'EXPENSE';
    _frequency = r?.frequency ?? 'MONTHLY';
    _intervalValue = r?.intervalValue ?? 1;
    _dayOfWeek = r?.dayOfWeek ?? 1;
    _dayOfMonth = r?.dayOfMonth ?? DateTime.now().day;
    _startDate = r?.startDate != null
        ? DateTime.parse(r!.startDate!)
        : (fe?.expenseDate != null
            ? DateTime.parse(fe!.expenseDate!.substring(0, 10))
            : DateTime.now());
    _endDate = r?.endDate != null ? DateTime.parse(r!.endDate!) : null;
    _categoryRowId = r?.categoryRowId ?? fe?.categoryRowId;
    _assetRowId = r?.assetRowId ?? fe?.assetRowId;
    _amountCtrl = TextEditingController(
        text: (r?.amount ?? fe?.amount)?.toString() ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? fe?.description ?? '');
    _merchantCtrl =
        TextEditingController(text: r?.merchant ?? fe?.merchant ?? '');
    _autoLog = r?.autoLog ?? false;
    _notifyDayBefore = r?.notifyDayBefore ?? false;
    widget.controller.onSubmit = _submit;
    if (_isEdit) widget.controller.onDelete = _delete;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _merchantCtrl.dispose();
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

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    _setSubmitting(true);
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          categoryRowId: _categoryRowId!,
          assetRowId: _assetRowId!,
          expenseType: _type,
          amount: amount,
          frequency: _frequency,
          intervalValue: _intervalValue,
          dayOfWeek: _frequency == 'WEEKLY' ? _dayOfWeek : null,
          dayOfMonth: _frequency == 'MONTHLY' ? _dayOfMonth : null,
          startDate: _fmt(_startDate),
          endDate: _endDate == null ? null : _fmt(_endDate!),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          merchant: _merchantCtrl.text.trim().isEmpty
              ? null
              : _merchantCtrl.text.trim(),
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
        );
      } else {
        await repo.create(
          categoryRowId: _categoryRowId!,
          assetRowId: _assetRowId!,
          sourceExpenseRowId: widget.fromExpense?.rowId,
          expenseType: _type,
          amount: amount,
          frequency: _frequency,
          intervalValue: _intervalValue,
          dayOfWeek: _frequency == 'WEEKLY' ? _dayOfWeek : null,
          dayOfMonth: _frequency == 'MONTHLY' ? _dayOfMonth : null,
          startDate: _fmt(_startDate),
          endDate: _endDate == null ? null : _fmt(_endDate!),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          merchant: _merchantCtrl.text.trim().isEmpty
              ? null
              : _merchantCtrl.text.trim(),
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
        );
      }
      ref.invalidate(recurringListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '반복 거래가 수정되었습니다' : '반복 거래가 추가되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    final ok = await showPConfirmDialog(
      context,
      title: '반복 거래 삭제',
      message: '이 반복 거래를 삭제하시겠습니까?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(recurringListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          // 거래 유형
          _Seg(
            options: const [
              ('EXPENSE', '지출'),
              ('INCOME', '수입'),
            ],
            value: _type,
            onChanged: (v) => setState(() => _type = v),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x16),

          _Label('금액'),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _amountCtrl,
            numbersOnly: true,
            style: PTypo.h3,
            placeholder: '0',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('카테고리'),
          const SizedBox(height: PSpace.x8),
          categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('카테고리 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (categories) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final c in categories)
                  _CatChip(
                    label: c.categoryName,
                    icon: lucideByName(c.icon),
                    fg: parseColor(c.color, fallback: t.fgBrand),
                    selected: _categoryRowId == c.rowId,
                    onTap: () => setState(() => _categoryRowId = c.rowId),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('자산'),
          const SizedBox(height: PSpace.x8),
          assetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('자산 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (assets) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final a in assets)
                  _PlainChip(
                    label: a.assetName,
                    selected: _assetRowId == a.rowId,
                    onTap: () => setState(() => _assetRowId = a.rowId),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x20),

          // 주기
          _Label('주기'),
          const SizedBox(height: PSpace.x8),
          _Seg(
            options: const [
              ('DAILY', '매일'),
              ('WEEKLY', '매주'),
              ('MONTHLY', '매월'),
              ('YEARLY', '매년'),
            ],
            value: _frequency,
            onChanged: (v) => setState(() => _frequency = v),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x12),

          if (_frequency == 'WEEKLY') ...[
            _Label('요일'),
            const SizedBox(height: PSpace.x8),
            _DowPicker(
                value: _dayOfWeek,
                onChanged: (v) => setState(() => _dayOfWeek = v),
                tokens: t),
            const SizedBox(height: PSpace.x12),
          ],
          if (_frequency == 'MONTHLY') ...[
            _Label('매월 며칠'),
            const SizedBox(height: PSpace.x4),
            _DomPicker(
                value: _dayOfMonth,
                onChanged: (v) => setState(() => _dayOfMonth = v),
                tokens: t),
            const SizedBox(height: PSpace.x12),
          ],

          _Label('시작 날짜'),
          const SizedBox(height: PSpace.x4),
          _DateField(
            value: _startDate,
            onChange: (d) => setState(() => _startDate = d),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x12),

          _Label('종료 날짜 (선택)'),
          const SizedBox(height: PSpace.x4),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  value: _endDate,
                  hint: '미설정 = 무기한',
                  onChange: (d) => setState(() => _endDate = d),
                  tokens: t,
                ),
              ),
              if (_endDate != null)
                IconButton(
                  icon: Icon(LucideIcons.x, size: 16, color: t.fgTertiary),
                  onPressed: () => setState(() => _endDate = null),
                  tooltip: '종료 날짜 제거',
                ),
            ],
          ),
          const SizedBox(height: PSpace.x12),

          // 다음 발생일 3건 미리보기 — front previewNextDates 미러
          Builder(builder: (_) {
            final preview = _previewNextDates(
                _startDate, _frequency, _dayOfWeek, _dayOfMonth, 3);
            if (preview.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.bgSurface,
                borderRadius: PRadius.brMd,
                border: Border.all(color: t.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 13, color: t.fgSecondary),
                      const SizedBox(width: 6),
                      Text('다음 예정일',
                          style: PTypo.caption.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: PSpace.x8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in preview)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.bgMuted,
                            borderRadius: PRadius.brFull,
                            border: Border.all(color: t.borderSubtle),
                          ),
                          child: Text(
                              '${d.month.toString().padLeft(2, '0')}월 ${d.day.toString().padLeft(2, '0')}일',
                              style: PTypo.caption.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.semi)),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: PSpace.x16),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('자동 기록',
                style: PTypo.body.copyWith(color: t.fgPrimary)),
            subtitle: Text('실행 일자에 자동으로 거래 생성',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
            value: _autoLog,
            onChanged: (v) => setState(() => _autoLog = v),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('하루 전 알림',
                style: PTypo.body.copyWith(color: t.fgPrimary)),
            value: _notifyDayBefore,
            onChanged: (v) => setState(() => _notifyDayBefore = v),
          ),

          _Label('가맹점 (선택)'),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _merchantCtrl,
            placeholder: '예: 넷플릭스',
          ),
          const SizedBox(height: PSpace.x12),
          _Label('메모 (선택)'),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _descCtrl,
            placeholder: '메모',
          ),
      ],
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

class _Seg extends StatelessWidget {
  const _Seg(
      {required this.options,
      required this.value,
      required this.onChanged,
      required this.tokens});
  final List<(String code, String label)> options;
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: tokens.bgMuted, borderRadius: PRadius.brMd),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        o.$1 == value ? tokens.bgSurface : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(o.$2,
                      textAlign: TextAlign.center,
                      style: PTypo.bodySm.copyWith(
                          color: o.$1 == value
                              ? tokens.fgPrimary
                              : tokens.fgTertiary,
                          fontWeight: o.$1 == value
                              ? PFontWeight.semi
                              : PFontWeight.medium)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DowPicker extends StatelessWidget {
  const _DowPicker(
      {required this.value, required this.onChanged, required this.tokens});
  final int value; // ISO 1=월~7=일
  final ValueChanged<int> onChanged;
  final PorestTokens tokens;

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == value ? tokens.bgBrand : tokens.bgSurface,
                    border: Border.all(
                        color: i == value
                            ? tokens.borderBrand
                            : tokens.borderDefault),
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    _labels[i - 1],
                    style: PTypo.bodySm.copyWith(
                      color: i == value ? tokens.fgOnBrand : tokens.fgPrimary,
                      fontWeight:
                          i == value ? PFontWeight.bold : PFontWeight.medium,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DomPicker extends StatelessWidget {
  const _DomPicker(
      {required this.value, required this.onChanged, required this.tokens});
  final int value;
  final ValueChanged<int> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.bgMuted,
        borderRadius: PRadius.brMd,
        border: Border.all(color: tokens.borderDefault),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: Icon(LucideIcons.minus, size: 18, color: tokens.fgSecondary),
          ),
          Expanded(
            child: Text('$value 일',
                textAlign: TextAlign.center,
                style: PTypo.body.copyWith(color: tokens.fgPrimary)),
          ),
          IconButton(
            onPressed: value < 31 ? () => onChanged(value + 1) : null,
            icon: Icon(LucideIcons.plus, size: 18, color: tokens.fgSecondary),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.value,
      required this.onChange,
      required this.tokens,
      this.hint});
  final DateTime? value;
  final ValueChanged<DateTime> onChange;
  final PorestTokens tokens;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final p = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030, 12, 31),
        );
        if (p != null) onChange(p);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.bgMuted,
          borderRadius: PRadius.brMd,
          border: Border.all(color: tokens.borderDefault),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 18, color: tokens.fgSecondary),
            const SizedBox(width: PSpace.x8),
            Text(
              value == null
                  ? (hint ?? '날짜 선택')
                  : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
              style: PTypo.body.copyWith(
                  color: value == null ? tokens.fgPlaceholder : tokens.fgPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip(
      {required this.label,
      required this.icon,
      required this.fg,
      required this.selected,
      required this.onTap,
      required this.tokens});
  final String label;
  final IconData icon;
  final Color fg;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: PRadius.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label,
                style: PTypo.bodySm.copyWith(
                  color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                  fontWeight:
                      selected ? PFontWeight.semi : PFontWeight.medium,
                )),
          ],
        ),
      ),
    );
  }
}

class _PlainChip extends StatelessWidget {
  const _PlainChip(
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
                fontWeight: selected ? PFontWeight.semi : PFontWeight.medium)),
      ),
    );
  }
}

// ─── helpers ────────────────────────────────────────────────

/// front `previewNextDates` 미러.
///
/// [start] 시작 날짜에서 [count] 개의 다음 발생일을 계산.
/// - DAILY: +1일
/// - WEEKLY: 시작일을 [dayOfWeekIso] 요일로 정규화 후 +7일씩
/// - MONTHLY: [dayOfMonth] 일자, 해당 일이 없는 달은 말일
/// - YEARLY: +1년 (월/일 동일)
List<DateTime> _previewNextDates(
  DateTime start,
  String frequency,
  int dayOfWeekIso, // 1=월~7=일
  int dayOfMonth,
  int count,
) {
  final out = <DateTime>[];
  var cursor = DateTime(start.year, start.month, start.day);

  if (frequency == 'WEEKLY') {
    // ISO 1=월 7=일, DateTime.weekday 도 1~7 (Mon=1, Sun=7) — 일치.
    final diff = (dayOfWeekIso - cursor.weekday + 7) % 7;
    cursor = cursor.add(Duration(days: diff));
  } else if (frequency == 'MONTHLY') {
    final last = DateTime(cursor.year, cursor.month + 1, 0).day;
    final d = dayOfMonth.clamp(1, last);
    cursor = DateTime(cursor.year, cursor.month, d);
  }

  for (var i = 0; i < count; i++) {
    out.add(cursor);
    switch (frequency) {
      case 'DAILY':
        cursor = cursor.add(const Duration(days: 1));
        break;
      case 'WEEKLY':
        cursor = cursor.add(const Duration(days: 7));
        break;
      case 'MONTHLY':
        final ny = cursor.year;
        final nm = cursor.month + 1;
        final last = DateTime(ny, nm + 1, 0).day;
        cursor = DateTime(ny, nm, dayOfMonth.clamp(1, last));
        break;
      case 'YEARLY':
        cursor = DateTime(cursor.year + 1, cursor.month, cursor.day);
        break;
      default:
        return out;
    }
  }
  return out;
}
