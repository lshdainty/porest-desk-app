import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../asset/application/asset_providers.dart';
import '../../asset/domain/asset.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';

/// 거래 데이터 내보내기 시트 — front `ExportDialog` 미러.
void showExportDialog(BuildContext context) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: '내보내기',
    contentBuilder: (ctx, scrollCtrl) => _ExportBody(
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: 'CSV 내보내기'),
  );
}

enum _Period { week, month, q3, year, custom }

enum _Include { tx, category, asset }

class _ExportBody extends ConsumerStatefulWidget {
  const _ExportBody({
    required this.scrollController,
    required this.controller,
  });
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_ExportBody> createState() => _ExportBodyState();
}

class _ExportBodyState extends ConsumerState<_ExportBody> {
  _Period _period = _Period.month;
  final Set<_Include> _includes = {_Include.tx, _Include.category};
  DateTime _customFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customTo = DateTime.now();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onSubmit = _run;
  }

  void _setRunning(bool v) {
    setState(() => _running = v);
    widget.controller.setSubmitting(v);
  }

  ({DateTime from, DateTime to}) _resolvePeriod() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.week:
        return (from: now.subtract(const Duration(days: 7)), to: now);
      case _Period.month:
        return (from: DateTime(now.year, now.month, 1), to: now);
      case _Period.q3:
        return (from: DateTime(now.year, now.month - 3, now.day), to: now);
      case _Period.year:
        return (from: DateTime(now.year, 1, 1), to: now);
      case _Period.custom:
        return (from: _customFrom, to: _customTo);
    }
  }

  String _yyyymmdd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _csvEscape(Object? v) {
    if (v == null) return '';
    final s = v.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _buildCsv({
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
    required List<Asset> assets,
  }) {
    final buf = StringBuffer();
    if (_includes.contains(_Include.tx)) {
      buf.writeln('# 거래 내역');
      buf.writeln('날짜,유형,카테고리,자산,금액,가맹점,결제수단,메모');
      for (final e in expenses) {
        buf.writeln([
          _csvEscape(e.expenseDateOnly ?? ''),
          _csvEscape(e.expenseType),
          _csvEscape(e.categoryName ?? ''),
          _csvEscape(e.assetName ?? ''),
          _csvEscape(e.amount),
          _csvEscape(e.merchant ?? ''),
          _csvEscape(e.paymentMethod ?? ''),
          _csvEscape(e.description ?? ''),
        ].join(','));
      }
      buf.writeln();
    }
    if (_includes.contains(_Include.category)) {
      final byCat = <String, int>{};
      for (final e in expenses) {
        if (e.expenseType != 'EXPENSE') continue;
        final k = e.categoryName ?? '미분류';
        byCat[k] = (byCat[k] ?? 0) + e.amount;
      }
      final total = byCat.values.fold<int>(0, (a, b) => a + b);
      buf.writeln('# 카테고리 요약');
      buf.writeln('카테고리,합계,비율(%)');
      final sorted = byCat.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        final pct = total == 0 ? 0 : (e.value * 100 / total);
        buf.writeln('${_csvEscape(e.key)},${e.value},${pct.toStringAsFixed(1)}');
      }
      buf.writeln();
    }
    if (_includes.contains(_Include.asset)) {
      buf.writeln('# 자산 스냅샷');
      buf.writeln('자산명,유형,잔액,통화');
      for (final a in assets) {
        buf.writeln([
          _csvEscape(a.assetName),
          _csvEscape(a.assetType),
          _csvEscape(a.balance ?? 0),
          _csvEscape(a.currency ?? 'KRW'),
        ].join(','));
      }
      buf.writeln();
    }
    return buf.toString();
  }

  Future<void> _run() async {
    if (_running || _includes.isEmpty) return;
    _setRunning(true);
    try {
      final p = _resolvePeriod();
      final eRepo = await ref.read(expenseRepositoryProvider.future);
      final expenses = _includes.contains(_Include.tx) ||
              _includes.contains(_Include.category)
          ? await eRepo.list(
              startDate: _yyyymmdd(p.from),
              endDate: _yyyymmdd(p.to),
            )
          : <Expense>[];
      final categories = _includes.contains(_Include.category)
          ? await eRepo.categories()
          : <ExpenseCategory>[];
      final assets = _includes.contains(_Include.asset)
          ? (ref.read(assetsProvider).value ?? <Asset>[])
          : <Asset>[];

      final csv = _buildCsv(
          expenses: expenses, categories: categories, assets: assets);
      final dir = await getTemporaryDirectory();
      final filename =
          'porest-export-${_yyyymmdd(p.from)}-${_yyyymmdd(p.to)}.csv';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: filename)],
        text: '거래 내보내기 (${_yyyymmdd(p.from)} ~ ${_yyyymmdd(p.to)})',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내보내기 실패: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내보내기 실패: $e')),
      );
    } finally {
      if (mounted) _setRunning(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_includes.isNotEmpty);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          _Label('파일 형식'),
          const SizedBox(height: PSpace.x8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.bgBrandSubtle,
              borderRadius: PRadius.brMd,
              border: Border.all(color: t.borderBrand),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.fileText, size: 16, color: t.fgBrand),
                const SizedBox(width: PSpace.x8),
                Text('CSV',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgBrand, fontWeight: PFontWeight.bold)),
                const SizedBox(width: PSpace.x8),
                Text('Excel·Google 시트에서 열기',
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),
          _Label('기간'),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (final p in _Period.values)
                _Chip(
                  label: _periodLabel(p),
                  selected: _period == p,
                  onTap: () => setState(() => _period = p),
                  tokens: t,
                ),
            ],
          ),
          if (_period == _Period.custom) ...[
            const SizedBox(height: PSpace.x8),
            Row(
              children: [
                Expanded(
                  child: _DatePickField(
                    label: '시작',
                    value: _customFrom,
                    onChanged: (d) => setState(() => _customFrom = d),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: _DatePickField(
                    label: '종료',
                    value: _customTo,
                    onChanged: (d) => setState(() => _customTo = d),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: PSpace.x16),
          _Label('포함할 내용'),
          const SizedBox(height: PSpace.x8),
          for (final inc in _Include.values)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpace.x8),
              child: _IncludeRow(
                inc: inc,
                selected: _includes.contains(inc),
                onChanged: (v) => setState(() {
                  if (v) {
                    _includes.add(inc);
                  } else {
                    _includes.remove(inc);
                  }
                }),
                tokens: t,
              ),
            ),
      ],
    );
  }

  String _periodLabel(_Period p) => switch (p) {
        _Period.week => '주간',
        _Period.month => '이번 달',
        _Period.q3 => '분기',
        _Period.year => '올해',
        _Period.custom => '직접 선택',
      };
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final String label;
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
        child: Text(label,
            style: PTypo.bodySm.copyWith(
                color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                fontWeight: selected ? PFontWeight.semi : PFontWeight.medium)),
      ),
    );
  }
}

class _DatePickField extends StatelessWidget {
  const _DatePickField(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: () async {
        final p = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030, 12, 31),
        );
        if (p != null) onChanged(p);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.bgMuted,
          borderRadius: PRadius.brMd,
          border: Border.all(color: t.borderDefault),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14, color: t.fgTertiary),
            const SizedBox(width: 6),
            Text(
                '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                style: PTypo.caption.copyWith(color: t.fgPrimary)),
          ],
        ),
      ),
    );
  }
}

class _IncludeRow extends StatelessWidget {
  const _IncludeRow({
    required this.inc,
    required this.selected,
    required this.onChanged,
    required this.tokens,
  });
  final _Include inc;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (inc) {
      _Include.tx => (LucideIcons.receipt, '거래 내역', '모든 수입·지출·이체'),
      _Include.category => (LucideIcons.pieChart, '카테고리 요약', '카테고리별 합계와 비율'),
      _Include.asset => (LucideIcons.wallet, '자산 스냅샷', '자산 잔액 현황'),
    };
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderSubtle,
          ),
          borderRadius: PRadius.brMd,
        ),
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: PSpace.x4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tokens.bgMuted,
                borderRadius: PRadius.brSm,
              ),
              child: Icon(icon, size: 15, color: tokens.fgSecondary),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: PTypo.bodySm.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.semi)),
                  Text(subtitle,
                      style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
