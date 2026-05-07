import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../application/recurring_providers.dart';

/// 거래 → 반복 설정 다이얼로그 (front `RecurringFromTxDialog` 미러).
///
/// 거래의 카테고리/자산/금액/메모/가맹점은 그대로 사용하고, 사용자는 반복
/// 주기·종료·옵션만 설정합니다.
void showRecurringFromTxDialog(BuildContext context, Expense expense) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).extension<PorestTokens>()?.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PRadius.xl2)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) =>
          _RecurringFromTxBody(expense: expense, scrollController: scrollCtrl),
    ),
  );
}

enum _EndMode { none, count, date }

class _RecurringFromTxBody extends ConsumerStatefulWidget {
  const _RecurringFromTxBody(
      {required this.expense, required this.scrollController});
  final Expense expense;
  final ScrollController scrollController;

  @override
  ConsumerState<_RecurringFromTxBody> createState() =>
      _RecurringFromTxBodyState();
}

class _RecurringFromTxBodyState extends ConsumerState<_RecurringFromTxBody> {
  late final String _expenseDay; // 'YYYY-MM-DD'
  late final DateTime _baseDate;

  String _frequency = 'MONTHLY';
  int _dayOfWeekUi = 1; // 0=일 ~ 6=토 (UI). 백엔드는 ISO (월=1~일=7) 변환.
  int _dayOfMonth = 1;

  _EndMode _endMode = _EndMode.date;
  final TextEditingController _endCountCtrl = TextEditingController(text: '12');
  late DateTime _endDate;

  bool _autoLog = true;
  bool _notifyDayBefore = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final raw = (widget.expense.expenseDate ?? '').trim();
    final base = raw.isNotEmpty
        ? DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw)
        : null;
    final today = DateTime.now();
    _baseDate = base ?? DateTime(today.year, today.month, today.day);
    _expenseDay = _fmt(_baseDate);
    _dayOfWeekUi = _baseDate.weekday % 7; // Mon=1..Sun=7 → UI 1..0
    _dayOfMonth = _baseDate.day.clamp(1, 31);
    _endDate = DateTime(_baseDate.year + 1, _baseDate.month, _baseDate.day);
  }

  @override
  void dispose() {
    _endCountCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _ready {
    if (_endMode == _EndMode.count) {
      final n = int.tryParse(_endCountCtrl.text.trim());
      if (n == null || n <= 0) return false;
    }
    return widget.expense.categoryRowId != null &&
        widget.expense.assetRowId != null;
  }

  Future<void> _save() async {
    final e = widget.expense;
    if (!_ready || _submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      await repo.create(
        categoryRowId: e.categoryRowId!,
        assetRowId: e.assetRowId!,
        sourceExpenseRowId: e.rowId,
        expenseType: e.expenseType,
        amount: e.amount.abs(),
        frequency: _frequency,
        intervalValue: 1,
        // UI 0=일 → ISO 7=일. UI 1~6 (월~토) → ISO 1~6.
        dayOfWeek: _frequency == 'WEEKLY'
            ? (_dayOfWeekUi == 0 ? 7 : _dayOfWeekUi)
            : null,
        dayOfMonth: (_frequency == 'MONTHLY' || _frequency == 'YEARLY')
            ? _dayOfMonth
            : null,
        startDate: _expenseDay,
        endDate: _endMode == _EndMode.date ? _fmt(_endDate) : null,
        description:
            (e.description ?? '').trim().isEmpty ? null : e.description!.trim(),
        merchant:
            (e.merchant ?? '').trim().isEmpty ? null : e.merchant!.trim(),
        paymentMethod: e.paymentMethod,
        autoLog: _autoLog,
        notifyDayBefore: _notifyDayBefore,
      );
      ref.invalidate(recurringListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반복 설정이 저장되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickEndDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _baseDate,
      lastDate: DateTime(_baseDate.year + 30, 12, 31),
    );
    if (p != null) setState(() => _endDate = p);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = widget.expense;
    final categoriesAsync = ref.watch(categoriesProvider);
    final cats = categoriesAsync.value ?? const [];
    final cat = e.categoryRowId == null
        ? null
        : cats.where((c) => c.rowId == e.categoryRowId).firstOrNull;
    final fg = cat == null
        ? t.fgBrand
        : parseColor(cat.color, fallback: t.fgBrand);
    final iconData = lucideByName(cat?.icon ?? 'tag');

    final nextDates = _previewNextDates(
      _baseDate,
      _frequency,
      _dayOfWeekUi,
      _dayOfMonth,
      3,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.borderDefault,
              borderRadius: PRadius.brXs2,
            ),
          ),
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, PSpace.x12, PSpace.x8, PSpace.x4),
            child: Row(
              children: [
                Expanded(
                  child: Text('반복 설정',
                      style: PTypo.h3.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.heavy)),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: t.fgTertiary, size: 20),
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, 0, PSpace.x16, PSpace.x16),
              children: [
                Text(
                  '이 거래를 정해진 주기로 자동 반복합니다. 구독료·월세·정기 후원 등에 사용해보세요.',
                  style: PTypo.bodySm.copyWith(color: t.fgSecondary, height: 1.55),
                ),
                const SizedBox(height: 14),
                // Source card
                _SourceCard(
                  expense: e,
                  startDate: _expenseDay,
                  iconData: iconData,
                  fg: fg,
                  tokens: t,
                ),
                const SizedBox(height: 18),

                _Section(
                  title: '반복 주기',
                  child: _Segmented(
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
                ),

                if (_frequency == 'WEEKLY')
                  _Section(
                    title: '요일',
                    child: _DowGrid(
                      value: _dayOfWeekUi,
                      onChanged: (v) => setState(() => _dayOfWeekUi = v),
                      tokens: t,
                    ),
                  ),

                if (_frequency == 'MONTHLY')
                  _Section(
                    title: '반복 일자',
                    child: Row(
                      children: [
                        Text('매월',
                            style: PTypo.bodySm
                                .copyWith(color: t.fgSecondary)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 64,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            controller: TextEditingController(
                                text: _dayOfMonth.toString())
                              ..selection = TextSelection.collapsed(
                                  offset: _dayOfMonth.toString().length),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: t.bgSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n == null) return;
                              setState(() =>
                                  _dayOfMonth = n.clamp(1, 31));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('일',
                            style: PTypo.bodySm
                                .copyWith(color: t.fgSecondary)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '해당 일이 없는 달은 말일에 처리됩니다',
                            style: PTypo.caption
                                .copyWith(color: t.fgTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                _Section(
                  title: '종료',
                  child: Column(
                    children: [
                      _RadioCard(
                        selected: _endMode == _EndMode.none,
                        onSelect: () =>
                            setState(() => _endMode = _EndMode.none),
                        title: '무기한',
                        subtitle: '중지할 때까지 계속 반복',
                        tokens: t,
                      ),
                      const SizedBox(height: 8),
                      _RadioCard(
                        selected: _endMode == _EndMode.count,
                        onSelect: () =>
                            setState(() => _endMode = _EndMode.count),
                        title: '횟수 지정',
                        tokens: t,
                        subtitleChild: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('총',
                                style: PTypo.caption
                                    .copyWith(color: t.fgSecondary)),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 64,
                              child: TextField(
                                controller: _endCountCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                onTap: () => setState(
                                    () => _endMode = _EndMode.count),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: t.bgSurface,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('회',
                                style: PTypo.caption
                                    .copyWith(color: t.fgSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RadioCard(
                        selected: _endMode == _EndMode.date,
                        onSelect: () =>
                            setState(() => _endMode = _EndMode.date),
                        title: '종료일 지정',
                        tokens: t,
                        subtitleChild: GestureDetector(
                          onTap: () {
                            setState(() => _endMode = _EndMode.date);
                            _pickEndDate();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: t.bgSurface,
                              border: Border.all(color: t.borderDefault),
                              borderRadius: PRadius.brMd,
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.calendar,
                                    size: 14, color: t.fgSecondary),
                                const SizedBox(width: 8),
                                Text(_fmt(_endDate),
                                    style: PTypo.bodySm.copyWith(
                                        color: t.fgPrimary,
                                        fontWeight: PFontWeight.semi)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _Section(
                  title: '옵션',
                  child: Column(
                    children: [
                      _ToggleRow(
                        icon: LucideIcons.zap,
                        title: '자동 기록',
                        subtitle: '해당 일자에 거래를 자동으로 추가합니다',
                        value: _autoLog,
                        onChanged: (v) => setState(() => _autoLog = v),
                        tokens: t,
                      ),
                      const SizedBox(height: 8),
                      _ToggleRow(
                        icon: LucideIcons.bell,
                        title: '하루 전 알림',
                        subtitle: '결제·이체 예정일 전날 알림을 보냅니다',
                        value: _notifyDayBefore,
                        onChanged: (v) =>
                            setState(() => _notifyDayBefore = v),
                        tokens: t,
                      ),
                    ],
                  ),
                ),

                if (nextDates.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.bgSurface,
                      border: Border.all(color: t.borderSubtle),
                      borderRadius: PRadius.brLg,
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
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final d in nextDates)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: t.bgMuted,
                                  borderRadius: PRadius.brPill,
                                  border: Border.all(color: t.borderSubtle),
                                ),
                                child: Text(
                                  '${d.month.toString().padLeft(2, '0')}월 ${d.day.toString().padLeft(2, '0')}일',
                                  style: PTypo.caption.copyWith(
                                      color: t.fgPrimary,
                                      fontWeight: PFontWeight.semi,
                                      fontFamily: 'monospace'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Footer — 웹 ModalShell 과 동일: justify-end + gap-2 + auto-width
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x20, vertical: PSpace.x12),
            color: t.bgSurface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _ready && !_submitting ? _save : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('반복 저장'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── widgets ────────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.expense,
    required this.startDate,
    required this.iconData,
    required this.fg,
    required this.tokens,
  });
  final Expense expense;
  final String startDate;
  final IconData iconData;
  final Color fg;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.expenseType == 'INCOME';
    final amountText = '${isIncome ? '+' : '−'}${krw(expense.amount.abs())}';
    final title = (expense.merchant ?? '').isNotEmpty
        ? expense.merchant!
        : ((expense.description ?? '').isNotEmpty
            ? expense.description!
            : '거래');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: PRadius.brLg,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.14),
              borderRadius: PRadius.brTile,
            ),
            alignment: Alignment.center,
            child: Icon(iconData, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: PFontWeight.bold)),
                const SizedBox(height: 2),
                Text('$startDate 시작',
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: amountText,
                  style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.heavy,
                      fontFamily: 'monospace'),
                ),
                TextSpan(
                  text: '원',
                  style: PTypo.bodySm.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.heavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: PTypo.caption.copyWith(
                  color: t.fgSecondary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented(
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
                    color: o.$1 == value
                        ? tokens.bgBrand
                        : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(o.$2,
                      textAlign: TextAlign.center,
                      style: PTypo.bodySm.copyWith(
                          color: o.$1 == value
                              ? tokens.fgOnBrand
                              : tokens.fgTertiary,
                          fontWeight: o.$1 == value
                              ? PFontWeight.bold
                              : PFontWeight.medium)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DowGrid extends StatelessWidget {
  const _DowGrid(
      {required this.value, required this.onChanged, required this.tokens});
  final int value; // 0=일 ~ 6=토
  final ValueChanged<int> onChanged;
  final PorestTokens tokens;

  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == value
                      ? tokens.bgBrandSubtle
                      : tokens.bgSurface,
                  border: Border.all(
                    color: i == value
                        ? tokens.borderBrand
                        : tokens.borderSubtle,
                  ),
                  borderRadius: PRadius.brPill,
                ),
                child: Text(_labels[i],
                    style: PTypo.bodySm.copyWith(
                      color: i == value
                          ? tokens.fgBrandStrong
                          : tokens.fgPrimary,
                      fontWeight:
                          i == value ? PFontWeight.bold : PFontWeight.medium,
                    )),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.selected,
    required this.onSelect,
    required this.title,
    required this.tokens,
    this.subtitle,
    this.subtitleChild,
  });
  final bool selected;
  final VoidCallback onSelect;
  final String title;
  final String? subtitle;
  final Widget? subtitleChild;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: PRadius.brLg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color:
                selected ? tokens.borderBrand : tokens.borderSubtle,
          ),
          borderRadius: PRadius.brLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? tokens.borderBrand : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? tokens.borderBrand
                      : tokens.borderDefault,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.bgSurface,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: PTypo.bodySm.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: PTypo.caption
                            .copyWith(color: tokens.fgSecondary)),
                  ],
                  if (subtitleChild != null) ...[
                    const SizedBox(height: 4),
                    subtitleChild!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.tokens,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: PRadius.brLg,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.bgMuted,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: tokens.fgSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: PFontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: tokens.bgBrand,
          ),
        ],
      ),
    );
  }
}

// ─── helpers ────────────────────────────────────────────────────────────────

/// front `previewNextDates` 미러 (UI dow 0=일 ~ 6=토 사용).
List<DateTime> _previewNextDates(
  DateTime start,
  String frequency,
  int dayOfWeekUi, // 0=일 ~ 6=토
  int dayOfMonth,
  int count,
) {
  final out = <DateTime>[];
  var cursor = DateTime(start.year, start.month, start.day);

  if (frequency == 'WEEKLY') {
    // DateTime.weekday: Mon=1..Sun=7. UI: Sun=0..Sat=6 → 변환.
    final cursorUi = cursor.weekday % 7; // Sun(7) → 0, Mon(1) → 1, ...
    final diff = (dayOfWeekUi - cursorUi + 7) % 7;
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
