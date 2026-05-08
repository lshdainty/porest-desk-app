import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/brand/bank_colors.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../card/application/card_providers.dart';
import '../../card/domain/card_catalog.dart';
import '../application/asset_providers.dart';

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
      builder: (_, scrollCtrl) => _CardAddBody(scrollController: scrollCtrl),
    ),
  );
}

enum _CardType { credit, check }

extension on _CardType {
  String get label => switch (this) {
        _CardType.credit => '신용카드',
        _CardType.check => '체크카드',
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
  const _CardAddBody({required this.scrollController});
  final ScrollController scrollController;
  @override
  ConsumerState<_CardAddBody> createState() => _CardAddBodyState();
}

class _CardAddBodyState extends ConsumerState<_CardAddBody> {
  late final TextEditingController _keywordCtrl;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _balanceCtrl;

  _CardType _cardType = _CardType.credit;
  bool _includeDiscontinued = false;
  CardCatalogSummary? _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _keywordCtrl = TextEditingController()..addListener(_onChanged);
    _nicknameCtrl = TextEditingController()..addListener(_onChanged);
    _balanceCtrl = TextEditingController(text: '0');
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _nicknameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _selected == null) return;
    final selected = _selected!;
    final nickname = _nicknameCtrl.text.trim();
    final name = nickname.isEmpty ? selected.cardName : nickname;
    final outstanding =
        int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final company = selected.company?.name;

    setState(() => _submitting = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.create(
        assetName: name,
        assetType: _cardType.assetType,
        balance: outstanding,
        currency: 'KRW',
        institution: company,
        cardCatalogRowId: selected.rowId,
      );
      // brand color hex 는 모바일 측에선 별도 파싱이라 institution 으로 추후 매칭.
      // (web 의 color 필드는 같은 효과를 내는 보조 정보)
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카드가 추가되었습니다')),
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
    final canSubmit = _selected != null && !_submitting;

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
                    '카드 추가',
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
          Expanded(
            child: ListView(
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
                Text('카드 종류',
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                _CardTypeRow(
                  value: _cardType,
                  onChanged: (v) => setState(() {
                    _cardType = v;
                    _selected = null; // 종류 바뀌면 선택 초기화
                  }),
                ),
                const SizedBox(height: PSpace.x20),

                // 카드 상품 ──────────────────────────
                Row(
                  children: [
                    Text('카드 상품',
                        style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.medium)),
                    const Spacer(),
                    Text('단종 포함',
                        style: PTypo.micro.copyWith(color: t.fgTertiary)),
                    const SizedBox(width: 6),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _includeDiscontinued,
                        onChanged: (v) =>
                            setState(() => _includeDiscontinued = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (pageAsync.value != null)
                      Text(
                        '총 ${pageAsync.value!.totalElements}건',
                        style: PTypo.micro.copyWith(color: t.fgTertiary),
                      ),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _keywordCtrl,
                  placeholder: '카드명 또는 발급사 검색',
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(LucideIcons.search,
                        size: 14, color: t.fgTertiary),
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                _CatalogList(
                  async: pageAsync.whenData((p) => p.content),
                  selectedId: _selected?.rowId,
                  onPick: (c) => setState(() => _selected = c),
                ),
                const SizedBox(height: PSpace.x20),

                // 별칭 (선택) ────────────────────────
                Text('별칭 (선택)',
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: _nicknameCtrl,
                  placeholder:
                      _selected?.cardName ?? '예: 신한 Deep Dream',
                ),
                const SizedBox(height: PSpace.x20),

                // 현재 사용액 (원) ───────────────────
                Text('현재 사용액 (원)',
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
                Text('청구될 금액을 입력하세요. 총 부채에 반영됩니다.',
                    style: PTypo.micro.copyWith(color: t.fgTertiary)),

                const SizedBox(height: PSpace.x24),

                // 액션 ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting
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
                        disabledBackgroundColor: t.bgDisabled,
                        disabledForegroundColor: t.fgTertiary,
                      ),
                      onPressed: canSubmit ? _submit : null,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_selected == null ? '카드 선택 필요' : '추가'),
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
    final company = selected?.company?.name;
    final brand = company != null ? getBrandColor([company]) : null;
    final preview =
        nickname.isEmpty ? (selected?.cardName ?? '새 카드') : nickname;
    final subtitle = [
      if (company != null && company.isNotEmpty) company,
      cardType.label,
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
                    errorBuilder: (_, __, ___) =>
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

/// 2칸 segmented row — 신용카드 / 체크카드.
class _CardTypeRow extends StatelessWidget {
  const _CardTypeRow({required this.value, required this.onChanged});
  final _CardType value;
  final ValueChanged<_CardType> onChanged;

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
          for (final c in _CardType.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c == value ? t.fgBrandStrong : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    c.label,
                    style: PTypo.bodySm.copyWith(
                      color: c == value ? t.fgOnBrand : t.fgSecondary,
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
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('카탈로그 로드 실패',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('검색 결과가 없어요',
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ),
            );
          }
          return Scrollbar(
            thumbVisibility: false,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: t.borderSubtle),
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
    final company = item.company?.name;
    final brand = company != null ? getBrandColor([company]) : null;
    final fee = item.annualFee?.amount ?? 0;
    final feePart = fee > 0 ? ' · 연회비 ${_fmtKrw(fee)}원' : '';
    final subtitle =
        '${company ?? '—'} · ${item.cardType == 'CREDIT' ? '신용' : '체크'}$feePart';

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
                  borderRadius: BorderRadius.circular(4),
                  child: item.imgUrl != null && item.imgUrl!.isNotEmpty
                      ? Image.network(
                          item.imgUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
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
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '단종',
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
