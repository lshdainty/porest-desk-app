import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/card_providers.dart';
import '../domain/card_catalog.dart';

/// 카드 카탈로그 검색 picker — front `CardCatalogCombobox` 미러.
///
/// [showCardCatalogPicker] 호출 시 검색 BottomSheet 가 열리고,
/// 사용자가 선택한 [CardCatalogSummary] 를 반환한다 (취소 시 null).
Future<CardCatalogSummary?> showCardCatalogPicker(
  BuildContext context, {
  String? cardType, // CREDIT/CHECK
}) {
  return showPSheet<CardCatalogSummary>(
    context,
    title: '카드 선택',
    contentBuilder: (ctx, scrollCtrl) => _CardPickerSheet(
      initialType: cardType,
      scrollController: scrollCtrl,
    ),
  );
}

class _CardPickerSheet extends ConsumerStatefulWidget {
  const _CardPickerSheet({this.initialType, required this.scrollController});
  final String? initialType;
  final ScrollController scrollController;
  @override
  ConsumerState<_CardPickerSheet> createState() => _CardPickerSheetState();
}

class _CardPickerSheetState extends ConsumerState<_CardPickerSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  late String? _type = widget.initialType;
  late CardSearchKey _key = defaultCardSearchKey(
    cardType: widget.initialType,
    size: 30,
  );

  void _rebuildKey() {
    _key = defaultCardSearchKey(
      keyword: _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
      cardType: _type,
      size: 30,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChange(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(_rebuildKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pageAsync = ref.watch(cardCatalogPageProvider(_key));
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
            PTextInput(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChange,
              placeholder: '카드명 / 회사 검색',
              prefix:
                  Icon(LucideIcons.search, size: 16, color: t.fgTertiary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(
                  label: '전체',
                  selected: _type == null,
                  onTap: () => setState(() {
                    _type = null;
                    _rebuildKey();
                  }),
                  tokens: t,
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: '신용',
                  selected: _type == 'CREDIT',
                  onTap: () => setState(() {
                    _type = 'CREDIT';
                    _rebuildKey();
                  }),
                  tokens: t,
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: '체크',
                  selected: _type == 'CHECK',
                  onTap: () => setState(() {
                    _type = 'CHECK';
                    _rebuildKey();
                  }),
                  tokens: t,
                ),
              ],
            ),
            const SizedBox(height: 8),
            pageAsync.when(
                loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('카드 검색 실패: $e',
                      style: PTypo.caption.copyWith(color: t.statusDanger)),
                ),
                data: (page) {
                  if (page.content.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('일치하는 카드가 없습니다',
                            style: PTypo.caption
                                .copyWith(color: t.fgTertiary)),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: page.content.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: t.borderSubtle),
                    itemBuilder: (_, i) {
                      final c = page.content[i];
                      return InkWell(
                        onTap: () => Navigator.pop(context, c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: t.bgMuted,
                                  borderRadius: PRadius.brSm,
                                ),
                                alignment: Alignment.center,
                                child: Icon(LucideIcons.creditCard,
                                    size: 16, color: t.fgSecondary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.cardName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: PTypo.bodySm.copyWith(
                                            color: t.fgPrimary,
                                            fontWeight: PFontWeight.semi)),
                                    if (c.company?.name != null)
                                      Text(c.company!.name!,
                                          style: PTypo.caption.copyWith(
                                              color: t.fgTertiary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.cardType == 'CREDIT'
                                      ? t.bgBrandSubtle
                                      : t.bgMuted,
                                  borderRadius: PRadius.brXs,
                                ),
                                child: Text(
                                    c.cardType == 'CREDIT' ? '신용' : '체크',
                                    style: PTypo.micro.copyWith(
                                        color: c.cardType == 'CREDIT'
                                            ? t.fgBrand
                                            : t.fgSecondary,
                                        fontWeight: PFontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.tokens});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgMuted,
          borderRadius: PRadius.brFull,
          border: Border.all(
              color: selected ? tokens.borderBrand : tokens.borderSubtle),
        ),
        child: Text(label,
            style: PTypo.caption.copyWith(
                color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                fontWeight: selected ? PFontWeight.bold : PFontWeight.medium)),
      ),
    );
  }
}
