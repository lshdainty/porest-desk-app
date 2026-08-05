import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 매수·매도 입력 — web `AssetTradeDialog` 미러.
///
/// 예수금이 줄고 느는 진짜 사건을 여기서 기록한다. 보유 목록을 손으로 고치는 것과 다르다 —
/// 평가액 갱신을 보고 예수금을 추측하면 시세 변동·추가 매수·재등록이 구분되지 않는다.
///
/// 거래대금은 수수료를 뺀 순수 금액이다. 수수료는 매수면 취득원가에 들어가고
/// 매도면 대금에서 빠진다 — 어느 쪽이든 예수금에서 실제로 나간다.
void showAssetTradeSheet(
  BuildContext context, {
  required Asset asset,
  /// 어떤 종목인지 정해진 채로 들어온다 — 여기서 다시 고르게 하면 편집과 역할이 겹친다.
  required AssetHolding holding,
  String defaultType = 'BUY',
}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.tradeTitle,
    contentBuilder: (ctx, scrollCtrl) => _TradeBody(
      asset: asset,
      holding: holding,
      defaultType: defaultType,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.actionSave,
    ),
  ).whenComplete(controller.dispose);
}

class _TradeBody extends ConsumerStatefulWidget {
  const _TradeBody({
    required this.asset,
    required this.holding,
    required this.defaultType,
    required this.scrollController,
    required this.controller,
  });
  final Asset asset;
  final AssetHolding holding;
  final String defaultType;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_TradeBody> createState() => _TradeBodyState();
}

class _TradeBodyState extends ConsumerState<_TradeBody> {
  final _qtyCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  late String _type;
  bool _submitting = false;
  /// 결제 계좌 — null 이면 증권계좌 예수금에서. 예수금을 따로 관리하지 않으면 통장을 고른다.
  int? _settlementAssetRowId;

  bool get _viaCash => _settlementAssetRowId == null;

  bool get _isSell => _type == 'SELL';

  AssetHolding get _h => widget.holding;

  /// 종목 식별자 — 연동은 토스 종목코드, 미연동은 항목명.
  /// 보유 목록은 편집할 때마다 통째로 재생성돼서 rowId 로는 거래를 묶을 수 없다.
  String get _holdingKey =>
      (_h.linked ? _h.tossSymbol : _h.holdingName) ?? '';

  /// 티커가 아니라 이름으로 보여 준다 — 편집 화면과 같아야 헷갈리지 않는다.
  String get _holdingName =>
      (_h.linked ? (_h.tossSymbol ?? '') : (_h.holdingName ?? ''));

  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 0;
  int get _amount => int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
  int get _fee => int.tryParse(_feeCtrl.text.replaceAll(',', '')) ?? 0;

  double get _heldQty => double.tryParse(_h.quantity?.toString() ?? '') ?? 0;

  /// 돈이 오가는 방향·크기 — 매수는 수수료까지 빠지고 매도는 떼고 들어온다.
  int get _cashDelta => _isSell ? _amount - _fee : -(_amount + _fee);

  /// 거래 후 예수금 (예수금 결제일 때만 의미 있다).
  int get _cashAfter => (widget.asset.cashBalance ?? 0) + _cashDelta;

  /// 실현손익 미리보기 — 서버와 같은 비율로 판 만큼의 원가를 뺀다.
  int? get _realizedPreview {
    if (!_isSell || _heldQty <= 0 || _qty <= 0) return null;
    final soldCost = ((_h.totalCost ?? 0) * _qty / _heldQty).round();
    return _amount - _fee - soldCost;
  }

  bool get _canSubmit =>
      !_submitting &&
      _holdingKey.isNotEmpty &&
      _qty > 0 &&
      _amount > 0 &&
      (!_isSell || _qty <= _heldQty) &&
      // 예수금으로 살 때만 잔액을 본다 — 결제 계좌는 마이너스를 막지 않는다(서버도 같은 규칙).
      // 예수금이 모자라도 막지 않는다 — 기록용 앱이라 마이너스로 쌓이는 게 정상이다.
      true;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType == 'SELL' ? 'SELL' : 'BUY';
    for (final c in [_qtyCtrl, _amountCtrl, _feeCtrl]) {
      c.addListener(_sync);
    }
    widget.controller.onSubmit = _submit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    setState(() {});
    widget.controller.setCanSubmit(_canSubmit);
  }

  @override
  void dispose() {
    for (final c in [_qtyCtrl, _amountCtrl, _feeCtrl, _memoCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final l = AppLocalizations.of(context);
    setState(() => _submitting = true);
    widget.controller.setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.createTrade(
        assetRowId: widget.asset.rowId,
        tradeType: _type,
        holdingType: _h.holdingType.wire,
        holdingKey: _holdingKey,
        linked: _h.linked,
        quantity: _qtyCtrl.text.trim(),
        amount: _amount,
        fee: _fee,
        tradeDate: DateTime.now().toIso8601String().substring(0, 19),
        description: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
        settlementAssetRowId: _settlementAssetRowId,
      );
      // 예수금·보유·실현손익이 한꺼번에 바뀐다 — 자산과 거래 목록을 모두 새로 받는다.
      ref.invalidate(assetsProvider);
      ref.invalidate(assetTradesProvider(widget.asset.rowId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, _isSell ? l.tradeSold : l.tradeBought,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, e.message, severity: PSnackSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        widget.controller.setSubmitting(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final realized = _realizedPreview;
    // 결제 계좌 후보 — 이 증권계좌 자신과 카드는 뺀다.
    final settlementOptions = (ref.watch(assetsProvider).value ?? const <Asset>[])
        .where((a) =>
            a.rowId != widget.asset.rowId &&
            a.assetType != 'CREDIT_CARD' &&
            a.assetType != 'CHECK_CARD')
        .toList(growable: false);

    return ListView(
      controller: widget.scrollController,
      children: [
        PTabs<String>(
          items: [
            PTabItem(value: 'BUY', label: l.tradeBuy),
            PTabItem(value: 'SELL', label: l.tradeSell),
          ],
          value: _type,
          onChanged: (v) => setState(() {
            _type = v;
            _sync();
          }),
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
        ),
        const SizedBox(height: PSpace.x20),

        // 어떤 종목인지 — 여기서 고르는 게 아니라 이미 정해져서 들어온다.
        // 종목 추가는 편집(토스 검색)에서 한다.
        Container(
          padding: const EdgeInsets.all(PSpace.x12),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brMd,
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_holdingName,
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                l.tradeHeldSummary(
                  _h.quantity?.toString() ?? '0',
                  _h.avgPrice != null
                      ? krwSigned(
                          double.tryParse(_h.avgPrice!)?.round() ?? 0, false)
                      : '—',
                ),
                style: PTypo.micro.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x20),

        PSectionLabel(l.tradeQuantity),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _qtyCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          placeholder: '0',
        ),
        const SizedBox(height: PSpace.x20),

        PSectionLabel(l.tradeAmount),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          placeholder: '0',
        ),
        const SizedBox(height: 6),
        Text(l.tradeAmountHelp,
            style: PTypo.micro.copyWith(color: t.fgTertiary)),
        const SizedBox(height: PSpace.x20),

        PSectionLabel(l.tradeFee),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _feeCtrl,
          keyboardType: TextInputType.number,
          placeholder: '0',
        ),
        const SizedBox(height: PSpace.x20),

        // 결제 계좌는 매수에만. 매도 대금은 예수금에 남기고 사용자가 이체로 관리한다 —
        // 팔았다고 통장으로 자동 이체되지는 않는다.
        if (!_isSell) ...[
          PSectionLabel(l.tradeSettlement),
          const SizedBox(height: PSpace.x4),
          PSelect<int>(
            value: _settlementAssetRowId ?? -1,
            title: l.tradeSettlement,
            items: [
              PSelectItem(value: -1, label: l.tradeSettlementCash),
              for (final a in settlementOptions)
                PSelectItem(
                  value: a.rowId,
                  label: a.institution != null && a.institution!.isNotEmpty
                      ? '${a.institution} · ${a.assetName}'
                      : a.assetName,
                ),
            ],
            onChanged: (v) => setState(() {
              _settlementAssetRowId = (v == null || v == -1) ? null : v;
              _sync();
            }),
          ),
          const SizedBox(height: 6),
          Text(_viaCash ? l.tradeSettlementCashHelp : l.tradeSettlementAccountHelp,
              style: PTypo.micro.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x20),
        ],

        PSectionLabel(l.tradeMemo),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _memoCtrl,
          placeholder: l.tradeMemoPlaceholder,
        ),
        const SizedBox(height: PSpace.x20),

        // 저장하고 놀라지 않게 예수금과 손익을 먼저 보여 준다.
        Container(
          padding: const EdgeInsets.all(PSpace.x12),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brMd,
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_viaCash ? l.tradeCashAfter : l.tradeSettlementDelta,
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                  Text(
                    _viaCash
                        ? krwSigned(_cashAfter, false, unit: true)
                        : krwSigned(_cashDelta.abs(), false,
                            sign: _cashDelta >= 0 ? '+' : '-', unit: true),
                    style: PTypo.money.copyWith(
                      color: _viaCash && _cashAfter < 0 ? t.statusDanger : t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (realized != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.tradeRealizedPreview,
                        style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                    Text(
                      krwSigned(realized.abs(), false,
                          sign: realized >= 0 ? '+' : '-', unit: true),
                      style: PTypo.money.copyWith(
                        color: realized >= 0 ? t.fgIncome : t.fgExpense,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (!_isSell && _viaCash && _cashAfter < 0) ...[
                const SizedBox(height: 6),
                Text(l.tradeInsufficientCash,
                    style: PTypo.micro.copyWith(color: t.statusDanger)),
              ],
              if (_isSell && _qty > _heldQty) ...[
                const SizedBox(height: 6),
                Text(l.tradeInsufficientQty,
                    style: PTypo.micro.copyWith(color: t.statusDanger)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
