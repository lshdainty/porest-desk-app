import 'package:flutter/material.dart';
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
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_detail.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/features/dutch_pay/presentation/dutch_pay_from_tx_dialog.dart';
import 'package:porest_desk_app/features/expense_split/presentation/split_tx_dialog.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_settings_drawer.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/expense_actions.dart';
import 'package:porest_desk_app/features/expense/domain/refund_preview.dart';
import 'package:porest_desk_app/features/expense/presentation/delete_confirm_dialog.dart';
import 'package:porest_desk_app/features/expense/presentation/refund_confirm_dialog.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense_split/domain/expense_split.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 거래 상세 다이얼로그 — front `TxDetailDialog` 미러.
///
/// 구성:
/// - Hero: 카테고리 색 그라데이션 배경 + 큰 아이콘 + 가맹점 + 큰 금액 + 날짜
/// - Field rows: 카테고리 / 금액 / 계좌·카드 / 결제 수단 / 날짜·시간 / 메모
/// - Quick actions (3-col grid): 내역 분할 / 반복 설정 / 더치페이
/// - Footer: 삭제 / 편집 / 확인
void showTxDetailDialog(BuildContext context, Expense expense) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  final isIncome = expense.expenseType == 'INCOME';
  showPSheet<void>(
    context,
    title: isIncome ? l.expIncomeDetail : l.expExpenseDetail,
    contentBuilder: (ctx, scrollCtrl) => _DetailBody(
      expense: expense,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) =>
        _TxDetailFooter(expense: expense, controller: controller),
  ).whenComplete(controller.dispose);
}

class _TxDetailFooter extends StatelessWidget {
  const _TxDetailFooter({required this.expense, required this.controller});
  final Expense expense;
  final PSheetController controller;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final busy = controller.submitting;
        // 고칠 수 없는 거래 둘 — 시스템이 만든 것(매도 실현손익·이체 이자)은 원본을
        // 지워야 사라지고, 환불된 것은 돈이 이미 자산으로 돌아가 되돌릴 기준이 없다
        // (서버도 EXP_043 으로 막는다 — 먼저 환불을 취소해야 한다). 판정은
        // [expenseActions.canEdit] 하나다. 눌러야 거부 토스트가 뜨는 대신 아예 감춘다.
        final canEdit = expenseActions.canEdit(expense);
        return PViewFooter(
          onDelete: expense.autoSource != null ? null : controller.onDelete,
          deleting: busy,
          onEdit: busy || !canEdit
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  showAddTxSheet(ctx, edit: expense);
                },
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.expense,
    required this.scrollController,
    required this.controller,
  });
  final Expense expense;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _deleting = false;
  bool _refunding = false;
  bool _splitExpanded = true; // 분할 요약 카드 펼침 상태

  /// 화면이 그리는 거래. 열릴 때는 넘겨받은 것과 같지만, 환불을 찍거나 취소하면
  /// 서버가 돌려준 것으로 갈아 끼운다 — 그래야 배너가 그 자리에서 바뀐다.
  late Expense _e = widget.expense;

  @override
  void initState() {
    super.initState();
    // 삭제는 그 거래의 자산을 봐야 한다(카드면 환급 안내를 띄운다) — build 에서
    // 고른 자산을 여기 담아 두고 콜백이 읽는다.
    widget.controller.onDelete = () => _delete(_assetForDelete);
  }

  /// 마지막 build 가 고른 자산 — 삭제 확인창이 카드인지 가르는 데 쓴다.
  Asset? _assetForDelete;

  void _setDeleting(bool v) {
    setState(() => _deleting = v);
    widget.controller.setSubmitting(v);
  }

  /// 삭제는 [expenseActions] 가 한다 — 목록 행(스와이프)도 같은 것을 부른다.
  /// 여기서 다시 짜면 무효화 하나만 어긋나도 경로에 따라 화면이 달라진다.
  ///
  /// 확인은 이 화면 몫이다. 지운 뒤 시트를 닫는 것도 여기서만 필요하다 —
  /// 목록에서 지울 땐 닫을 시트가 없다.
  Future<void> _delete(Asset? asset) async {
    // 카드 거래만 물어본다 — 그 밖에는 돌려줄 자리가 없다.
    final isCard = asset?.assetType == 'CREDIT_CARD';
    final preview = isCard ? _loadRefundPreview() : null;

    final result = await showDeleteConfirmDialog(
      context,
      title: expenseActions.deleteConfirmTitle(context, _e),
      message: expenseActions.deleteConfirmMessage(context, _e),
      preview: preview,
      isCreditCard: isCard,
      cardHasPaymentAsset: expenseActions.paidRefundPossible(asset),
    );
    if (!result.ok || !mounted) return;

    _setDeleting(true);
    try {
      final deleted = await expenseActions.delete(
        context,
        ref,
        _e,
        previewed: result.previewed,
      );
      if (deleted && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) _setDeleting(false);
    }
  }

  /// 확인창이 그릴 환급 미리보기 — 실패는 확인창이 폴백 문구로 받는다.
  Future<RefundPreview> _loadRefundPreview() async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    return repo.refundPreview(_e.rowId);
  }

  /// 환불 처리 — 원거래에 표식을 찍는다. 거래는 지워지지 않는다.
  ///
  /// 환불일을 받는 것이 핵심이다. 카드사 환급은 며칠 걸려서 "언제 돌려받았나" 는
  /// 사용자만 안다. 시각은 **정오**로 보낸다 — 자정이면 같은 날 앞서 찍힌 거래보다
  /// 과거가 되어 카드 회차 판정이 하루 밀린다.
  Future<void> _refund(Asset? asset) async {
    // 결제계좌가 있는 카드만 물어본다 — 그 밖에는 돌려줄 자리가 없다.
    final isCard = asset?.assetType == 'CREDIT_CARD';
    final picked = await showRefundConfirmDialog(
      context,
      expense: _e,
      asset: asset,
      preview: isCard && expenseActions.paidRefundPossible(asset)
          ? _loadRefundPreview()
          : null,
    );
    if (picked == null || !mounted) return;

    setState(() => _refunding = true);
    try {
      final updated = await expenseActions.refund(ref, _e, refundedAt: picked);
      if (updated != null && mounted) setState(() => _e = updated);
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  /// 환불 취소 — 표식을 걷고, 마크가 만든 환급 이체까지 되돌린다.
  ///
  /// 되돌리면 이 거래가 합계에 다시 들어가고 카드가 다시 빚이 된다. 돈이 움직이는
  /// 일이라 삭제와 같은 무게로 묻는다.
  Future<void> _cancelRefund() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.expRefundCancel,
      message: l.expRefundCancelConfirm,
      confirmLabel: l.expRefundCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _refunding = true);
    try {
      final updated = await expenseActions.cancelRefund(ref, _e);
      if (updated != null && mounted) setState(() => _e = updated);
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  String _paymentMethodLabel(AppLocalizations l, String? m) => switch (m) {
    'CASH' => l.expPayCash,
    'CARD' => l.expPayCard,
    'TRANSFER' => l.expPayTransfer,
    'OTHER' => l.expPayOther,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 이 거래의 종류로 판정한다 — 화면 카드('거래 상세')가 켜졌거나 그 종류 카드가
    // 켜졌으면 가린다. 부호가 아니라 타입으로 가른다(환불이 음수 지출이라 부호로는 샌다).
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(_e.expenseType);
    final e = _e;
    final isIncome = e.expenseType == 'INCOME';
    // 분할 내역 — 퀵액션 배지 개수 + 요약 카드(내역·비율) 표시용.
    final splits =
        ref.watch(expenseSplitsProvider(e.rowId)).value ??
        const <ExpenseSplit>[];
    final splitCount = splits.length;
    final categories =
        ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];

    // 카테고리 색은 다크에서 light variant 로 swap(웹 getPaletteByColor 정합) — parseColor(raw) 금지.
    final fg = resolveChartColor(context, e.categoryColor, fallback: t.fgBrand);
    final icon = lucideByName(e.categoryIcon, fallback: LucideIcons.tag);

    final assets = ref.watch(assetsProvider).value ?? const [];
    final asset = assets.where((a) => a.rowId == e.assetRowId).firstOrNull;
    _assetForDelete = asset;
    final assetLabel = asset == null
        ? null
        : (asset.institution != null && asset.institution!.isNotEmpty
              ? '${asset.institution} · ${asset.assetName}'
              : asset.assetName);

    final dayStr = (e.expenseDate ?? '').length >= 10
        ? e.expenseDate!.substring(0, 10)
        : null;
    final timeStr = (e.expenseDate ?? '').length >= 16
        ? e.expenseDate!.substring(11, 16)
        : null;
    final timeLabel = (timeStr != null && timeStr != '00:00') ? timeStr : null;

    final paymentLabel = _paymentMethodLabel(l, e.paymentMethod);
    // 삭제 확인창이 부르는 이름과 같은 규칙 — 한 군데서만 정한다.
    final displayMerchant = expenseActions.displayNameOf(context, e);
    // 웹 TxDetailDialog 매칭: 수입=fg-brand (초록), 지출=fg-primary (검정)
    final amountColor = t.fgPrimary;
    final amountText = masked
        ? '••••••'
        : '${isIncome ? '+' : '−'}${krw(e.amount, abs: true)}';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        // Hero — 플랫 좌측 정렬(design 신판 토스 톤, PDetailHero)
        PDetailHero(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: softBg(context, fg),
              borderRadius: PRadius.tile(32),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: fg),
          ),
          title: displayMerchant,
          meta: dayStr == null
              ? null
              : (timeLabel != null ? '$dayStr · $timeLabel' : dayStr),
          amount: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: amountText,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    color: amountColor,
                    fontSize: PFontSize.displayMd,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: -0.96,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!masked)
                  TextSpan(
                    text: wonUnit(),
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      color: amountColor,
                      fontSize: PFontSize.h4,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Fields — 카드 없는 플랫 행(PDetailField, 웹 body-sm=앱 body 정합)
        PDetailFieldGroup(
          children: [
            PDetailField(
              label: l.expCategory,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: PRadius.brXs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.categoryName ?? l.expUncategorized,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ],
              ),
            ),
            PDetailField(
              label: l.expAmount,
              child: Text(
                '$amountText${masked ? '' : wonUnit()}',
                style: PTypo.body.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
            ),
            if (e.originalCurrency != null && e.originalAmount != null)
              PDetailField(
                label: l.expForeignPayment,
                child: Text(
                  e.exchangeRate != null
                      ? '${formatOriginalAmount(e.originalAmount!, e.originalCurrency!, Localizations.localeOf(context).toString())} × ${_trimRate(e.exchangeRate!)}'
                      : formatOriginalAmount(
                          e.originalAmount!,
                          e.originalCurrency!,
                          Localizations.localeOf(context).toString(),
                        ),
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            if (assetLabel != null)
              PDetailField(
                label: l.expAccountCard,
                child: Text(
                  assetLabel,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            if (paymentLabel.isNotEmpty)
              PDetailField(
                label: l.expPaymentMethod,
                child: Text(
                  paymentLabel,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            if (dayStr != null)
              PDetailField(
                label: l.expDateTime,
                child: Text(
                  timeLabel != null ? '$dayStr $timeLabel' : dayStr,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            PDetailField(
              label: l.expDescription,
              child: Text(
                (e.description ?? '').isEmpty ? l.expValueNone : e.description!,
                style: PTypo.body.copyWith(
                  color: (e.description ?? '').isEmpty
                      ? t.fgTertiary
                      : t.fgPrimary,
                  fontWeight: PFontWeight.medium,
                ),
              ),
            ),
          ],
        ),
        // 시스템이 만든 거래 — 왜 못 고치는지 알려 준다. 버튼만 없으면 고장으로 보인다.
        if (e.autoSource != null)
          PDetailSection(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x12,
                vertical: PSpace.x8,
              ),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.lock, size: 14, color: t.fgTertiary),
                  const SizedBox(width: PSpace.x8),
                  Expanded(
                    child: Text(switch (e.autoSource) {
                      'TRADE_REALIZED' => l.expAutoSourceTradeRealized,
                      'TRANSFER_INTEREST' => l.expAutoSourceTransferInterest,
                      _ => l.expAutoSourceDefault,
                    }, style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                ],
              ),
            ),
          ),

        // 환불됨 — 이 거래는 합계에서 빠져 있다. 되돌릴 자리를 함께 준다.
        // 웹도 같은 자리·같은 문구다(설계서 7절).
        if (e.isRefunded)
          PDetailSection(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x12,
                vertical: PSpace.x8,
              ),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.undo2, size: 15, color: t.fgTertiary),
                  const SizedBox(width: PSpace.x8),
                  Expanded(
                    child: Text(
                      l.expRefundedAt(e.refundedAt!.substring(0, 10)),
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  PButton(
                    label: l.expRefundCancel,
                    variant: PButtonVariant.outline,
                    size: PButtonSize.sm,
                    loading: _refunding,
                    onPressed: _deleting || _refunding ? null : _cancelRefund,
                  ),
                ],
              ),
            ),
          ),
        // 기록만 — 결제가 끝난 회차에 뒤늦게 적은 카드 지출(닫힌 회차 R2). 계좌에서는
        // 안 빠졌다는 것을 상세에서 한 번 더 말한다. 할부는 지난 회차분만 기록용이라
        // 금액이 거래보다 작으면 "이 중 N원" 으로 말한다. 웹도 같은 자리·같은 문구다.
        if (e.isRecordOnly)
          PDetailSection(
            child: Container(
              key: const ValueKey('record-only-note'),
              padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x12,
                vertical: PSpace.x8,
              ),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
              ),
              child: Text(
                (e.recordOnlyAmount ?? e.amount.abs()) < e.amount.abs()
                    ? l.expRecordOnlyPartNote(
                        krwSigned(e.recordOnlyAmount ?? 0, masked, unit: true),
                      )
                    : l.expRecordOnlyNote,
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
              ),
            ),
          ),
        // Quick actions — 원형 아이콘(PDetailQuickAction, 연결 시 active)
        PDetailSection(
          child: Row(
            children: [
              // 환불 — 지출에만, 아직 환불 안 한 것만. 누르면 확인 다이얼로그(환불일)
              // 이고, 확인하면 원거래에 표식이 찍혀 합계에서 빠진다. 시트를 닫지 않는다
              // — 표식이 찍힌 모습(배너)을 그 자리에서 보여 준다.
              if (!isIncome && !e.isRefunded)
                Expanded(
                  child: PDetailQuickAction(
                    icon: LucideIcons.undo2,
                    label: l.expRefund,
                    onTap: _deleting || _refunding
                        ? null
                        : () => _refund(asset),
                  ),
                ),
              // 분할도 환불된 거래에는 안 띄운다 — 서버가 EXP_043 으로 막으므로
              // 눌러 봐야 토스트만 뜬다.
              if (!e.isRefunded)
                Expanded(
                  child: PDetailQuickAction(
                    icon: LucideIcons.scissors,
                    label: l.expSplit,
                    active: splitCount > 0,
                    badge: splitCount > 0 ? l.expItemsCount(splitCount) : null,
                    onTap: _deleting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            showSplitTxDialog(context, e);
                          },
                  ),
                ),
              Expanded(
                child: PDetailQuickAction(
                  icon: LucideIcons.repeat,
                  label: l.expConvertRecurring,
                  onTap: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showRecurringSettingsDialog(context, expense: e);
                        },
                ),
              ),
              Expanded(
                child: PDetailQuickAction(
                  icon: LucideIcons.users,
                  label: l.dutchTitle,
                  onTap: _deleting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          showDutchPayFromTxDialog(context, e);
                        },
                ),
              ),
            ],
          ),
        ),
        // 분할 내역 요약 — 분할이 있으면 접을 수 있는 카드로 항목·비율 표시(쉬운 확인)
        if (splits.isNotEmpty)
          _SplitSummaryCard(
            splits: splits,
            isIncome: isIncome,
            total: e.amount.abs(),
            categories: categories,
            expanded: _splitExpanded,
            onToggle: () => setState(() => _splitExpanded = !_splitExpanded),
            masked: masked,
            tokens: t,
          ),
        // Merchant history — 같은 가맹점·같은 달 이전 거래
        if ((e.merchant ?? '').isNotEmpty && dayStr != null)
          _MerchantHistorySection(
            merchant: e.merchant!,
            year: int.parse(dayStr.substring(0, 4)),
            month: int.parse(dayStr.substring(5, 7)),
            excludeRowId: e.rowId,
            masked: masked,
            tokens: t,
          ),
      ],
    );
  }
}

/// "이마트에서의 이전 거래" 섹션 — 같은 가맹점·같은 달 거래 리스트.
class _MerchantHistorySection extends ConsumerWidget {
  const _MerchantHistorySection({
    required this.merchant,
    required this.year,
    required this.month,
    required this.excludeRowId,
    required this.masked,
    required this.tokens,
  });
  final String merchant;
  final int year;
  final int month;
  final int excludeRowId;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(
      merchantMonthExpensesProvider((
        merchant: merchant,
        year: year,
        month: month,
      )),
    );
    final all = async.value ?? const <Expense>[];
    final history = all.where((x) => x.rowId != excludeRowId).take(5).toList();
    if (history.isEmpty) return const SizedBox.shrink();

    final monthCount = all.length;
    final monthTotal = all.fold<int>(0, (s, x) => s + x.amount.abs());
    final categories = ref.watch(categoriesProvider).value ?? const [];

    // 가계부 메인 리스트 미러 — 날짜별 그룹(provider 최신순 유지).
    // 일 합계는 상단 스탯이 대신하므로 헤더는 날짜(요일)만.
    final dayGroups = <String, List<Expense>>{};
    for (final h in history) {
      final k = h.expenseDateOnly ?? '';
      dayGroups.putIfAbsent(k, () => <Expense>[]).add(h);
    }

    // 섹션 제목 + 2열 스플릿 통계(이번 달 거래/총 금액) + 플랫 리스트 —
    // design 신판(카드 제거), 마스킹 시 '원' 미노출(web MaskAmount 컨벤션).
    return PDetailSection(
      title: Text(l.expPrevTxAt(merchant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: PSpace.x4, bottom: PSpace.x4),
            child: PDetailStatSplit(
              items: [
                PDetailStat(
                  label: l.expThisMonth,
                  value: l.expTimesCount(monthCount),
                ),
                PDetailStat(
                  label: l.expTotal,
                  value: masked
                      ? '••••••'
                      : krwSigned(monthTotal, false, unit: true),
                ),
              ],
            ),
          ),
          for (final entry in dayGroups.entries) ...[
            // 웹 DateGroupHeader 미러 — "7월 8일"(primary/bold) + "수"(tertiary).
            // 이번 달 내역이므로 연도 없이 날짜만(사용자 결정).
            Padding(
              padding: const EdgeInsets.only(top: PSpace.x12, bottom: 6),
              child: Builder(
                builder: (context) {
                  final d = DateTime.tryParse(entry.key);
                  if (d == null) {
                    return Text(
                      entry.key,
                      style: PTypo.bodySm.copyWith(color: tokens.fgSecondary),
                    );
                  }
                  final label = formatDay(d);
                  return Row(
                    children: [
                      Text(
                        label.md,
                        style: PTypo.bodySm.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: PSpace.x8),
                      Text(
                        label.dow,
                        style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
                      ),
                    ],
                  );
                },
              ),
            ),
            for (final h in entry.value)
              ExpenseRow(
                expense: h,
                category: h.categoryRowId == null
                    ? null
                    : categories.byRowId(h.categoryRowId!),
                flags: ref.watch(maskFlagsProvider('ledger.txDetail')),
                interactive: false,
              ),
          ],
        ],
      ),
    );
  }
}

/// 분할 내역 요약 카드 — 헤더(개수·합계·펼침) + 비율 바 + 항목별(이름·카테고리·비율·금액).
/// 거래에 분할이 있을 때 거래 상세에서 한눈에 확인용(웹 TxDetailDialog 분할 요약 정합).
class _SplitSummaryCard extends StatelessWidget {
  const _SplitSummaryCard({
    required this.splits,
    required this.isIncome,
    required this.total,
    required this.categories,
    required this.expanded,
    required this.onToggle,
    required this.masked,
    required this.tokens,
  });
  final List<ExpenseSplit> splits;
  final bool isIncome;
  final int total;
  final List<ExpenseCategory> categories;
  final bool expanded;
  final VoidCallback onToggle;

  /// 히어로 금액과 **같은 값**이라 같이 가려야 한다 — 안 그러면 위를 가려도 여기서 보인다.
  final bool masked;
  final PorestTokens tokens;

  Color _colorFor(BuildContext context, int categoryRowId) => resolveChartColor(
    context,
    categories.byRowId(categoryRowId)?.color,
    fallback: tokens.fgBrand,
  );

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    return PDetailSection(
      title: Text('${l.expSplit} ${l.expItemsCount(splits.length)}'),
      // 접기 토글 — 합계 우측 chevron (사용자 결정, 웹 정합)
      trailing: InkWell(
        onTap: onToggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l.expTotal} ${krwSigned(total, masked, unit: true)}',
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
            const SizedBox(width: 6),
            Icon(
              expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
              color: t.fgTertiary,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: PRadius.brFull,
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (final s in splits)
                    if (total > 0 && s.amount > 0)
                      Flexible(
                        flex: s.amount,
                        child: Container(
                          color: _colorFor(context, s.categoryRowId),
                        ),
                      ),
                ],
              ),
            ),
          ),
          if (expanded)
            for (int i = 0; i < splits.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: i == splits.length - 1 ? 0 : 0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _colorFor(context, splits[i].categoryRowId),
                        borderRadius: PRadius.brXs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (splits[i].label?.trim().isNotEmpty ?? false)
                                ? splits[i].label!
                                : (splits[i].categoryName ?? l.expItem),
                            style: PTypo.bodySm.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.semi,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${splits[i].categoryName ?? '-'} · '
                            '${total > 0 ? ((splits[i].amount / total) * 100).round() : 0}%',
                            style: PTypo.caption.copyWith(color: t.fgTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      krwSigned(
                        splits[i].amount,
                        masked,
                        sign: isIncome ? '+' : '−',
                        unit: true,
                      ),
                      // 행 금액 중립색 — 가계부 리스트 정합(사용자 결정)
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
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

/// 1400.000000 을 1400 으로 — 상세에 소수 6자리를 그대로 보여 주면 지저분하다.
String _trimRate(double rate) {
  final s = rate.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}
