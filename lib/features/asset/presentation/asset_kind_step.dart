import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/select_box/p_select_box.dart';

/// 추가 1단계 "무엇을 추가할까요?"(I-17 6) — 종류 아홉이 한 묶음에서 하나만 골라진다.
///
/// 묶음 제목(계좌 · 카드 · 투자)은 그 아래 상자들의 이름이다. 상자는 세로형 2열(앱은 늘 2열)이고 컨트롤 없이 테두리만으로 고른 것을
/// 보인다. 상자를 누르는 것으로는 넘어가지 않는다(반영은 바닥 [다음]). 고르지 않고 [다음] 을 누르면 묶음 아래 오류 글이 서고 버튼은
/// 켜 둔다(DESIGN.desk "저장 버튼은 켜 두고 누르면 오류"). 묶음 제목 위는 첫 묶음 0 · 다음 묶음 16 이다(T13).
class AssetKindStep extends StatelessWidget {
  const AssetKindStep({
    super.key,
    required this.picked,
    required this.showError,
    required this.onPick,
    required this.onNext,
  });

  final AssetKind? picked;
  final bool showError;
  final ValueChanged<AssetKind> onPick;
  final VoidCallback onNext;

  String _groupTitle(AppLocalizations l, AssetKindGroup g) => switch (g) {
    AssetKindGroup.account => l.assetCatAccount,
    AssetKindGroup.card => l.assetGroupCard,
    AssetKindGroup.investment => l.assetGroupInvestment,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PBottomSheetContent(
      title: l.assetFormFirstTitle,
      closeLabel: l.actionClose,
      scrollFog: true,
      flushBody: true,
      body: PField(
        edgeInset: PSpacing.globalGutter,
        invalid: showError && picked == null,
        errorMessage: l.assetFormPickKindError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (group, kinds)) in assetKindGroups.indexed) ...[
              PListHeader(
                title: _groupTitle(l, group),
                headingLevel: 3,
                topInset: i == 0 ? 0 : PSpacing.x4,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PSpacing.globalGutter,
                ),
                child: PRadioSelectBoxGroup<AssetKind>(
                  value: picked,
                  onChanged: onPick,
                  columns: 2,
                  semanticLabel: _groupTitle(l, group),
                  children: [
                    for (final k in kinds)
                      PRadioSelectBox<AssetKind>(
                        value: k,
                        label: k.label(l),
                        prefix: Icon(k.icon),
                        control: PRadioSelectBoxControl.none,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      footer: [
        PButton(
          label: l.actionNext,
          size: PButtonSize.large,
          onPressed: onNext,
        ),
      ],
    );
  }
}
