import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/brand/bank_colors.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/asset_providers.dart';

/// 계좌 추가 다이얼로그 — front `AssetAddDialog` 미러.
///
/// Wolt sheet 의 3 영역 활용:
/// - 상단 (sticky)  : `topBarTitle` + `trailingNavBarWidget`
/// - 본문 (scroll) : `child` — 미리보기 / 기관·브랜드 / 별칭 / 계좌 종류 / 계좌번호·잔액
/// - 하단 (sticky)  : `stickyActionBar` — 취소 / 추가
void showAccountAddDialog(BuildContext context, {String? presetType}) {
  final initialSub = switch (presetType) {
    'SAVINGS' => _SubType.savingsRecurring,
    'CASH' => _SubType.cash,
    'LOAN' => _SubType.loan,
    _ => _SubType.checking,
  };
  final bodyKey = GlobalKey<_AccountAddBodyState>();
  final submitting = ValueNotifier<bool>(false);
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) {
      final t = Theme.of(modalCtx).extension<PorestTokens>();
      return [
        WoltModalSheetPage(
          topBarTitle: const Text('계좌 추가'),
          isTopBarLayerAlwaysVisible: true,
          backgroundColor: t?.bgSurface,
          surfaceTintColor: t?.bgSurface,
          trailingNavBarWidget: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () {
              if (submitting.value) return;
              Navigator.of(modalCtx).pop();
            },
          ),
          child: _AccountAddBody(
            key: bodyKey,
            initialSubType: initialSub,
            submitting: submitting,
          ),
          stickyActionBar: _ActionBar(
            submitting: submitting,
            onCancel: () => Navigator.of(modalCtx).pop(),
            onSubmit: () => bodyKey.currentState?.submit(),
          ),
        ),
      ];
    },
  );
}

enum _SubType { checking, savingsRecurring, savingsTime, cash, loan }

extension _SubTypeX on _SubType {
  String get label => switch (this) {
        _SubType.checking => '입출금',
        _SubType.savingsRecurring => '적금',
        _SubType.savingsTime => '예금',
        _SubType.cash => '현금',
        _SubType.loan => '대출',
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
    super.key,
    required this.initialSubType,
    required this.submitting,
  });
  final _SubType initialSubType;
  final ValueNotifier<bool> submitting;

  @override
  ConsumerState<_AccountAddBody> createState() => _AccountAddBodyState();
}

class _AccountAddBodyState extends ConsumerState<_AccountAddBody> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _balanceCtrl;

  String _brand = bankEntries.first.name;
  late _SubType _subType;

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
    _subType = widget.initialSubType;
    _queryCtrl = TextEditingController()..addListener(_onQueryChanged);
    _nicknameCtrl = TextEditingController()..addListener(_onPreviewChanged);
    _accountNumberCtrl = TextEditingController();
    _balanceCtrl = TextEditingController(text: '0');
  }

  void _onQueryChanged() => setState(() {});
  void _onPreviewChanged() => setState(() {});

  @override
  void dispose() {
    _queryCtrl.dispose();
    _nicknameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  /// stickyActionBar 의 '추가' 에서 호출.
  Future<void> submit() async {
    if (widget.submitting.value) return;
    final brand = _brand;
    final nickname = _nicknameCtrl.text.trim();
    final name = nickname.isEmpty ? '$brand ${_subType.label}' : nickname;
    final balance = int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final accountNumber = _accountNumberCtrl.text.trim();

    widget.submitting.value = true;
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.create(
        assetName: name,
        assetType: _subType.assetType,
        balance: balance,
        currency: 'KRW',
        institution: brand,
        memo: accountNumber.isEmpty ? null : accountNumber,
      );
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계좌가 추가되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      widget.submitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      // 하단 stickyActionBar 높이만큼 여유 (action bar ≈ 56)
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x4, PSpace.x16, PSpace.x16 + 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewTile(
              entry: _selectedEntry, nickname: _nicknameCtrl.text.trim()),
          const SizedBox(height: PSpace.x20),

          // 기관·브랜드 ──────────────────────────
          Row(
            children: [
              Text('기관·브랜드',
                  style: PTypo.caption.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.medium)),
              const Spacer(),
              Text('총 $_accountEntriesCount개',
                  style: PTypo.micro.copyWith(color: t.fgTertiary)),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _queryCtrl,
            placeholder: '은행명 또는 증권사 검색',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: Icon(LucideIcons.search, size: 14, color: t.fgTertiary),
            ),
          ),
          const SizedBox(height: PSpace.x8),
          _BrandPicker(
            categories: _filteredByCategory,
            selectedName: _brand,
            onPick: (name) => setState(() => _brand = name),
          ),
          const SizedBox(height: PSpace.x20),

          // 별칭 ────────────────────────────────────
          Text('별칭',
              style: PTypo.caption.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.medium)),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _nicknameCtrl,
            placeholder: '예: 신한 주거래',
          ),
          const SizedBox(height: PSpace.x20),

          // 계좌 종류 ────────────────────────────────
          Text('계좌 종류',
              style: PTypo.caption.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.medium)),
          const SizedBox(height: PSpace.x8),
          _SubTypeRow(
            value: _subType,
            onChanged: (v) => setState(() => _subType = v),
          ),
          const SizedBox(height: PSpace.x20),

          // 계좌번호 / 잔액 ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('계좌번호',
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
                    Text('잔액 (원)',
                        style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.medium)),
                    const SizedBox(height: PSpace.x8),
                    PTextInput(
                      controller: _balanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true),
                      placeholder: '0',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    final letter = entry.name.isEmpty ? '?' : entry.name.characters.first;
    final preview = nickname.isEmpty ? '새 계좌' : nickname;
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
              Text('${entry.name} · 미리보기',
                  style: PTypo.caption.copyWith(color: t.fgTertiary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 카테고리별 브랜드 chip 그리드 — 자체 스크롤(maxHeight 220).
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
    return Container(
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderSubtle),
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: categories.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '검색 결과가 없어요',
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in categories) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        entry.key.label,
                        style: PTypo.micro.copyWith(
                          color: t.fgTertiary,
                          fontWeight: PFontWeight.semi,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in entry.value)
                            _BrandChip(
                              entry: e,
                              selected: e.name == selectedName,
                              onTap: () => onPick(e.name),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.entry,
    required this.selected,
    required this.onTap,
  });
  final BankEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // ⚠️ Container 에 alignment 를 주면 부모가 unbounded 일 때 width 를 다 차지.
    //    Wrap 안에서 chip 이 행 전체로 stretched 되는 걸 막기 위해 명시적으로
    //    Row(MainAxisSize.min) + Padding 으로 intrinsic 폭 강제.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? entry.color.bg : t.bgMuted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.name,
                style: PTypo.bodySm.copyWith(
                  color: selected ? entry.color.fg : t.fgSecondary,
                  fontWeight: PFontWeight.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5칸 segmented row — 입출금/적금/예금/현금/대출.
class _SubTypeRow extends StatelessWidget {
  const _SubTypeRow({required this.value, required this.onChanged});
  final _SubType value;
  final ValueChanged<_SubType> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          for (final s in _SubType.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s == value ? t.fgBrandStrong : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    s.label,
                    style: PTypo.bodySm.copyWith(
                      color: s == value ? t.fgOnBrand : t.fgSecondary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 하단 sticky 액션 바 — 취소 / 추가. `submitting` 노티파이어로 spinner 동기화.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });
  final ValueNotifier<bool> submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSurface,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: ValueListenableBuilder<bool>(
            valueListenable: submitting,
            builder: (_, busy, __) => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: t.fgSecondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child: Text('취소',
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: t.bgBrand,
                    foregroundColor: t.fgOnBrand,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                  ),
                  onPressed: busy ? null : onSubmit,
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('추가'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
