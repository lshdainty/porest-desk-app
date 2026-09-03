import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/core/format/amount_limits.dart';
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
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/card/presentation/card_fee_text.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_sign.dart';
import 'package:porest_desk_app/features/asset/presentation/include_in_total_card.dart';

/// 카드 추가/편집 다이얼로그 — front `AssetEditDialog`(group='card') 미러.
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
void showCardAddDialog(BuildContext context) => _open(context, edit: null);

/// 카드 편집 — 기존 카드 자산을 받아 동일 폼 재사용.
/// 계좌 폼을 쓰면 은행 브랜드·계좌번호가 뜨고 카드 상품을 못 바꾼다.
void showCardEditDialog(BuildContext context, Asset asset) =>
    _open(context, edit: asset);

void _open(BuildContext context, {required Asset? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.assetCardAdd : l.assetCardEdit,
    contentBuilder: (ctx, scrollCtrl) => _CardAddBody(
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
    required this.edit,
    required this.scrollController,
    required this.controller,
  });
  final Asset? edit;
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

  late _CardType _cardType;
  bool _includeDiscontinued = false;
  late bool _includeInTotal;
  CardCatalogSummary? _selected;
  int? _paymentDay; // 결제일 1~31
  int? _paymentAssetRowId; // 결제 출금계좌 자산 rowId
  bool _submitting = false;
  bool _touched = false;

  bool get _isEdit => widget.edit != null;

  /// 별칭 길이 상한 — 계좌와 같은 값(QA #16).
  static const _kNicknameMax = 30;

  String get _nicknameTrim => _nicknameCtrl.text.trim();

  /// 별칭은 선택 입력이다 — 비우면 카드 상품명으로 떨어지므로 중복을 안 본다.
  bool get _nicknameDuplicate =>
      _nicknameTrim.isNotEmpty &&
      (ref.read(assetsProvider).value ?? const <Asset>[]).any(
        (a) =>
            a.assetName.trim() == _nicknameTrim &&
            a.rowId != widget.edit?.rowId,
      );

  String? get _nicknameError {
    if (!_touched) return null;
    final l = AppLocalizations.of(context);
    if (_nicknameTrim.length > _kNicknameMax) {
      return l.nameTooLong(_kNicknameMax);
    }
    if (_nicknameDuplicate) return l.assetNicknameDuplicate;
    return null;
  }

  bool get _nicknameValid =>
      _nicknameTrim.length <= _kNicknameMax && !_nicknameDuplicate;

  /// 편집은 상품을 다시 고르지 않아도 별칭·금액만 바꿔 저장할 수 있어야 한다.
  ///
  /// 신용카드는 결제일이 필수다 — 없으면 명세서(예정 회차·할부 구성)가 성립하지 않는다.
  /// 결제일 없는 카드는 체크카드뿐이고 체크카드는 할부를 안 받는다(사용자 결정).
  /// 기존에 결제일 없이 등록된 신용카드도 여기서 걸린다 — 수정하며 채우게 된다.
  bool get _canSubmit =>
      !_submitting &&
      (_isEdit || _selected != null) &&
      (_cardType != _CardType.credit || _paymentDay != null) &&
      (!_touched || _nicknameValid);

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _cardType = e?.assetType == 'CHECK_CARD'
        ? _CardType.check
        : _CardType.credit;
    _keywordCtrl = TextEditingController()..addListener(_onChanged);
    _nicknameCtrl = TextEditingController(text: e?.assetName ?? '')
      ..addListener(_onNicknameChanged);
    // '현재 사용액' 이라는 라벨 아래 −500000 이 보이면 안 된다 — 부호는 저장 규약이다.
    _balanceCtrl = TextEditingController(
      text: (e?.balance ?? 0).abs().toString(),
    );
    _creditLimitCtrl = TextEditingController(
      text: e?.creditLimit?.toString() ?? '',
    );
    _paymentDay = e?.paymentDay;
    _paymentAssetRowId = e?.paymentAssetRowId;
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    // 연결된 상품을 고른 상태로 되살린다. 카탈로그 목록은 rowId 로 하이라이트하므로
    // 요약(rowId·이름·이미지·발급사)만 있으면 충분하다.
    final c = e?.cardCatalog;
    if (c != null) {
      _selected = CardCatalogSummary(
        rowId: c.rowId,
        cardName: c.cardName,
        cardType: _cardType.apiCode,
        imgUrl: c.imgUrl,
        company: c.companyName == null
            ? null
            : CardCompany(name: c.companyName, logoUrl: c.companyLogoUrl),
      );
    }
    widget.controller.onSubmit = _submit;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  void _onChanged() {
    setState(() {});
    widget.controller.setCanSubmit(_canSubmit);
  }

  /// 별칭 리스너 — 카탈로그 검색과 달리 여기서만 touched 를 세운다.
  /// 검색어를 쳤다고 별칭 에러가 빨개지면 무슨 일이 났는지 알 수 없다.
  void _onNicknameChanged() {
    setState(() => _touched = true);
    widget.controller.setCanSubmit(_canSubmit);
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
    if (!_canSubmit) return;
    final l = AppLocalizations.of(context);
    final edit = widget.edit;
    final nickname = _nicknameCtrl.text.trim();
    // 편집에서 상품을 다시 고르지 않았으면 기존 값으로 채운다.
    final name = nickname.isNotEmpty
        ? nickname
        : (_selected?.cardName ?? edit?.assetName ?? l.assetNewCard);
    // 체크카드는 잔액을 들지 않는다 — 사용액은 연결 계좌에서 이미 빠져 있다.
    //
    // 신용카드 잔액은 미결제 사용액이라 음수로 저장한다 — 화면은 "현재 사용액" 을 묻고
    // 사용자는 양수를 치는 게 자연스럽다. 서버도 같은 정규화를 하지만 여기서도 맞춰 보낸다.
    final outstanding = _cardType == _CardType.credit
        ? signedBalance(
            'CREDIT_CARD',
            int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0,
          )
        : 0;
    final company = _selected?.company?.name ?? edit?.institution;
    final catalogRowId = _selected?.rowId ?? edit?.cardCatalog?.rowId;
    // 청구 사이클 필드는 신용카드일 때만. 빈 한도는 null 로 전송.
    final isCredit = _cardType == _CardType.credit;
    final creditLimit = isCredit
        ? int.tryParse(_creditLimitCtrl.text.replaceAll(',', ''))
        : null;

    _setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      // brand color hex 는 모바일 측에선 별도 파싱이라 institution 으로 추후 매칭.
      // (web 의 color 필드는 같은 효과를 내는 보조 정보)
      if (edit != null) {
        await repo.update(
          id: edit.rowId,
          assetName: name,
          assetType: _cardType.assetType,
          balance: outstanding,
          currency: 'KRW',
          institution: company,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          cardCatalogRowId: catalogRowId,
          creditLimit: creditLimit,
          paymentDay: isCredit ? _paymentDay : null,
          // 계좌 연결은 두 종류 다 쓴다 — 신용은 결제일 자동이체, 체크는 즉시 차감.
          paymentAssetRowId: _paymentAssetRowId,
        );
      } else {
        await repo.create(
          assetName: name,
          assetType: _cardType.assetType,
          balance: outstanding,
          currency: 'KRW',
          institution: company,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          cardCatalogRowId: catalogRowId,
          creditLimit: creditLimit,
          paymentDay: isCredit ? _paymentDay : null,
          // 계좌 연결은 두 종류 다 쓴다 — 신용은 결제일 자동이체, 체크는 즉시 차감.
          paymentAssetRowId: _paymentAssetRowId,
        );
      }
      ref.invalidate(assetsProvider);
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
    final l = AppLocalizations.of(context);
    // 중복 검사는 `assetsProvider` 캐시를 읽는다 — 리스너가 도는 시점엔 아직
    // 로딩 중일 수 있어 그때 계산한 값은 믿을 수 없다. 그려질 때 다시 확정한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });
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
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        _PreviewTile(
          selected: _selected,
          cardType: _cardType,
          nickname: _nicknameCtrl.text.trim(),
        ),
        const SizedBox(height: PSpace.x20),

        // 카드 종류 ──────────────────────────
        Text(
          l.assetCardType,
          style: PTypo.caption.copyWith(
            color: t.fgPrimary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: PSpace.x8),
        PTabs<_CardType>(
          items: [
            for (final c in _CardType.values)
              PTabItem(value: c, label: c.label(l)),
          ],
          value: _cardType,
          onChanged: (v) {
            setState(() {
              _cardType = v;
              // 신규만 선택 초기화. 편집은 종류를 잘못 눌렀다고 해서
              // 연결된 상품까지 잃으면 곤란하다(web 동일).
              if (!_isEdit) _selected = null;
            });
            // 신용↔체크 전환은 결제일 필수 여부를 바꾼다 — 저장 버튼을 다시 판정한다.
            _onChanged();
          },
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
        ),
        const SizedBox(height: PSpace.x20),

        // 카드 상품 ──────────────────────────
        Row(
          children: [
            Text(
              l.assetCardProduct,
              style: PTypo.caption.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.medium,
              ),
            ),
            const Spacer(),
            // web: '단종 포함 [switch]   총 N건' — 한 row 에 끝까지 정렬.
            InkWell(
              onTap: () =>
                  setState(() => _includeDiscontinued = !_includeDiscontinued),
              borderRadius: PRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.assetIncludeDiscontinued,
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                    const SizedBox(width: 6),
                    // PSwitch(44×24) 를 60%로 축소 — toolbar dense 화면.
                    SizedBox(
                      width: 36,
                      height: 22,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: PSwitch(
                          value: _includeDiscontinued,
                          onChanged: (v) =>
                              setState(() => _includeDiscontinued = v),
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
        PSearchField(hint: l.assetCardSearchHint, controller: _keywordCtrl),
        const SizedBox(height: PSpace.x8),
        _CatalogList(
          async: pageAsync.whenData((p) => p.content),
          selectedId: _selected?.rowId,
          onPick: (c) => setState(() => _selected = c),
        ),
        const SizedBox(height: PSpace.x20),

        // 별칭 (선택) ────────────────────────
        Text(
          l.assetNicknameOptional,
          style: PTypo.caption.copyWith(
            color: t.fgPrimary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _nicknameCtrl,
          placeholder: _selected?.cardName ?? l.assetCardNicknamePlaceholder,
        ),
        const SizedBox(height: PSpace.x4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _nicknameError ?? '${_nicknameTrim.length}/$_kNicknameMax',
            style: PTypo.micro.copyWith(
              color: _nicknameError != null ? t.fgExpense : t.fgTertiary,
            ),
          ),
        ),
        // 신용카드 — design 신판 순서: 신용한도 → 결제일 → 현재 사용액 → 결제 계좌(연동 유지)
        if (isCredit) ...[
          const SizedBox(height: PSpace.x20),
          // 신용한도 (원)
          Text(
            l.assetCreditLimitLabel,
            style: PTypo.caption.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _creditLimitCtrl,
            numbersOnly: true,
            amountMax: kBalanceMax,
            placeholder: l.assetCreditLimitPlaceholder,
          ),
          const SizedBox(height: 6),
          Text(
            l.assetCreditLimitHint,
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(height: PSpace.x20),
          // 결제일 (1~31)
          Text(
            l.assetPaymentDayLabel,
            style: PTypo.caption.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PSelect<int>(
            value: _paymentDay,
            placeholder: l.assetPaymentDaySelect,
            title: l.assetPaymentDay,
            items: [
              for (var d = 1; d <= 31; d++)
                PSelectItem(value: d, label: l.dayN(d)),
            ],
            onChanged: (v) {
              setState(() => _paymentDay = v);
              _onChanged();
            },
          ),
        ],
        // 현재 사용액 (원) ───────────────────
        // 체크카드는 잔액 개념이 없다 — 긁는 즉시 연결 계좌에서 빠지므로
        // 카드가 들고 있을 금액이 없다. 신용카드만 결제일까지 사용액을 든다.
        if (isCredit) ...[
          const SizedBox(height: PSpace.x20),
          Text(
            l.assetCurrentUsage,
            style: PTypo.caption.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _balanceCtrl,
            // 부호는 종류가 정한다 — 화면은 '얼마 썼나' 만 묻는다.
            numbersOnly: true,
            amountMax: kBalanceMax,
            placeholder: '0',
          ),
          const SizedBox(height: 6),
          Text(
            l.assetCurrentUsageHint,
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
        ],

        // 계좌 연결 — 신용카드는 결제일에 여기서 한 번에 빠지고,
        // 체크카드는 긁는 즉시 빠진다. 의미가 달라 라벨을 나눈다.
        const SizedBox(height: PSpace.x20),
        Text(
          isCredit ? l.assetPaymentAccountLabel : l.assetLinkedAccountLabel,
          style: PTypo.caption.copyWith(
            color: t.fgPrimary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: PSpace.x8),
        PSelect<int>(
          value: _paymentAssetRowId,
          placeholder: bankAccounts.isEmpty
              ? l.assetNoBankAccounts
              : (isCredit
                    ? l.assetPaymentAccountSelect
                    : l.assetLinkedAccountSelect),
          title: isCredit ? l.assetPaymentAccount : l.assetLinkedAccount,
          enabled: bankAccounts.isNotEmpty,
          items: [
            for (final a in bankAccounts)
              PSelectItem(
                value: a.rowId,
                label: a.institution != null && a.institution!.isNotEmpty
                    ? '${a.assetName} · ${a.institution}'
                    : a.assetName,
              ),
          ],
          onChanged: (v) => setState(() => _paymentAssetRowId = v),
        ),
        const SizedBox(height: 6),
        Text(
          isCredit ? l.assetPaymentAccountHint : l.assetLinkedAccountHint,
          style: PTypo.micro.copyWith(color: t.fgTertiary),
        ),

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
    final preview = nickname.isEmpty
        ? (selected?.cardName ?? l.assetNewCard)
        : nickname;
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
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
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
      child: Icon(
        LucideIcons.creditCard,
        size: 18,
        color: brand?.fg ?? tokens.fgPrimary,
      ),
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
            child: Text(
              l.assetCatalogLoadError,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l.assetNoSearchResults,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ),
            );
          }
          return Scrollbar(
            thumbVisibility: false,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) => PDivider(),
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
    // 연회비 정보가 아예 없으면(annualFee == null) 좁은 목록에서 생략한다.
    // 정보가 있으면 금액이든 "무료"든 보여준다 — 예전엔 amount>0 만 보여줘서
    // 0원 카드와 미수집 카드가 똑같이 빈칸이었다.
    final feePart = item.annualFee == null
        ? ''
        : ' · ${l.assetAnnualFee} ${cardFeeValue(l, item.annualFee, preferLabel: false)}';
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
                          errorBuilder: (_, _, _) => _RowPlaceholder(
                            brand: brand,
                            name: company ?? item.cardName,
                            tokens: t,
                          ),
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
                              color: active ? t.fgBrandStrong : t.fgPrimary,
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
                              horizontal: 6,
                              vertical: 1,
                            ),
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
