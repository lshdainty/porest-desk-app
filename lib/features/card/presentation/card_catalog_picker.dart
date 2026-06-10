import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';

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
            PSearchField(
              hint: '카드명 / 회사 검색',
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChange,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PChip(
                  variant: PChipVariant.subtle,
                  label: '전체',
                  selected: _type == null,
                  onTap: () => setState(() {
                    _type = null;
                    _rebuildKey();
                  }),
                ),
                const SizedBox(width: 6),
                PChip(
                  variant: PChipVariant.subtle,
                  label: '신용',
                  selected: _type == 'CREDIT',
                  onTap: () => setState(() {
                    _type = 'CREDIT';
                    _rebuildKey();
                  }),
                ),
                const SizedBox(width: 6),
                PChip(
                  variant: PChipVariant.subtle,
                  label: '체크',
                  selected: _type == 'CHECK',
                  onTap: () => setState(() {
                    _type = 'CHECK';
                    _rebuildKey();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            pageAsync.when(
                loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: PCircularProgressIndicator())),
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
                        PDivider(),
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
                              PBadge(
                                label: c.cardType == 'CREDIT' ? '신용' : '체크',
                                variant: c.cardType == 'CREDIT'
                                    ? PBadgeVariant.softBrand
                                    : PBadgeVariant.secondary,
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

