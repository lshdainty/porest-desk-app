import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/features/import/data/import_repository.dart';

typedef _FieldMeta = ({String key, String Function(AppLocalizations) label, bool required});

const List<String> _sources = ['POREST', 'EASYBUDGET', 'BANKSALAD', 'TOSS', 'CUSTOM'];

String _sourceLabel(AppLocalizations l, String v) => switch (v) {
      'POREST' => '${l.importSourcePorest} · ${l.importSourcePorestDesc}',
      'EASYBUDGET' => '${l.importSourceEasybudget} · ${l.importSourceEasybudgetDesc}',
      'BANKSALAD' => '${l.importSourceBanksalad} · ${l.importSourceBanksaladDesc}',
      'TOSS' => '${l.importSourceToss} · ${l.importSourceTossDesc}',
      _ => '${l.importSourceCustom} · ${l.importSourceCustomDesc}',
    };

const List<_FieldMeta> _fields = [
  (key: 'DATE', label: _fDate, required: true),
  (key: 'AMOUNT', label: _fAmount, required: true),
  (key: 'TYPE', label: _fType, required: false),
  (key: 'CATEGORY', label: _fCategory, required: false),
  (key: 'ASSET', label: _fAsset, required: false),
  (key: 'MEMO', label: _fMemo, required: false),
  // 소스에 따라 있을 수도 없을 수도 있는 열 — 자동매핑이 잡으면 채워지고 없으면 '사용 안 함'.
  (key: 'SUBCATEGORY', label: _fSubcategory, required: false),
  (key: 'TIME', label: _fTime, required: false),
  (key: 'MERCHANT', label: _fMerchant, required: false),
  (key: 'PAYMENT_METHOD', label: _fPaymentMethod, required: false),
];

String _fSubcategory(AppLocalizations l) => l.importFieldSubcategory;
String _fTime(AppLocalizations l) => l.importFieldTime;
String _fMerchant(AppLocalizations l) => l.importFieldMerchant;
String _fPaymentMethod(AppLocalizations l) => l.importFieldPaymentMethod;
String _fDate(AppLocalizations l) => l.importFieldDate;
String _fAmount(AppLocalizations l) => l.importFieldAmount;
String _fType(AppLocalizations l) => l.importFieldType;
String _fCategory(AppLocalizations l) => l.importFieldCategory;
String _fAsset(AppLocalizations l) => l.importFieldAsset;
String _fMemo(AppLocalizations l) => l.importFieldMemo;

enum _Step { upload, mapping, done }

/// 데이터 가져오기 마법사 — 소스선택 → 파일업로드(analyze) → 열매핑·미리보기·옵션(execute) → 완료.
/// ExportScreen 세그의 '가져오기' 모드 본문.
class ImportView extends ConsumerStatefulWidget {
  const ImportView({super.key});

  @override
  ConsumerState<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends ConsumerState<ImportView> {
  _Step _step = _Step.upload;
  String _source = 'POREST';
  File? _file;
  bool _analyzing = false;
  ImportAnalyzeResult? _analysis;
  Map<String, int> _mapping = {};
  bool _dupSkip = true;
  bool _autoCat = true;
  bool _executing = false;
  ImportExecuteResult? _result;

  bool get _canExecute =>
      _mapping.containsKey('DATE') &&
      (_mapping.containsKey('AMOUNT') || _mapping.containsKey('AMOUNT_OUT') || _mapping.containsKey('AMOUNT_IN'));

  Future<void> _pickAndAnalyze() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() {
      _file = File(path);
      _analyzing = true;
    });
    try {
      final repo = await ref.read(importRepositoryProvider.future);
      final res = await repo.analyze(_file!, _source);
      if (!mounted) return;
      setState(() {
        _analysis = res;
        _mapping = Map<String, int>.from(res.suggestedMapping);
        _step = _Step.mapping;
      });
    } on ApiException catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        showPSnackBar(context, '${l.expActionFailed}: ${e.message}', severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _runImport() async {
    if (_file == null || !_canExecute) return;
    final l = AppLocalizations.of(context);
    setState(() => _executing = true);
    try {
      final repo = await ref.read(importRepositoryProvider.future);
      final res = await repo.execute(
        _file!,
        source: _source,
        mapping: _mapping,
        dupSkip: _dupSkip,
        autoCat: _autoCat,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _step = _Step.done;
      });
    } on ApiException catch (e) {
      if (mounted) showPSnackBar(context, '${l.expActionFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.upload;
      _file = null;
      _analysis = null;
      _mapping = {};
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      // 세그↔스텝바 32(web gap-2xl 정합, 사용자 결정) — 하단은 24 유지.
      padding: const EdgeInsets.fromLTRB(PSpace.x24, PSpace.x32, PSpace.x24, PSpace.x24),
      children: [
        _stepper(t),
        const SizedBox(height: PSpace.x32),
        if (_step == _Step.upload) ..._uploadStep(t),
        if (_step == _Step.mapping && _analysis != null) ..._mappingStep(t, _analysis!),
        if (_step == _Step.done && _result != null) _doneStep(t, _result!),
        const SizedBox(height: PSpace.x32),
      ],
    );
  }

  // ── 스텝 인디케이터 ──────────────────────────────────────

  Widget _stepper(PorestTokens t) {
    final l = AppLocalizations.of(context);
    final steps = [
      (k: _Step.upload, label: l.importStepUpload),
      (k: _Step.mapping, label: l.importStepMapping),
      (k: _Step.done, label: l.importStepDone),
    ];
    final idx = steps.indexWhere((s) => s.k == _step);
    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              // 동그라미 채움은 다크에서도 primary 고정(bgBrandSolid, 사용자 결정·web 정합).
              color: i <= idx ? t.bgBrandSolid : t.bgMuted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              i < idx ? '✓' : '${i + 1}',
              style: PTypo.micro.copyWith(
                color: i <= idx ? t.fgOnBrand : t.fgTertiary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: PSpace.x8),
          Text(
            steps[i].label,
            style: PTypo.bodySm.copyWith(
              color: i <= idx ? t.fgPrimary : t.fgTertiary,
              fontWeight: i == idx ? PFontWeight.bold : PFontWeight.regular,
            ),
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: PSpace.x8),
                color: t.borderSubtle,
              ),
            ),
        ],
      ],
    );
  }

  // ── 1. 업로드 ────────────────────────────────────────────

  List<Widget> _uploadStep(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return [
      _cardShell(
        t,
        title: l.importSourceTitle,
        desc: l.importSourceDesc,
        child: PSelect<String>(
          value: _source,
          onChanged: (v) => setState(() => _source = v ?? 'POREST'),
          items: _sources.map((s) => PSelectItem(value: s, label: _sourceLabel(l, s))).toList(),
        ),
      ),
      const SizedBox(height: PSpace.x32),
      _cardShell(
        t,
        title: l.importUploadTitle,
        desc: l.importUploadDesc,
        child: InkWell(
          onTap: _analyzing ? null : _pickAndAnalyze,
          borderRadius: PRadius.brLg,
          child: Container(
            width: double.infinity, // 풀폭 드롭존(web 정합, 사용자 결정)
            padding: const EdgeInsets.symmetric(vertical: PSpace.x24, horizontal: PSpace.x16),
            decoration: BoxDecoration(
              color: t.bgMuted,
              borderRadius: PRadius.brLg,
              border: Border.all(color: t.borderDefault, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: t.bgBrandSubtle, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: _analyzing
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: t.fgBrand),
                        )
                      : Icon(LucideIcons.upload, size: 22, color: t.fgBrand),
                ),
                const SizedBox(height: PSpace.x8),
                Text(
                  _analyzing ? l.importAnalyzing : l.importDropTitle,
                  style: PTypo.body.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(l.importDropHint, style: PTypo.micro.copyWith(color: t.fgTertiary)),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: PSpace.x32),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x12),
        decoration: BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.info, size: 15, color: t.fgTertiary),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Text(l.importNotice, style: PTypo.caption.copyWith(color: t.fgSecondary, height: 1.5)),
            ),
          ],
        ),
      ),
    ];
  }

  // ── 2. 매핑 ──────────────────────────────────────────────

  List<Widget> _mappingStep(PorestTokens t, ImportAnalyzeResult a) {
    final l = AppLocalizations.of(context);
    return [
      // 실행하면 반드시 실패할 행을 미리 알린다 — 넣고 나서 실패 숫자만 보면 원인을 알 수 없다.
      if (a.blockedParents.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(PSpace.x16),
          decoration: BoxDecoration(
            color: t.bgMuted,
            borderRadius: PRadius.brLg,
            border: Border.all(color: t.statusDanger.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.triangleAlert, size: 17, color: t.statusDanger),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.importBlockedTitle(a.blockedParents.join(', ')),
                        style: PTypo.bodySm
                            .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi)),
                    const SizedBox(height: 3),
                    Text(l.importBlockedDesc,
                        style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),
      ],
      _cardShell(
        t,
        title: l.importFileTitle,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
              alignment: Alignment.center,
              child: Icon(LucideIcons.fileSpreadsheet, size: 17, color: t.fgSecondary),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.fileName,
                      style: PTypo.bodySm.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(l.importRowsDetected(a.totalRows, a.validRows),
                      style: PTypo.micro.copyWith(color: t.fgTertiary)),
                ],
              ),
            ),
            PButton(
              label: l.importChange,
              icon: LucideIcons.x,
              variant: PButtonVariant.ghost,
              size: PButtonSize.sm,
              onPressed: _reset,
            ),
          ],
        ),
      ),
      const SizedBox(height: PSpace.x32),
      _cardShell(
        t,
        title: l.importMapTitle,
        desc: l.importMapDesc,
        child: Column(
          children: [
            for (final f in _fields) ...[
              Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: f.label(l),
                          style: PTypo.bodySm.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi)),
                      if (f.required)
                        TextSpan(text: ' *', style: PTypo.bodySm.copyWith(color: t.statusDanger)),
                    ])),
                  ),
                  Expanded(
                    child: PSelect<int?>(
                      value: _mapping[f.key],
                      placeholder: l.importNotMapped,
                      onChanged: (v) => setState(() {
                        if (v == null) {
                          _mapping.remove(f.key);
                        } else {
                          _mapping[f.key] = v;
                        }
                      }),
                      items: [
                        PSelectItem<int?>(value: null, label: l.importNotMapped),
                        ...a.columns.map((c) => PSelectItem<int?>(
                            value: c.index, label: c.name.isEmpty ? '#${c.index + 1}' : c.name)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x8),
            ],
          ],
        ),
      ),
      const SizedBox(height: PSpace.x32),
      _cardShell(
        t,
        title: l.exportPreview,
        desc: l.importPreviewDesc(a.duplicateCount),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 44,
            columnSpacing: 18,
            columns: [
              l.importFieldDate,
              l.importFieldType,
              l.importFieldCategory,
              l.importFieldAsset,
              l.importFieldAmount,
              l.importFieldMemo,
            ]
                .map((h) => DataColumn(
                    label: Text(h, style: PTypo.caption.copyWith(color: t.fgSecondary, fontWeight: PFontWeight.bold))))
                .toList(),
            rows: a.preview.map((r) {
              final dim = r.error != null || (r.duplicate && _dupSkip);
              final color = dim ? t.fgTertiary : t.fgPrimary;
              return DataRow(cells: [
                DataCell(Text(r.date != null && r.date!.length >= 10 ? r.date!.substring(0, 10) : '—',
                    style: PTypo.caption.copyWith(color: color))),
                DataCell(r.type == null
                    ? Text('—', style: PTypo.caption.copyWith(color: color))
                    : Text(r.type == 'INCOME' ? l.importIncome : l.importExpense,
                        style: PTypo.caption.copyWith(
                            color: r.type == 'INCOME' ? t.fgBrand : t.fgSecondary,
                            fontWeight: PFontWeight.bold))),
                DataCell(Text(r.category ?? '—', style: PTypo.caption.copyWith(color: color))),
                DataCell(Text(r.asset ?? '—', style: PTypo.caption.copyWith(color: color))),
                DataCell(Text(r.amount != null ? _fmt(r.amount!) : '—',
                    style: PTypo.caption.copyWith(color: color, fontWeight: PFontWeight.bold))),
                DataCell(Row(children: [
                  if (r.duplicate)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(l.importDupBadge,
                          style: PTypo.micro.copyWith(color: t.statusWarning, fontWeight: PFontWeight.bold)),
                    ),
                  Flexible(child: Text(r.memo ?? '', style: PTypo.caption.copyWith(color: color), overflow: TextOverflow.ellipsis)),
                ])),
              ]);
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: PSpace.x32),
      _cardShell(
        t,
        title: l.importOptionsTitle,
        child: Column(
          children: [
            _optionRow(t, l.importOptDupSkip, l.importOptDupSkipDesc(a.duplicateCount), _dupSkip,
                (v) => setState(() => _dupSkip = v)),
            const SizedBox(height: PSpace.x8),
            _optionRow(t, l.importOptAutoCat, l.importOptAutoCatDesc, _autoCat,
                (v) => setState(() => _autoCat = v)),
          ],
        ),
      ),
      const SizedBox(height: PSpace.x32),
      Row(
        children: [
          Expanded(
            child: PButton(
              label: l.importPrev,
              icon: LucideIcons.arrowLeft,
              variant: PButtonVariant.outline,
              onPressed: _reset,
            ),
          ),
          const SizedBox(width: PSpace.x8),
          Expanded(
            child: PButton(
              label: l.importDoImport(_dupSkip ? a.validRows - a.duplicateCount : a.validRows),
              icon: LucideIcons.download,
              loading: _executing,
              onPressed: _canExecute ? _runImport : null,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _optionRow(PorestTokens t, String title, String desc, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PTypo.bodySm.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi)),
              const SizedBox(height: 1),
              Text(desc, style: PTypo.micro.copyWith(color: t.fgTertiary)),
            ],
          ),
        ),
        const SizedBox(width: PSpace.x12),
        PSwitch(value: value, onChanged: onChanged),
      ],
    );
  }

  // ── 3. 완료 ──────────────────────────────────────────────

  Widget _doneStep(PorestTokens t, ImportExecuteResult r) {
    final l = AppLocalizations.of(context);
    return _cardShell(
      t,
      title: l.importDoneTitle,
      child: Column(
        children: [
          const SizedBox(height: PSpace.x12),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: t.bgBrandSubtle, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(LucideIcons.check, size: 30, color: t.fgBrand),
          ),
          const SizedBox(height: PSpace.x12),
          Text(l.importDoneCount(r.imported),
              style: PTypo.body.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(l.importDoneDetail(r.skipped, r.failed),
              style: PTypo.bodySm.copyWith(color: t.fgTertiary), textAlign: TextAlign.center),
          const SizedBox(height: PSpace.x16),
          PButton(
            label: l.importAnother,
            icon: LucideIcons.plus,
            variant: PButtonVariant.outline,
            size: PButtonSize.sm,
            onPressed: _reset,
          ),
          const SizedBox(height: PSpace.x12),
        ],
      ),
    );
  }

  // ── 공통 ─────────────────────────────────────────────────

  Widget _cardShell(PorestTokens t, {required String title, String? desc, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: PTypo.body.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold)),
        if (desc != null) ...[
          const SizedBox(height: 2),
          Text(desc, style: PTypo.caption.copyWith(color: t.fgTertiary)),
        ],
        const SizedBox(height: PSpace.x12),
        child,
      ],
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
