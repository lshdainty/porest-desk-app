import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/brand/bank_colors.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/include_in_total_card.dart';

/// 투자 추가/편집 다이얼로그 — front `InvestmentAddDialog` / `AssetEditDialog`
/// (editingGroup === 'invest') 미러.
///
/// 계좌 다이얼로그와 동일한 패턴 (showModalBottomSheet + DraggableScrollableSheet).
/// 차이점:
/// - 브랜드 picker 가 증권사 + 가상자산거래소 만 표시
/// - 계좌 종류 segmented / 계좌번호 필드 없음
/// - 라벨: '상품·종목명' / '평가액 (원)'
/// - 편집 모드에 메모 (선택) 필드
void showInvestmentAddDialog(BuildContext context) {
  _open(context, edit: null);
}

void showInvestmentEditDialog(BuildContext context, Asset asset) {
  _open(context, edit: asset);
}

void _open(BuildContext context, {required Asset? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.assetInvestAdd : l.assetInvestEdit,
    contentBuilder: (ctx, scrollCtrl) => _InvestmentAddBody(
      edit: edit,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit != null ? l.actionSave : l.calAdd,
    ),
  ).whenComplete(controller.dispose);
}

/// 투자에 노출되는 브랜드만 평탄화 (증권사 + 가상자산거래소).
List<BankEntry> get _investBrands => [
      for (final cat in investCategories)
        ...?bankEntriesByCategory[cat],
    ];

class _InvestmentAddBody extends ConsumerStatefulWidget {
  const _InvestmentAddBody({
    required this.edit,
    required this.scrollController,
    required this.controller,
  });
  final Asset? edit;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_InvestmentAddBody> createState() =>
      _InvestmentAddBodyState();
}

class _InvestmentAddBodyState extends ConsumerState<_InvestmentAddBody> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _productCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _memoCtrl;

  late String _brand;
  late bool _includeInTotal;
  bool _submitting = false;
  bool _deleting = false;

  bool get _isEdit => widget.edit != null;

  /// 검색 q 매칭된 카테고리별 entries (증권사·가상자산거래소만).
  List<MapEntry<BankCategory, List<BankEntry>>> get _filteredByCategory {
    final q = _norm(_queryCtrl.text.trim());
    final result = <MapEntry<BankCategory, List<BankEntry>>>[];
    for (final cat in investCategories) {
      final all = bankEntriesByCategory[cat] ?? const <BankEntry>[];
      final list =
          all.where((e) => _matchesQuery(e, q)).toList(growable: false);
      if (list.isEmpty) continue;
      result.add(MapEntry(cat, list));
    }
    // bankCategoryOrder 순서 보장.
    result.sort((a, b) => bankCategoryOrder
        .indexOf(a.key)
        .compareTo(bankCategoryOrder.indexOf(b.key)));
    return result;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  static bool _matchesQuery(BankEntry e, String needle) {
    if (needle.isEmpty) return true;
    if (_norm(e.name).contains(needle)) return true;
    return e.aliases.any((a) => _norm(a).contains(needle));
  }

  int get _investEntriesCount => _investBrands.length;

  BankEntry get _selectedEntry => _investBrands.firstWhere(
      (e) => e.name == _brand,
      orElse: () => _investBrands.first);

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _brand = e?.institution != null && e!.institution!.isNotEmpty
        ? _investBrands
            .firstWhere(
              (b) =>
                  b.name == e.institution ||
                  b.aliases.contains(e.institution),
              orElse: () => _investBrands.first,
            )
            .name
        : _investBrands.first.name;
    _queryCtrl = TextEditingController()..addListener(_onChanged);
    _productCtrl = TextEditingController(text: e?.assetName ?? '')
      ..addListener(_onChanged);
    _balanceCtrl =
        TextEditingController(text: (e?.balance ?? 0).toString());
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    widget.controller.onSubmit = _submit;
    if (widget.edit != null) widget.controller.onDelete = _delete;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.controller.setCanSubmit(true));
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v || _deleting);
  }

  void _setDeleting(bool v) {
    setState(() => _deleting = v);
    widget.controller.setSubmitting(v || _submitting);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _queryCtrl.dispose();
    _productCtrl.dispose();
    _balanceCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final brand = _brand;
    final product = _productCtrl.text.trim();
    final name = product.isEmpty ? '$brand ${l.assetTypeInvestment}' : product;
    final balance = int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final memo = _memoCtrl.text.trim();

    _setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          assetName: name,
          assetType: 'INVESTMENT',
          balance: balance,
          currency: 'KRW',
          institution: brand,
          memo: memo.isEmpty ? null : memo,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
        );
      } else {
        await repo.create(
          assetName: name,
          assetType: 'INVESTMENT',
          balance: balance,
          currency: 'KRW',
          institution: brand,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
        );
      }
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, _isEdit ? l.assetInvestUpdated : l.assetInvestAdded,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetActionFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _delete() async {
    if (_deleting || widget.edit == null) return;
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.assetInvestDelete,
      message: l.assetInvestDeleteConfirm,
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setDeleting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, l.assetInvestDeleted, severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetDeleteFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setDeleting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
                _PreviewTile(
                    entry: _selectedEntry,
                    productName: _productCtrl.text.trim()),
                const SizedBox(height: PSpace.x20),

                // 증권사·거래소 ──────────────────────
                Row(
                  children: [
                    Text(l.assetBrokerExchange,
                        style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.medium)),
                    const Spacer(),
                    Text(l.assetTotalEntries(_investEntriesCount),
                        style: PTypo.micro.copyWith(color: t.fgTertiary)),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                PSearchField(
                  controller: _queryCtrl,
                  hint: l.assetInvestSearchHint,
                ),
                const SizedBox(height: PSpace.x8),
                _BrandPicker(
                  categories: _filteredByCategory,
                  selectedName: _brand,
                  onPick: (name) => setState(() => _brand = name),
                ),
                const SizedBox(height: PSpace.x20),

                // 상품·종목명 ────────────────────────
                Text(l.assetProductName,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _productCtrl,
                  placeholder: l.assetProductPlaceholder,
                ),
                const SizedBox(height: PSpace.x20),

                // 평가액 (원) ────────────────────────
                Text(l.assetValuation,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _balanceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  placeholder: '0',
                ),

                // 메모 (선택) — 편집 모드에서만.
                if (_isEdit) ...[
                  const SizedBox(height: PSpace.x20),
                  Text(l.assetMemoOptional,
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.medium)),
                  const SizedBox(height: PSpace.x8),
                  PTextInput(
                    controller: _memoCtrl,
                    placeholder: l.assetMemoPlaceholder,
                  ),
                ],

                // 전체 자산 합계 포함 토글 ──────────────
                const SizedBox(height: PSpace.x20),
                IncludeInTotalCard(
                  value: _includeInTotal,
                  onChanged: (v) => setState(() => _includeInTotal = v),
                ),
              ],
            );
  }
}

/// 미리보기 타일 — 브랜드 컬러 박스 + 상품·종목명/브랜드.
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.entry, required this.productName});
  final BankEntry entry;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final letter = entry.name.isEmpty ? '?' : entry.name.characters.first;
    final preview = productName.isEmpty ? l.assetNewInvestment : productName;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: entry.color.bg,
            borderRadius: PRadius.brMd,
          ),
          child: Text(
            letter,
            style: TextStyle(
              color: entry.color.fg,
              fontWeight: PFontWeight.bold,
              fontSize: PFontSize.body,
            ),
          ),
        ),
        const SizedBox(width: PSpace.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.body.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
              const SizedBox(height: 2),
              Text('${entry.name} · ${l.assetPreview}',
                  style: PTypo.caption.copyWith(color: t.fgTertiary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 카테고리별 브랜드 chip 그리드 — maxHeight 260 + 자체 스크롤 (web 동일).
class _BrandPicker extends StatelessWidget {
  const _BrandPicker({
    required this.categories,
    required this.selectedName,
    required this.onPick,
  });
  final List<MapEntry<BankCategory, List<BankEntry>>> categories;
  final String selectedName;
  final ValueChanged<String> onPick;

  /// 카테고리 라벨 — 가상자산 → 가상자산거래소 (web 동일).
  static String _label(AppLocalizations l, BankCategory c) =>
      c == BankCategory.cryptoExchange ? l.assetCryptoExchange : c.label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final box = BoxDecoration(
      color: t.bgSurface,
      borderRadius: PRadius.brMd,
      border: Border.all(color: t.borderSubtle),
    );
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: box,
        child: Center(
          child: Text(
            l.assetNoSearchResults,
            style: PTypo.caption.copyWith(color: t.fgTertiary),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      decoration: box,
      constraints: const BoxConstraints(maxHeight: 260),
      clipBehavior: Clip.hardEdge,
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _label(l, categories[i].key),
                    style: PTypo.micro.copyWith(
                      color: t.fgTertiary,
                      fontWeight: PFontWeight.semi,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in categories[i].value)
                      PChip(
                        label: e.name,
                        selected: e.name == selectedName,
                        onTap: () => onPick(e.name),
                        color: e.color.bg,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

