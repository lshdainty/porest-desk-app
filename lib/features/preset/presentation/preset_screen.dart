import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import '../application/preset_providers.dart';
import '../domain/expense_template.dart';
import 'preset_edit_dialog.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';

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
      showPSnackBar(context, '"${p.templateName}" 거래로 기록됐습니다');
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
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
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('프리셋'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        onPressed: () => showPresetEditDialog(context),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(presetListProvider);
          await ref.read(presetListProvider.future);
        },
        child: listAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(PSpace.x16),
            child: PListSkeleton(rows: 5),
          ),
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
              padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
              children: [
                Text('탭 한 번으로 거래 기록',
                    style:
                        PTypo.caption.copyWith(color: t.fgSecondary)),
                const SizedBox(height: PSpace.x12),
                PCard(
                  variant: PCardVariant.bordered,
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
                          PDivider(indent: PSpace.x16),
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
    final fg = resolveChartColor(context, category?.color, fallback: tokens.fgBrand);
    final bg = softBg(context, fg);
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
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.tile(36)),
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
              krwSigned(template.amount, masked, sign: isExpense ? '-' : '+'),
              style: PTypo.bodySm.copyWith(
                  color: isExpense
                      ? tokens.statusDanger
                      : tokens.statusSuccess,
                  fontWeight: PFontWeight.bold),
            ),
            const SizedBox(width: 4),
            PButton.icon(
              icon: LucideIcons.zap,
              size: PButtonSize.sm,
              iconColor: tokens.fgBrand,
              tooltip: '오늘 거래로 기록',
              loading: useBusy,
              onPressed: anyBusy ? null : onUseNow,
            ),
          ],
        ),
      ),
    );
  }
}
