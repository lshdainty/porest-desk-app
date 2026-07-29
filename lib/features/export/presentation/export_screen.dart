import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_checkbox.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/features/export/data/export_repository.dart';
import 'package:porest_desk_app/features/import/presentation/import_view.dart';

typedef _TypeMeta = ({String name, String slug, IconData icon});
typedef _FormatMeta = ({String value, String label, String ext, IconData icon});
typedef _PeriodMeta = ({String value});

const List<_TypeMeta> _types = [
  (name: 'EXPENSE', slug: 'expense', icon: LucideIcons.receipt),
  (name: 'ASSET', slug: 'asset', icon: LucideIcons.wallet),
  (name: 'BUDGET', slug: 'budget', icon: LucideIcons.target),
  (name: 'CATEGORY', slug: 'category', icon: LucideIcons.tag),
  (name: 'MEMO', slug: 'memo', icon: LucideIcons.fileText),
  (name: 'CALENDAR', slug: 'calendar', icon: LucideIcons.calendar),
  (name: 'TODO', slug: 'todo', icon: LucideIcons.squareCheckBig),
];

const List<_FormatMeta> _formats = [
  (value: 'CSV', label: 'CSV', ext: '.csv', icon: LucideIcons.fileText),
  (value: 'EXCEL', label: 'Excel', ext: '.xlsx', icon: LucideIcons.sheet),
  (value: 'JSON', label: 'JSON', ext: '.json', icon: LucideIcons.braces),
];

const List<_PeriodMeta> _periods = [
  (value: 'THIS_MONTH'),
  (value: 'LAST_MONTH'),
  (value: 'LAST_3_MONTHS'),
  (value: 'THIS_YEAR'),
  (value: 'CUSTOM'),
];

String _slugOf(String name) => _types.firstWhere((t) => t.name == name).slug;

String _typeLabel(AppLocalizations l, String name) => switch (name) {
      'EXPENSE' => l.exportTypeExpense,
      'ASSET' => l.exportTypeAsset,
      'BUDGET' => l.exportTypeBudget,
      'CATEGORY' => l.exportTypeCategory,
      'MEMO' => l.exportTypeMemo,
      'CALENDAR' => l.exportTypeCalendar,
      _ => l.exportTypeTodo,
    };

String _formatDesc(AppLocalizations l, String value) => switch (value) {
      'EXCEL' => l.exportFormatExcelDesc,
      'JSON' => l.exportFormatJsonDesc,
      _ => l.exportFormatCsvDesc,
    };

String _periodLabel(AppLocalizations l, String value) => switch (value) {
      'LAST_MONTH' => l.exportPeriodLastMonth,
      'LAST_3_MONTHS' => l.exportPeriodLast3Months,
      'THIS_YEAR' => l.exportPeriodThisYear,
      'CUSTOM' => l.exportPeriodCustom,
      _ => l.exportPeriodThisMonth,
    };

String _two(int n) => n.toString().padLeft(2, '0');
String _iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _krLabel(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length < 3) return isoDate;
  return formatDay(
    DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
  ).md;
}

/// 데이터 내보내기 풀스크린 — 설정 > 데이터 내보내기.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _mode = 'export'; // export | import
  String _format = 'CSV';
  String _period = 'THIS_MONTH';
  DateTime? _customFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _customTo = DateTime.now();
  List<String> _selected = ['EXPENSE', 'ASSET', 'BUDGET'];
  bool _mask = false;

  Map<String, int> _counts = {};
  bool _downloading = false;
  bool _previewing = false;
  List<ExportPreviewTable>? _preview;
  String? _previewTab;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  bool get _customInvalid =>
      _period == 'CUSTOM' &&
      (_customFrom == null || _customTo == null || _customFrom!.isAfter(_customTo!));

  ({String start, String end}) _resolveRange(String period) {
    final now = DateTime.now();
    DateTime firstOf(int y, int m) => DateTime(y, m, 1);
    DateTime lastOf(int y, int m) => DateTime(y, m + 1, 0);
    switch (period) {
      case 'THIS_MONTH':
        return (start: _iso(firstOf(now.year, now.month)), end: _iso(lastOf(now.year, now.month)));
      case 'LAST_MONTH':
        final d = DateTime(now.year, now.month - 1, 1);
        return (start: _iso(firstOf(d.year, d.month)), end: _iso(lastOf(d.year, d.month)));
      case 'LAST_3_MONTHS':
        final d = DateTime(now.year, now.month - 2, 1);
        return (start: _iso(firstOf(d.year, d.month)), end: _iso(lastOf(now.year, now.month)));
      case 'THIS_YEAR':
        return (start: '${now.year}-01-01', end: _iso(lastOf(now.year, now.month)));
      default:
        return (start: _customFrom != null ? _iso(_customFrom!) : '', end: _customTo != null ? _iso(_customTo!) : '');
    }
  }

  Map<String, dynamic> _queryBody(List<String> types) {
    final r = _resolveRange(_period);
    return {
      'period': _period,
      if (_period == 'CUSTOM') 'startDate': r.start,
      if (_period == 'CUSTOM') 'endDate': r.end,
      'types': types,
    };
  }

  String _buildFilename(String format, List<String> types, ({String start, String end}) r) {
    final ext = format == 'EXCEL' ? 'xlsx' : format == 'JSON' ? 'json' : 'csv';
    final rangePart = '${r.start}_${r.end}';
    if (format != 'EXCEL' && types.length > 1) return 'porest-export-$rangePart.zip';
    final namePart = types.length == 1 ? _slugOf(types.first) : 'export';
    return 'porest-$namePart-$rangePart.$ext';
  }

  String _mimeType(String format, List<String> types) {
    if (format != 'EXCEL' && types.length > 1) return 'application/zip';
    switch (format) {
      case 'EXCEL':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'JSON':
        return 'application/json';
      default:
        return 'text/csv';
    }
  }

  Future<void> _loadCounts() async {
    if (_customInvalid) return;
    try {
      final repo = await ref.read(exportRepositoryProvider.future);
      final list = await repo.counts(_queryBody(_types.map((t) => t.name).toList()));
      if (!mounted) return;
      setState(() => _counts = {for (final c in list) c.type: c.count});
    } catch (_) {/* ignore — 화면 진입 건수는 best-effort */}
  }

  void _changePeriod(String p) {
    setState(() => _period = p);
    _loadCounts();
  }

  void _toggleType(String name) {
    setState(() {
      _selected = _selected.contains(name)
          ? (_selected.where((x) => x != name).toList())
          : [..._selected, name];
    });
  }

  Future<void> _runPreview() async {
    if (_selected.isEmpty || _customInvalid) return;
    setState(() => _previewing = true);
    try {
      final repo = await ref.read(exportRepositoryProvider.future);
      final tables = await repo.preview(_queryBody(_orderedSelected()));
      if (!mounted) return;
      setState(() {
        _preview = tables;
        _previewTab = tables.isNotEmpty ? tables.first.type : null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        showPSnackBar(context, '${l.expActionFailed}: ${e.message}', severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _runExport() async {
    if (_selected.isEmpty || _customInvalid) return;
    final l = AppLocalizations.of(context);
    setState(() => _downloading = true);
    try {
      final repo = await ref.read(exportRepositoryProvider.future);
      final r = _resolveRange(_period);
      final types = _orderedSelected();
      final body = {..._queryBody(types), 'format': _format, 'mask': _mask};
      final filename = _buildFilename(_format, types, r);
      final file = await repo.download(body: body, filename: filename);
      try {
        await Share.shareXFiles(
          [XFile(file.path, name: filename, mimeType: _mimeType(_format, types))],
          text: l.exportShareText(r.start, r.end),
        );
      } finally {
        // 금융 데이터 평문 임시파일 — 공유 완료 후 즉시 삭제(복구 방지).
        if (await file.exists()) await file.delete();
      }
      if (mounted) showPSnackBar(context, l.exportSuccess, severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (mounted) showPSnackBar(context, '${l.expActionFailed}: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  /// 선언 순서 정렬 (백엔드와 일관).
  List<String> _orderedSelected() =>
      _types.where((t) => _selected.contains(t.name)).map((t) => t.name).toList();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.exportTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(PSpace.x20, PSpace.x16, PSpace.x20, 0),
            // 언어 설정과 동일한 container 세그먼트(풀폭 균등, 웹 정합·사용자 결정) —
            // 트랙(bgMuted) + active = surface pill + shadow.
            child: PTabs<String>(
              value: _mode,
              onChanged: (v) => setState(() => _mode = v),
              variant: PTabsVariant.container,
              size: PTabsSize.sm,
              expand: true,
              items: [
                PTabItem(value: 'export', label: l.exportTab),
                PTabItem(value: 'import', label: l.importTab),
              ],
            ),
          ),
          Expanded(
            child: _mode == 'import'
                ? const ImportView()
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: PSpace.x20, vertical: PSpace.x24),
                    children: [
                      _periodCard(t),
                      const SizedBox(height: PSpace.x32),
                      _typesCard(t),
                      const SizedBox(height: PSpace.x32),
                      _formatCard(t),
                      const SizedBox(height: PSpace.x32),
                      _maskRow(t),
                      const SizedBox(height: PSpace.x12),
                      _actions(),
                      if (_preview != null) ...[
                        const SizedBox(height: PSpace.x32),
                        _previewCard(t),
                      ],
                      const SizedBox(height: PSpace.x32),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── 카드들 ────────────────────────────────────────────────

  // 카드 다이어트 — design .m-subpage 플랫: 카드 없이 섹션 타이틀 + 콘텐츠만.
  Widget _cardShell(PorestTokens t, {required String title, String? desc, required Widget child, bool flushContent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: PTypo.body.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold)),
        if (desc != null) ...[
          const SizedBox(height: 2),
          Text(desc, style: PTypo.caption.copyWith(color: t.fgTertiary)),
        ],
        // 데이터 종류 섹션만 label↔content gap 0(사용자 결정) — 나머지는 x12.
        if (!flushContent) const SizedBox(height: PSpace.x12),
        child,
      ],
    );
  }

  Widget _periodCard(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return _cardShell(
      t,
      title: l.exportPeriodTitle,
      child: Column(
        children: [
          _grid2(_periods.map((p) {
            final active = _period == p.value;
            final r = _resolveRange(p.value);
            final sub = p.value == 'CUSTOM' ? l.expPeriodCustom : '${_krLabel(r.start)} — ${_krLabel(r.end)}';
            return _tile(t, active: active, onTap: () => _changePeriod(p.value), children: [
              Text(_periodLabel(l, p.value),
                  style: PTypo.bodySm.copyWith(
                      color: active ? t.fgBrand : t.fgPrimary, fontWeight: PFontWeight.bold)),
              const SizedBox(height: 3),
              Text(sub, style: PTypo.micro.copyWith(color: t.fgTertiary)),
            ]);
          }).toList()),
          if (_period == 'CUSTOM') ...[
            const SizedBox(height: PSpace.x12),
            Row(
              children: [
                Expanded(
                  child: PDateInput(
                    value: _customFrom,
                    onChanged: (d) {
                      setState(() => _customFrom = d);
                      _loadCounts();
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: PSpace.x8),
                  child: Text('~'),
                ),
                Expanded(
                  child: PDateInput(
                    value: _customTo,
                    onChanged: (d) {
                      setState(() => _customTo = d);
                      _loadCounts();
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_customInvalid) ...[
            const SizedBox(height: PSpace.x8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l.exportDateRangeError,
                  style: PTypo.caption.copyWith(color: t.statusDanger)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typesCard(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return _cardShell(
      t,
      flushContent: true,
      title: l.exportTypesTitle(_selected.length),
      desc: l.exportTypesDesc,
      child: Column(
        children: [
          for (int i = 0; i < _types.length; i++)
            InkWell(
              onTap: () => _toggleType(_types[i].name),
              child: Padding(
                // web 행 '12px 4px' 정합(사용자 결정).
                padding: const EdgeInsets.symmetric(vertical: PSpace.x12, horizontal: PSpace.x4),
                child: Row(
                  children: [
                    PCheckbox(
                      dense: true,
                      value: _selected.contains(_types[i].name),
                      onChanged: (_) => _toggleType(_types[i].name),
                    ),
                    const SizedBox(width: PSpace.x12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
                      alignment: Alignment.center,
                      child: Icon(_types[i].icon, size: 16, color: t.fgSecondary),
                    ),
                    const SizedBox(width: PSpace.x12),
                    Expanded(
                      child: Text(_typeLabel(l, _types[i].name),
                          style: PTypo.bodySm.copyWith(color: t.fgPrimary, fontWeight: PFontWeight.semi)),
                    ),
                    Text(
                      _counts.containsKey(_types[i].slug) ? l.exportCount(_counts[_types[i].slug]!) : '…',
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formatCard(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return _cardShell(
      t,
      title: l.exportFormatTitle,
      child: _grid2(_formats.map((f) {
        final active = _format == f.value;
        return _tile(t, active: active, onTap: () => setState(() => _format = f.value), children: [
          Row(
            children: [
              Icon(f.icon, size: 16, color: active ? t.fgBrand : t.fgSecondary),
              const SizedBox(width: PSpace.x4),
              Text(f.label,
                  style: PTypo.bodySm.copyWith(
                      color: active ? t.fgBrand : t.fgPrimary, fontWeight: PFontWeight.bold)),
              const Spacer(),
              Text(f.ext, style: PTypo.micro.copyWith(color: t.fgTertiary)),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          Text(_formatDesc(l, f.value), style: PTypo.micro.copyWith(color: t.fgTertiary)),
        ]);
      }).toList()),
    );
  }

  Widget _maskRow(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        PSwitch(value: _mask, onChanged: (v) => setState(() => _mask = v)),
        const SizedBox(width: PSpace.x8),
        Expanded(
          child: Text(l.exportMaskLabel,
              style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
        ),
      ],
    );
  }

  Widget _actions() {
    final l = AppLocalizations.of(context);
    final disabled = _selected.isEmpty || _customInvalid;
    return Row(
      children: [
        Expanded(
          child: PButton(
            label: l.exportPreview,
            icon: LucideIcons.eye,
            variant: PButtonVariant.outline,
            loading: _previewing,
            onPressed: disabled ? null : _runPreview,
          ),
        ),
        const SizedBox(width: PSpace.x8),
        Expanded(
          child: PButton(
            label: l.exportRun,
            icon: LucideIcons.download,
            loading: _downloading,
            onPressed: disabled ? null : _runExport,
          ),
        ),
      ],
    );
  }

  Widget _previewCard(PorestTokens t) {
    final l = AppLocalizations.of(context);
    final tables = _preview!;
    final active = tables.firstWhere(
      (x) => x.type == _previewTab,
      orElse: () => tables.isNotEmpty ? tables.first : const ExportPreviewTable(
          type: '', displayName: '', headers: [], rows: [], totalCount: 0),
    );
    return _cardShell(
      t,
      title: l.exportPreview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tables.map((tb) {
              final on = tb.type == active.type;
              return InkWell(
                onTap: () => setState(() => _previewTab = tb.type),
                borderRadius: PRadius.brFull,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: on ? t.bgBrandSubtle : t.bgSurface,
                    borderRadius: PRadius.brFull,
                    border: Border.all(color: on ? t.borderBrand : t.borderSubtle),
                  ),
                  child: Text('${tb.displayName} ${tb.totalCount}',
                      style: PTypo.caption.copyWith(
                          color: on ? t.fgBrand : t.fgSecondary, fontWeight: PFontWeight.semi)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: PSpace.x12),
          if (active.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x20),
              child: Center(
                child: Text(l.exportEmpty,
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                columnSpacing: 20,
                columns: active.headers
                    .map((h) => DataColumn(
                        label: Text(h,
                            style: PTypo.caption.copyWith(color: t.fgSecondary, fontWeight: PFontWeight.bold))))
                    .toList(),
                rows: active.rows
                    .map((row) => DataRow(
                        cells: List.generate(
                            active.headers.length,
                            (ci) => DataCell(Text(ci < row.length ? row[ci] : '',
                                style: PTypo.caption.copyWith(color: t.fgPrimary))))))
                    .toList(),
              ),
            ),
          const SizedBox(height: PSpace.x8),
          Text(l.exportPreviewRows(active.rows.length),
              style: PTypo.micro.copyWith(color: t.fgTertiary)),
        ],
      ),
    );
  }

  // ── 보조 위젯 ─────────────────────────────────────────────

  /// 2열 그리드 (LayoutBuilder 로 타일 폭 계산).
  Widget _grid2(List<Widget> tiles) {
    return LayoutBuilder(builder: (ctx, c) {
      final w = (c.maxWidth - PSpace.x8) / 2;
      return Wrap(
        spacing: PSpace.x8,
        runSpacing: PSpace.x8,
        children: tiles.map((t) => SizedBox(width: w, child: t)).toList(),
      );
    });
  }

  Widget _tile(PorestTokens t,
      {required bool active, required VoidCallback onTap, required List<Widget> children}) {
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brLg,
      child: Container(
        padding: const EdgeInsets.all(PSpace.x12),
        decoration: BoxDecoration(
          color: active ? t.bgBrandSubtle : t.bgSurface,
          borderRadius: PRadius.brLg,
          border: Border.all(color: active ? t.borderBrand : t.borderSubtle),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
