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
import '../../../shared/widgets/p_back_button.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_dropdown_menu.dart';
import '../../../shared/widgets/p_toggle.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import '../application/recurring_providers.dart';
import '../domain/recurring_transaction.dart';
import 'recurring_settings_drawer.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';

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
    setState(() => _busyToggleId = it.rowId);
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      await repo.toggle(it.rowId);
      ref.invalidate(recurringListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '변경 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) setState(() => _busyToggleId = null);
    }
  }

  Future<void> _delete(RecurringTransaction it) async {
    final ok = await showPConfirmDialog(
      context,
      title: '반복 거래 삭제',
      message: '"${_displayTitle(it)}" 반복 설정을 삭제할까요?\n이미 기록된 거래는 그대로 남습니다.',
      confirmLabel: '삭제',
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
        '삭제 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) setState(() => _busyDeleteId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final listAsync = ref.watch(recurringListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('반복 거래'),
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
                message: '반복 거래를 불러오지 못했습니다\n$e',
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
                horizontal: PSpace.x20,
                vertical: PSpace.x24,
              ),
              children: [
                _SummaryCard(
                  active: stats.active,
                  paused: stats.paused,
                  monthlyExpense: stats.monthlyExpense,
                  monthlyIncome: stats.monthlyIncome,
                  masked: settings.hideAmounts,
                  tokens: t,
                ),
                if (stats.next7.isNotEmpty) ...[
                  const SizedBox(height: PSpace.x12),
                  _UpcomingCard(
                    items: stats.next7,
                    categories: categories,
                    masked: settings.hideAmounts,
                    tokens: t,
                  ),
                ],
                const SizedBox(height: PSpace.x12),
                PCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더: 전체 목록 (좌) + 필터 개별 toggle (우, 배경 없음)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          PSpace.x16,
                          PSpace.x12,
                          PSpace.x16,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1행: 전체 목록 (좌) + 추가 버튼 (우, accent 강조)
                            Row(
                              children: [
                                Text(
                                  '전체 목록',
                                  style: PTypo.bodySm.copyWith(
                                    color: t.fgPrimary,
                                    fontWeight: PFontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                PButton(
                                  label: '추가',
                                  icon: LucideIcons.plus,
                                  variant: PButtonVariant.accent,
                                  size: PButtonSize.sm,
                                  onPressed: () =>
                                      showRecurringSettingsDialog(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: PSpace.x8),
                            // 2행: 필터 single toggle
                            Row(
                              children: [
                                for (final e in <(_Filter, String)>[
                                  (_Filter.all, '전체 ${items.length}'),
                                  (
                                    _Filter.expense,
                                    '지출 ${items.where((i) => i.expenseType == 'EXPENSE' && i.isActive == 'Y').length}',
                                  ),
                                  (
                                    _Filter.income,
                                    '수입 ${items.where((i) => i.expenseType == 'INCOME' && i.isActive == 'Y').length}',
                                  ),
                                  (
                                    _Filter.paused,
                                    '정지 ${items.where((i) => i.isActive != 'Y').length}',
                                  ),
                                ]) ...[
                                  PToggle(
                                    pressed: _filter == e.$1,
                                    onChanged: (_) =>
                                        setState(() => _filter = e.$1),
                                    label: e.$2,
                                    size: PToggleSize.sm,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (filtered.isEmpty)
                        _EmptyState(filter: _filter, tokens: t)
                      else
                        Column(
                          children: [
                            for (int i = 0; i < filtered.length; i++) ...[
                              _RecurringRow(
                                item: filtered[i],
                                category: categories.byRowId(
                                  filtered[i].categoryRowId,
                                ),
                                masked: settings.hideAmounts,
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
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      variant: PCardVariant.shadow,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: '활성 반복',
                  icon: LucideIcons.repeat,
                  value: '$active개',
                  color: tokens.fgPrimary,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: '일시정지',
                  icon: LucideIcons.pauseCircle,
                  value: '$paused개',
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
                  label: '매월 고정 지출',
                  icon: LucideIcons.trendingDown,
                  value: krwSigned(monthlyExpense, masked, sign: '-'),
                  color: tokens.statusDanger,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: '매월 고정 수입',
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
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      variant: PCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '다가오는 7일',
                style: PTypo.bodySm.copyWith(
                  color: tokens.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length}건 예정',
                style: PTypo.caption.copyWith(color: tokens.fgTertiary),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
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
              isToday ? '오늘' : 'D-$days',
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
                  _displayTitle(item),
                  style: PTypo.bodySm.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.assetName ?? '계좌 없음'} · ${_summary(item)}',
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
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x12,
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
                          _displayTitle(item),
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
                        const PBadge(
                          label: '일시정지',
                          variant: PBadgeVariant.secondary,
                        ),
                      ],
                      if (item.maxOccurrences != null) ...[
                        const SizedBox(width: 6),
                        PBadge(
                          label:
                              '${item.executedCount}/${item.maxOccurrences}회',
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
                    '${_summary(item)} · ${item.assetName ?? '계좌 없음'}'
                    '${item.nextExecutionDate != null ? ' · 다음 ${item.nextExecutionDate!.substring(5).replaceAll('-', '/')}' : ''}',
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
                color: isExpense ? tokens.statusDanger : tokens.fgIncome,
                fontWeight: PFontWeight.bold,
              ),
            ),
            PDropdownMenu(
              enabled: !anyBusy,
              entries: [
                PDropdownItem(
                  icon: isActive ? LucideIcons.pause : LucideIcons.play,
                  label: isActive ? '일시정지' : '시작',
                  onTap: onToggle,
                ),
                PDropdownItem(
                  icon: LucideIcons.pencil,
                  label: '수정',
                  onTap: onEdit,
                ),
                const PDropdownDivider(),
                PDropdownItem(
                  icon: LucideIcons.trash2,
                  label: '삭제',
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

/// 반복 거래 skeleton — 통계 카드 + 예정 카드 + 리스트 행 4개.
class _RecurringSkeleton extends StatelessWidget {
  const _RecurringSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
        vertical: PSpace.x24,
      ),
      children: [
        // 통계 카드 (활성/일시중지/월 지출·수입 4열)
        PCard(
          variant: PCardVariant.shadow,
          padding: const EdgeInsets.all(PSpace.x16),
          child: Column(
            children: [
              Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    Expanded(
                      child: Column(
                        children: [
                          const PSkeleton(width: 24, height: 24),
                          const SizedBox(height: 4),
                          PSkeleton.line(width: 48, height: 12),
                          const SizedBox(height: 2),
                          PSkeleton.line(width: 32, height: 10),
                        ],
                      ),
                    ),
                    if (i < 3) Container(width: 1, height: 36, color: t.borderSubtle),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x12),
        // 반복 거래 리스트
        PCard(
          variant: PCardVariant.bordered,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < 4; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i < 3
                        ? Border(bottom: BorderSide(color: t.borderSubtle))
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x16,
                    vertical: PSpace.x12,
                  ),
                  child: Row(
                    children: [
                      const PSkeleton(width: 36, height: 36),
                      const SizedBox(width: PSpace.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PSkeleton.line(width: i.isEven ? 120 : 100),
                            const SizedBox(height: 4),
                            PSkeleton.line(width: 80, height: 12),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const PSkeleton.line(width: 72),
                          const SizedBox(height: 4),
                          PSkeleton.line(width: 48, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.tokens});
  final _Filter filter;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final msg = switch (filter) {
      _Filter.all => '아직 등록된 반복 거래가 없습니다',
      _Filter.expense => '활성 반복 지출이 없습니다',
      _Filter.income => '활성 반복 수입이 없습니다',
      _Filter.paused => '일시정지된 반복 거래가 없습니다',
    };
    return PEmptyState(
      icon: LucideIcons.repeat,
      message: msg,
      subMessage: '우하단 + 버튼으로 새 반복 거래를 등록하세요',
      padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
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
            label: '다시 시도',
            variant: PButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

String _displayTitle(RecurringTransaction it) =>
    it.merchant ?? it.description ?? it.categoryName ?? '반복 거래';

String _summary(RecurringTransaction it) {
  String core = switch (it.frequency) {
    'DAILY' => '매일',
    'WEEKLY' => '매주',
    'MONTHLY' => '매월',
    'YEARLY' => '매년',
    _ => it.frequency,
  };
  if (it.frequency == 'WEEKLY' && it.dayOfWeek != null) {
    const dows = ['', '월', '화', '수', '목', '금', '토', '일'];
    final idx = it.dayOfWeek!;
    if (idx >= 1 && idx <= 7) core = '매주 ${dows[idx]}';
  } else if (it.frequency == 'MONTHLY' && it.dayOfMonth != null) {
    core = '매월 ${it.dayOfMonth}일';
  }
  final end = it.endDate != null ? '~${it.endDate}' : '무기한';
  final notify = it.notifyDayBefore ? ' · 알림' : '';
  return '$core · $end$notify';
}
