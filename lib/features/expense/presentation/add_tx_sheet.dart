import 'package:flutter/material.dart';
import 'package:porest_desk_app/core/format/amount_limits.dart';
import 'package:porest_desk_app/core/format/currency.dart';
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
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_category_tile.dart';
import 'package:porest_desk_app/shared/widgets/p_checkbox.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/features/preset/domain/expense_template.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/features/expense_split/data/expense_split_repository.dart';
import 'package:porest_desk_app/features/expense_split/presentation/split_tx_dialog.dart';
import 'package:porest_desk_app/features/sms/data/sms_android.dart';
import 'package:porest_desk_app/features/sms/data/sms_repository.dart';
import 'package:porest_desk_app/features/sms/domain/sms_draft.dart';

String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 거래 추가/편집 시트 (front `AddTxSheet` 미러).
///
/// [edit] 가 주어지면 편집 모드 (PUT /expense/{id}), 아니면 신규 (POST /expense).
/// 성공 시 해당 월 expensesProvider invalidate.
void showAddTxSheet(
  BuildContext context, {
  String? defaultDate,
  Expense? edit,

  /// 환불 모드 — 이 지출의 환불을 기록한다.
  /// 수입으로 들어가되 원거래에 묶여 통계에서 지출을 상계한다(수입으로 부풀지 않는다).
  Expense? refundOf,

  /// 이체 편집 모드 — 서버가 이자 지출·잔액 이력을 되돌렸다 다시 만든다(rowId 유지).
  AssetTransfer? editTransfer,

  /// 결제 문자 초안 — 파싱 결과로 폼을 채우고, 저장은 문자 전용 경로로 보낸다
  /// (카드 연결 기억·취소 문자 차단이 그 경로에 있다).
  SmsDraft? smsDraft,
}) {
  final controller = PSheetController();
  final l = AppLocalizations.of(context);
  final isEdit = edit != null || editTransfer != null;
  showPSheet<void>(
    context,
    title: isEdit
        ? l.expEdit
        : (refundOf != null ? l.expRefundRecord : l.expAdd),
    contentBuilder: (ctx, scrollCtrl) => _AddTxBody(
      defaultDate: defaultDate,
      edit: edit,
      refundOf: refundOf,
      editTransfer: editTransfer,
      smsDraft: smsDraft,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: isEdit ? l.actionSave : l.expAddShort,
    ),
  ).whenComplete(controller.dispose);
}

class _AddTxBody extends ConsumerStatefulWidget {
  const _AddTxBody({
    this.defaultDate,
    this.edit,
    this.refundOf,
    this.editTransfer,
    this.smsDraft,
    required this.scrollController,
    required this.controller,
  });
  final String? defaultDate;
  final Expense? edit;
  final Expense? refundOf;
  final AssetTransfer? editTransfer;
  final SmsDraft? smsDraft;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_AddTxBody> createState() => _AddTxBodyState();
}

class _AddTxBodyState extends ConsumerState<_AddTxBody> {
  late final _TxInputController _input;
  bool _submitting = false;

  /// 프리셋을 통해 폼이 초기화된 경우 해당 프리셋 ID — 저장 성공 후 /touch.
  int? _appliedPresetId;

  // 편집 모드 분할 일치화: 서버 분할(build 에서 적재) + 이번 세션에서 맞춘 분할.
  List<SplitInput> _serverSplits = const [];
  List<SplitInput>? _reconciledSplits;
  List<SplitInput> get _effectiveSplits => _reconciledSplits ?? _serverSplits;
  int get _splitSum => _effectiveSplits.fold<int>(0, (s, x) => s + x.amount);
  // 금액을 바꿔 분할 합과 어긋남(편집·지출/수입만). 이때 저장을 막고 일치화 유도.
  bool get _splitMismatch =>
      _isEdit &&
      _input.type != 'TRANSFER' &&
      _input.amountInt > 0 &&
      _effectiveSplits.isNotEmpty &&
      _input.amountInt != _splitSum;

  bool get _isEdit => widget.edit != null || widget.editTransfer != null;

  /// 결제 문자에서 온 초안인가 — 저장이 `/import/sms/commit` 으로 간다.
  bool get _isSmsDraft => widget.smsDraft != null;

  /// 종류 토글을 잠그는가 — 편집뿐이다.
  ///
  /// 결제 문자 초안도 한동안 잠겨 있었다(#326). 저장 경로인 `/import/sms/commit` 이
  /// `expenseType` 을 안 받고 서버가 `EXPENSE` 를 박아 넣어서, 수입으로 바꿔 저장해도
  /// 지출로 남았기 때문이다 — 화면만 수입이라 말하느니 못 고르게 두는 게 나았다.
  /// **서버가 이제 그 값을 받으므로**(desk-back #326) 잠금을 푼다. 환불·입금 문자를
  /// 수입으로 남길 수 있어야 그 달 지출이 부풀지 않는다.
  bool get _typeLocked => _isEdit;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    DateTime date;
    TimeOfDay time = TimeOfDay.now();
    final tr = widget.editTransfer;
    if (tr?.transferDate != null) {
      date = parseIsoDate(tr!.transferDate!.substring(0, 10));
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(tr.transferDate!);
      if (m != null) {
        time = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
      }
    } else if (e?.expenseDate != null) {
      date = parseIsoDate(e!.expenseDate!.substring(0, 10));
      // 시간 추출 (T 또는 공백 뒤 HH:mm)
      final raw = e.expenseDate!;
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(raw);
      if (m != null) {
        time = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
      }
    } else if (widget.smsDraft?.parsed.expenseDate != null) {
      final raw = widget.smsDraft!.parsed.expenseDate!;
      date = parseIsoDate(raw.substring(0, 10));
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(raw);
      if (m != null) {
        time = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
      }
    } else if (widget.defaultDate != null) {
      date = parseIsoDate(widget.defaultDate!);
    } else {
      date = DateTime.now();
    }
    // 환불 모드 — 타입은 수입 고정(원거래 연결이 상계를 만든다), 나머지는 원거래 승계.
    // 부분 환불이면 금액만 고치면 된다.
    final r = widget.refundOf;
    // 환불 상한 — **원거래 금액이 아니라 남은 금액**이다(QA #152).
    final refundCap = r == null ? null : _refundCapOf(r);
    // 결제 문자 초안 — 카드 결제라 유형·결제수단은 고정이고, 나머지는 파싱 값을 채운다.
    final sms = widget.smsDraft?.parsed;
    _input = _TxInputController(
      type: tr != null
          ? 'TRANSFER'
          : (r != null ? 'INCOME' : (e?.expenseType ?? 'EXPENSE')),
      amount: tr != null
          ? tr.amount.toString()
          : e != null
          ? e.amount.toString()
          : (refundCap != null
                // 이미 일부 환불된 거래는 **남은 금액**으로 연다. 원거래 금액으로
                // 열면 그대로 저장만 눌러도 합계가 원거래를 넘는다 — 포매터는
                // 타이핑을 막을 뿐, 처음부터 들어 있는 값은 안 건드린다.
                ? (refundCap > 0 ? refundCap.toString() : '')
                : (sms?.amount?.toString() ?? '')),
      memo: tr?.description ?? e?.description ?? '',
      merchant: e?.merchant ?? r?.merchant ?? sms?.merchant ?? '',
      paymentMethod:
          e?.paymentMethod ?? r?.paymentMethod ?? (sms != null ? 'CARD' : ''),
      categoryRowId: e?.categoryRowId ?? r?.categoryRowId ?? sms?.categoryRowId,
      // 이체는 출금 자산이 assetRowId, 입금 자산이 toAssetRowId 다.
      assetRowId:
          tr?.fromAssetRowId ??
          e?.assetRowId ??
          r?.assetRowId ??
          sms?.assetRowId,
      date: date,
      time: time,
    );
    _input.refundCap = refundCap;
    _input.refundedBefore = r?.refundedAmount ?? 0;
    if (tr != null) {
      _input.toAssetRowId = tr.toAssetRowId;
      if ((tr.fee ?? 0) > 0) _input.feeCtrl.text = tr.fee.toString();
      if ((tr.interestAmount ?? 0) > 0) {
        _input.interestCtrl.text = tr.interestAmount.toString();
      }
    }
    // 편집·환불은 원거래의 통화를 승계한다 — 해외 결제를 고치는데 원화로 되돌아가면
    // 원 통화 기록이 조용히 지워진다.
    final src = e ?? r;
    if (src != null) {
      // 원화 거래는 `originalCurrency` 가 `null` 로 온다 — 그때도 원화라고 못
      // 박는다. 안 박으면 설정의 기본 통화가 흘러들어, 원화로 적어 둔 거래를
      // 열기만 해도 해외 결제 입력이 펼쳐진다(D7).
      _input.txCurrency = src.originalCurrency ?? kDefaultCurrency;
      if (src.originalCurrency != null) {
        _input.origAmountCtrl.text = _trimNum(src.originalAmount);
        _input.fxRateCtrl.text = _trimNum(src.exchangeRate);
      }
    }
    if (e?.installmentMonths != null) {
      _input.installmentMonths = e!.installmentMonths!;
    } else if (sms?.installmentMonths != null) {
      _input.installmentMonths = sms!.installmentMonths!;
    }
    if (sms != null) {
      // 문자에 외화가 안 실렸으면 원화 결제다 — 설정의 기본 통화가 외화여도
      // 여기선 문자가 맞다. 안 막으면 원화 결제 문자가 해외 결제 입력으로 열린다.
      _input.txCurrency = sms.originalCurrency ?? kDefaultCurrency;
      if (sms.originalCurrency != null) {
        _input.origAmountCtrl.text = _trimNum(sms.originalAmount?.toDouble());
      }
    }
    // 카드를 알아봤는데 아직 안 외운 경우에만 "이 카드로 기억" 을 물어본다.
    _input.smsRememberAsk = widget.smsDraft?.canRememberCard ?? false;
    _input.autoSource = e?.autoSource;
    widget.controller.onSubmit = _submit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
  }

  void _syncController() {
    widget.controller.setCanSubmit(_canSubmit);
    widget.controller.setSubmitting(_submitting);
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _applyPreset(ExpenseTemplate p) {
    final locked = (p.lockAmount ?? 'N') == 'Y';
    setState(() {
      _appliedPresetId = p.rowId;
      _input.type = p.expenseType;
      // 웹과 동일: lockAmount === 'Y' 일 때만 금액 채움, 아니면 비워둠
      _input.amountCtrl.text = locked ? (p.amount ?? 0).toString() : '';
      _input.categoryRowId = p.categoryRowId;
      _input.assetRowId = p.assetRowId;
      _input.memoCtrl.text = p.description ?? '';
      _input.merchantCtrl.text = p.merchant ?? '';
      _input.paymentMethod = p.paymentMethod ?? '';
      _input.amountLocked = locked;
    });
  }

  void _clearPresetMark() {
    if (_appliedPresetId == null) return;
    setState(() => _appliedPresetId = null);
  }

  Future<void> _showSavePresetDialog() async {
    final amount = _input.amountInt;
    if (amount <= 0 || _input.categoryRowId == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _SavePresetDialog(
        seedExpenseType: _input.type == 'TRANSFER' ? 'EXPENSE' : _input.type,
        seedAmount: amount,
        seedCategoryRowId: _input.categoryRowId!,
        seedAssetRowId: _input.assetRowId,
        seedMerchant: _input.merchantCtrl.text.trim(),
        seedDescription: _input.memoCtrl.text.trim(),
        seedPaymentMethod: _input.paymentMethod,
      ),
    );
  }

  bool get _canSubmit {
    final amount = _input.amountInt;
    if (_submitting || amount <= 0) return false;
    // 환불은 남은 환불 가능액을 넘을 수 없다(QA #152). 금액칸의 포매터는 **타이핑만**
    // 막는다 — 프리셋 적용과 외화 환산은 칸에 값을 직접 꽂으므로 그 경로로 들어온
    // 초과값은 여기서만 걸린다.
    if (_input.amountOverRefundCap) return false;
    if (_input.type == 'TRANSFER') {
      return _input.assetRowId != null &&
          _input.toAssetRowId != null &&
          _input.assetRowId != _input.toAssetRowId;
    }
    // 자산은 선택사항 — 자산까지 관리하지 않고 가계부로만 쓰는 사용법을 막지 않는다(웹 정합).
    if (_input.categoryRowId == null) return false;
    // 분할 합 불일치 시 저장 보류 — 배너의 '분할 내역 맞추기'로 먼저 일치화.
    if (_splitMismatch) return false;
    return true;
  }

  Future<void> _submit() async {
    final amount = _input.amountInt;
    final isoDate = _input.isoDate;
    final dateStr = '${isoDate}T${_formatTime(_input.time)}:00';
    final desc = _input.memoOrNull;
    final merchant = _input.merchantOrNull;
    final payment = _input.paymentMethodOrNull;
    // 할부는 신용카드 지출에만 — 그 밖의 조합에선 값을 흘리지 않는다.
    final installment = _input.installmentMonths > 1
        ? _input.installmentMonths
        : null;
    // 환불 모드에서만 원거래를 묶는다 — 이 연결이 통계 상계를 만든다.
    final refundOf = (widget.refundOf != null && _input.type == 'INCOME')
        ? widget.refundOf!.rowId
        : null;
    // 원 통화는 셋이 함께여야 의미가 있다 — 서버도 반쪽이면 전부 비운다.
    final origAmount = _input.origAmountOrNull;
    final origCurrency = origAmount != null ? _input.currency : null;
    final fxRate = origAmount != null ? _input.fxRateOrNull : null;
    final d = _input.date;

    if (_input.type == 'TRANSFER') {
      _setSubmitting(true);
      try {
        final fee = int.tryParse(_input.feeCtrl.text.replaceAll(',', ''));
        // 이자는 대출 상환에만 — 그 밖의 이체엔 값을 흘리지 않는다.
        final interest = _showInterest(_input, ref.read(assetsProvider).value)
            ? int.tryParse(_input.interestCtrl.text.replaceAll(',', ''))
            : null;
        final aRepo = await ref.read(assetRepositoryProvider.future);
        final editing = widget.editTransfer;
        if (editing != null) {
          await aRepo.updateTransfer(
            rowId: editing.rowId,
            fromAssetRowId: _input.assetRowId!,
            toAssetRowId: _input.toAssetRowId!,
            amount: amount,
            fee: fee,
            interestAmount: interest,
            description: desc,
            transferDate: dateStr,
          );
        } else {
          await aRepo.createTransfer(
            fromAssetRowId: _input.assetRowId!,
            toAssetRowId: _input.toAssetRowId!,
            amount: amount,
            fee: fee,
            interestAmount: interest,
            description: desc,
            transferDate: dateStr,
          );
        }
        ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
        invalidateAfterExpenseChange(ref);
        if (!mounted) return;
        Navigator.of(context).pop();
      } on ApiException {
        if (!mounted) return;
      } finally {
        if (mounted) _setSubmitting(false);
      }
      return;
    }

    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      if (_isEdit) {
        // 이 시트가 소유한 칸은 비운 상태 그대로 실어야 지워진다 — 키를 빼면
        // 서버가 옛 값을 지킨다(QA #99). 환불 연결(refundOf)만 예외다:
        // 편집 시트엔 그 칸이 없어, null 로 실으면 원거래 연결이 끊긴다.
        await repo.update(
          id: widget.edit!.rowId,
          categoryRowId: _input.categoryRowId!,
          assetRowId: Patch.set(_input.assetRowId),
          expenseType: _input.type,
          amount: amount,
          expenseDate: dateStr,
          description: Patch.set(desc),
          merchant: Patch.set(merchant),
          paymentMethod: Patch.set(payment),
          installmentMonths: Patch.set(installment),
          refundOfExpenseRowId: refundOf,
          originalAmount: Patch.set(origAmount),
          originalCurrency: Patch.set(origCurrency),
          exchangeRate: Patch.set(fxRate),
          // 일치화한 분할이 있으면 금액과 함께 원자적으로 교체(백엔드가 합==금액 검증).
          splits: _reconciledSplits,
        );
        // 분할이 교체됐을 수 있으니 분할 쿼리도 무효화.
        ref.invalidate(expenseSplitsProvider(widget.edit!.rowId));
      } else if (widget.smsDraft != null) {
        // 결제 문자는 전용 경로로 저장한다 — 서버가 원문을 다시 봐 취소 문자를 막고,
        // 체크했다면 (카드 힌트 → 자산) 을 기억한다. 저장 자체는 같은 지출 생성이다.
        final smsRepo = await ref.read(smsRepositoryProvider.future);
        await smsRepo.commit(
          text: widget.smsDraft!.text,
          assetRowId: _input.assetRowId,
          categoryRowId: _input.categoryRowId,
          // 종류를 안 실으면 서버가 지출로 본다 — 환불 문자를 수입으로 골라도
          // 지출로 남아 그 달 지출이 부푼다(desk-back #326).
          expenseType: _input.type,
          amount: amount,
          merchant: merchant,
          description: desc,
          expenseDate: dateStr,
          paymentMethod: payment,
          installmentMonths: installment,
          originalAmount: origAmount,
          originalCurrency: origCurrency,
          exchangeRate: fxRate,
          rememberCard: _input.assetRowId != null && _input.smsRememberCard,
        );
        // 수신 보관함에서 온 문자면 기록됐으니 목록에서 뺀다.
        // 실패해도 본 저장에는 영향이 없다 — 목록에 한 줄 남을 뿐이다.
        final inboxId = widget.smsDraft!.inboxId;
        if (inboxId != null) {
          try {
            await SmsAndroid.removeFromInbox(inboxId);
          } catch (_) {
            /* 보관함 정리 실패는 저장 결과를 바꾸지 않는다 */
          }
        }
      } else {
        await repo.create(
          categoryRowId: _input.categoryRowId!,
          assetRowId: _input.assetRowId,
          expenseType: _input.type,
          amount: amount,
          expenseDate: dateStr,
          description: desc,
          merchant: merchant,
          paymentMethod: payment,
          installmentMonths: installment,
          refundOfExpenseRowId: refundOf,
          originalAmount: origAmount,
          originalCurrency: origCurrency,
          exchangeRate: fxRate,
        );
      }
      // 프리셋으로 채운 뒤 일반 저장한 경우 useCount/lastUsedAt 갱신.
      if (!_isEdit && _appliedPresetId != null) {
        try {
          final pRepo = await ref.read(presetRepositoryProvider.future);
          await pRepo.touch(_appliedPresetId!);
          ref.invalidate(presetListProvider);
        } catch (_) {
          /* touch 실패는 본 거래 저장에 영향 없음 */
        }
      }
      // 원래 거래의 월 + 새 월 모두 invalidate (날짜 변경 가능성)
      if (_isEdit && widget.edit!.expenseDate != null) {
        final orig = parseIsoDate(widget.edit!.expenseDate!.substring(0, 10));
        if (orig.year != d.year || orig.month != d.month) {
          ref.invalidate(
            monthExpensesProvider((year: orig.year, month: orig.month)),
          );
        }
      }
      ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
      invalidateAfterExpenseChange(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 설정의 기본 통화를 매 빌드 흘려 넣는다(D7 · QA #124) — `/me/preferences` 는
    // 이 시트보다 늦게 도착할 수 있고, 열 때 한 번만 읽으면 첫 렌더의 원화에
    // 잠긴다. 아직 안 고른 **새 거래**에만 닿는다(`_TxInputController.currency`).
    _input.defaultCurrency = ref.watch(defaultCurrencyProvider);
    final presetsAsync = _isEdit
        ? const AsyncValue<List<ExpenseTemplate>>.data(<ExpenseTemplate>[])
        : ref.watch(presetListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    // 편집 모드: 기존 분할을 적재해 금액↔분할 합 불일치 판정(일치화 유도).
    if (_isEdit) {
      final sp = ref.watch(expenseSplitsProvider(widget.edit!.rowId)).value;
      _serverSplits = sp == null
          ? const []
          : [
              for (final s in sp)
                SplitInput(
                  categoryRowId: s.categoryRowId,
                  amount: s.amount,
                  label: s.label,
                  sortOrder: s.sortOrder,
                ),
            ];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        _TxInputForm(
          controller: _input,
          onChanged: () => setState(_syncController),
          typeReadOnly: _typeLocked,
          typeDisabledFor: _typeLocked ? _input.type : null,
          // 문자 초안은 지출↔수입만 오간다. 이체를 고르면 저장이 일반 이체 경로로
          // 새고(`_submit` 의 TRANSFER 분기가 먼저다) 취소 문자 차단·카드 기억이
          // 조용히 빠진다 — 그 경로에만 있는 가드다.
          allowTransfer: !_isSmsDraft,
          presetSlot: _isEdit
              ? null
              : _PresetSection(
                  presets: presetsAsync.value ?? const [],
                  categories: categoriesAsync.value ?? const [],
                  appliedId: _appliedPresetId,
                  canSave: _input.amountInt > 0 && _input.categoryRowId != null,
                  onTap: _applyPreset,
                  onSave: _showSavePresetDialog,
                  onClear: _clearPresetMark,
                  tokens: t,
                ),
        ),
        if (_splitMismatch) ...[
          const SizedBox(height: PSpace.x16),
          _splitMismatchBanner(t),
        ],
      ],
    );
  }

  /// 분할 합 불일치 경고 — 금액을 바꿔 기존 분할 합과 어긋날 때. '분할 내역 맞추기'로 일치화 진입.
  Widget _splitMismatchBanner(PorestTokens t) {
    final l = AppLocalizations.of(context);
    final amount = _input.amountInt;
    final diff = amount - _splitSum;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: t.statusWarningSubtle,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.statusWarningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, size: 16, color: t.statusWarningFg),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.expSplitMismatch,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.expSplitDiff(
                    krw(amount),
                    krw(_splitSum),
                    '${diff > 0 ? '+' : '-'}${krw(diff.abs())}',
                  ),
                  style: PTypo.caption.copyWith(
                    color: t.fgSecondary,
                    height: PLineHeight.normal,
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                PButton(
                  label: l.expSplitReconcile,
                  icon: LucideIcons.scissors,
                  size: PButtonSize.sm,
                  onPressed: _submitting ? null : _openReconcile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openReconcile() {
    showSplitTxDialog(
      context,
      widget.edit!,
      overrideTotal: _input.amountInt,
      recordedTotal: widget.edit!.amount.abs(),
      initialSplits: _effectiveSplits,
      onReconciled: (splits) {
        if (!mounted) return;
        setState(() => _reconciledSplits = splits);
        _syncController();
      },
    );
  }
}

/// 프리셋 섹션 — 헤더 (라벨 + 적용됨 뱃지 + 저장 버튼) + 칩 strip + 적용 배너.
/// 웹 `AddTxSheet` 의 "프리셋 불러오기" 영역 1:1 미러.
class _PresetSection extends StatelessWidget {
  const _PresetSection({
    required this.presets,
    required this.categories,
    required this.appliedId,
    required this.canSave,
    required this.onTap,
    required this.onSave,
    required this.onClear,
    required this.tokens,
  });

  final List<ExpenseTemplate> presets;
  final List<ExpenseCategory> categories;
  final int? appliedId;
  final bool canSave;
  final ValueChanged<ExpenseTemplate> onTap;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 사용 빈도 desc 로 8개 (웹과 동일).
    final sorted = [...presets]
      ..sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
    final top = sorted.take(8).toList();
    final hasMore = presets.length > top.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: PSpace.x8),
          child: Row(
            children: [
              Icon(LucideIcons.bookmark, size: 13, color: tokens.fgTertiary),
              const SizedBox(width: 6),
              Text(
                l.expPresetLoad,
                style: TextStyle(
                  fontSize: PFontSize.micro,
                  color: tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                  letterSpacing: 0.44, // micro size × wide tracking
                ),
              ),
              if (appliedId != null) ...[
                const SizedBox(width: 6),
                PBadge(
                  label: l.expPresetApplied,
                  variant: PBadgeVariant.softBrand,
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: canSave ? onSave : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: canSave ? tokens.fgBrandStrong : tokens.fgTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l.expPresetSaveCurrent,
                      style: TextStyle(
                        fontSize: PFontSize.caption,
                        color: canSave
                            ? tokens.fgBrandStrong
                            : tokens.fgTertiary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Strip
        if (top.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: top.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                if (i == top.length) return _MorePresetsHint(tokens: tokens);
                final p = top[i];
                final active = p.rowId == appliedId;
                final showAmount =
                    (p.lockAmount ?? 'N') == 'Y' && (p.amount ?? 0) > 0;
                final cat = p.categoryRowId == null
                    ? null
                    : categories.byRowId(p.categoryRowId!);
                return _PresetChip(
                  preset: p,
                  category: cat,
                  active: active,
                  showAmount: showAmount,
                  onTap: () => onTap(p),
                  tokens: tokens,
                );
              },
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgMuted,
              border: Border.all(color: tokens.borderDefault),
              borderRadius: PRadius.brSm,
            ),
            child: Text(
              l.expPresetEmpty,
              style: TextStyle(
                fontSize: PFontSize.caption,
                color: tokens.fgTertiary,
              ),
            ),
          ),

        // Active preset banner
        if (appliedId != null) ...[
          const SizedBox(height: PSpace.x8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              border: Border.all(color: tokens.borderBrand),
              borderRadius: PRadius.brSm,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 13, color: tokens.fgBrandStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.expPresetFilled,
                    style: TextStyle(
                      fontSize: PFontSize.caption,
                      color: tokens.fgBrandStrong,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    l.expClear,
                    style: TextStyle(
                      fontSize: PFontSize.micro,
                      color: tokens.fgBrandStrong,
                      fontWeight: PFontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.category,
    required this.active,
    required this.showAmount,
    required this.onTap,
    required this.tokens,
  });

  final ExpenseTemplate preset;
  final ExpenseCategory? category;
  final bool active;
  final bool showAmount;
  final VoidCallback onTap;
  final PorestTokens tokens;

  /// 칩에 붙는 금액 — 사용자가 프리셋을 만들 때 자유입력한 값이라 임의값이다.
  /// 그래서 축약도 차트 축·도넛 중앙과 같은 함수 하나([formatChartAxis])를 쓴다.
  ///
  /// 예전엔 1만 위를 `${(n / 1000).floor()}k` 로 냈다. `k` 는 한국어 화면에서
  /// 합의한 단위가 아니고(만·억·조), floor 라 19,900 이 `19k`(=19,000)로 900원을
  /// 버렸다. 1만 아래(`9,900`)는 예전과 같은 글자다.
  String _shortAmount(int n) => formatChartAxis(n.toDouble());

  @override
  Widget build(BuildContext context) {
    final catColor = resolveChartColor(
      context,
      category?.color,
      fallback: tokens.fgBrand,
    );
    final iconData = lucideByName(category?.icon, fallback: LucideIcons.tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          // border 사각형 제거 — 아이콘+글씨만 노출. active 만 subtle 채움으로 강조.
          color: active ? tokens.bgBrandSubtle : Colors.transparent,
          borderRadius: PRadius.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: softBg(context, catColor),
                  borderRadius: PRadius.tile(18),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, size: 11, color: catColor),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              preset.templateName,
              style: TextStyle(
                fontSize: PFontSize.bodySm,
                fontWeight: active ? PFontWeight.bold : PFontWeight.semi,
                color: active ? tokens.fgBrandStrong : tokens.fgPrimary,
              ),
            ),
            if (showAmount) ...[
              const SizedBox(width: 7),
              Text(
                _shortAmount(preset.amount ?? 0),
                style: TextStyle(
                  fontSize: PFontSize.micro,
                  color: active ? tokens.fgBrandStrong : tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MorePresetsHint extends StatelessWidget {
  const _MorePresetsHint({required this.tokens});
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(
          color: tokens.borderDefault,
          style: BorderStyle.solid,
        ),
        borderRadius: PRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.moreHorizontal, size: 14, color: tokens.fgTertiary),
          const SizedBox(width: 4),
          Text(
            l.expPresetManageHint,
            style: TextStyle(
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.semi,
              color: tokens.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 입력값을 프리셋으로 저장. 웹 `SavePresetDialog` 1:1 미러.
class _SavePresetDialog extends ConsumerStatefulWidget {
  const _SavePresetDialog({
    required this.seedExpenseType,
    required this.seedAmount,
    required this.seedCategoryRowId,
    required this.seedAssetRowId,
    required this.seedMerchant,
    required this.seedDescription,
    required this.seedPaymentMethod,
  });

  final String seedExpenseType;
  final int seedAmount;
  final int seedCategoryRowId;
  final int? seedAssetRowId;
  final String seedMerchant;
  final String seedDescription;
  final String seedPaymentMethod;

  @override
  ConsumerState<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends ConsumerState<_SavePresetDialog> {
  late final TextEditingController _nameCtrl;
  bool _lockAmount = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.seedMerchant);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _submitting) return;
    if (widget.seedAssetRowId == null) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      await repo.create(
        templateName: name,
        categoryRowId: widget.seedCategoryRowId,
        assetRowId: widget.seedAssetRowId!,
        expenseType: widget.seedExpenseType,
        amount: _lockAmount ? widget.seedAmount : 0,
        description: widget.seedDescription.isEmpty
            ? null
            : widget.seedDescription,
        merchant: widget.seedMerchant.isEmpty ? null : widget.seedMerchant,
        paymentMethod: widget.seedPaymentMethod.isEmpty
            ? null
            : widget.seedPaymentMethod,
        lockAmount: _lockAmount,
      );
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return PFormAlertDialog(
      title: l.expPresetSaveTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PTextInput(
            controller: _nameCtrl,
            autofocus: true,
            placeholder: l.expPresetNamePlaceholder,
          ),
          const SizedBox(height: PSpace.x12),
          InkWell(
            onTap: () => setState(() => _lockAmount = !_lockAmount),
            borderRadius: PRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  PCheckbox(
                    value: _lockAmount,
                    onChanged: (v) => setState(() => _lockAmount = v ?? false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l.expPresetLockAmount(krw(widget.seedAmount)),
                      style: TextStyle(
                        fontSize: PFontSize.caption,
                        color: t.fgSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        PButton(
          label: l.actionCancel,
          // ghost 는 배경이 없어 전체 폭 배치에서 버튼으로 안 보인다
          // (spec button.md Migration notes 2026-08).
          variant: PButtonVariant.secondary,
          size: PButtonSize.lg,
          fullWidth: true,
          onPressed: _submitting ? null : Navigator.of(context).pop,
        ),
        PButton(
          label: l.actionSave,
          size: PButtonSize.lg,
          fullWidth: true,
          loading: _submitting,
          onPressed: (_submitting || _nameCtrl.text.trim().isEmpty)
              ? null
              : _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 거래 입력 (inline) — recurring 과 독립. tx_input_form.dart 해체 후 add_tx 자체 보유.

const _txPaymentMethodCodes = ['CASH', 'CARD', 'TRANSFER', 'OTHER'];

String _txPaymentMethodLabel(AppLocalizations l, String code) => switch (code) {
  'CASH' => l.expPayCash,
  'CARD' => l.expPayCard,
  'TRANSFER' => l.expPayTransfer,
  'OTHER' => l.expPayOther,
  _ => code,
};

const Map<String, List<String>?> _txPaymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

/// 카드사 공통 할부 개월 — 2~12, 18, 24.
const List<int> _installmentMonths = [
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  18,
  24,
];

/// 해외 결제는 $5.50 을 보고 입력하지 원화 환산액을 모른다 — 원 통화 × 환율로 금액을 채운다.
///
/// 카드사 실제 청구액이 다르면 금액 칸을 직접 고치면 된다. 원 통화·환율을 다시 건드릴
/// 때만 다시 계산하므로 손으로 고친 금액을 덮어쓰지 않는다.
/// 1400.000000 을 1400 으로 — 서버가 소수로 주는 값을 그대로 넣으면 입력칸이 지저분하다.
String _trimNum(double? v) {
  if (v == null) return '';
  final s = v.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}

/// 환불 금액칸에 걸 상한 — 남은 환불 가능액([ExpenseX.refundableAmount]).
///
/// 거래 상한(100억)을 넘기지 않는다 — 상한이 생기기 전에 저장된 999억 지출이
/// 남아 있고, 그 환불을 100억 위로 열어 주면 서버의 `@Max` 가 받지 않는다.
int _refundCapOf(Expense original) =>
    original.refundableAmount.clamp(0, kAmountMax);

VoidCallback _syncKrwFromForeign(_TxInputController c) => () {
  final a = c.origAmountOrNull;
  final r = c.fxRateOrNull;
  if (a == null || r == null || a <= 0 || r <= 0) return;
  c.amountCtrl.text = (a * r).round().toString();
};

/// 이자 입력을 보일지 — 대출 상환일 때만.
///
/// 원금은 부채가 줄어드는 자산 이동이지만 이자는 은행으로 아예 나가는 비용이라,
/// 입금 대상이 대출 자산일 때만 의미가 있다.
bool _showInterest(_TxInputController c, List<Asset>? assets) {
  if (c.type != 'TRANSFER' || c.toAssetRowId == null || assets == null) {
    return false;
  }
  final to = assets.where((a) => a.rowId == c.toAssetRowId).firstOrNull;
  return to?.assetType == 'LOAN';
}

/// 할부 입력을 보일지 — 신용카드 지출일 때만.
bool _showInstallment(_TxInputController c, List<Asset>? assets) {
  if (c.type != 'EXPENSE' || c.assetRowId == null || assets == null) {
    return false;
  }
  final picked = assets.where((a) => a.rowId == c.assetRowId).firstOrNull;
  return picked?.assetType == 'CREDIT_CARD';
}

/// 결제 수단 + 거래 타입으로 계좌·카드 후보를 고른다.
///
/// 지출에선 예·적금(SAVINGS: 청약·정기예금·정기적금)을 뺀다 — 만기 전까지 묶인 돈이라
/// 거기서 직접 결제나 출금이 나가지 않는다(쓰려면 해지해서 입출금으로 옮긴다).
/// 납입·해지는 이체로 처리하므로 이체 목록에는 그대로 남는다.
/// 수입은 이자가 그 계좌로 직접 들어오므로 남긴다.
bool _allowTxAsset(Asset a, String paymentMethod, String type) {
  final allowed = paymentMethod.isNotEmpty
      ? _txPaymentAssetTypes[paymentMethod]
      : null;
  if (allowed != null && !allowed.contains(a.assetType)) return false;
  if (type == 'EXPENSE' && a.assetType == 'SAVINGS') return false;
  return true;
}

/// 이체 대상 자산 — 카드는 뺀다.
///   체크카드: 잔액을 들지 않는다(긁는 즉시 연결 계좌에서 빠진다). 걸면 카드에
///     있을 수 없는 잔액이 생긴다.
///   신용카드: 대금 결제는 전용 기능(자산 상세 → 결제)이 담당한다. 그쪽은 이체와
///     함께 card_billing 을 남기고, 자동 결제의 멱등 체크가 그 기록으로 걸린다.
///     손으로 이체하면 기록이 없어 결제일에 자동 결제가 또 돌아 이중 차감된다.
List<Asset> _transferAssets(List<Asset> assets) => assets
    .where((a) => a.assetType != 'CHECK_CARD' && a.assetType != 'CREDIT_CARD')
    .toList(growable: false);

/// 거래 입력 상태 (지출/수입/이체).
class _TxInputController {
  _TxInputController({
    this.type = 'EXPENSE',
    String amount = '',
    String merchant = '',
    String memo = '',
    this.categoryRowId,
    this.assetRowId,
    this.paymentMethod = '',
    DateTime? date,
    TimeOfDay? time,
  }) : date = date ?? DateTime.now(),
       time = time ?? TimeOfDay.now(),
       amountCtrl = TextEditingController(text: amount),
       merchantCtrl = TextEditingController(text: merchant),
       memoCtrl = TextEditingController(text: memo),
       feeCtrl = TextEditingController(),
       interestCtrl = TextEditingController(),
       origAmountCtrl = TextEditingController(),
       fxRateCtrl = TextEditingController();

  final TextEditingController amountCtrl;
  final TextEditingController merchantCtrl;
  final TextEditingController memoCtrl;
  final TextEditingController feeCtrl;

  /// 대출 상환의 이자 — 상환액 중 이 금액은 부채를 줄이지 않고 지출로 잡힌다.
  final TextEditingController interestCtrl;

  /// 해외 결제의 원 통화 금액·환율 — 셋이 함께여야 카드사 청구 환율과 대사할 수 있다.
  final TextEditingController origAmountCtrl;
  final TextEditingController fxRateCtrl;

  String type; // EXPENSE / INCOME / TRANSFER
  int? categoryRowId;
  int? assetRowId; // EXPENSE/INCOME 자산, TRANSFER 출금 자산
  int? toAssetRowId; // TRANSFER 입금 자산 (이체 시 폼에서 set)
  String paymentMethod;

  /// 할부 개월 — 신용카드 지출에만 의미. 0 = 일시불.
  int installmentMonths = 0;

  /// 사용자가 고른 결제 통화. `null` 이면 아직 아무것도 안 골랐다.
  String? currencyPick;

  /// 이 거래에 이미 적혀 있던 통화 — 편집·환불·문자 초안이 채운다.
  ///
  /// 원화 거래는 서버에서 `originalCurrency` 가 `null` 로 오지만 여기엔 `KRW` 를
  /// 넣는다. 비워 두면 아래 [currency] 가 설정의 기본 통화로 떨어져, 원화로 적어
  /// 둔 거래를 열기만 해도 해외 결제 입력이 펼쳐진다.
  String? txCurrency;

  /// 설정의 기본 통화 — 폼이 매 빌드 흘려 넣는다(D7 · QA #124).
  ///
  /// `/me/preferences` 는 설정 화면을 안 들른 세션에서 이 시트보다 늦게 도착한다.
  /// 열 때 한 번만 읽어 굳히면 첫 렌더의 원화에 잠기므로, 도착한 값을 매 빌드
  /// 다시 흘려 넣어 아직 안 고른 새 거래에 반영한다.
  String defaultCurrency = kDefaultCurrency;

  /// 결제 통화 — KRW 면 원화 결제(원 통화 기록 없음).
  ///
  /// 우선순위는 **고른 값 > 이 거래의 값 > 설정의 기본 통화**다. 기본 통화는
  /// 새 거래에만 닿는다 — 편집·환불·문자 초안은 [txCurrency] 에서 멈춘다.
  String get currency => currencyPick ?? txCurrency ?? defaultCurrency;
  DateTime date;
  TimeOfDay time;
  bool amountLocked = false; // 프리셋 금액 잠금 (applyPreset 에서 set)

  /// 환불 모드에서 이 환불이 넘을 수 없는 금액 — **원거래 금액 − 이미 환불된 금액**.
  /// `null` 이면 환불 모드가 아니다(시트를 열 때 굳는다).
  int? refundCap;

  /// 원거래에 **이미 달려 있던** 환불 합계 — 안내 문구가 남은 금액과 함께 읽어 준다.
  int refundedBefore = 0;

  /// 지금 이 입력이 환불로 나가는가.
  ///
  /// 원거래 연결(`refundOfExpenseRowId`)을 싣는 조건과 **같아야 한다** — 환불 모드로
  /// 열었어도 종류를 지출로 바꾸면 연결이 안 실려 그냥 지출이 된다. 그때 상한이
  /// 남아 있으면 환불과 무관한 지출이 원거래 금액에 묶인다.
  bool get isRefundInput => refundCap != null && type == 'INCOME';

  /// 금액칸에 걸 상한 — 환불이면 남은 환불 가능액, 아니면 거래 상한(100억).
  int get amountMaxForInput => isRefundInput ? refundCap! : kAmountMax;

  /// 남은 환불 가능액이 0 인가 — 원거래를 이미 다 환불했다.
  bool get refundExhausted => isRefundInput && refundCap == 0;

  /// 상한을 넘긴 금액이 칸에 들어와 있는가.
  bool get amountOverRefundCap => isRefundInput && amountInt > refundCap!;

  /// 시스템이 만든 거래의 출처 (TRADE_REALIZED / TRANSFER_INTEREST). null 이면 손으로 쓴 거래.
  /// 값이 있으면 금액·날짜·자산이 잠긴다 — 서버도 같은 규칙으로 거른다.
  String? autoSource;

  /// 결제 문자 초안에서 "이 카드로 기억" 을 물어볼 상황인가 (카드는 알아봤는데 아직 안 외움).
  bool smsRememberAsk = false;

  /// 사용자가 그 체크를 켰는가 — 저장 시 (카드 힌트 → 자산) 을 서버가 적어 둔다.
  bool smsRememberCard = false;

  /// 금액·날짜·자산을 못 고치는가 — 계산 결과라서.
  bool get isAutoGenerated => autoSource != null;

  int get amountInt => int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String? get merchantOrNull =>
      merchantCtrl.text.trim().isEmpty ? null : merchantCtrl.text.trim();
  String? get memoOrNull =>
      memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim();
  String? get paymentMethodOrNull =>
      paymentMethod.isEmpty ? null : paymentMethod;

  /// 외화 결제인가 — 이체는 두 자산 사이의 이동이라 통화가 자산에 달려 있어 제외.
  bool get isForeignTx => type != 'TRANSFER' && isForeignCurrency(currency);
  double? get origAmountOrNull => isForeignTx
      ? double.tryParse(origAmountCtrl.text.replaceAll(',', ''))
      : null;
  double? get fxRateOrNull =>
      isForeignTx ? double.tryParse(fxRateCtrl.text.replaceAll(',', '')) : null;

  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    memoCtrl.dispose();
    feeCtrl.dispose();
    interestCtrl.dispose();
    origAmountCtrl.dispose();
    fxRateCtrl.dispose();
  }
}

/// 거래 입력 폼 (지출/수입/이체) — add_tx_sheet 자체 보유.
class _TxInputForm extends ConsumerWidget {
  const _TxInputForm({
    required this.controller,
    required this.onChanged,
    this.typeReadOnly = false,
    this.typeDisabledFor,
    this.allowTransfer = true,
    this.presetSlot,
  });

  final _TxInputController controller;
  final VoidCallback onChanged;
  final bool typeReadOnly;
  final String? typeDisabledFor;

  /// 이체 선택지를 내놓는가 — 저장 경로가 이체를 못 받는 화면은 false 다.
  final bool allowTransfer;
  final Widget? presetSlot;

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
    final amountColor = c.type == 'EXPENSE'
        ? t.fgExpense
        : (c.type == 'INCOME' ? t.fgIncome : t.fgTransfer);
    final amountPrefix = c.type == 'EXPENSE'
        ? '−'
        : (c.type == 'INCOME' ? '+' : '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 토글
        PTabs<String>(
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          value: c.type,
          onChanged: typeReadOnly
              ? (_) {}
              : (v) => _set(() {
                  c.type = v;
                  // 종류를 바꾸면 안 맞는 카테고리는 놓는다(웹 `AddTxSheet` 정합).
                  // 서버가 종류≠카테고리 종류를 400 으로 막으므로(`ExpenseServiceImpl`)
                  // 들고 있어 봐야 저장이 실패한다 — 문자 초안은 지출 카테고리를
                  // 미리 채워 오므로 수입으로 바꾸는 순간 바로 걸린다.
                  final cats = categoriesAsync.value;
                  if (cats != null) {
                    final cat = cats
                        .where((x) => x.rowId == c.categoryRowId)
                        .firstOrNull;
                    if (cat == null || cat.expenseType != v) {
                      c.categoryRowId = null;
                    }
                  }
                }),
          items: [
            PTabItem(
              value: 'EXPENSE',
              label: l.expTypeExpense,
              disabled: typeReadOnly && typeDisabledFor != 'EXPENSE',
            ),
            PTabItem(
              value: 'INCOME',
              label: l.expTypeIncome,
              disabled: typeReadOnly && typeDisabledFor != 'INCOME',
            ),
            if (allowTransfer && (!typeReadOnly || c.type == 'TRANSFER'))
              PTabItem(
                value: 'TRANSFER',
                label: l.expTypeTransfer,
                disabled: typeReadOnly && typeDisabledFor != 'TRANSFER',
              ),
          ],
        ),
        const SizedBox(height: PSpace.x12),

        if (presetSlot != null) ...[
          presetSlot!,
          const SizedBox(height: PSpace.x20),
        ],

        // 금액
        Row(
          children: [
            Expanded(child: PSectionLabel(l.expAmount)),
            if (c.amountLocked || c.isAutoGenerated) ...[
              Icon(LucideIcons.lock, size: 11, color: t.fgTertiary),
              const SizedBox(width: 3),
              Text(
                c.isAutoGenerated ? l.expAutoLock : l.expPresetLock,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.amountCtrl,
          numbersOnly: true,
          // 환불이면 남은 환불 가능액이 상한이다 — 넘는 값은 타이핑 자체가 안 된다
          // (`AmountLimitFormatter`, 거래 100억 상한과 같은 방식).
          amountMax: c.amountMaxForInput,
          // 다 환불된 거래는 넣을 금액이 0 이다. 상한 0 이면 어차피 한 글자도
          // 안 찍히는데, 살아 있는 칸으로 두면 키가 안 먹는 고장으로 보인다.
          enabled: !c.amountLocked && !c.isAutoGenerated && !c.refundExhausted,
          placeholder: '0',
          prefixText: amountInt > 0 ? amountPrefix : null,
          suffixText: wonUnit(),
          style: PTypo.h4.copyWith(
            color: amountColor,
            fontWeight: PFontWeight.bold,
          ),
          onChanged: (_) => onChanged(),
        ),
        // 환불 상한을 **말해 준다.** 조용히 안 찍히는 칸은 고장으로 보인다
        // (웹 #130 이 그 상태였다: 상한에 걸려 값이 깎여도 아무 말이 없었다).
        // 프리셋·외화 환산은 칸에 값을 직접 꽂아 상한을 넘길 수 있으므로,
        // 그때는 같은 한 줄을 빨갛게 세워 저장이 막힌 이유를 잇는다.
        if (c.isRefundInput) ...[
          const SizedBox(height: PSpace.x4),
          Text(
            c.refundExhausted
                ? l.expRefundCapUsedUp
                : c.refundedBefore > 0
                ? l.expRefundCapLeft(krw(c.refundedBefore), krw(c.refundCap!))
                : l.expRefundCap(krw(c.refundCap!)),
            style: PTypo.caption.copyWith(
              color: (c.refundExhausted || c.amountOverRefundCap)
                  ? t.statusDanger
                  : t.fgTertiary,
            ),
          ),
        ],
        // 왜 못 고치는지 알려 준다 — 잠긴 칸만 보여 주면 고장으로 보인다.
        if (c.isAutoGenerated) ...[
          const SizedBox(height: PSpace.x4),
          Text(switch (c.autoSource) {
            'TRADE_REALIZED' => l.expAutoSourceTradeRealized,
            'TRANSFER_INTEREST' => l.expAutoSourceTransferInterest,
            _ => l.expAutoSourceDefault,
          }, style: PTypo.micro.copyWith(color: t.fgTertiary)),
        ],
        const SizedBox(height: PSpace.x16),

        if (c.type != 'TRANSFER') ...[
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
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
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
                          l.expTopCategorySuffix(
                            topCategories
                                .firstWhere(
                                  (cat) => cat.rowId == selectedParentId,
                                )
                                .categoryName,
                          ),
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
        ],

        if (c.type != 'TRANSFER') ...[
          // 거래처
          PSectionLabel(c.type == 'INCOME' ? l.expIncomeSource : l.expPayee),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: c.merchantCtrl,
            placeholder: c.type == 'INCOME'
                ? l.expIncomeSourcePlaceholder
                : l.expPayeePlaceholder,
          ),
          const SizedBox(height: PSpace.x12),

          // 결제 수단 (Select)
          PSectionLabel(
            c.type == 'INCOME' ? l.expIncomeMethod : l.expPaymentMethod,
          ),
          const SizedBox(height: PSpace.x4),
          _SelectField<String>(
            // ''(선택 안 함)도 유효 default — null 변환 금지(웹 정합: '선택 안 함' selected).
            value: c.paymentMethod,
            hint: l.expNone,
            items: [
              _SelectOption<String>('', l.expNone),
              for (final code in _txPaymentMethodCodes)
                _SelectOption<String>(code, _txPaymentMethodLabel(l, code)),
            ],
            onChanged: (v) => _set(() {
              c.paymentMethod = v ?? '';
              if (c.paymentMethod.isNotEmpty && c.assetRowId != null) {
                final assets = assetsAsync.value ?? const [];
                final cur = assets
                    .where((a) => a.rowId == c.assetRowId)
                    .firstOrNull;
                if (cur != null &&
                    !_allowTxAsset(cur, c.paymentMethod, c.type)) {
                  c.assetRowId = null;
                }
              }
            }),
          ),
          const SizedBox(height: PSpace.x12),

          // 계좌·카드 (Select, payment method 로 필터)
          PSectionLabel(
            c.type == 'INCOME' ? l.expDepositAccount : l.expAccountCard,
          ),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: PCircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '${l.expAssetLoadError}: $e',
              style: PTypo.caption.copyWith(color: t.statusDanger),
            ),
            data: (assets) {
              final filtered = assets
                  .where((a) => _allowTxAsset(a, c.paymentMethod, c.type))
                  .toList();
              return _SelectField<int>(
                // null(미선택)도 '선택 안 함'(-1) default로 표시 — 웹 정합.
                value: c.assetRowId ?? -1,
                enabled: !c.isAutoGenerated,
                hint: l.expNone,
                items: [
                  _SelectOption<int>(-1, l.expNone),
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
          // 결제 문자로 들어온 카드를 아직 안 외운 경우에만 물어본다.
          // 한 번 켜 두면 다음 문자부터는 자산을 고르는 단계가 사라진다.
          if (c.smsRememberAsk) ...[
            const SizedBox(height: PSpace.x8),
            InkWell(
              onTap: c.assetRowId == null
                  ? null
                  : () => _set(() => c.smsRememberCard = !c.smsRememberCard),
              borderRadius: PRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    PCheckbox(
                      // 자산을 안 골랐으면 기억할 대상이 없다.
                      value: c.assetRowId != null && c.smsRememberCard,
                      onChanged: c.assetRowId == null
                          ? null
                          : (v) => _set(() => c.smsRememberCard = v ?? false),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l.smsRememberCard,
                        style: TextStyle(
                          fontSize: PFontSize.caption,
                          color: c.assetRowId == null
                              ? t.fgTertiary
                              : t.fgSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: PSpace.x12),

          // 할부 — 신용카드 지출에만. 청구는 이 개월 수로 나뉘어 잡힌다.
          // (체크카드는 긁는 즉시 계좌에서 빠지고, 현금·이체는 나눌 수 없다)
          if (_showInstallment(c, assetsAsync.value)) ...[
            PSectionLabel(l.expInstallment),
            const SizedBox(height: PSpace.x4),
            _SelectField<int>(
              value: c.installmentMonths,
              hint: l.expLumpSum,
              items: [
                _SelectOption<int>(0, l.expLumpSum),
                for (final m in _installmentMonths)
                  _SelectOption<int>(m, l.expInstallmentMonths(m)),
              ],
              onChanged: (v) => _set(() => c.installmentMonths = v ?? 0),
            ),
            if (c.installmentMonths > 1 && c.amountInt > 0) ...[
              const SizedBox(height: PSpace.x4),
              Text(
                l.expInstallmentHint(
                  krw(c.amountInt ~/ c.installmentMonths),
                  c.installmentMonths,
                ),
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
            const SizedBox(height: PSpace.x12),
          ],

          // 통화 — 외화면 원 통화 금액·환율이 열리고, 금액(원화)이 자동으로 채워진다.
          PSectionLabel(l.expCurrency),
          const SizedBox(height: PSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SelectField<String>(
                  value: c.currency,
                  hint: kDefaultCurrency,
                  items: [
                    for (final cur in kCurrencies)
                      _SelectOption<String>(
                        cur.code,
                        '${cur.symbol} ${cur.code}',
                      ),
                  ],
                  onChanged: (v) => _set(() {
                    c.currencyPick = v ?? kDefaultCurrency;
                    // 원화로 돌아오면 남은 외화 입력을 지운다(저장 시 흘러들지 않도록).
                    if (!isForeignCurrency(c.currency)) {
                      c.origAmountCtrl.clear();
                      c.fxRateCtrl.clear();
                    }
                  }),
                ),
              ),
              if (c.isForeignTx) ...[
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: PTextInput(
                    controller: c.origAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: l.expOriginalAmount,
                    onChanged: (_) => _set(_syncKrwFromForeign(c)),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: PTextInput(
                    controller: c.fxRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: l.expExchangeRate,
                    onChanged: (_) => _set(_syncKrwFromForeign(c)),
                  ),
                ),
              ],
            ],
          ),
          if (c.isForeignTx &&
              (c.origAmountOrNull ?? 0) > 0 &&
              (c.fxRateOrNull ?? 0) > 0) ...[
            const SizedBox(height: PSpace.x4),
            Text(
              l.expFxHint(
                formatOriginalAmount(
                  c.origAmountOrNull!,
                  c.currency,
                  Localizations.localeOf(context).toString(),
                ),
                krw((c.origAmountOrNull! * c.fxRateOrNull!).round()),
              ),
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ],
          const SizedBox(height: PSpace.x12),
        ] else ...[
          // 이체 — 출금/입금/수수료
          PSectionLabel(l.expWithdrawAccount),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (assets) => _SelectField<int>(
              value: c.assetRowId,
              hint: l.expSelect,
              items: [
                for (final a in _transferAssets(assets))
                  _SelectOption<int>(
                    a.rowId,
                    a.institution != null
                        ? '${a.institution} · ${a.assetName}'
                        : a.assetName,
                  ),
              ],
              onChanged: (v) => _set(() => c.assetRowId = v),
            ),
          ),
          const SizedBox(height: PSpace.x12),
          PSectionLabel(l.expDepositAccount),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (assets) => _SelectField<int>(
              value: c.toAssetRowId,
              hint: l.expSelect,
              items: [
                for (final a in _transferAssets(
                  assets,
                ).where((a) => a.rowId != c.assetRowId))
                  _SelectOption<int>(
                    a.rowId,
                    a.institution != null
                        ? '${a.institution} · ${a.assetName}'
                        : a.assetName,
                  ),
              ],
              onChanged: (v) => _set(() => c.toAssetRowId = v),
            ),
          ),
          if (c.assetRowId != null && c.assetRowId == c.toAssetRowId)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.expTransferSameAsset,
                style: PTypo.caption.copyWith(color: t.statusDanger),
              ),
            ),
          const SizedBox(height: PSpace.x12),
          PSectionLabel(l.expFeeOptional),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: c.feeCtrl,
            numbersOnly: true,
            amountMax: kAmountMax,
            placeholder: '0',
          ),
          const SizedBox(height: PSpace.x12),

          // 이자 — 대출 상환에만. 상환액 중 이자는 부채를 줄이지 않고 지출로 잡힌다.
          if (_showInterest(c, assetsAsync.value)) ...[
            PSectionLabel(l.expInterest),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: c.interestCtrl,
              numbersOnly: true,
              amountMax: kAmountMax,
              placeholder: '0',
              onChanged: (_) => _set(() {}),
            ),
            const SizedBox(height: PSpace.x4),
            Builder(
              builder: (_) {
                final interest =
                    int.tryParse(c.interestCtrl.text.replaceAll(',', '')) ?? 0;
                final amount = c.amountInt;
                return Text(
                  (interest > 0 && amount > 0)
                      ? l.expInterestSplit(
                          krw(amount - interest < 0 ? 0 : amount - interest),
                          krw(interest),
                        )
                      : l.expInterestHint,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                );
              },
            ),
            const SizedBox(height: PSpace.x12),
          ],
        ],

        // 날짜(·시간)
        // 이체도 시각을 받는다 — transfer_date 가 DATETIME 이라, 시각이 있어야
        // 같은 날 잔액수정보다 뒤에 일어난 이체가 절대 앵커에 지워지지 않는다.
        PSectionLabel(l.expDateTime),
        const SizedBox(height: PSpace.x4),
        Row(
          children: [
            Expanded(
              child: PDateInput(
                value: c.date,
                enabled: !c.isAutoGenerated,
                onChanged: (d) {
                  if (d != null) _set(() => c.date = d);
                },
                firstDate: DateTime(2020),
                lastDate: DateTime(2030, 12, 31),
              ),
            ),
            const SizedBox(width: PSpace.x8),
            SizedBox(
              width: 116,
              child: PTimeInput(
                value: c.time,
                enabled: !c.isAutoGenerated,
                onChanged: (tm) {
                  if (tm != null) _set(() => c.time = tm);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        PSectionLabel(l.expDescription),
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
    this.enabled = true,
  });
  final T? value;
  final List<_SelectOption<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PSelect<T>(
      value: items.any((i) => i.value == value) ? value : null,
      placeholder: hint,
      enabled: enabled,
      onChanged: onChanged,
      items: [
        for (final opt in items)
          PSelectItem<T>(value: opt.value, label: opt.label),
      ],
    );
  }
}
