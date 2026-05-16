import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import '../application/preset_providers.dart';
import '../domain/expense_template.dart';
import 'preset_edit_dialog.dart';

class PresetScreen extends ConsumerStatefulWidget {
  const PresetScreen({super.key});

  @override
  ConsumerState<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends ConsumerState<PresetScreen> {
  int? _busyUseId;

  Future<void> _useNow(ExpenseTemplate p) async {
    if (_busyUseId != null) return;
    setState(() => _busyUseId = p.rowId);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      final today = DateTime.now();
      final ymd =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await repo.use(p.rowId, expenseDate: ymd);
      ref.invalidate(presetListProvider);
      ref.invalidate(monthExpensesProvider(
          (year: today.year, month: today.month)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${p.templateName}" 거래로 기록됐습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _busyUseId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final listAsync = ref.watch(presetListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('프리셋'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () => showPresetEditDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(presetListProvider);
          await ref.read(presetListProvider.future);
        },
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              Text('프리셋 로드 실패\n$e',
                  style: PTypo.bodySm.copyWith(color: t.statusDanger)),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  PEmptyState(
                    icon: LucideIcons.zap,
                    message: '등록된 프리셋이 없습니다',
                    subMessage: '자주 입력하는 거래를 프리셋으로 저장하세요',
                  ),
                ],
              );
            }
            final categories =
                categoriesAsync.value ?? const <ExpenseCategory>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x80),
              children: [
                Text('탭 한 번으로 거래 기록',
                    style:
                        PTypo.caption.copyWith(color: t.fgSecondary)),
                const SizedBox(height: PSpace.x12),
                Container(
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    borderRadius: PRadius.brLg,
                    border: Border.all(color: t.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        _PresetRow(
                          template: items[i],
                          category:
                              categories.byRowId(items[i].categoryRowId),
                          masked: settings.hideAmounts,
                          tokens: t,
                          useBusy: _busyUseId == items[i].rowId,
                          anyBusy: _busyUseId != null,
                          onEdit: () => showPresetEditDialog(context,
                              edit: items[i]),
                          onUseNow: () => _useNow(items[i]),
                        ),
                        if (i < items.length - 1)
                          Divider(
                              height: 1,
                              color: t.borderSubtle,
                              indent: PSpace.x16),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.template,
    required this.category,
    required this.masked,
    required this.tokens,
    required this.useBusy,
    required this.anyBusy,
    required this.onEdit,
    required this.onUseNow,
  });
  final ExpenseTemplate template;
  final ExpenseCategory? category;
  final bool masked;
  final PorestTokens tokens;
  final bool useBusy;
  final bool anyBusy;
  final VoidCallback onEdit;
  final VoidCallback onUseNow;

  @override
  Widget build(BuildContext context) {
    final fg = parseColor(category?.color, fallback: tokens.fgBrand);
    final bg = softBg(fg);
    final isExpense = template.expenseType == 'EXPENSE';
    final used = template.useCount ?? 0;

    return InkWell(
      onTap: anyBusy ? null : onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x12, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(lucideByName(category?.icon), size: 18, color: fg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(template.templateName,
                            style: PTypo.body.copyWith(
                                color: tokens.fgPrimary,
                                fontWeight: PFontWeight.semi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if ((template.lockAmount ?? 'N') == 'Y') ...[
                        const SizedBox(width: 4),
                        Icon(LucideIcons.lock,
                            size: 11, color: tokens.fgTertiary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${template.categoryName ?? '카테고리'} · ${template.assetName ?? '계좌'}'
                    '${used > 0 ? ' · $used회 사용' : ''}',
                    style:
                        PTypo.caption.copyWith(color: tokens.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Text(
              '${isExpense ? '-' : '+'}${krwMasked(template.amount, masked)}',
              style: PTypo.bodySm.copyWith(
                  color: isExpense
                      ? tokens.statusDanger
                      : tokens.statusSuccess,
                  fontWeight: PFontWeight.bold),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: '오늘 거래로 기록',
              onPressed: anyBusy ? null : onUseNow,
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              constraints:
                  const BoxConstraints.tightFor(width: 32, height: 32),
              icon: useBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(LucideIcons.zap, color: tokens.fgBrand),
            ),
          ],
        ),
      ),
    );
  }
}
