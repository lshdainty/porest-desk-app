import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/picker_sheet.dart';
import 'package:groo_damda_app/shared/brand/bank_colors.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/p_searchable_list.dart';
import 'package:groo_damda_app/shared/forms/search_match.dart';

/// 분류 이름 — enum 의 한글 label 은 데이터 원문이고, 화면은 로케일을 따른다(영어 사용자에게 '시중은행' 이 그대로 나오면 안 된다).
String bankCategoryLabel(AppLocalizations l, BankCategory c) => switch (c) {
  BankCategory.retailBank => l.assetCategoryCommercialBank,
  BankCategory.internetBank => l.assetCategoryInternetBank,
  BankCategory.regionalBank => l.assetCategoryLocalBank,
  BankCategory.specialBank => l.assetCategorySpecialBank,
  BankCategory.savingsInstitution => l.assetCategorySavingsInstitution,
  BankCategory.foreignBank => l.assetCategoryForeignBank,
  BankCategory.other => l.assetCategoryOther,
  BankCategory.brokerage => l.assetCategoryBrokerage,
  BankCategory.commodityExchange => l.assetCategoryCommodityExchange,
  BankCategory.cryptoExchange => l.assetCategoryCryptoExchange,
};

/// 계좌 쪽 기관 — 증권사 · 거래소를 뺀 것. 투자 쪽 기관은 그 셋뿐이다.
List<BankEntry> institutionEntries({required bool invest}) => [
  for (final e in bankEntries)
    if (investCategories.contains(e.category) == invest) e,
];

/// 기관 고르기(I-17 18) — 칸의 Input Button 이 여는 검색 시트. 분류 머리 + 줄(Logo Tile 40 + 오른쪽 라디오). 고르면 닫힌다.
///
/// [invest] 면 증권사 · 상품거래소 · 가상자산거래소, 아니면 은행류. 돌려주는 값은 기관 이름이다(취소하면 null).
Future<String?> showInstitutionPicker(
  BuildContext context, {
  required bool invest,
  required String? current,
}) {
  final focus = FocusNode(debugLabel: 'institution search');
  return PBottomSheet.show<String>(
    context,
    initialFocus: focus,
    builder: (_) =>
        _InstitutionSheet(invest: invest, current: current, searchFocus: focus),
  ).whenComplete(focus.dispose);
}

class _InstitutionSheet extends StatefulWidget {
  const _InstitutionSheet({
    required this.invest,
    required this.current,
    required this.searchFocus,
  });

  final bool invest;
  final String? current;
  final FocusNode searchFocus;

  @override
  State<_InstitutionSheet> createState() => _InstitutionSheetState();
}

class _InstitutionSheetState extends State<_InstitutionSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = institutionEntries(invest: widget.invest);
    // 분류 차례는 지금 그대로 — 걸러져 줄이 없는 분류는 머리째 숨는다
    final groups = [
      for (final cat in bankCategoryOrder)
        (
          category: cat,
          entries: [
            for (final e in all)
              if (e.category == cat &&
                  matchesSearch(e.name, _query, aliases: e.aliases))
                e,
          ],
        ),
    ].where((g) => g.entries.isNotEmpty).toList();
    return PBottomSheetContent(
      title: widget.invest
          ? l.assetPickBrokerTitle
          : l.assetPickInstitutionTitle,
      closeLabel: l.actionClose,
      // 줄 · 검색칸이 제 좌우 24 를 갖는다
      flushBody: true,
      body: SizedBox(
        height: pickerBodyHeight(context),
        child: PSearchableList(
          focusNode: widget.searchFocus,
          defaultValue: widget.current,
          onValueChanged: (v) => PBottomSheet.of(context).close(v),
          onQueryChanged: (q) => setState(() => _query = q),
          children: [
            PSearchableListInput(
              placeholder: widget.invest
                  ? l.assetInvestSearchHint
                  : l.assetBankSearchHint,
              semanticLabel: l.actionSearch,
            ),
            if (groups.isEmpty)
              PSearchableListEmpty(titleBuilder: (q) => l.assetSearchEmpty(q))
            else
              PSearchableListResults(
                semanticLabel: widget.invest
                    ? l.assetBrokerExchange
                    : l.assetInstitutionBrand,
                children: [
                  for (final g in groups)
                    PSearchableListGroup(
                      label: bankCategoryLabel(l, g.category),
                      children: [
                        for (final e in g.entries)
                          PSearchableListItem(
                            value: e.name,
                            title: e.name,
                            prefix: PLogoTile(name: e.name),
                          ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
