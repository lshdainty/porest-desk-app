import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/account_add_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_parts.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind_step.dart';
import 'package:groo_damda_app/features/asset/presentation/card_add_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/investment_add_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';

/// 자산 추가 · 수정 폼의 표면을 여는 곳(I-17 A 4 · B 5 ~ 8) — 세 폼(계좌 · 카드 · 투자)이 한 시트 안에서 단계만 바꾼다.
///
/// 추가는 1단계(종류 고르기) → [다음] → 같은 시트의 2단계(그 종류의 칸) → [추가]. 수정은 2단계로 바로 열린다. 시트는 입력 폼이라
/// 바깥 누르기 · 끌어내리기로 닫히지 않고, 바뀐 값이 있는 채 닫으면 "작성한 내용이 사라져요" 를 묻는다.
/// 몸(`AccountAddBody` · `CardAddBody` · `InvestmentAddBody`)은 각 폼 파일이 갖는다 — 이 파일은 표면과 단계만 안다.

/// 추가 — 1단계(종류 고르기)부터. 관리 화면의 [추가] 가 연다.
Future<void> showAssetAddFlow(BuildContext context) =>
    showAssetFormFlow(context);

/// 수정 — 종류는 자산에서 재서 2단계로 바로 연다.
Future<void> showAssetEditForm(BuildContext context, Asset asset) =>
    showAssetFormFlow(context, edit: asset);

/// 그 종류의 2단계를 바로 여는 추가 — 1단계를 건너뛴다(옛 진입 함수 셋이 이 길을 쓴다).
Future<void> showAssetKindForm(BuildContext context, AssetKind kind) =>
    showAssetFormFlow(context, kind: kind);

/// 옛 진입 함수 — 계좌 추가(`presetType` 은 서버 유형 코드). 예금 · 적금은 SAVINGS 라 지금처럼 "적금" 으로 연다.
Future<void> showAccountAddDialog(BuildContext context, {String? presetType}) =>
    showAssetKindForm(context, switch (presetType) {
      'SAVINGS' => AssetKind.installment,
      'CASH' => AssetKind.cash,
      'LOAN' => AssetKind.loan,
      _ => AssetKind.checking,
    });

Future<void> showAccountEditDialog(BuildContext context, Asset asset) =>
    showAssetEditForm(context, asset);

Future<void> showCardAddDialog(BuildContext context) =>
    showAssetKindForm(context, AssetKind.credit);

Future<void> showCardEditDialog(BuildContext context, Asset asset) =>
    showAssetEditForm(context, asset);

Future<void> showInvestmentAddDialog(BuildContext context) =>
    showAssetKindForm(context, AssetKind.investment);

Future<void> showInvestmentEditDialog(BuildContext context, Asset asset) =>
    showAssetEditForm(context, asset);

/// 시트를 띄운다. [edit] 가 있으면 수정(2단계), [kind] 가 있으면 그 종류의 2단계, 둘 다 없으면 1단계.
Future<void> showAssetFormFlow(
  BuildContext context, {
  Asset? edit,
  AssetKind? kind,
}) {
  final l = AppLocalizations.of(context);
  final probe = AssetFormProbe();
  return PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => AssetFormFlow(probe: probe, edit: edit, initialKind: kind),
  );
}

/// 시트 안 단계 — 1단계(종류) ↔ 2단계(칸). 시트를 새로 띄우지 않고 같은 표면의 본문만 바꾼다.
class AssetFormFlow extends StatefulWidget {
  const AssetFormFlow({
    super.key,
    required this.probe,
    this.edit,
    this.initialKind,
  });

  final AssetFormProbe probe;
  final Asset? edit;
  final AssetKind? initialKind;

  @override
  State<AssetFormFlow> createState() => _AssetFormFlowState();
}

class _AssetFormFlowState extends State<AssetFormFlow> {
  /// 2단계의 종류 — null 이면 1단계.
  AssetKind? _kind;

  /// 1단계에서 고른 종류 — 2단계에서 ← 로 돌아와도 골라진 채다.
  AssetKind? _picked;
  bool _showError = false;

  /// 2단계에 들어올 때마다 새 몸을 만든다(← 로 나갔다 오면 쓴 값은 버려진 뒤다).
  int _epoch = 0;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    _kind = widget.edit != null
        ? AssetKindX.of(widget.edit!)
        : widget.initialKind;
    _picked = _kind;
  }

  void _next() {
    final picked = _picked;
    if (picked == null) {
      setState(() => _showError = true);
      return;
    }
    setState(() {
      _kind = picked;
      _epoch++;
      _showError = false;
    });
  }

  /// ← — 1단계로. 쓴 값이 있으면 먼저 묻고 버린다(고른 종류는 그대로 골라진 채).
  Future<void> _back() async {
    if (widget.probe.dirty()) {
      final l = AppLocalizations.of(context);
      final leave = await PAlertDialog.confirmLeave(
        context,
        PLeaveConfirmCopy(
          title: l.sheetLeaveTitle,
          description: l.sheetLeaveDescription,
          stayLabel: l.sheetLeaveStay,
          leaveLabel: l.sheetLeaveLeave,
        ),
      );
      if (!leave || !mounted) return;
    }
    setState(() {
      _picked = _kind;
      _kind = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    if (kind == null) {
      return AssetKindStep(
        picked: _picked,
        showError: _showError,
        onPick: (k) => setState(() => _picked = k),
        onNext: _next,
      );
    }
    final onBack = _isEdit ? null : _back;
    final key = ValueKey('asset-form-$_epoch');
    return switch (kind.group) {
      AssetKindGroup.account => AccountAddBody(
        key: key,
        edit: widget.edit,
        initialKind: kind,
        probe: widget.probe,
        onBack: onBack,
      ),
      AssetKindGroup.card => CardAddBody(
        key: key,
        edit: widget.edit,
        initialKind: kind,
        probe: widget.probe,
        onBack: onBack,
      ),
      AssetKindGroup.investment => InvestmentAddBody(
        key: key,
        edit: widget.edit,
        probe: widget.probe,
        onBack: onBack,
      ),
    };
  }
}
