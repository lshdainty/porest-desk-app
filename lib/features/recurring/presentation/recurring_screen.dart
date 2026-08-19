import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_dropdown_menu.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/recurring/application/recurring_providers.dart';
import 'package:porest_desk_app/features/recurring/domain/recurring_transaction.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_settings_drawer.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

enum _Filter { all, expense, income, paused }

/// 반복 거래 매니저.
///
/// - 상단 통계 (활성/매월 고정 지출·수입/일시정지)
/// - 다가오는 7일 카드
/// - 필터 칩 + 목록 (재생/일시정지 토글, 편집, 삭제)
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  _Filter _filter = _Filter.all;
  int? _busyToggleId;
  int? _busyDeleteId;

  Future<void> _toggle(RecurringTransaction it) async {
    if (_busyToggleId != null) return;
    final l = AppLocalizations.of(context);
    setState(() => _busyToggleId = it.rowId);
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      await repo.toggle(it.rowId);
      ref.invalidate(recurringListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${l.recurringToggleFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) setState(() => _busyToggleId = null);
    }
  }

  Future<void> _delete(RecurringTransaction it) async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.recurringDeleteTitle,
      message: l.recurringDeleteConfirm(_displayTitle(l, it)),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busyDeleteId = it.rowId);
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      await repo.delete(it.rowId);
      ref.invalidate(recurringListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${l.recurringDeleteFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) setState(() => _busyDeleteId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(recurringListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.navRecurring),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(recurringListProvider);
          await ref.read(recurringListProvider.future);
        },
        child: listAsync.when(
          loading: () => const _RecurringSkeleton(),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              _ErrorBox(
                message: '${l.recurringLoadError}\n$e',
                onRetry: () => ref.invalidate(recurringListProvider),
              ),
            ],
          ),
          data: (items) {
            final categories =
                categoriesAsync.value ?? const <ExpenseCategory>[];
            final stats = _computeStats(items);
            final filtered = _applyFilter(items, _filter);

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x24,
                vertical: PSpace.x24,
              ),
              children: [
                _SummaryCard(
                  active: stats.active,
                  paused: stats.paused,
                  monthlyExpense: stats.monthlyExpense,
                  monthlyIncome: stats.monthlyIncome,
                  masked: ref.watch(hideCardProvider('etc.recurring')),
                  tokens: t,
                ),
                if (stats.next7.isNotEmpty) ...[
                  const SizedBox(height: PSpace.x24),
                  _UpcomingCard(
                    items: stats.next7,
                    categories: categories,
                    masked: ref.watch(hideCardProvider('etc.recurring')),
                    tokens: t,
                  ),
                ],
                const SizedBox(height: PSpace.x24),
                // 카드 다이어트 — 리스트 셸 카드 제거, 플랫.
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더: 전체 목록 (좌) + 필터 개별 toggle (우, 배경 없음)
                      Padding(
                        // 라벨·토글은 inset 0(최상위 폭) — 행만 살짝 inset(가계부 목록 뷰 패턴).
                        padding: const EdgeInsets.fromLTRB(0, PSpace.x12, 0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1행: 라벨만
                            Text(
                              l.recurringAllList,
                              // 웹 --text-body-sm(14) 정합 — 앱 bodySm 은 13이라 body(14) 사용.
                              style: PTypo.body.copyWith(
                                color: t.fgPrimary,
                                fontWeight: PFontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: PSpace.x4), // 라벨↔toggle 4(사용자 결정)
                            // 2행: 필터 토글(좌, 넘치면 가로 스크롤·스크롤바 없음) + 추가 버튼(우)
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    // Flutter SingleChildScrollView 는 기본적으로 스크롤바를 그리지 않음
                                    // (Scrollbar 위젯 미적용) — 웹 scrollbar-hide 와 동일 효과.
                                    child: PTabs<_Filter>(
                                      value: _filter,
                                      onChanged: (v) => setState(() => _filter = v),
                                      variant: PTabsVariant.pills,
                                      size: PTabsSize.sm,
                                      items: [
                                        PTabItem(
                                            value: _Filter.all,
                                            label: l.recurringFilterAll(items.length)),
                                        PTabItem(
                                            value: _Filter.expense,
                                            label: l.recurringFilterExpense(items
                                                .where((i) => i.expenseType == 'EXPENSE' && i.isActive == 'Y')
                                                .length)),
                                        PTabItem(
                                            value: _Filter.income,
                                            label: l.recurringFilterIncome(items
                                                .where((i) => i.expenseType == 'INCOME' && i.isActive == 'Y')
                                                .length)),
                                        PTabItem(
                                            value: _Filter.paused,
                                            label: l.recurringFilterPaused(
                                                items.where((i) => i.isActive != 'Y').length)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: PSpace.x8),
                                PButton(
                                  label: l.recurringAdd,
                                  icon: LucideIcons.plus,
                                  variant: PButtonVariant.accent,
                                  size: PButtonSize.sm,
                                  onPressed: () =>
                                      showRecurringSettingsDialog(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (filtered.isEmpty)
                        _EmptyState(tokens: t)
                      else
                        Column(
                          children: [
                            for (int i = 0; i < filtered.length; i++) ...[
                              _RecurringRow(
                                item: filtered[i],
                                category: categories.byRowId(
                                  filtered[i].categoryRowId,
                                ),
                                masked: ref.watch(hideCardProvider('etc.recurring')),
                                tokens: t,
                                anyBusy:
                                    _busyToggleId != null ||
                                    _busyDeleteId != null,
                                onToggle: () => _toggle(filtered[i]),
                                onEdit: () => showRecurringSettingsDialog(
                                  context,
                                  recurring: filtered[i],
                                ),
                                onDelete: () => _delete(filtered[i]),
                              ),
                              if (i < filtered.length - 1) const PDivider(),
                            ],
                          ],
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<RecurringTransaction> _applyFilter(
    List<RecurringTransaction> items,
    _Filter f,
  ) {
    return items
        .where((it) {
          final active = it.isActive == 'Y';
          switch (f) {
            case _Filter.all:
              return true;
            case _Filter.expense:
              return it.expenseType == 'EXPENSE' && active;
            case _Filter.income:
              return it.expenseType == 'INCOME' && active;
            case _Filter.paused:
              return !active;
          }
        })
        .toList(growable: false);
  }

  _Stats _computeStats(List<RecurringTransaction> items) {
    final active = items.where((i) => i.isActive == 'Y').toList();
    final monthlyExpense = active
        .where((i) => i.expenseType == 'EXPENSE' && i.frequency == 'MONTHLY')
        .fold<int>(0, (s, i) => s + i.amount.abs());
    final monthlyIncome = active
        .where((i) => i.expenseType == 'INCOME' && i.frequency == 'MONTHLY')
        .fold<int>(0, (s, i) => s + i.amount);

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final next7 =
        active.where((i) {
          if (i.nextExecutionDate == null) return false;
          final d = DateTime.parse(i.nextExecutionDate!.substring(0, 10));
          final ds = DateTime(d.year, d.month, d.day);
          final diff = ds.difference(todayStart).inDays;
          return diff >= 0 && diff <= 7;
        }).toList()..sort(
          (a, b) =>
              (a.nextExecutionDate ?? '').compareTo(b.nextExecutionDate ?? ''),
        );

    return _Stats(
      active: active.length,
      paused: items.length - active.length,
      monthlyExpense: monthlyExpense,
      monthlyIncome: monthlyIncome,
      next7: next7,
    );
  }
}

class _Stats {
  const _Stats({
    required this.active,
    required this.paused,
    required this.monthlyExpense,
    required this.monthlyIncome,
    required this.next7,
  });
  final int active;
  final int paused;
  final int monthlyExpense;
  final int monthlyIncome;
  final List<RecurringTransaction> next7;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.active,
    required this.paused,
    required this.monthlyExpense,
    required this.monthlyIncome,
    required this.masked,
    required this.tokens,
  });
  final int active;
  final int paused;
  final int monthlyExpense;
  final int monthlyIncome;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // raised 카드(가계부 취합·예산 히어로 정합, 사용자 결정) — padding 16 미러.
    return PCard(
      variant: PCardVariant.raised,
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l.recurringStatActive,
                  icon: LucideIcons.repeat,
                  value: l.recurringCount(active),
                  color: tokens.fgPrimary,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: l.recurringPaused,
                  icon: LucideIcons.pauseCircle,
                  value: l.recurringCount(paused),
                  color: tokens.fgTertiary,
                  tokens: tokens,
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          PDivider(),
          const SizedBox(height: PSpace.x12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l.recurringMonthlyExpense,
                  icon: LucideIcons.trendingDown,
                  value: krwSigned(monthlyExpense, masked, sign: '-'),
                  color: tokens.fgExpense,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: l.recurringMonthlyIncome,
                  icon: LucideIcons.trendingUp,
                  value: krwSigned(monthlyIncome, masked, sign: '+'),
                  color: tokens.fgIncome,
                  tokens: tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.tokens,
  });
  final String label;
  final IconData icon;
  final String value;
  final Color color;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: tokens.fgTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: PTypo.caption.copyWith(
                color: tokens.fgTertiary,
                fontWeight: PFontWeight.semi,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: PTypo.h4.copyWith(color: color, fontWeight: PFontWeight.bold),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.items,
    required this.categories,
    required this.masked,
    required this.tokens,
  });
  final List<RecurringTransaction> items;
  final List<ExpenseCategory> categories;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    // 라벨은 inset 0(최상위 폭), 타일만 좌우 살짝 inset(10) — 전체 목록·가계부 패턴 정합.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.recurringUpcoming,
              // 웹 --text-body-sm(14) 정합 — 앱 bodySm 은 13이라 body(14) 사용.
              style: PTypo.body.copyWith(
                color: tokens.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              l.recurringUpcomingCount(items.length),
              style: PTypo.caption.copyWith(color: tokens.fgTertiary),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        // 다가오는 7일 행은 헤더와 좌우 정렬(inset 0) — 추가 좌우 inset 제거(사용자 결정, web 정합).
        Column(
          children: [
            for (final it in items) ...[
              _UpcomingRow(
                item: it,
                category: categories.byRowId(it.categoryRowId),
                todayStart: todayStart,
                masked: masked,
                tokens: tokens,
              ),
              if (it != items.last) const SizedBox(height: PSpace.x4),
            ],
          ],
        ),
      ],
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.category,
    required this.todayStart,
    required this.masked,
    required this.tokens,
  });
  final RecurringTransaction item;
  final ExpenseCategory? category;
  final DateTime todayStart;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final due = item.nextExecutionDate != null
        ? DateTime.parse(item.nextExecutionDate!.substring(0, 10))
        : todayStart;
    final dueStart = DateTime(due.year, due.month, due.day);
    final days = dueStart.difference(todayStart).inDays;
    final isToday = days == 0;
    final isExpense = item.expenseType == 'EXPENSE';

    final fg = resolveChartColor(
      context,
      category?.color,
      fallback: tokens.fgBrand,
    );
    final bg = softBg(context, fg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? tokens.bgBrandSubtle : tokens.bgMuted,
        borderRadius: PRadius.brSm,
        border: Border.all(
          color: isToday ? tokens.borderBrand : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isToday ? tokens.bgBrand : tokens.bgSurface,
              borderRadius: PRadius.brXs,
            ),
            alignment: Alignment.center,
            child: Text(
              isToday ? l.recurringToday : l.dashDaysLeft(days),
              style: PTypo.caption.copyWith(
                color: isToday ? tokens.fgOnBrand : tokens.fgSecondary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: PSpace.x8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: bg, borderRadius: PRadius.tile(28)),
            alignment: Alignment.center,
            child: Icon(lucideByName(category?.icon), size: 14, color: fg),
          ),
          const SizedBox(width: PSpace.x8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayTitle(l, item),
                  style: PTypo.bodySm.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.assetName ?? l.recurringNoAccount} · ${_summary(l, item)}',
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          Text(
            krwSigned(item.amount.abs(), masked,
                sign: isExpense ? '-' : '+', mask: '••••'),
            style: PTypo.bodySm.copyWith(
              color: isExpense ? tokens.fgExpense : tokens.fgIncome,
              fontWeight: PFontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.item,
    required this.category,
    required this.masked,
    required this.tokens,
    required this.anyBusy,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final RecurringTransaction item;
  final ExpenseCategory? category;
  final bool masked;
  final PorestTokens tokens;
  final bool anyBusy;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isActive = item.isActive == 'Y';
    final isExpense = item.expenseType == 'EXPENSE';
    final fg = resolveChartColor(
      context,
      category?.color,
      fallback: tokens.fgBrand,
    );
    final bg = softBg(context, fg);

    return Opacity(
      opacity: isActive ? 1.0 : 0.55,
      child: Padding(
        // 좌우 0 — 라벨·토글과 같은 지점에서 시작한다(설정 리스트 공통 규칙).
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: PSpace.x12,
        ),
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
                        child: Text(
                          _displayTitle(l, item),
                          style: PTypo.body.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: PFontWeight.semi,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 6),
                        PBadge(
                          label: l.recurringPaused,
                          variant: PBadgeVariant.secondary,
                        ),
                      ],
                      if (item.maxOccurrences != null) ...[
                        const SizedBox(width: 6),
                        PBadge(
                          label: l.recurringOccurrences(
                            item.executedCount,
                            item.maxOccurrences!,
                          ),
                          variant: PBadgeVariant.softWarning,
                        ),
                      ],
                      if (item.autoLog) ...[
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.zap,
                          size: 12,
                          color: tokens.fgBrandStrong,
                        ),
                      ],
                      if (item.notifyDayBefore) ...[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.bell,
                          size: 12,
                          color: tokens.fgTertiary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_summary(l, item)} · ${item.assetName ?? l.recurringNoAccount}'
                    '${item.nextExecutionDate != null ? ' · ${l.recurringNext} ${item.nextExecutionDate!.substring(5).replaceAll('-', '/')}' : ''}',
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Text(
              krwSigned(item.amount.abs(), masked,
                  sign: isExpense ? '-' : '+', mask: '••••'),
              style: PTypo.bodySm.copyWith(
                color: isExpense ? tokens.fgExpense : tokens.fgIncome,
                fontWeight: PFontWeight.bold,
              ),
            ),
            PDropdownMenu(
              enabled: !anyBusy,
              entries: [
                PDropdownItem(
                  icon: isActive ? LucideIcons.pause : LucideIcons.play,
                  label: isActive ? l.recurringPaused : l.recurringStart,
                  onTap: onToggle,
                ),
                PDropdownItem(
                  icon: LucideIcons.pencil,
                  label: l.actionEdit,
                  onTap: onEdit,
                ),
                const PDropdownDivider(),
                PDropdownItem(
                  icon: LucideIcons.trash2,
                  label: l.actionDelete,
                  onTap: onDelete,
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 반복 거래 skeleton — 데이터 영역만 placeholder.
///
/// 실제 로딩-후와 1:1 정합:
/// - 통계 카드 = shadow PCard, 2×2 그리드(가운데 PDivider) — 각 칸 `_Stat`
///   (icon12+label / 값 h4).
/// - 리스트 카드 = shadow PCard. 헤더의 "전체 목록"/"추가" 버튼은 정적 틀이라
///   실제 렌더, 데이터에 의존하는 필터 칩 카운트와 행은 placeholder.
class _RecurringSkeleton extends StatelessWidget {
  const _RecurringSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x24,
        vertical: PSpace.x24,
      ),
      children: [
        // 통계 — raised 카드 스켈레톤 (실제와 동일 2×2 그리드).
        PCard(
          variant: PCardVariant.raised,
          padding: const EdgeInsets.all(PSpace.x16),
          child: Column(
            children: [
              Row(
                children: const [
                  Expanded(child: _StatSkeleton()),
                  Expanded(child: _StatSkeleton()),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              const PDivider(),
              const SizedBox(height: PSpace.x12),
              Row(
                children: const [
                  Expanded(child: _StatSkeleton()),
                  Expanded(child: _StatSkeleton()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x12),
        // 반복 거래 리스트 — 플랫 스켈레톤.
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: "전체 목록"(정적) + "추가"(정적) — 실제 렌더.
              Padding(
                // 라벨·토글은 inset 0(최상위 폭) — 행만 살짝 inset(가계부 목록 뷰 패턴).
                padding: const EdgeInsets.fromLTRB(0, PSpace.x12, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l.recurringAllList,
                          // 웹 --text-body-sm(14) 정합 — 앱 bodySm 은 13이라 body(14) 사용(스켈레톤 정합).
                          style: PTypo.body.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: PSpace.x4),
                    // 필터 칩(카운트=데이터) placeholder + 추가 버튼 — 실제 렌더 정합(같은 줄).
                    Row(
                      children: [
                        const PSkeleton(width: 56, height: 32, borderRadius: PRadius.brSm),
                        const SizedBox(width: PSpace.x4),
                        const PSkeleton(width: 56, height: 32, borderRadius: PRadius.brSm),
                        const SizedBox(width: PSpace.x4),
                        const PSkeleton(width: 56, height: 32, borderRadius: PRadius.brSm),
                        const Spacer(),
                        PButton(
                          label: l.recurringAdd,
                          icon: LucideIcons.plus,
                          variant: PButtonVariant.accent,
                          size: PButtonSize.sm,
                          onPressed: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 행 4개 — 실제 _RecurringRow 와 동일 구조/치수, PDivider 구분.
              for (int i = 0; i < 4; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0, // 실제 행과 같은 값
                    vertical: PSpace.x12,
                  ),
                  child: Row(
                    children: [
                      // 아이콘 36×36, PRadius.tile(36)=11.
                      PSkeleton(
                        width: 36,
                        height: 36,
                        borderRadius: PRadius.tile(36),
                      ),
                      const SizedBox(width: PSpace.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목(body 14) → 2px → 메타(caption 12).
                            PSkeleton.line(width: i.isEven ? 120 : 100, height: 14),
                            const SizedBox(height: 2),
                            PSkeleton.line(width: 140, height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: PSpace.x8),
                      // 금액(bodySm 13 bold).
                      const PSkeleton.line(width: 64, height: 13),
                      const SizedBox(width: PSpace.x8),
                      // 더보기 메뉴 아이콘 버튼(32×32 brMd).
                      const PSkeleton(
                        width: 32,
                        height: 32,
                        borderRadius: PRadius.brMd,
                      ),
                    ],
                  ),
                ),
                if (i < 3) const PDivider(),
              ],
            ],
          ),
      ],
    );
  }
}

/// _SummaryCard 의 단일 `_Stat` placeholder — icon12+label / 값 h4(18).
class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            PSkeleton(width: 12, height: 12),
            SizedBox(width: 4),
            PSkeleton.line(width: 48, height: 12),
          ],
        ),
        const SizedBox(height: 4),
        const PSkeleton.line(width: 64, height: 18),
      ],
    );
  }
}

/// 빈 상태 — 웹 RecurringManager 정합: 아이콘·서브문구 없이 중앙 단문(필터 공통).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(PSpace.x40),
      child: Center(
        child: Text(
          l.recurringEmpty,
          style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.statusDangerSubtle,
        borderRadius: PRadius.brLg,
      ),
      child: Column(
        children: [
          Text(message, style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
          const SizedBox(height: PSpace.x8),
          PButton(
            label: l.actionRetry,
            variant: PButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

String _displayTitle(AppLocalizations l, RecurringTransaction it) =>
    it.merchant ?? it.description ?? it.categoryName ?? l.navRecurring;

String _summary(AppLocalizations l, RecurringTransaction it) {
  String core = switch (it.frequency) {
    'DAILY' => l.calRepeatDaily,
    'WEEKLY' => l.calRepeatWeekly,
    'MONTHLY' => l.calRepeatMonthly,
    'YEARLY' => l.calRepeatYearly,
    _ => it.frequency,
  };
  if (it.frequency == 'WEEKLY' && it.dayOfWeek != null) {
    final idx = it.dayOfWeek!;
    if (idx >= 1 && idx <= 7) {
      core = '${l.calRepeatWeekly} ${weekdayLabels(mondayFirst: true)[idx - 1]}';
    }
  } else if (it.frequency == 'MONTHLY' && it.dayOfMonth != null) {
    core = '${l.calRepeatMonthly} ${l.dayN(it.dayOfMonth!)}';
  }
  final end = it.endDate != null ? '~${it.endDate}' : l.recurringIndefinite;
  final notify = it.notifyDayBefore ? ' · ${l.recurringNotifyShort}' : '';
  return '$core · $end$notify';
}
