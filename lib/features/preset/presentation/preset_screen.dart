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
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_toggle.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import '../application/preset_providers.dart';
import '../domain/expense_template.dart';
import 'preset_edit_dialog.dart';

enum _SortKey { used, recent, name }

class PresetScreen extends ConsumerStatefulWidget {
  const PresetScreen({super.key});

  @override
  ConsumerState<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends ConsumerState<PresetScreen> {
  _SortKey _sortBy = _SortKey.used;

  List<ExpenseTemplate> _sorted(List<ExpenseTemplate> items) {
    final arr = [...items];
    switch (_sortBy) {
      case _SortKey.used:
        arr.sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
      case _SortKey.recent:
        arr.sort((a, b) => (b.lastUsedAt ?? '').compareTo(a.lastUsedAt ?? ''));
      case _SortKey.name:
        // 한국어 로케일 오름차순 (Dart 기본 코드포인트 비교 = 한글 가나다순 정합).
        arr.sort((a, b) => a.templateName.compareTo(b.templateName));
    }
    return arr;
  }

  Future<void> _confirmDelete(ExpenseTemplate p) async {
    final ok = await showPConfirmDialog(
      context,
      title: '프리셋 삭제',
      message: '"${p.templateName}" 프리셋을 삭제할까요? 이미 저장된 거래 내역에는 영향이 없습니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      await repo.delete(p.rowId);
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      showPSnackBar(context, '프리셋이 삭제되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '삭제 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final listAsync = ref.watch(presetListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final isLoading = listAsync.isLoading || categoriesAsync.isLoading;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('프리셋 관리'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(presetListProvider);
          await ref.read(presetListProvider.future);
        },
        child: listAsync.when(
          loading: () => _content(
            t: t,
            items: const [],
            categories: const [],
            masked: settings.hideAmounts,
            isLoading: true,
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.lg),
            children: [
              Text(
                '프리셋 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger),
              ),
            ],
          ),
          data: (items) => _content(
            t: t,
            items: items,
            categories: categoriesAsync.value ?? const <ExpenseCategory>[],
            masked: settings.hideAmounts,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  Widget _content({
    required PorestTokens t,
    required List<ExpenseTemplate> items,
    required List<ExpenseCategory> categories,
    required bool masked,
    required bool isLoading,
  }) {
    final totalUses = items.fold<int>(0, (s, p) => s + (p.useCount ?? 0));
    final expenseCount = items.where((p) => p.expenseType == 'EXPENSE').length;
    final incomeCount = items.where((p) => p.expenseType == 'INCOME').length;
    final sorted = _sorted(items);

    return ListView(
      padding: const EdgeInsets.all(PSpace.lg),
      children: [
        // (1) 안내 배너
        _IntroBanner(),
        const SizedBox(height: PSpace.x16),

        // (2) 통계 3카드
        _StatsRow(
          isLoading: isLoading,
          presetCount: items.length,
          totalUses: totalUses,
          expenseCount: expenseCount,
          incomeCount: incomeCount,
        ),
        const SizedBox(height: PSpace.x16),

        // (3) 정렬 툴바
        _Toolbar(
          sortBy: _sortBy,
          onSort: (v) => setState(() => _sortBy = v),
          onAdd: () => showPresetEditDialog(context),
        ),
        const SizedBox(height: PSpace.x16),

        // (4) 리스트 카드 — web 은 shadow Card (border 없음)
        PCard(
          variant: PCardVariant.shadow,
          padding: EdgeInsets.zero,
          child: isLoading
              ? const _ListSkeleton()
              : (sorted.isEmpty
                    ? const _EmptyState()
                    : Column(
                        children: [
                          for (int i = 0; i < sorted.length; i++)
                            _PresetRow(
                              template: sorted[i],
                              category: sorted[i].categoryRowId == null
                                  ? null
                                  : categories.byRowId(
                                      sorted[i].categoryRowId!,
                                    ),
                              masked: masked,
                              tokens: t,
                              divider: i > 0,
                              onEdit: () => showPresetEditDialog(
                                context,
                                edit: sorted[i],
                              ),
                              onDelete: () => _confirmDelete(sorted[i]),
                            ),
                        ],
                      )),
        ),
      ],
    );
  }
}

// ── (1) 안내 배너 ──────────────────────────────────────────────────────────
class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.bgBrandSubtle,
        border: Border.all(color: t.borderBrand),
        borderRadius: PRadius.brLg, // --radius-tile = 12
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.bookmark, size: 16, color: t.fgPrimary),
          ),
          const SizedBox(width: PSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프리셋이란?',
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: PFontSize.bodySm, // --text-label-sm = 13
                    fontWeight: PFontWeight.bold,
                    color: t.fgBrandStrong,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '자주 쓰는 내역(점심·커피·교통비 등)을 미리 저장해두면, 내역 추가 화면에서 한 번 탭으로 '
                  '카테고리·결제수단·내역을 모두 채워넣어요. 금액만 바꿔서 단건으로 저장하기 좋습니다.',
                  style: PTypo.caption.copyWith(
                    color: t.fgSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── (2) 통계 3카드 ─────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.isLoading,
    required this.presetCount,
    required this.totalUses,
    required this.expenseCount,
    required this.incomeCount,
  });
  final bool isLoading;
  final int presetCount;
  final int totalUses;
  final int expenseCount;
  final int incomeCount;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: PSpace.x8),
            const Expanded(child: _StatSkeleton()),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _StatCard(label: '저장된 프리셋', value: '$presetCount'),
        ),
        const SizedBox(width: PSpace.x8),
        Expanded(
          child: _StatCard(label: '누적 사용', value: '$totalUses회'),
        ),
        const SizedBox(width: PSpace.x8),
        Expanded(
          child: _StatCard(
            label: '지출 / 수입',
            value: '$expenseCount / $incomeCount',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // web 다크 --bg-sunken = surface-input — 앱 등가는 bgMuted.
      // (앱 bgSunken 다크는 canvas 와 동일색이라 카드가 배경에 묻힘)
      decoration: BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.micro, // --text-badge = 11
              fontWeight: PFontWeight.semi,
              color: t.fgTertiary,
              letterSpacing: 0.44, // 0.04em × 11
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.titleMd, // --text-title-md = 18
              fontWeight: PFontWeight.bold,
              color: t.fgPrimary,
              letterSpacing: PTracking.tight(PFontSize.titleMd),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          PSkeleton(width: 64, height: 12),
          SizedBox(height: 6),
          PSkeleton(width: 48, height: 24),
        ],
      ),
    );
  }
}

// ── (3) 정렬 툴바 ──────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.sortBy,
    required this.onSort,
    required this.onAdd,
  });
  final _SortKey sortBy;
  final ValueChanged<_SortKey> onSort;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: PSpace.x8,
      spacing: PSpace.x8,
      children: [
        PToggleGroupSingle<_SortKey>(
          value: sortBy,
          size: PToggleSize.sm,
          items: const [
            PToggleGroupItem(value: _SortKey.used, label: '사용 많은 순'),
            PToggleGroupItem(value: _SortKey.recent, label: '최근 사용'),
            PToggleGroupItem(value: _SortKey.name, label: '이름순'),
          ],
          onChanged: onSort,
        ),
        PButton(
          label: '프리셋 추가',
          icon: LucideIcons.plus,
          variant: PButtonVariant.accent,
          size: PButtonSize.sm,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

// ── (4-row) 프리셋 행 ──────────────────────────────────────────────────────
class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.template,
    required this.category,
    required this.masked,
    required this.tokens,
    required this.divider,
    required this.onEdit,
    required this.onDelete,
  });
  final ExpenseTemplate template;
  final ExpenseCategory? category;
  final bool masked;
  final PorestTokens tokens;
  final bool divider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final cat = category;
    final hasCat = cat != null;
    final fg = hasCat
        ? resolveChartColor(context, cat.color, fallback: t.fgBrandStrong)
        : t.fgTertiary;
    final bg = hasCat ? softBg(context, fg) : t.bgSunken;
    final isExpense = template.expenseType == 'EXPENSE';
    final lock = (template.lockAmount ?? 'N') == 'Y';
    final amount = template.amount;
    final used = template.useCount ?? 0;

    // 금액 줄: 고정금액 사용 + 값 있으면 부호 + KRW, 아니면 em-dash.
    final String amountText;
    if (lock && amount != null) {
      if (masked) {
        amountText = kHideMask;
      } else {
        amountText = '${isExpense ? '−' : '+'}${krw(amount)}';
      }
    } else {
      amountText = '—';
    }

    return Container(
      decoration: divider
          ? BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // (a) 아이콘 박스 40×40
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: PRadius.tile(40),
            ),
            alignment: Alignment.center,
            child: Icon(
              lucideByName(
                hasCat ? cat.icon : null,
                fallback: hasCat ? LucideIcons.tag : LucideIcons.helpCircle,
              ),
              size: hasCat ? 20 : 18,
              color: fg,
            ),
          ),
          const SizedBox(width: PSpace.md),

          // (b) 중앙 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        template.templateName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.body, // --text-body-sm = 14
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                    ),
                    if (!isExpense) ...[
                      const SizedBox(width: 6),
                      _MiniBadge(
                        label: '수입',
                        bg: t.bgIncomeSubtle,
                        fg: t.fgIncome,
                        weight: PFontWeight.bold,
                      ),
                    ],
                    if (!lock) ...[
                      const SizedBox(width: 6),
                      _MiniBadge(
                        label: '금액 비움',
                        bg: t.bgSunken,
                        fg: t.fgTertiary,
                        weight: PFontWeight.semi,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                _MetaLine(
                  categoryName: template.categoryName,
                  merchant: template.merchant,
                  tokens: t,
                ),
              ],
            ),
          ),
          const SizedBox(width: PSpace.md),

          // (c) 금액 블록
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 12.5,
                  fontWeight: PFontWeight.bold,
                  color: isExpense ? t.fgExpense : t.fgIncome,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$used회',
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 10,
                  color: t.fgTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(width: PSpace.x8),

          // (d) 액션 버튼
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PButton.icon(
                icon: LucideIcons.pencil,
                size: PButtonSize.sm,
                tooltip: '수정',
                onPressed: onEdit,
              ),
              const SizedBox(width: 4),
              PButton.icon(
                icon: LucideIcons.trash2,
                size: PButtonSize.sm,
                iconColor: t.fgExpense,
                tooltip: '삭제',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.bg,
    required this.fg,
    required this.weight,
  });
  final String label;
  final Color bg;
  final Color fg;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: PRadius.brXs),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: PFontSize.micro, // --text-badge = 11
          fontWeight: weight,
          color: fg,
        ),
      ),
    );
  }
}

/// 메타 라인: `카테고리 · merchant` (모바일은 assetName 미표시).
class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.categoryName,
    required this.merchant,
    required this.tokens,
  });
  final String? categoryName;
  final String? merchant;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final style = PTypo.caption.copyWith(color: t.fgTertiary);
    final hasMerchant = merchant != null && merchant!.isNotEmpty;
    return Row(
      children: [
        Flexible(
          flex: 0,
          child: Text(
            categoryName ?? '카테고리 없음',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (hasMerchant) ...[
          Text(' · ', style: style),
          Flexible(
            child: Text(
              merchant!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}

// ── 빈 상태 ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: t.bgSunken,
              borderRadius: PRadius.brLg,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.bookmark, size: 22, color: t.fgTertiary),
          ),
          const SizedBox(height: 12),
          Text(
            '저장된 프리셋이 없어요',
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.body, // --text-body-sm = 14
              fontWeight: PFontWeight.bold,
              color: t.fgPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '자주 쓰는 내역을 추가해 매번 입력하는 수고를 줄여보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.bodySm, // --text-label-sm = 13
              color: t.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 스켈레톤 (5행) ─────────────────────────────────────────────────────────
class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        for (int i = 0; i < 5; i++)
          Container(
            decoration: i > 0
                ? BoxDecoration(
                    border: Border(top: BorderSide(color: t.borderSubtle)),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const PSkeleton(
                  width: 40,
                  height: 40,
                  borderRadius: PRadius.brMd,
                ),
                const SizedBox(width: PSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      PSkeleton(width: 128, height: 16),
                      SizedBox(height: 6),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.66,
                        child: PSkeleton(height: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PSpace.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    PSkeleton(width: 56, height: 16),
                    SizedBox(height: 6),
                    PSkeleton(width: 32, height: 12),
                  ],
                ),
                const SizedBox(width: PSpace.x8),
                Row(
                  children: const [
                    PSkeleton(
                      width: 32,
                      height: 32,
                      borderRadius: PRadius.brMd,
                    ),
                    SizedBox(width: 4),
                    PSkeleton(
                      width: 32,
                      height: 32,
                      borderRadius: PRadius.brMd,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
