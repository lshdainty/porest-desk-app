import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_category_tile.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/recurring/application/recurring_providers.dart';
import 'package:porest_desk_app/features/recurring/domain/recurring_transaction.dart';

/// 반복 설정 drawer — **거래 기반 신규 생성**과 **기존 반복 수정**을 공용으로 처리.
///
/// - [expense] 제공 → 거래에서 반복 생성 (sourceExpenseRowId 연결, `repo.create`)
/// - [recurring] 제공 → 기존 반복 수정 (`repo.update`)
///
/// 정확히 하나만 제공한다. 거래 정보(카테고리·금액·가맹점)는 읽기 전용 요약
/// 카드로 보여주고, 사용자는 반복 주기·종료·옵션만 설정한다. 가계부 거래 상세의
/// "반복 설정"과 설정 화면의 "반복 거래 수정"이 같은 body를 공유한다.
void showRecurringSettingsDialog(
  BuildContext context, {
  Expense? expense,
  RecurringTransaction? recurring,
}) {
  assert(
    !(expense != null && recurring != null),
    'expense 와 recurring 을 동시에 줄 수 없습니다 (둘 다 null = 신규 추가)',
  );
  final isAdd = expense == null && recurring == null;
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: isAdd ? l.recurringAddTitle : l.expConvertRecurring,
    contentBuilder: (ctx, scrollCtrl) => _RecurringSettingsBody(
      expense: expense,
      recurring: recurring,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: isAdd ? l.recurringAdd : l.recurringSaveSubmit,
    ),
  );
}

enum _EndMode { none, count, date }

class _RecurringSettingsBody extends ConsumerStatefulWidget {
  const _RecurringSettingsBody({
    this.expense,
    this.recurring,
    required this.scrollController,
    required this.controller,
  });
  final Expense? expense;
  final RecurringTransaction? recurring;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_RecurringSettingsBody> createState() =>
      _RecurringSettingsBodyState();
}

class _RecurringSettingsBodyState
    extends ConsumerState<_RecurringSettingsBody> {
  bool get _isEdit => widget.recurring != null;
  bool get _isAdd => widget.recurring == null && widget.expense == null;

  _TxInputController? _txInput; // 신규 추가 모드에서만 (거래 입력)
  late final DateTime _fixedBaseDate; // edit/from-tx 시작일
  DateTime get _baseDate => _isAdd ? _txInput!.date : _fixedBaseDate;
  String get _startDay => _fmt(_baseDate);

  String _frequency = 'MONTHLY';
  int _dayOfWeekUi = 1; // 0=일 ~ 6=토 (UI). 저장 시 ISO 1~7 변환.
  int _dayOfMonth = 1;

  late _EndMode _endMode;
  final TextEditingController _endCountCtrl = TextEditingController(text: '12');
  late DateTime _endDate;

  bool _autoLog = true;
  bool _notifyDayBefore = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recurring;
    final e = widget.expense;

    if (_isAdd) {
      _txInput = _TxInputController(date: DateTime.now());
    } else {
      // base date: edit → recurring.startDate, from-tx → expense.expenseDate
      final raw = (_isEdit ? (r!.startDate ?? '') : (e!.expenseDate ?? ''))
          .trim();
      final parsed = raw.isNotEmpty
          ? DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw)
          : null;
      final today = DateTime.now();
      _fixedBaseDate = parsed ?? DateTime(today.year, today.month, today.day);
    }

    _frequency = r?.frequency ?? 'MONTHLY';

    // dayOfWeek: edit는 ISO 1~7 저장 → UI 0~6, create는 거래일 요일
    if (_isEdit && r!.dayOfWeek != null) {
      _dayOfWeekUi = r.dayOfWeek! % 7; // ISO Sun(7)→0, Mon(1)→1 ...
    } else {
      _dayOfWeekUi = _baseDate.weekday % 7; // Mon=1..Sun=7 → UI 1..0
    }
    _dayOfMonth = (r?.dayOfMonth ?? _baseDate.day).clamp(1, 31);

    // 종료 모드: edit는 저장값에서 복원, create는 종료일 기본
    if (_isEdit && r!.maxOccurrences != null) {
      _endMode = _EndMode.count;
    } else if (_isEdit && r!.endDate != null) {
      _endMode = _EndMode.date;
    } else if (_isEdit) {
      _endMode = _EndMode.none;
    } else {
      _endMode = _EndMode.date;
    }
    _endCountCtrl.text = (r?.maxOccurrences ?? 12).toString();
    _endDate = (_isEdit && r!.endDate != null)
        ? DateTime.parse(r.endDate!)
        : DateTime(_baseDate.year + 1, _baseDate.month, _baseDate.day);

    _autoLog = r?.autoLog ?? true;
    _notifyDayBefore = r?.notifyDayBefore ?? true;

    widget.controller.onSubmit = _save;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _endCountCtrl.dispose();
    _txInput?.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _ready {
    if (_endMode == _EndMode.count) {
      final n = int.tryParse(_endCountCtrl.text.trim());
      if (n == null || n <= 0) return false;
    }
    if (_isEdit) return true;
    if (_isAdd) {
      final i = _txInput!;
      return i.amountInt > 0 && i.categoryRowId != null && i.assetRowId != null;
    }
    return widget.expense!.categoryRowId != null &&
        widget.expense!.assetRowId != null;
  }

  Future<void> _save() async {
    if (!_ready || _submitting) return;
    final l = AppLocalizations.of(context);
    _setSubmitting(true);
    final isWeekly = _frequency == 'WEEKLY';
    final isMonthlyish = _frequency == 'MONTHLY' || _frequency == 'YEARLY';
    // UI 0=일 → ISO 7=일. UI 1~6 (월~토) → ISO 1~6.
    final dow = isWeekly ? (_dayOfWeekUi == 0 ? 7 : _dayOfWeekUi) : null;
    final dom = isMonthlyish ? _dayOfMonth : null;
    final endDateStr = _endMode == _EndMode.date ? _fmt(_endDate) : null;
    final maxOcc = _endMode == _EndMode.count
        ? int.tryParse(_endCountCtrl.text.trim())
        : null;
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      if (_isEdit) {
        final r = widget.recurring!;
        await repo.update(
          id: r.rowId,
          categoryRowId: r.categoryRowId,
          assetRowId: r.assetRowId,
          expenseType: r.expenseType,
          amount: r.amount.abs(),
          frequency: _frequency,
          intervalValue: r.intervalValue ?? 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          startDate: _startDay,
          endDate: endDateStr,
          maxOccurrences: maxOcc,
          description: (r.description ?? '').trim().isEmpty
              ? null
              : r.description!.trim(),
          merchant: (r.merchant ?? '').trim().isEmpty
              ? null
              : r.merchant!.trim(),
          paymentMethod: r.paymentMethod,
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
        );
      } else if (_isAdd) {
        final i = _txInput!;
        await repo.create(
          categoryRowId: i.categoryRowId!,
          assetRowId: i.assetRowId!,
          sourceExpenseRowId: null,
          expenseType: i.type,
          amount: i.amountInt,
          frequency: _frequency,
          intervalValue: 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          startDate: _startDay,
          endDate: endDateStr,
          maxOccurrences: maxOcc,
          description: i.memoOrNull,
          merchant: i.merchantOrNull,
          paymentMethod: i.paymentMethodOrNull,
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
        );
      } else {
        final e = widget.expense!;
        await repo.create(
          categoryRowId: e.categoryRowId!,
          assetRowId: e.assetRowId!,
          sourceExpenseRowId: e.rowId,
          expenseType: e.expenseType,
          amount: e.amount.abs(),
          frequency: _frequency,
          intervalValue: 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          startDate: _startDay,
          endDate: endDateStr,
          maxOccurrences: maxOcc,
          description: (e.description ?? '').trim().isEmpty
              ? null
              : e.description!.trim(),
          merchant: (e.merchant ?? '').trim().isEmpty
              ? null
              : e.merchant!.trim(),
          paymentMethod: e.paymentMethod,
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
        );
      }
      ref.invalidate(recurringListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(
        context,
        _isEdit ? l.recurringUpdated : l.recurringSaved,
        severity: PSnackSeverity.success,
      );
    } on ApiException catch (err) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${l.recurringSaveFailed}: ${err.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    final Widget topWidget;
    if (_isAdd) {
      topWidget = _TxFields(
        controller: _txInput!,
        onChanged: () => setState(() {}),
      );
    } else {
      // 요약 카드 데이터 — edit: recurring / from-tx: expense
      final cats = ref.watch(categoriesProvider).value ?? const [];
      final r = widget.recurring;
      final e = widget.expense;
      final catRowId = _isEdit ? r!.categoryRowId : e!.categoryRowId;
      final cat = catRowId == null
          ? null
          : cats.where((c) => c.rowId == catRowId).firstOrNull;
      final fg = cat == null
          ? t.fgBrand
          : resolveChartColor(context, cat.color, fallback: t.fgBrand);
      final iconData = lucideByName(cat?.icon ?? 'tag');
      final String summaryTitle;
      final int summaryAmount;
      final String summaryType;
      if (_isEdit) {
        summaryTitle = (r!.merchant ?? '').isNotEmpty
            ? r.merchant!
            : ((r.description ?? '').isNotEmpty
                  ? r.description!
                  : (r.categoryName ?? l.navRecurring));
        summaryAmount = r.amount;
        summaryType = r.expenseType;
      } else {
        summaryTitle = (e!.merchant ?? '').isNotEmpty
            ? e.merchant!
            : ((e.description ?? '').isNotEmpty ? e.description! : l.expTxFallback);
        summaryAmount = e.amount;
        summaryType = e.expenseType;
      }
      topWidget = _SourceCard(
        title: summaryTitle,
        amount: summaryAmount,
        expenseType: summaryType,
        startDate: _startDay,
        iconData: iconData,
        fg: fg,
        tokens: t,
      );
    }

    final nextDates = _previewNextDates(
      _baseDate,
      _frequency,
      _dayOfWeekUi,
      _dayOfMonth,
      3,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_ready);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        Text(
          l.recurringIntro,
          style: PTypo.bodySm.copyWith(
            color: t.fgSecondary,
            height: PLineHeight.normal,
          ),
        ),
        const SizedBox(height: 14),
        topWidget,
        const SizedBox(height: 18),

        _Section(
          title: l.recurringFrequencyLabel,
          child: PTabs<String>(
            value: _frequency,
            variant: PTabsVariant.container,
            size: PTabsSize.sm,
            expand: true,
            items: [
              PTabItem(value: 'DAILY', label: l.calRepeatDaily),
              PTabItem(value: 'WEEKLY', label: l.calRepeatWeekly),
              PTabItem(value: 'MONTHLY', label: l.calRepeatMonthly),
              PTabItem(value: 'YEARLY', label: l.calRepeatYearly),
            ],
            onChanged: (v) => setState(() => _frequency = v),
          ),
        ),

        if (_frequency == 'WEEKLY')
          _Section(
            title: l.recurringDayOfWeekLabel,
            child: _DowGrid(
              value: _dayOfWeekUi,
              onChanged: (v) => setState(() => _dayOfWeekUi = v),
              tokens: t,
            ),
          ),

        if (_frequency == 'MONTHLY')
          _Section(
            title: l.recurringDayOfMonthLabel,
            child: Row(
              children: [
                Text(l.calRepeatMonthly, style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: PTextInput(
                    numbersOnly: true,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    controller:
                        TextEditingController(text: _dayOfMonth.toString())
                          ..selection = TextSelection.collapsed(
                            offset: _dayOfMonth.toString().length,
                          ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n == null) return;
                      setState(() => _dayOfMonth = n.clamp(1, 31));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('일', style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.recurringDayNote,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        _Section(
          title: l.recurringEndLabel,
          child: Column(
            children: [
              _RadioCard(
                selected: _endMode == _EndMode.none,
                onSelect: () => setState(() => _endMode = _EndMode.none),
                title: l.recurringIndefinite,
                subtitle: l.recurringIndefiniteDesc,
                tokens: t,
              ),
              const SizedBox(height: 8),
              _RadioCard(
                selected: _endMode == _EndMode.count,
                onSelect: () => setState(() => _endMode = _EndMode.count),
                title: l.recurringByCount,
                tokens: t,
                subtitleChild: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.recurringTotal,
                      style: PTypo.caption.copyWith(color: t.fgSecondary),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 64,
                      child: PTextInput(
                        controller: _endCountCtrl,
                        numbersOnly: true,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onChanged: (_) =>
                            setState(() => _endMode = _EndMode.count),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.recurringTimesUnit,
                      style: PTypo.caption.copyWith(color: t.fgSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _RadioCard(
                selected: _endMode == _EndMode.date,
                onSelect: () => setState(() => _endMode = _EndMode.date),
                title: l.recurringByDate,
                tokens: t,
                subtitleChild: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: PDateInput(
                    value: _endDate,
                    onChanged: (d) {
                      if (d == null) return;
                      setState(() {
                        _endMode = _EndMode.date;
                        _endDate = d;
                      });
                    },
                    firstDate: _baseDate,
                    lastDate: DateTime(_baseDate.year + 30, 12, 31),
                  ),
                ),
              ),
            ],
          ),
        ),

        _Section(
          title: l.recurringOptions,
          child: Column(
            children: [
              _ToggleRow(
                icon: LucideIcons.zap,
                title: l.recurringAutoLog,
                subtitle: l.recurringAutoLogDesc,
                value: _autoLog,
                onChanged: (v) => setState(() => _autoLog = v),
                tokens: t,
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                icon: LucideIcons.bell,
                title: l.recurringNotifyDayBefore,
                subtitle: l.recurringNotifyDesc,
                value: _notifyDayBefore,
                onChanged: (v) => setState(() => _notifyDayBefore = v),
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
                    Icon(LucideIcons.calendar, size: 13, color: t.fgSecondary),
                    const SizedBox(width: 6),
                    Text(
                      l.recurringNextDates,
                      style: PTypo.caption.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
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
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: t.bgMuted,
                          borderRadius: PRadius.brFull,
                          border: Border.all(color: t.borderSubtle),
                        ),
                        child: Text(
                          '${d.month.toString().padLeft(2, '0')}월 ${d.day.toString().padLeft(2, '0')}일',
                          style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.semi,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── widgets ────────────────────────────────────────────────────────────────

/// 읽기 전용 거래/반복 요약 카드 (생성·수정 공용).
class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.amount,
    required this.expenseType,
    required this.startDate,
    required this.iconData,
    required this.fg,
    required this.tokens,
  });
  final String title;
  final int amount;
  final String expenseType;
  final String startDate;
  final IconData iconData;
  final Color fg;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isIncome = expenseType == 'INCOME';
    final amountText = '${isIncome ? '+' : '−'}${krw(amount.abs())}';
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
              borderRadius: PRadius.brLg,
            ),
            alignment: Alignment.center,
            child: Icon(iconData, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.bodySm.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.recurringStartFrom(startDate),
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                ),
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
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: wonUnit(),
                  style: PTypo.bodySm.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
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
          Text(
            title,
            style: PTypo.caption.copyWith(
              color: t.fgSecondary,
              fontWeight: PFontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DowGrid extends StatelessWidget {
  const _DowGrid({
    required this.value,
    required this.onChanged,
    required this.tokens,
  });
  final int value; // 0=일 ~ 6=토
  final ValueChanged<int> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final labels = weekdayLabels();
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
                  color: i == value ? tokens.bgBrandSubtle : tokens.bgSurface,
                  border: Border.all(
                    color: i == value
                        ? tokens.borderBrand
                        : tokens.borderSubtle,
                  ),
                  borderRadius: PRadius.brFull,
                ),
                child: Text(
                  labels[i],
                  style: PTypo.bodySm.copyWith(
                    color: i == value ? tokens.fgBrandStrong : tokens.fgPrimary,
                    fontWeight: i == value
                        ? PFontWeight.bold
                        : PFontWeight.medium,
                  ),
                ),
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
            color: selected ? tokens.borderBrand : tokens.borderSubtle,
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
                  color: selected ? tokens.borderBrand : tokens.borderDefault,
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
                  Text(
                    title,
                    style: PTypo.bodySm.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: PTypo.caption.copyWith(color: tokens.fgSecondary),
                    ),
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
                Text(
                  title,
                  style: PTypo.bodySm.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                ),
              ],
            ),
          ),
          PSwitch(value: value, onChanged: onChanged),
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

// ─────────────────────────────────────────────
// 거래 입력 (inline) — add_tx_sheet 와 독립. 지출/수입만, 시간 없음, 날짜 = 반복 시작일.
// (웹 RecurringAddDialog 와 동일 구조 — 공용 TxInputForm 분리 대신 각 호스트 자체 보유)

const _txPaymentMethodValues = ['CASH', 'CARD', 'TRANSFER', 'OTHER'];

String _txPayLabel(AppLocalizations l, String v) => switch (v) {
      'CASH' => l.expPayCash,
      'CARD' => l.expPayCard,
      'TRANSFER' => l.expPayTransfer,
      _ => l.expPayOther,
    };

const Map<String, List<String>?> _txPaymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

/// 반복 추가 전용 거래 입력 상태 (지출/수입). 시간/이체 없음.
class _TxInputController {
  _TxInputController({DateTime? date})
      : date = date ?? DateTime.now(),
        amountCtrl = TextEditingController(),
        merchantCtrl = TextEditingController(),
        memoCtrl = TextEditingController();

  final TextEditingController amountCtrl;
  final TextEditingController merchantCtrl;
  final TextEditingController memoCtrl;

  String type = 'EXPENSE'; // EXPENSE / INCOME
  int? categoryRowId;
  int? assetRowId;
  String paymentMethod = '';
  DateTime date;

  int get amountInt => int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String? get merchantOrNull =>
      merchantCtrl.text.trim().isEmpty ? null : merchantCtrl.text.trim();
  String? get memoOrNull =>
      memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim();
  String? get paymentMethodOrNull =>
      paymentMethod.isEmpty ? null : paymentMethod;

  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    memoCtrl.dispose();
  }
}

/// 반복 추가 거래 입력 폼 (inline). 타입(지출/수입) · 금액 · 카테고리 · 거래처 ·
/// 결제 수단 · 계좌 · 반복 시작일 · 메모.
class _TxFields extends ConsumerWidget {
  const _TxFields({required this.controller, required this.onChanged});

  final _TxInputController controller;
  final VoidCallback onChanged;

  void _set(VoidCallback mutate) {
    mutate();
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final c = controller;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);

    final amountInt = c.amountInt;
    final amountColor = c.type == 'EXPENSE' ? t.fgExpense : t.fgIncome;
    final amountPrefix = c.type == 'EXPENSE' ? '−' : '+';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 (지출/수입)
        PTabs<String>(
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          value: c.type,
          onChanged: (v) => _set(() => c.type = v),
          items: [
            PTabItem(value: 'EXPENSE', label: l.expTypeExpense),
            PTabItem(value: 'INCOME', label: l.expTypeIncome),
          ],
        ),
        const SizedBox(height: PSpace.x12),

        // 금액
        PSectionLabel(l.expAmount),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.amountCtrl,
          numbersOnly: true,
          placeholder: '0',
          prefixText: amountInt > 0 ? amountPrefix : null,
          suffixText: wonUnit(),
          style: PTypo.h4.copyWith(
            color: amountColor,
            fontWeight: PFontWeight.bold,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: PSpace.x16),

        // 카테고리
        PSectionLabel(l.expCategory, variant: PSectionLabelVariant.eyebrow),
        const SizedBox(height: PSpace.x8),
        categoriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: PCircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            '${l.categoryLoadError}: $e',
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (categories) {
            final topCategories =
                categories
                    .where(
                      (cat) =>
                          cat.expenseType == c.type &&
                          (cat.parentRowId == null || cat.parentRowId == 0),
                    )
                    .toList()
                  ..sort(
                    (a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0),
                  );
            if (topCategories.isEmpty) {
              return Text(
                l.expNoCategoryForType,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              );
            }

            final childrenByParent = <int, List<dynamic>>{};
            for (final cat in categories) {
              if (cat.parentRowId == null ||
                  cat.parentRowId == 0 ||
                  cat.expenseType != c.type) {
                continue;
              }
              childrenByParent
                  .putIfAbsent(cat.parentRowId!, () => [])
                  .add(cat);
            }
            for (final list in childrenByParent.values) {
              list.sort(
                (a, b) => ((a.sortOrder ?? 0) as int).compareTo(
                  (b.sortOrder ?? 0) as int,
                ),
              );
            }

            final selectedCat = c.categoryRowId == null
                ? null
                : categories
                      .where((cat) => cat.rowId == c.categoryRowId)
                      .firstOrNull;
            final selectedParentId = selectedCat == null
                ? null
                : (selectedCat.parentRowId == null ||
                          selectedCat.parentRowId == 0
                      ? selectedCat.rowId
                      : selectedCat.parentRowId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        for (final cat in topCategories)
                          SizedBox(
                            width: cellWidth,
                            child: PCategoryTile(
                              name: cat.categoryName,
                              color: resolveChartColor(
                                context,
                                cat.color,
                                fallback: t.fgBrand,
                              ),
                              icon: lucideByName(cat.icon ?? 'tag'),
                              active: selectedParentId == cat.rowId,
                              onTap: () => _set(() {
                                final firstChild =
                                    childrenByParent[cat.rowId]?.first;
                                c.categoryRowId = firstChild != null
                                    ? firstChild.rowId
                                    : cat.rowId;
                              }),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (selectedParentId != null &&
                    (childrenByParent[selectedParentId]?.isNotEmpty ??
                        false)) ...[
                  const SizedBox(height: 10),
                  _SelectField<int>(
                    value: c.categoryRowId,
                    hint: l.expSubcategory,
                    items: [
                      _SelectOption<int>(
                        selectedParentId,
                        l.recurringParentCategory(topCategories.firstWhere((cat) => cat.rowId == selectedParentId).categoryName),
                      ),
                      for (final child in childrenByParent[selectedParentId]!)
                        _SelectOption<int>(
                          child.rowId as int,
                          child.categoryName as String,
                        ),
                    ],
                    onChanged: (v) => _set(() => c.categoryRowId = v),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: PSpace.x12),

        // 거래처
        PSectionLabel(c.type == 'INCOME' ? l.expIncomeSource : l.recurringMerchant),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.merchantCtrl,
          placeholder: c.type == 'INCOME' ? l.expIncomeSourcePlaceholder : l.recurringMerchantPlaceholder,
        ),
        const SizedBox(height: PSpace.x12),

        // 결제 수단
        PSectionLabel(c.type == 'INCOME' ? l.expIncomeMethod : l.expPaymentMethod),
        const SizedBox(height: PSpace.x4),
        _SelectField<String>(
          value: c.paymentMethod.isEmpty ? null : c.paymentMethod,
          hint: l.recurringSelectNone,
          items: [
            _SelectOption<String>('', l.recurringSelectNone),
            for (final pm in _txPaymentMethodValues)
              _SelectOption<String>(pm, _txPayLabel(l, pm)),
          ],
          onChanged: (v) => _set(() {
            c.paymentMethod = v ?? '';
            if (c.paymentMethod.isNotEmpty && c.assetRowId != null) {
              final allowed = _txPaymentAssetTypes[c.paymentMethod];
              if (allowed != null) {
                final assets = assetsAsync.value ?? const [];
                final cur =
                    assets.where((a) => a.rowId == c.assetRowId).firstOrNull;
                if (cur != null && !allowed.contains(cur.assetType)) {
                  c.assetRowId = null;
                }
              }
            }
          }),
        ),
        const SizedBox(height: PSpace.x12),

        // 계좌·카드
        PSectionLabel(c.type == 'INCOME' ? l.expDepositAccount : l.recurringAssetCard),
        const SizedBox(height: PSpace.x4),
        assetsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: PCircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            '${l.recurringAssetLoadError}: $e',
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (assets) {
            final allowed = c.paymentMethod.isNotEmpty
                ? _txPaymentAssetTypes[c.paymentMethod]
                : null;
            final filtered = allowed == null
                ? assets
                : assets.where((a) => allowed.contains(a.assetType)).toList();
            return _SelectField<int>(
              value: c.assetRowId,
              hint: l.recurringSelectNone,
              items: [
                _SelectOption<int>(-1, l.recurringSelectNone),
                for (final a in filtered)
                  _SelectOption<int>(
                    a.rowId,
                    a.institution != null
                        ? '${a.institution} · ${a.assetName}'
                        : a.assetName,
                  ),
              ],
              onChanged: (v) => _set(() => c.assetRowId = v == -1 ? null : v),
            );
          },
        ),
        const SizedBox(height: PSpace.x12),

        // 반복 시작일 (날짜만 — 웹 정합)
        PSectionLabel(l.recurringStartDateLabel),
        const SizedBox(height: PSpace.x4),
        PDateInput(
          value: c.date,
          onChanged: (d) {
            if (d != null) _set(() => c.date = d);
          },
          firstDate: DateTime(2020),
          lastDate: DateTime(2030, 12, 31),
        ),
        const SizedBox(height: PSpace.x16),

        // 메모
        PSectionLabel(l.navMemo),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.memoCtrl,
          maxLines: 2,
          placeholder: l.expMemoPlaceholder,
        ),
      ],
    );
  }
}

class _SelectOption<T> {
  const _SelectOption(this.value, this.label);
  final T value;
  final String label;
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
  });
  final T? value;
  final List<_SelectOption<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return PSelect<T>(
      value: items.any((i) => i.value == value) ? value : null,
      placeholder: hint,
      onChanged: onChanged,
      items: [
        for (final opt in items)
          PSelectItem<T>(value: opt.value, label: opt.label),
      ],
    );
  }
}
