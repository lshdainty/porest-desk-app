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
  required List<AssetHolding> holdings,
  String defaultType = 'BUY',
}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.tradeTitle,
    contentBuilder: (ctx, scrollCtrl) => _TradeBody(
      asset: asset,
      holdings: holdings,
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
    required this.holdings,
    required this.defaultType,
    required this.scrollController,
    required this.controller,
  });
  final Asset asset;
  final List<AssetHolding> holdings;
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
  final _newNameCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  late String _type;
  String? _holdingKey;
  String _newType = 'STOCK';
  bool _addNew = false;
  bool _submitting = false;

  bool get _isSell => _type == 'SELL';

  /// 종목 식별자 — 연동은 토스 종목코드, 미연동은 항목명.
  /// 보유 목록은 편집할 때마다 통째로 재생성돼서 rowId 로는 거래를 묶을 수 없다.
  String _keyOf(AssetHolding h) =>
      (h.linked ? h.tossSymbol : h.holdingName) ?? '';

  List<AssetHolding> get _options =>
      widget.holdings.where((h) => _keyOf(h).isNotEmpty).toList(growable: false);

  AssetHolding? get _picked =>
      _options.where((h) => _keyOf(h) == _holdingKey).firstOrNull;

  bool get _useNew => !_isSell && _addNew;

  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 0;
  int get _amount => int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
  int get _fee => int.tryParse(_feeCtrl.text.replaceAll(',', '')) ?? 0;

  double get _heldQty =>
      double.tryParse(_picked?.quantity?.toString() ?? '') ?? 0;

  /// 거래 후 예수금 — 매수는 수수료까지 빠지고 매도는 떼고 들어온다.
  int get _cashAfter {
    final delta = _isSell ? _amount - _fee : -(_amount + _fee);
    return (widget.asset.cashBalance ?? 0) + delta;
  }

  /// 실현손익 미리보기 — 서버와 같은 비율로 판 만큼의 원가를 뺀다.
  int? get _realizedPreview {
    final h = _picked;
    if (!_isSell || h == null || _heldQty <= 0 || _qty <= 0) return null;
    final soldCost = ((h.totalCost ?? 0) * _qty / _heldQty).round();
    return _amount - _fee - soldCost;
  }

  String get _resolvedKey =>
      _useNew ? _newNameCtrl.text.trim() : (_holdingKey ?? '');

  bool get _canSubmit =>
      !_submitting &&
      _resolvedKey.isNotEmpty &&
      _qty > 0 &&
      _amount > 0 &&
      (!_isSell || (_picked != null && _qty <= _heldQty)) &&
      (_isSell || _cashAfter >= 0);

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType == 'SELL' ? 'SELL' : 'BUY';
    _holdingKey = _options.isNotEmpty ? _keyOf(_options.first) : null;
    _addNew = _options.isEmpty;
    for (final c in [_qtyCtrl, _amountCtrl, _feeCtrl, _newNameCtrl]) {
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
    for (final c in [_qtyCtrl, _amountCtrl, _feeCtrl, _newNameCtrl, _memoCtrl]) {
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
        holdingType: _useNew ? _newType : (_picked?.holdingType.wire ?? 'STOCK'),
        holdingKey: _resolvedKey,
        // 새로 들이는 종목은 수동 입력이다 — 토스 연동은 종목 검색을 거쳐야 해서 편집 화면에서 붙인다.
        linked: _useNew ? false : (_picked?.linked ?? false),
        quantity: _qtyCtrl.text.trim(),
        amount: _amount,
        fee: _fee,
        tradeDate: DateTime.now().toIso8601String().substring(0, 19),
        description: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
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
            if (v == 'SELL') _addNew = false;
            _sync();
          }),
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
        ),
        const SizedBox(height: PSpace.x20),

        PSectionLabel(l.tradeHolding),
        const SizedBox(height: PSpace.x4),
        if (_useNew) ...[
          PTextInput(
            controller: _newNameCtrl,
            placeholder: l.tradeNewHoldingPlaceholder,
          ),
          const SizedBox(height: PSpace.x8),
          PSelect<String>(
            value: _newType,
            title: l.tradeHoldingType,
            items: [
              PSelectItem(value: 'STOCK', label: l.holdingTypeStock),
              PSelectItem(value: 'GOLD', label: l.holdingTypeGold),
              PSelectItem(value: 'CRYPTO', label: l.holdingTypeCrypto),
            ],
            onChanged: (v) => setState(() => _newType = v ?? 'STOCK'),
          ),
        ] else
          PSelect<String>(
            value: _holdingKey,
            placeholder: l.tradeNoHolding,
            title: l.tradeHolding,
            enabled: _options.isNotEmpty,
            items: [
              for (final h in _options)
                PSelectItem(value: _keyOf(h), label: _keyOf(h)),
            ],
            onChanged: (v) => setState(() {
              _holdingKey = v;
              _sync();
            }),
          ),
        if (!_isSell && _options.isNotEmpty) ...[
          const SizedBox(height: PSpace.x4),
          GestureDetector(
            onTap: () => setState(() {
              _addNew = !_addNew;
              _sync();
            }),
            child: Text(
              _useNew ? l.tradePickExisting : l.tradeAddNewHolding,
              style: PTypo.caption.copyWith(
                  color: t.fgBrand, fontWeight: PFontWeight.semi),
            ),
          ),
        ],
        if (_isSell && _picked != null) ...[
          const SizedBox(height: PSpace.x4),
          Text(
            l.tradeHeldSummary(
              _picked!.quantity?.toString() ?? '0',
              _picked!.avgPrice != null
                  ? krwSigned(
                      double.tryParse(_picked!.avgPrice!)?.round() ?? 0, false)
                  : '—',
            ),
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
        ],
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
                  Text(l.tradeCashAfter,
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                  Text(
                    krwSigned(_cashAfter, false, unit: true),
                    style: PTypo.money.copyWith(
                      color: _cashAfter < 0 ? t.statusDanger : t.fgPrimary,
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
              if (!_isSell && _cashAfter < 0) ...[
                const SizedBox(height: 6),
                Text(l.tradeInsufficientCash,
                    style: PTypo.micro.copyWith(color: t.statusDanger)),
              ],
              if (_isSell && _picked != null && _qty > _heldQty) ...[
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
