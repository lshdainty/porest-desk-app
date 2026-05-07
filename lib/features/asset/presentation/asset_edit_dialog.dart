import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../card/presentation/card_catalog_picker.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';
import '../domain/asset_type_meta.dart';
import 'asset_detail_dialog.dart';

/// 자산 추가/수정 통합 시트 (구). 신규 코드는 아래 4종 진입점 사용 권장:
///   [showAssetAddDialog] / [showCardAddDialog] /
///   [showInvestmentAddDialog] / [showAssetDetailDialog]
void showAssetEditDialog(BuildContext context, {Asset? edit}) {
  if (edit != null) {
    showAssetDetailDialog(context, edit);
  } else {
    showAssetAddDialog(context);
  }
}

/// 일반 자산 추가 — 계좌·예적금·현금·대출 등.
void showAssetAddDialog(BuildContext context, {String? presetType}) {
  _open(
    context: context,
    title: '자산 추가',
    body: _AssetEditBody(presetType: presetType),
  );
}

/// 카드 추가 — assetType 을 CREDIT_CARD 로 미리 지정.
/// 카드 카탈로그 매핑은 추후 구현 (현재 v0.1 은 일반 폼).
void showCardAddDialog(BuildContext context) {
  _open(
    context: context,
    title: '카드 추가',
    body: const _AssetEditBody(presetType: 'CREDIT_CARD', kindHint: AssetKind.card),
  );
}

/// 투자 자산 추가 — assetType 을 INVESTMENT 로 미리 지정.
/// 증권사·상품 카탈로그 매핑은 추후 구현.
void showInvestmentAddDialog(BuildContext context) {
  _open(
    context: context,
    title: '투자 추가',
    body: const _AssetEditBody(
        presetType: 'INVESTMENT', kindHint: AssetKind.investment),
  );
}

/// 자산 상세 — 잔액 추이 차트 + 최근 거래 + 편집/삭제 진입.
/// front `AssetDetailDialog` 미러.
void showAssetDetailDialog(BuildContext context, Asset asset) {
  showAssetDetailRich(context, asset);
}

/// 자산 편집 폼 진입 (상세 다이얼로그 내부에서 직접 호출용).
void showAssetEditForm(BuildContext context, Asset asset) {
  _open(
    context: context,
    title: '자산 수정',
    body: _AssetEditBody(edit: asset),
  );
}

void _open({
  required BuildContext context,
  required String title,
  required Widget body,
}) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(title),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: body,
      ),
    ],
  );
}

/// 진입점별 폼 힌트 — 카드/투자 는 자산 종류 chip 을 일부만 노출.
enum AssetKind { generic, card, investment }

class _AssetEditBody extends ConsumerStatefulWidget {
  const _AssetEditBody({
    this.edit,
    this.presetType,
    this.kindHint = AssetKind.generic,
  });
  final Asset? edit;
  final String? presetType;
  final AssetKind kindHint;

  @override
  ConsumerState<_AssetEditBody> createState() => _AssetEditBodyState();
}

class _AssetEditBodyState extends ConsumerState<_AssetEditBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _institutionCtrl;
  late final TextEditingController _memoCtrl;
  late String _type;
  late bool _includedInTotal;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _nameCtrl = TextEditingController(text: e?.assetName ?? '');
    _balanceCtrl = TextEditingController(
      text: e?.balance == null ? '' : e!.balance.toString(),
    );
    _institutionCtrl = TextEditingController(text: e?.institution ?? '');
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    _type = e?.assetType ?? widget.presetType ?? 'BANK_ACCOUNT';
    _includedInTotal = e?.isIncludedInTotal != 'N';
  }

  /// kindHint 별 노출할 자산 종류 chip 들.
  Iterable<AssetTypeMeta> _availableTypes() {
    return switch (widget.kindHint) {
      AssetKind.card => AssetTypeMeta.all
          .where((m) => m.code == 'CREDIT_CARD' || m.code == 'CHECK_CARD'),
      AssetKind.investment =>
        AssetTypeMeta.all.where((m) => m.code == 'INVESTMENT'),
      AssetKind.generic => AssetTypeMeta.all,
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _institutionCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_submitting && _nameCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final balance = int.tryParse(_balanceCtrl.text.replaceAll(',', ''));
    final institution =
        _institutionCtrl.text.trim().isEmpty ? null : _institutionCtrl.text.trim();
    final memo = _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim();

    setState(() => _submitting = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          assetName: name,
          assetType: _type,
          balance: balance,
          institution: institution,
          memo: memo,
          isIncludedInTotal: _includedInTotal ? 'Y' : 'N',
        );
      } else {
        await repo.create(
          assetName: name,
          assetType: _type,
          balance: balance,
          institution: institution,
          memo: memo,
        );
      }
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '자산이 수정되었습니다' : '자산이 추가되었습니다')),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('자산 삭제'),
        content: const Text('이 자산을 삭제하시겠습니까? 연결된 거래는 유지됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
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
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      ref.invalidate(assetsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자산이 삭제되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.kindHint == AssetKind.card && !_isEdit) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showCardCatalogPicker(
                  context,
                  cardType: _type == 'CHECK_CARD' ? 'CHECK' : 'CREDIT',
                );
                if (selected == null || !mounted) return;
                setState(() {
                  _nameCtrl.text = selected.cardName;
                  final cn = selected.company?.name;
                  if (cn != null && cn.isNotEmpty) {
                    _institutionCtrl.text = cn;
                  }
                  if (selected.cardType == 'CHECK') {
                    _type = 'CHECK_CARD';
                  } else if (selected.cardType == 'CREDIT') {
                    _type = 'CREDIT_CARD';
                  }
                });
              },
              icon: const Icon(LucideIcons.search, size: 14),
              label: const Text('카드 카탈로그에서 선택'),
            ),
            const SizedBox(height: PSpace.x12),
          ],
          _Label('자산 종류'),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (final m in _availableTypes())
                _TypeChip(
                  label: m.label,
                  icon: m.icon,
                  selected: _type == m.code,
                  onTap: () => setState(() => _type = m.code),
                  tokens: t,
                ),
            ],
          ),
          const SizedBox(height: PSpace.x16),

          _Label('이름'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: '예: 카카오뱅크 통장'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('현재 잔액 (선택)'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _balanceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '0'),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('금융사 (선택)'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _institutionCtrl,
            decoration: const InputDecoration(hintText: '예: 카카오뱅크'),
          ),
          const SizedBox(height: PSpace.x16),

          _Label('메모 (선택)'),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _memoCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '메모'),
          ),

          if (_isEdit) ...[
            const SizedBox(height: PSpace.x16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('순자산 합계에 포함',
                  style: PTypo.body.copyWith(color: t.fgPrimary)),
              subtitle: Text('대시보드 순자산 계산에 포함할지 여부',
                  style: PTypo.caption.copyWith(color: t.fgTertiary)),
              value: _includedInTotal,
              onChanged: (v) => setState(() => _includedInTotal = v),
            ),
          ],

          const SizedBox(height: PSpace.x24),

          Row(
            children: [
              if (_isEdit) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.statusDanger,
                      side: BorderSide(
                          color: t.statusDanger.withValues(alpha: 0.5)),
                    ),
                    onPressed: _submitting ? null : _delete,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('삭제'),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
              ],
              Expanded(
                flex: _isEdit ? 1 : 2,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? '수정' : '추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(text, style: PTypo.caption.copyWith(color: t.fgSecondary));
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: PRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? tokens.fgBrand : tokens.fgSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: PTypo.bodySm.copyWith(
                  color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                  fontWeight:
                      selected ? PFontWeight.semi : PFontWeight.medium,
                )),
          ],
        ),
      ),
    );
  }
}
