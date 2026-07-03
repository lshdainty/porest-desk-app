import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/brand/bank_colors.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/include_in_total_card.dart';

/// 카드 추가 다이얼로그 — front `CardAddDialog` 미러.
///
/// 계좌·투자 다이얼로그와 동일한 패턴 (showModalBottomSheet +
/// DraggableScrollableSheet, 헤더/푸터 border 없음).
///
/// 구성:
/// - 미리보기 타일 (카드 이미지 또는 발급사 컬러 박스 + 별칭/회사·종류)
/// - 카드 종류 segmented (신용카드 / 체크카드)
/// - 카드 상품 — 검색 + 단종 포함 토글 + 카탈로그 리스트 (선택)
/// - 별칭 (선택)
/// - 현재 사용액 (원)  → 청구 예정 금액. 총 부채에 반영.
void showCardAddDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.assetCardAdd,
    contentBuilder: (ctx, scrollCtrl) => _CardAddBody(
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.calAdd,
    ),
  ).whenComplete(controller.dispose);
}

enum _CardType { credit, check }

extension on _CardType {
  String label(AppLocalizations l) => switch (this) {
        _CardType.credit => l.assetTypeCreditCard,
        _CardType.check => l.assetTypeCheckCard,
      };
  String get apiCode => switch (this) {
        _CardType.credit => 'CREDIT',
        _CardType.check => 'CHECK',
      };
  String get assetType => switch (this) {
        _CardType.credit => 'CREDIT_CARD',
        _CardType.check => 'CHECK_CARD',
      };
}

class _CardAddBody extends ConsumerStatefulWidget {
  const _CardAddBody({
    required this.scrollController,
    required this.controller,
  });
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_CardAddBody> createState() => _CardAddBodyState();
}

class _CardAddBodyState extends ConsumerState<_CardAddBody> {
  late final TextEditingController _keywordCtrl;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _creditLimitCtrl;

  _CardType _cardType = _CardType.credit;
  bool _includeDiscontinued = false;
  bool _includeInTotal = true;
  CardCatalogSummary? _selected;
  int? _paymentDay; // 결제일 1~31
  int? _paymentAssetRowId; // 결제 출금계좌 자산 rowId
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _keywordCtrl = TextEditingController()..addListener(_onChanged);
    _nicknameCtrl = TextEditingController()..addListener(_onChanged);
    _balanceCtrl = TextEditingController(text: '0');
    _creditLimitCtrl = TextEditingController();
    widget.controller.onSubmit = _submit;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  void _onChanged() {
    setState(() {});
    widget.controller.setCanSubmit(_selected != null && !_submitting);
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _nicknameCtrl.dispose();
    _balanceCtrl.dispose();
    _creditLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _selected == null) return;
    final l = AppLocalizations.of(context);
    final selected = _selected!;
    final nickname = _nicknameCtrl.text.trim();
    final name = nickname.isEmpty ? selected.cardName : nickname;
    final outstanding =
        int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final company = selected.company?.name;
    // 청구 사이클 필드는 신용카드일 때만. 빈 한도는 null 로 전송.
    final isCredit = _cardType == _CardType.credit;
    final creditLimit = isCredit
        ? int.tryParse(_creditLimitCtrl.text.replaceAll(',', ''))
        : null;

    _setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.create(
        assetName: name,
        assetType: _cardType.assetType,
        balance: outstanding,
        currency: 'KRW',
        institution: company,
        isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
        cardCatalogRowId: selected.rowId,
        creditLimit: creditLimit,
        paymentDay: isCredit ? _paymentDay : null,
        paymentAssetRowId: isCredit ? _paymentAssetRowId : null,
      );
      // brand color hex 는 모바일 측에선 별도 파싱이라 institution 으로 추후 매칭.
      // (web 의 color 필드는 같은 효과를 내는 보조 정보)
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, l.assetCardAdded, severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetActionFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final searchKey = defaultCardSearchKey(
      keyword: _keywordCtrl.text.trim().isEmpty
          ? null
          : _keywordCtrl.text.trim(),
      cardType: _cardType.apiCode,
      includeDiscontinued: _includeDiscontinued ? true : null,
      page: 0,
      size: 40,
    );
    final pageAsync = ref.watch(cardCatalogPageProvider(searchKey));
    final isCredit = _cardType == _CardType.credit;
    // 결제 출금계좌 후보 — 본인 소유 BANK_ACCOUNT 자산.
    final bankAccounts = (ref.watch(assetsProvider).value ?? const <Asset>[])
        .where((a) => a.assetType == 'BANK_ACCOUNT')
        .toList(growable: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.setCanSubmit(_selected != null && !_submitting);
      }
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
                _PreviewTile(
                  selected: _selected,
                  cardType: _cardType,
                  nickname: _nicknameCtrl.text.trim(),
                ),
                const SizedBox(height: PSpace.x20),

                // 카드 종류 ──────────────────────────
                Text(l.assetCardType,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTabs<_CardType>(
                  items: [
                    for (final c in _CardType.values)
                      PTabItem(value: c, label: c.label(l)),
                  ],
                  value: _cardType,
                  onChanged: (v) => setState(() {
                    _cardType = v;
                    _selected = null; // 종류 바뀌면 선택 초기화
                  }),
                  variant: PTabsVariant.container,
                  size: PTabsSize.sm,
                  expand: true,
                ),
                const SizedBox(height: PSpace.x20),

                // 카드 상품 ──────────────────────────
                Row(
                  children: [
                    Text(l.assetCardProduct,
                        style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.medium)),
                    const Spacer(),
                    // web: '단종 포함 [switch]   총 N건' — 한 row 에 끝까지 정렬.
                    InkWell(
                      onTap: () => setState(
                          () => _includeDiscontinued = !_includeDiscontinued),
                      borderRadius: PRadius.brSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.assetIncludeDiscontinued,
                                style: PTypo.caption
                                    .copyWith(color: t.fgTertiary)),
                            const SizedBox(width: 6),
                            // PSwitch(44×24) 를 60%로 축소 — toolbar dense 화면.
                            SizedBox(
                              width: 36,
                              height: 22,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: PSwitch(
                                  value: _includeDiscontinued,
                                  onChanged: (v) => setState(
                                      () => _includeDiscontinued = v),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      pageAsync.value != null
                          ? l.assetTotalItems(pageAsync.value!.totalElements)
                          : l.assetTotalLoading,
                      style: PTypo.micro.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                PSearchField(
                  hint: l.assetCardSearchHint,
                  controller: _keywordCtrl,
                ),
                const SizedBox(height: PSpace.x8),
                _CatalogList(
                  async: pageAsync.whenData((p) => p.content),
                  selectedId: _selected?.rowId,
                  onPick: (c) => setState(() => _selected = c),
                ),
                const SizedBox(height: PSpace.x20),

                // 별칭 (선택) ────────────────────────
                Text(l.assetNicknameOptional,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _nicknameCtrl,
                  placeholder:
                      _selected?.cardName ?? l.assetCardNicknamePlaceholder,
                ),
                const SizedBox(height: PSpace.x20),

                // 현재 사용액 (원) ───────────────────
                Text(l.assetCurrentUsage,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true),
                  placeholder: '0',
                ),
                const SizedBox(height: 6),
                Text(l.assetCurrentUsageHint,
                    style: PTypo.micro.copyWith(color: t.fgTertiary)),

                // 청구 사이클 (신용카드 전용) ──────────────
                if (isCredit) ...[
                  const SizedBox(height: PSpace.x20),
                  // 신용한도 (원)
                  Text(l.assetCreditLimitLabel,
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                  const SizedBox(height: PSpace.x8),
                  PTextInput(
                    controller: _creditLimitCtrl,
                    keyboardType: TextInputType.number,
                    placeholder: l.assetCreditLimitPlaceholder,
                  ),
                  const SizedBox(height: 6),
                  Text(l.assetCreditLimitHint,
                      style: PTypo.micro.copyWith(color: t.fgTertiary)),
                  const SizedBox(height: PSpace.x20),
                  // 결제일 (1~31)
                  Text(l.assetPaymentDayLabel,
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                  const SizedBox(height: PSpace.x8),
                  PSelect<int>(
                    value: _paymentDay,
                    placeholder: l.assetPaymentDaySelect,
                    title: l.assetPaymentDay,
                    items: [
                      for (var d = 1; d <= 31; d++)
                        PSelectItem(value: d, label: '$d일'),
                    ],
                    onChanged: (v) => setState(() => _paymentDay = v),
                  ),
                  const SizedBox(height: PSpace.x20),
                  // 결제 출금계좌
                  Text(l.assetPaymentAccountLabel,
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                  const SizedBox(height: PSpace.x8),
                  PSelect<int>(
                    value: _paymentAssetRowId,
                    placeholder: bankAccounts.isEmpty
                        ? l.assetNoBankAccounts
                        : l.assetPaymentAccountSelect,
                    title: l.assetPaymentAccount,
                    enabled: bankAccounts.isNotEmpty,
                    items: [
                      for (final a in bankAccounts)
                        PSelectItem(
                          value: a.rowId,
                          label: a.institution != null &&
                                  a.institution!.isNotEmpty
                              ? '${a.assetName} · ${a.institution}'
                              : a.assetName,
                        ),
                    ],
                    onChanged: (v) => setState(() => _paymentAssetRowId = v),
                  ),
                  const SizedBox(height: 6),
                  Text(l.assetPaymentAccountHint,
                      style: PTypo.micro.copyWith(color: t.fgTertiary)),
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

/// 미리보기 타일 — 선택된 카드 이미지 또는 발급사 컬러 박스 + 별칭/회사·종류.
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.selected,
    required this.cardType,
    required this.nickname,
  });
  final CardCatalogSummary? selected;
  final _CardType cardType;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final company = selected?.company?.name;
    final brand = company != null ? getBrandColor([company]) : null;
    final preview =
        nickname.isEmpty ? (selected?.cardName ?? l.assetNewCard) : nickname;
    final subtitle = [
      if (company != null && company.isNotEmpty) company,
      cardType.label(l),
    ].join(' · ');
    final imgUrl = selected?.imgUrl;
    return Row(
      children: [
        SizedBox(
          width: 68,
          height: 44,
          child: ClipRRect(
            borderRadius: PRadius.brMd,
            child: imgUrl != null && imgUrl.isNotEmpty
                ? Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _PlaceholderBox(brand: brand, tokens: t),
                  )
                : _PlaceholderBox(brand: brand, tokens: t),
          ),
        ),
        const SizedBox(width: PSpace.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.caption.copyWith(color: t.fgTertiary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({required this.brand, required this.tokens});
  final BrandColor? brand;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: brand?.bg ?? tokens.bgSunken,
      alignment: Alignment.center,
      child: Icon(LucideIcons.creditCard,
          size: 18, color: brand?.fg ?? tokens.fgPrimary),
    );
  }
}

/// 카드 카탈로그 리스트 — 자체 maxHeight 260 + 내부 스크롤 (web 동일).
class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.async,
    required this.selectedId,
    required this.onPick,
  });
  final AsyncValue<List<CardCatalogSummary>> async;
  final int? selectedId;
  final ValueChanged<CardCatalogSummary> onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final box = BoxDecoration(
      color: t.bgSurface,
      borderRadius: PRadius.brMd,
      border: Border.all(color: t.borderSubtle),
    );
    return Container(
      width: double.infinity,
      decoration: box,
      constraints: const BoxConstraints(maxHeight: 260),
      clipBehavior: Clip.hardEdge,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: PCircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(l.assetCatalogLoadError,
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(l.assetNoSearchResults,
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ),
            );
          }
          return Scrollbar(
            thumbVisibility: false,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  PDivider(),
              itemBuilder: (_, i) {
                final c = items[i];
                final active = c.rowId == selectedId;
                final discontinued = c.isDiscontinued == 'Y';
                return _CatalogRow(
                  item: c,
                  active: active,
                  discontinued: discontinued,
                  onTap: () => onPick(c),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.item,
    required this.active,
    required this.discontinued,
    required this.onTap,
  });
  final CardCatalogSummary item;
  final bool active;
  final bool discontinued;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final company = item.company?.name;
    final brand = company != null ? getBrandColor([company]) : null;
    final fee = item.annualFee?.amount ?? 0;
    final feePart = fee > 0 ? ' · ${l.assetAnnualFee} ${_fmtKrw(fee)}원' : '';
    final subtitle =
        '${company ?? '—'} · ${item.cardType == 'CREDIT' ? l.assetCardShortCredit : l.assetCardShortCheck}$feePart';

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: discontinued && !active ? 0.7 : 1,
        child: Container(
          color: active ? t.bgBrandSubtle : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 28,
                child: ClipRRect(
                  borderRadius: PRadius.brSm,
                  child: item.imgUrl != null && item.imgUrl!.isNotEmpty
                      ? Image.network(
                          item.imgUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _RowPlaceholder(brand: brand, name: company ?? item.cardName, tokens: t),
                        )
                      : _RowPlaceholder(
                          brand: brand,
                          name: company ?? item.cardName,
                          tokens: t,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.cardName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PTypo.bodySm.copyWith(
                              color: active
                                  ? t.fgBrandStrong
                                  : t.fgPrimary,
                              fontWeight: active
                                  ? PFontWeight.semi
                                  : PFontWeight.medium,
                            ),
                          ),
                        ),
                        if (discontinued) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: t.bgDisabled,
                              borderRadius: PRadius.brXs,
                            ),
                            child: Text(
                              l.assetDiscontinued,
                              style: PTypo.micro.copyWith(
                                color: t.fgTertiary,
                                fontWeight: PFontWeight.semi,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.micro.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowPlaceholder extends StatelessWidget {
  const _RowPlaceholder({
    required this.brand,
    required this.name,
    required this.tokens,
  });
  final BrandColor? brand;
  final String name;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: brand?.bg ?? tokens.borderDefault,
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: TextStyle(
          color: brand?.fg ?? tokens.fgPrimary,
          fontWeight: PFontWeight.bold,
          fontSize: PFontSize.micro,
        ),
      ),
    );
  }
}

String _fmtKrw(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
