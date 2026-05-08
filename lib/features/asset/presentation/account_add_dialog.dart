import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/brand/bank_colors.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';

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
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).extension<PorestTokens>()?.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PRadius.xl2)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => _AccountAddBody(
        edit: edit,
        initialSubType: initialSubType,
        scrollController: scrollCtrl,
      ),
    ),
  );
}

_SubType _subTypeFromAssetType(String t) => switch (t) {
      'SAVINGS' => _SubType.savingsRecurring,
      'CASH' => _SubType.cash,
      'LOAN' => _SubType.loan,
      _ => _SubType.checking,
    };

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
    required this.edit,
    required this.initialSubType,
    required this.scrollController,
  });
  final Asset? edit;
  final _SubType initialSubType;
  final ScrollController scrollController;

  @override
  ConsumerState<_AccountAddBody> createState() => _AccountAddBodyState();
}

class _AccountAddBodyState extends ConsumerState<_AccountAddBody> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _memoCtrl;

  late String _brand;
  late _SubType _subType;
  bool _submitting = false;
  bool _deleting = false;

  bool get _isEdit => widget.edit != null;

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
  }

  void _onQueryChanged() => setState(() {});
  void _onPreviewChanged() => setState(() {});

  @override
  void dispose() {
    _queryCtrl.dispose();
    _nicknameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _balanceCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final brand = _brand;
    final nickname = _nicknameCtrl.text.trim();
    final name = nickname.isEmpty ? '$brand ${_subType.label}' : nickname;
    final balance = int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final accountNumber = _accountNumberCtrl.text.trim();
    final memo = _memoCtrl.text.trim();
    // 신규: 계좌번호를 memo 로 저장. 편집: 사용자가 입력한 메모를 우선,
    // 비었고 계좌번호가 채워졌으면 그걸 사용.
    final memoForApi = _isEdit
        ? (memo.isEmpty ? (accountNumber.isEmpty ? null : accountNumber) : memo)
        : (accountNumber.isEmpty ? null : accountNumber);

    setState(() => _submitting = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          assetName: name,
          assetType: _subType.assetType,
          balance: balance,
          currency: 'KRW',
          institution: brand,
          memo: memoForApi,
        );
      } else {
        await repo.create(
          assetName: name,
          assetType: _subType.assetType,
          balance: balance,
          currency: 'KRW',
          institution: brand,
          memo: memoForApi,
        );
      }
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEdit ? '계좌가 수정되었습니다' : '계좌가 추가되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    if (_deleting || widget.edit == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계좌 삭제'),
        content: const Text('이 계좌를 삭제하시겠습니까? 연결된 거래는 유지됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.tokens.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계좌가 삭제되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Drag handle ─────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.borderDefault,
              borderRadius: PRadius.brXs2,
            ),
          ),
          // Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, PSpace.x12, PSpace.x8, PSpace.x4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? '계좌 편집' : '계좌 추가',
                    style: PTypo.h3.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.heavy,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: t.fgTertiary, size: 20),
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Content (scrollable, 액션 버튼 포함) ──────
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, 0, PSpace.x16, PSpace.x16),
              children: [
                _PreviewTile(
                    entry: _selectedEntry,
                    nickname: _nicknameCtrl.text.trim()),
                const SizedBox(height: PSpace.x20),

                // 기관·브랜드 ────────────────────────
                Row(
                  children: [
                    Text('기관·브랜드',
                        style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.medium)),
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
                    child: Icon(LucideIcons.search,
                        size: 14, color: t.fgTertiary),
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                _BrandPicker(
                  categories: _filteredByCategory,
                  selectedName: _brand,
                  onPick: (name) => setState(() => _brand = name),
                ),
                const SizedBox(height: PSpace.x20),

                // 별칭 ────────────────────────────────
                Text('별칭',
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _nicknameCtrl,
                  placeholder: '예: 신한 주거래',
                ),
                const SizedBox(height: PSpace.x20),

                // 계좌 종류 ──────────────────────────
                Text('계좌 종류',
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                _SubTypeRow(
                  value: _subType,
                  onChanged: (v) => setState(() => _subType = v),
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
                          Text(_isEdit ? '잔액 (원)' : '잔액 (원)',
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

                // 메모 — 편집 모드에서만 노출 (web 동일).
                if (_isEdit) ...[
                  const SizedBox(height: PSpace.x20),
                  Text('메모 (선택)',
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.medium)),
                  const SizedBox(height: PSpace.x8),
                  PTextInput(
                    controller: _memoCtrl,
                    placeholder: '계좌번호 뒷자리, 결제일, 한도 등 메모하세요',
                  ),
                ],

                const SizedBox(height: PSpace.x24),

                // 액션 ──────────────────────────────
                Row(
                  children: [
                    if (_isEdit) ...[
                      TextButton.icon(
                        onPressed:
                            (_submitting || _deleting) ? null : _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: t.statusDangerFg,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        icon: _deleting
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.statusDangerFg))
                            : const Icon(LucideIcons.trash2, size: 14),
                        label: Text('삭제',
                            style: PTypo.bodySm
                                .copyWith(color: t.statusDangerFg)),
                      ),
                    ],
                    const Spacer(),
                    TextButton(
                      onPressed: (_submitting || _deleting)
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: t.fgSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: Text('취소',
                          style: PTypo.bodySm
                              .copyWith(color: t.fgSecondary)),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: t.bgBrand,
                        foregroundColor: t.fgOnBrand,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                      ),
                      onPressed:
                          (_submitting || _deleting) ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit ? '저장' : '추가'),
                    ),
                  ],
                ),
              ],
            ),
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
            '검색 결과가 없어요',
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
                      _BrandChip(
                        entry: e,
                        selected: e.name == selectedName,
                        onTap: () => onPick(e.name),
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
    // ⚠️ Container 에 alignment 를 주면 부모(Wrap)가 unbounded 일 때
    //    width 를 다 차지 → chip 이 행 전체로 stretched. Material+InkWell
    //    + Padding + Row(MainAxisSize.min) 으로 intrinsic 폭 강제.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

// _balanceFormatters: 향후 천단위 콤마 자동 포매팅 시 참조용 placeholder.
// 현재는 numberWithOptions(signed: true) 로 충분.
// ignore: unused_element
const _balanceFormatters = <TextInputFormatter>[];
