import 'package:flutter/material.dart';
import 'package:porest_desk_app/core/format/currency.dart';
import 'package:flutter/services.dart';
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
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/include_in_total_card.dart';

/// 계좌 추가/편집 다이얼로그 — front `AssetAddDialog` / `AssetEditDialog` 미러.
///
/// add_tx_sheet 와 동일한 패턴:
/// - showModalBottomSheet + DraggableScrollableSheet
/// - 본문 내부 row 헤더 (drag handle + 타이틀 + X) — border line 없음
/// - 본문은 ListView 로 스크롤, 액션 버튼도 본문 하단에 함께 들어가서 키보드 안 가림
void showAccountAddDialog(BuildContext context, {String? presetType}) {
  final initialSub = switch (presetType) {
    'SAVINGS' => _SubType.savingsRecurring,
    'CASH' => _SubType.cash,
    'LOAN' => _SubType.loan,
    _ => _SubType.checking,
  };
  _open(context, edit: null, initialSubType: initialSub);
}

/// 계좌 편집 — 기존 자산을 받아서 동일 폼 재사용.
void showAccountEditDialog(BuildContext context, Asset asset) {
  _open(
    context,
    edit: asset,
    initialSubType: _subTypeFromAssetType(asset.assetType),
  );
}

void _open(
  BuildContext context, {
  required Asset? edit,
  required _SubType initialSubType,
}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.assetAccountAdd : l.assetAccountEdit,
    contentBuilder: (ctx, scrollCtrl) => _AccountAddBody(
      edit: edit,
      initialSubType: initialSubType,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit != null ? l.actionSave : l.calAdd,
    ),
  ).whenComplete(controller.dispose);
}

_SubType _subTypeFromAssetType(String t) => switch (t) {
      'SAVINGS' => _SubType.savingsRecurring,
      'CASH' => _SubType.cash,
      'LOAN' => _SubType.loan,
      _ => _SubType.checking,
    };

enum _SubType { checking, savingsRecurring, savingsTime, cash, loan }

extension _SubTypeX on _SubType {
  String label(AppLocalizations l) => switch (this) {
        _SubType.checking => l.assetTypeBankAccount,
        _SubType.savingsRecurring => l.assetSubtypeInstallment,
        _SubType.savingsTime => l.assetSubtypeDeposit,
        _SubType.cash => l.assetTypeCash,
        _SubType.loan => l.assetTypeLoan,
      };

  /// 백엔드 assetType 매핑 — front 와 동일.
  String get assetType => switch (this) {
        _SubType.checking => 'BANK_ACCOUNT',
        _SubType.savingsRecurring => 'SAVINGS',
        _SubType.savingsTime => 'SAVINGS',
        _SubType.cash => 'CASH',
        _SubType.loan => 'LOAN',
      };
}

class _AccountAddBody extends ConsumerStatefulWidget {
  const _AccountAddBody({
    required this.edit,
    required this.initialSubType,
    required this.scrollController,
    required this.controller,
  });
  final Asset? edit;
  final _SubType initialSubType;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_AccountAddBody> createState() => _AccountAddBodyState();
}

class _AccountAddBodyState extends ConsumerState<_AccountAddBody> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _fxRateCtrl;

  late String _currency;
  late String _brand;
  late _SubType _subType;
  late bool _includeInTotal;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  /// 이 폼이 다루는 자산 유형 — `_SubType` 이 매핑하는 것과 같다.
  static const _accountTypes = {'BANK_ACCOUNT', 'SAVINGS', 'CASH', 'LOAN'};

  /// 계좌 추가에 노출할 카테고리 — 증권사·가상자산 제외.
  List<MapEntry<BankCategory, List<BankEntry>>> get _filteredByCategory {
    final q = _norm(_queryCtrl.text.trim());
    final result = <MapEntry<BankCategory, List<BankEntry>>>[];
    for (final cat in bankCategoryOrder) {
      if (investCategories.contains(cat)) continue;
      final list = (bankEntriesByCategory[cat] ?? const <BankEntry>[])
          .where((e) => _matchesQuery(e, q))
          .toList(growable: false);
      if (list.isEmpty) continue;
      result.add(MapEntry(cat, list));
    }
    return result;
  }

  /// 1400.000000 을 1400 으로 — 서버가 소수 6자리로 주는 값을 그대로 보여 주면 지저분하다.
  static String _trimRate(double rate) {
    final s = rate.toStringAsFixed(6);
    return s.contains('.')
        ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : s;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  static bool _matchesQuery(BankEntry e, String needle) {
    if (needle.isEmpty) return true;
    if (_norm(e.name).contains(needle)) return true;
    return e.aliases.any((a) => _norm(a).contains(needle));
  }

  int get _accountEntriesCount => bankEntries
      .where((e) => !investCategories.contains(e.category))
      .length;

  BankEntry get _selectedEntry => bankEntries.firstWhere(
      (e) => e.name == _brand,
      orElse: () => bankEntries.first);

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _subType = widget.initialSubType;
    // 편집 모드: institution 으로 brand 추론, 없으면 첫 항목.
    _brand = e?.institution != null && e!.institution!.isNotEmpty
        ? bankEntries.firstWhere(
            (b) =>
                b.name == e.institution ||
                b.aliases.contains(e.institution),
            orElse: () => bankEntries.first,
          ).name
        : bankEntries.first.name;
    _queryCtrl = TextEditingController()..addListener(_onQueryChanged);
    _nicknameCtrl = TextEditingController(text: e?.assetName ?? '')
      ..addListener(_onPreviewChanged);
    _accountNumberCtrl = TextEditingController();
    _balanceCtrl =
        TextEditingController(text: (e?.balance ?? 0).toString());
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    _currency = e?.currency ?? kDefaultCurrency;
    _fxRateCtrl = TextEditingController(
        text: e?.exchangeRate != null ? _trimRate(e!.exchangeRate!) : '');
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    widget.controller.onSubmit = _submit;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.controller.setCanSubmit(true));
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  void _onQueryChanged() => setState(() {});
  void _onPreviewChanged() => setState(() {});

  @override
  void dispose() {
    _queryCtrl.dispose();
    _nicknameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _balanceCtrl.dispose();
    _fxRateCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final brand = _brand;
    final nickname = _nicknameCtrl.text.trim();
    final name = nickname.isEmpty ? '$brand ${_subType.label(l)}' : nickname;
    final balance = int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0;
    // 환율은 외화일 때만 보낸다. 비우면 서버가 1로 잡아 환산 없이 더해진다.
    final fxRate = isForeignCurrency(_currency)
        ? double.tryParse(_fxRateCtrl.text.replaceAll(',', ''))
        : null;
    final accountNumber = _accountNumberCtrl.text.trim();
    final memo = _memoCtrl.text.trim();
    // 신규: 계좌번호를 memo 로 저장. 편집: 사용자가 입력한 메모를 우선,
    // 비었고 계좌번호가 채워졌으면 그걸 사용.
    final memoForApi = _isEdit
        ? (memo.isEmpty ? (accountNumber.isEmpty ? null : accountNumber) : memo)
        : (accountNumber.isEmpty ? null : accountNumber);
    // 계좌 그룹 밖 자산(카드·투자)이 흘러들어오면 원본 유형을 유지한다 —
    // `_subTypeFromAssetType` 이 모르는 유형을 입출금으로 떨어뜨리므로,
    // 저장하며 조용히 BANK_ACCOUNT 로 바뀌는 사고를 막는다.
    final original = widget.edit?.assetType;
    final assetType = original != null && !_accountTypes.contains(original)
        ? original
        : _subType.assetType;

    _setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          assetName: name,
          assetType: assetType,
          balance: balance,
          currency: _currency,
          exchangeRate: fxRate,
          institution: brand,
          memo: memoForApi,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
        );
      } else {
        await repo.create(
          assetName: name,
          assetType: assetType,
          balance: balance,
          currency: _currency,
          exchangeRate: fxRate,
          institution: brand,
          memo: memoForApi,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
        );
      }
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
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
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
                _PreviewTile(
                    entry: _selectedEntry,
                    nickname: _nicknameCtrl.text.trim()),
                const SizedBox(height: PSpace.x20),

                // 기관·브랜드 ────────────────────────
                Row(
                  children: [
                    Text(l.assetInstitutionBrand,
                        style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.medium)),
                    const Spacer(),
                    Text(l.assetTotalEntries(_accountEntriesCount),
                        style: PTypo.micro.copyWith(color: t.fgTertiary)),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                PSearchField(
                  hint: l.assetBankSearchHint,
                  controller: _queryCtrl,
                ),
                const SizedBox(height: PSpace.x8),
                _BrandPicker(
                  categories: _filteredByCategory,
                  selectedName: _brand,
                  onPick: (name) => setState(() => _brand = name),
                ),
                const SizedBox(height: PSpace.x20),

                // 별칭 ────────────────────────────────
                Text(l.assetNickname,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _nicknameCtrl,
                  placeholder: l.assetNicknamePlaceholder,
                ),
                const SizedBox(height: PSpace.x20),

                // 계좌 종류 ──────────────────────────
                Text(l.assetAccountType,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTabs<_SubType>(
                  items: [
                    for (final s in _SubType.values)
                      PTabItem(value: s, label: s.label(l)),
                  ],
                  value: _subType,
                  onChanged: (v) => setState(() => _subType = v),
                  variant: PTabsVariant.container,
                  size: PTabsSize.sm,
                  expand: true,
                ),
                const SizedBox(height: PSpace.x20),

                // 계좌번호 / 잔액 ─────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.assetAccountNumber,
                              style: PTypo.caption.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.medium)),
                          const SizedBox(height: PSpace.x8),
                          PTextInput(
                            controller: _accountNumberCtrl,
                            placeholder: '110-***-123456',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: PSpace.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.assetBalanceLabel,
                              style: PTypo.caption.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.medium)),
                          const SizedBox(height: PSpace.x8),
                          PTextInput(
                            controller: _balanceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    signed: true),
                            placeholder: '0',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 통화·환율 — 외화통장. 통화는 자산 유형과 무관하게 연다(해외 카드·외화 대출).
                const SizedBox(height: PSpace.x20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.assetCurrency,
                              style: PTypo.caption.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.medium)),
                          const SizedBox(height: PSpace.x8),
                          PSelect<String>(
                            value: _currency,
                            items: [
                              for (final c in kCurrencies)
                                PSelectItem(
                                    value: c.code,
                                    label: '${c.symbol} ${c.code}'),
                            ],
                            onChanged: (v) =>
                                setState(() => _currency = v ?? kDefaultCurrency),
                          ),
                        ],
                      ),
                    ),
                    if (isForeignCurrency(_currency)) ...[
                      const SizedBox(width: PSpace.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.assetExchangeRate,
                                style: PTypo.caption.copyWith(
                                    color: t.fgPrimary,
                                    fontWeight: PFontWeight.medium)),
                            const SizedBox(height: PSpace.x8),
                            PTextInput(
                              controller: _fxRateCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              placeholder: l.assetExchangeRateHint(_currency),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (isForeignCurrency(_currency)) ...[
                  const SizedBox(height: PSpace.x8),
                  Text(l.assetExchangeRateDesc,
                      style: PTypo.micro.copyWith(color: t.fgTertiary)),
                ],

                // 메모 — 편집 모드에서만 노출 (web 동일).
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

/// 미리보기 타일 — 브랜드 컬러 박스 + 별칭/브랜드.
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.entry, required this.nickname});
  final BankEntry entry;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final letter = entry.name.isEmpty ? '?' : entry.name.characters.first;
    final preview = nickname.isEmpty ? l.assetNewAccount : nickname;
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

/// 카테고리별 브랜드 chip 그리드 — web 동일 maxHeight 220 + 내부 자체 스크롤.
/// 박스 자체는 width 풀, 부모 ListView 와 별개로 자기 영역 안에서 스크롤.
class _BrandPicker extends StatelessWidget {
  const _BrandPicker({
    required this.categories,
    required this.selectedName,
    required this.onPick,
  });
  final List<MapEntry<BankCategory, List<BankEntry>>> categories;
  final String selectedName;
  final ValueChanged<String> onPick;

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
      constraints: const BoxConstraints(maxHeight: 220),
      // ClipRRect 없이 SingleChildScrollView 만 쓰면 박스 모서리 안쪽에서
      // 콘텐츠가 살짝 비져나와 보일 수 있어 radius clip 적용.
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
                    categories[i].key.label,
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

// _balanceFormatters: 향후 천단위 콤마 자동 포매팅 시 참조용 placeholder.
// 현재는 numberWithOptions(signed: true) 로 충분.
// ignore: unused_element
const _balanceFormatters = <TextInputFormatter>[];
