import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_edit_dialog.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/shared/ds/month_picker/p_month_picker.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/p_swipe_actions.dart';

/// 예산 설정 화면 — 웹 `BudgetManager.tsx`(설정 > 예산 설정) 미러.
///
/// 예산 개요(`BudgetScreen`)의 설정 버튼·"예산 설정하러 가기"·설정 메뉴 '예산 설정'
/// 에서 push 진입한다. 월 선택 + 지난달 복사, 월 총 예산 카드(수정), 카테고리별
/// 예산 리스트(추가·수정·삭제)를 한 페이지에서 제공한다.
class BudgetSettingsScreen extends ConsumerStatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  ConsumerState<BudgetSettingsScreen> createState() =>
      _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends ConsumerState<BudgetSettingsScreen> {
  late DateTime _month = monthStart(DateTime.now());

  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — budgetCompliance 는 keepAlive 라 다른 클라이언트 변경 반영 위해 무효화.
    Future.microtask(() {
      if (mounted) ref.invalidate(budgetComplianceProvider(6));
    });
  }

  BudgetMonthKey get _key => (year: _month.year, month: _month.month);

  String get _monthStartStr => _ymd(_month.year, _month.month, 1);
  String get _monthEndStr => _ymd(
    _month.year,
    _month.month,
    DateTime(_month.year, _month.month + 1, 0).day,
  );

  /// 지난달 예산 복사 — 웹 BudgetManager `copyFromLastMonth` 정합.
  ///
  /// 이미 로드된 [prevBudgets] 를 쓴다(재조회 없음). 이번 달에 같은 key(전체 상한 | 카테고리)의 예산이
  /// 있어 **덮어써서 잃는** 경우만 ds 확인창으로 묻는다 — 잃는 확정이라 criticalSolid, 글은 "복사"
  /// (alert-dialog.md:99). 덮어쓸 것이 없으면 묻지 않고 바로 복사하고, 끝나면 스낵바의 "되돌리기"가
  /// 방금 만든 예산만 지운다(원래 비어 있던 자리라 되돌릴 수 있다 — snackbar.md).
  ///
  /// 항목마다 따로 성공 · 실패를 센다. 일부만 실패하면 이미 만든 것은 남기고 critical 스낵바
  /// "가져오지 못한 예산이 N개 있어요" + "다시 시도"가 뜨며, 다시 시도는 실패한 항목만 다시 한다
  /// (이미 고른 복사의 나머지이므로 확인창을 다시 띄우지 않는다). 스낵바는 한 번에 하나 —
  /// 실패 알림이 먼저, 다시 시도가 다 끝난 뒤에 "가져왔어요 + 되돌리기"(덮어쓴 복사에는 되돌리기가 없다).
  Future<void> _confirmCopyFromPreviousMonth(
    List<Budget> prevBudgets,
    List<Budget> curBudgets,
  ) async {
    if (prevBudgets.isEmpty) return; // 버튼이 비활성이라 도달 불가 — 방어.
    final l = AppLocalizations.of(context);
    final existingByKey = <String, Budget>{
      for (final b in curBudgets) _budgetKey(b): b,
    };
    final overwrite = prevBudgets
        .where((p) => existingByKey.containsKey(_budgetKey(p)))
        .length;
    final created = <int>[];
    if (overwrite == 0) {
      final failed = await _copyItems(prevBudgets, existingByKey, created);
      await _afterCopy(failed, existingByKey, created, undoable: true);
      return;
    }
    var failed = <Budget>[];
    await PAlertDialog.show(
      context,
      title: l.budgetCopyLastMonth,
      description: l.budgetCopyOverwriteMessage(overwrite),
      cancelLabel: l.actionCancel,
      actionLabel: l.calCopy,
      destructive: true,
      // 항목별 실패는 던지지 않고 모아 둔다 — 창은 닫고, 알림은 닫힌 뒤 스낵바가 맡는다.
      onAction: () async {
        failed = await _copyItems(prevBudgets, existingByKey, created);
      },
    );
    await _afterCopy(failed, existingByKey, created, undoable: false);
  }

  String _budgetKey(Budget b) => '${b.categoryRowId ?? 'overall'}';

  /// 복사 뒤 알림 — 실패가 남았으면 그것만(다시 시도), 없으면 [undoable] 일 때 "가져왔어요 + 되돌리기".
  Future<void> _afterCopy(
    List<Budget> failed,
    Map<String, Budget> existingByKey,
    List<int> created, {
    required bool undoable,
  }) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (failed.isNotEmpty) {
      PSnackbar.of(context).show(
        message: l.budgetCopyPartialFailed(failed.length),
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(
          label: l.actionRetry,
          onPressed: () async {
            final still = await _copyItems(failed, existingByKey, created);
            await _afterCopy(still, existingByKey, created, undoable: undoable);
          },
        ),
      );
      return;
    }
    if (!undoable) return;
    PSnackbar.of(context).show(
      message: l.budgetCopiedDone,
      tone: PSnackbarTone.positive,
      action: PSnackbarAction(
        label: l.budgetCopyUndo,
        onPressed: () => _undoCopy(created),
      ),
    );
  }

  /// [items] 를 하나씩 복사한다 — 이번 달에 같은 key 가 있으면 **덮어쓰기**(update), 없으면 생성(create).
  /// 새로 만든 예산의 id 는 [created] 에 쌓는다. 실패한 항목을 돌려준다(던지지 않는다).
  Future<List<Budget>> _copyItems(
    List<Budget> items,
    Map<String, Budget> existingByKey,
    List<int> created,
  ) async {
    final failed = <Budget>[];
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      for (final p in items) {
        try {
          final existing = existingByKey[_budgetKey(p)];
          if (existing != null) {
            await repo.update(id: existing.rowId, budgetAmount: p.budgetAmount);
          } else {
            final id = await repo.create(
              categoryRowId: p.categoryRowId,
              budgetAmount: p.budgetAmount,
              budgetYear: _key.year,
              budgetMonth: _key.month,
            );
            if (id != null) created.add(id);
          }
        } catch (_) {
          failed.add(p);
        }
      }
    } catch (_) {
      return [...items]; // 저장소를 못 얻었다 — 전부 실패.
    } finally {
      // 일부만 됐어도 화면은 서버 값을 다시 읽는다.
      ref.invalidate(monthBudgetsProvider(_key));
      ref.invalidate(budgetComplianceProvider);
    }
    return failed;
  }

  /// 되돌리기 — 방금 만든 이번 달 예산을 id 로 지운다(덮어쓴 것은 없는 경로다). 일괄 삭제 API 는 없어 하나씩 부른다.
  /// 도중에 실패하면 지우지 못한 id 가 남는다 — 조용히 반만 지우지 않고 critical 스낵바 + "다시 시도"로 알리고,
  /// 다시 시도는 남은 id 만 지운다.
  Future<void> _undoCopy(List<int> createdIds) async {
    final l = AppLocalizations.of(context);
    final remaining = [...createdIds];
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      while (remaining.isNotEmpty) {
        await repo.delete(remaining.first);
        remaining.removeAt(0);
      }
    } catch (_) {
      ref.invalidate(monthBudgetsProvider(_key));
      ref.invalidate(budgetComplianceProvider);
      if (mounted) {
        PSnackbar.of(context).show(
          message: l.budgetCopyUndoPartial(remaining.length),
          tone: PSnackbarTone.critical,
          action: PSnackbarAction(
            label: l.actionRetry,
            onPressed: () => _undoCopy(remaining),
          ),
        );
      }
      return;
    }
    ref.invalidate(monthBudgetsProvider(_key));
    ref.invalidate(budgetComplianceProvider);
  }

  void _editOverall(Budget? overallBudget) {
    if (overallBudget != null) {
      showBudgetEditDialog(
        context,
        year: _key.year,
        month: _key.month,
        edit: overallBudget,
      );
    } else {
      showBudgetEditDialog(
        context,
        year: _key.year,
        month: _key.month,
        overallNew: true,
      );
    }
  }

  void _addCategory(List<Budget> budgets) {
    showBudgetEditDialog(
      context,
      year: _key.year,
      month: _key.month,
      usedCategoryIds: budgets
          .map((b) => b.categoryRowId)
          .whereType<int>()
          .toSet(),
    );
  }

  /// 스와이프 삭제 — ds 확인창(Alert Dialog)으로 묻고(삭제는 criticalSolid), 확정하면 지운다.
  /// 실패하면 확인창을 닫고 스낵바(critical + 다시 시도)로 알린다 — 다시 시도는 같은 삭제를 다시 묻는다.
  Future<void> _confirmDeleteCategory(Budget budget, String name) async {
    final l = AppLocalizations.of(context);
    Object? failure;
    final ok = await PAlertDialog.show(
      context,
      title: l.budgetDeleteTitle(name),
      description: l.budgetDeleteConfirm,
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
      onAction: () async {
        try {
          await _deleteCategory(budget);
        } catch (e) {
          failure = e;
        }
      },
    );
    if (ok && failure != null && mounted) {
      PSnackbar.of(context).show(
        message: l.budgetDeleteFailed,
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(
          label: l.actionRetry,
          onPressed: () => _confirmDeleteCategory(budget, name),
        ),
      );
    }
  }

  /// 수정 시트가 쓰던 저장소·무효화 경로를 그대로 쓴다. 실패하면 던진다.
  Future<void> _deleteCategory(Budget budget) async {
    final repo = await ref.read(budgetRepositoryProvider.future);
    await repo.delete(budget.rowId);
    ref.invalidate(monthBudgetsProvider(_key));
    // 준수율은 keepAlive — 지운 예산이 남아 있으면 달성률이 옛 값으로 굳는다.
    ref.invalidate(budgetComplianceProvider);
  }

  void _editCategory(Budget budget, List<Budget> budgets) {
    showBudgetEditDialog(
      context,
      year: _key.year,
      month: _key.month,
      edit: budget,
      usedCategoryIds: budgets
          .map((b) => b.categoryRowId)
          .whereType<int>()
          .toSet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final budgetsAsync = ref.watch(monthBudgetsProvider(_key));
    final summaryAsync = ref.watch(
      rangeSummaryProvider((startDate: _monthStartStr, endDate: _monthEndStr)),
    );
    final categoriesAsync = ref.watch(categoriesProvider);
    // 지난달 복사 버튼 사전 비활성 — 전월 예산이 없거나 로딩 중이면 끈다 (웹 정합).
    final prevMonth = DateTime(_month.year, _month.month - 1, 1);
    final prevBudgetsAsync = ref.watch(
      monthBudgetsProvider((year: prevMonth.year, month: prevMonth.month)),
    );
    final prevBudgets = prevBudgetsAsync.value ?? const <Budget>[];
    final curBudgets = budgetsAsync.value ?? const <Budget>[];
    final copyEnabled = prevBudgets.isNotEmpty;
    final budgets = budgetsAsync.value;
    final summary = summaryAsync.value;
    final masked = ref.watch(hideCardProvider('budget.manage'));

    void retry() {
      if (budgetsAsync.hasError) ref.invalidate(monthBudgetsProvider(_key));
      if (summaryAsync.hasError) {
        ref.invalidate(
          rangeSummaryProvider((
            startDate: _monthStartStr,
            endDate: _monthEndStr,
          )),
        );
      }
    }

    final failed =
        (budgetsAsync.hasError && budgets == null) ||
        (summaryAsync.hasError && summary == null);

    final children = <Widget>[
      // 달 줄 + 지난달 복사 — 흰 면 맨 위 4 + 한 줄(웹 BudgetManager 모바일 헤더 정합)
      BudgetMonthRow(
        month: _month,
        onPick: () async {
          final picked = await showPMonthPicker(context, initial: _month);
          if (picked != null) setState(() => _month = picked);
        },
        trailing: PButton(
          label: l.budgetCopyLastMonthBtn,
          prefixIcon: LucideIcons.copy,
          variant: PButtonVariant.neutralWeak,
          size: PButtonSize.small,
          onPressed: copyEnabled
              ? () => _confirmCopyFromPreviousMonth(prevBudgets, curBudgets)
              : null,
        ),
      ),
    ];

    if (failed) {
      children.add(
        BudgetSection(
          topPadding: PSpacing.x3,
          children: [
            BudgetFailure(title: l.budgetManagerLoadFailed, onRetry: retry),
          ],
        ),
      );
    } else if (budgets == null || summary == null) {
      children.addAll(const [_TotalSkeleton(), _ListSkeleton()]);
    } else {
      final categories = categoriesAsync.value ?? const <ExpenseCategory>[];
      final spentByCategory = _spentByCategoryFromSummary(summary);

      Budget? overallBudget;
      final categoryBudgets = <Budget>[];
      for (final b in budgets) {
        if (b.categoryRowId == null) {
          overallBudget = b;
        } else {
          categoryBudgets.add(b);
        }
      }
      final monthlyLimit = overallBudget?.budgetAmount ?? 0;
      final categoryLimitSum = categoryBudgets.fold<int>(
        0,
        (s, b) => s + b.budgetAmount,
      );
      // 할당 가능 = 월 총 예산 − 카테고리 한도 합 (음수면 초과 할당).
      final remaining = monthlyLimit - categoryLimitSum;

      // 예산 추가 가능 카테고리 = EXPENSE 최상위(부모)만 — 전부 보유 시 비활성화.
      final usedIds = categoryBudgets
          .map((b) => b.categoryRowId)
          .whereType<int>()
          .toSet();
      final selectable = categories
          .where((c) => c.expenseType == 'EXPENSE' && c.parentRowId == null)
          .toList();
      final allBudgeted =
          selectable.isNotEmpty &&
          selectable.every((c) => usedIds.contains(c.rowId));
      // 웹 정합: 카테고리 로딩 중에도 추가 비활성(빈 칩 다이얼로그 방지).
      final addDisabled = allBudgeted || categoriesAsync.isLoading;

      children.add(
        _TotalSection(
          month: _month.month,
          overallBudget: overallBudget,
          monthlyLimit: monthlyLimit,
          totalSpent: summary.totalExpense,
          categoryLimitSum: categoryLimitSum,
          remaining: remaining,
          masked: masked,
          onEdit: () => _editOverall(overallBudget),
        ),
      );
      // 목록 제목 위: 앞 구역 아래 24 + 8 + 제목 위 8 = 보이는 40
      children.add(const SizedBox(height: PSpacing.x2));
      children.add(
        PListHeader(
          title: l.budgetByCategoryCount(categoryBudgets.length),
          variant: PListHeaderVariant.boldSolid,
          action: PTextButton(
            label: l.budgetAdd,
            onPressed: addDisabled ? null : () => _addCategory(budgets),
          ),
        ),
      );
      children.add(
        categoryBudgets.isEmpty
            ? BudgetEmptyLine(l.budgetNoCategorySet)
            : PList(
                children: [
                  for (final b in categoryBudgets)
                    // 밀면 수정·삭제가 바로 나온다. 탭은 그대로 수정으로 — 스와이프는
                    // 지름길이지 유일한 경로가 아니다(spec swipe-actions.md · WCAG 2.1.1).
                    PSwipeActions(
                      key: ValueKey('budget-${b.rowId}'),
                      groupTag: 'budget-settings-list',
                      actions: [
                        PSwipeAction(
                          label: l.actionEdit,
                          icon: LucideIcons.pencil,
                          kind: PSwipeKind.primary,
                          onSelect: () => _editCategory(b, budgets),
                        ),
                        PSwipeAction(
                          label: l.actionDelete,
                          icon: LucideIcons.trash2,
                          kind: PSwipeKind.destructive,
                          // 확인은 ds 확인창이 받는다 — 트레이를 먼저 닫은 뒤 화면 context 로 띄운다.
                          onSelect: () => _confirmDeleteCategory(
                            b,
                            budgetRowName(
                              l,
                              categories.byRowId(b.categoryRowId!),
                              b,
                            ),
                          ),
                        ),
                      ],
                      child: BudgetCategoryRow(
                        budget: b,
                        category: categories.byRowId(b.categoryRowId!),
                        spent: spentByCategory[b.categoryRowId] ?? 0,
                        masked: masked,
                        onTap: () => _editCategory(b, budgets),
                        overText: l.budgetOverLimit,
                      ),
                    ),
                ],
              ),
      );
      children.add(const SizedBox(height: PSpacing.x3));
    }

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-16 14)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.budgetSetup,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      // 흰 면 하나 — 카드 · 줄 사이 선 없음. 구역과 줄이 제 좌우 24 를 갖는다(I-08 18)
      body: PScreenBandBody(
        child: PPullToRefresh(
          onRefresh: () async {
            ref.invalidate(monthBudgetsProvider(_key));
            ref.invalidate(
              rangeSummaryProvider((
                startDate: _monthStartStr,
                endDate: _monthEndStr,
              )),
            );
            await ref.read(monthBudgetsProvider(_key).future);
          },
          child: ListView(padding: EdgeInsets.zero, children: children),
        ),
      ),
    );
  }
}

Map<int, int> _spentByCategoryFromSummary(RangeSummary? summary) {
  final map = <int, int>{};
  if (summary == null) return map;
  for (final c in summary.categoryBreakdown) {
    final cid = c.categoryRowId;
    if (cid != null) {
      map.update(cid, (v) => v + c.totalAmount, ifAbsent: () => c.totalAmount);
    }
    final pid = c.parentCategoryRowId;
    if (pid != null) {
      map.update(pid, (v) => v + c.totalAmount, ifAbsent: () => c.totalAmount);
    }
  }
  return map;
}

String _ymd(int y, int m, int d) =>
    '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

class _Gap extends StatelessWidget {
  const _Gap(this.height);

  final double height;

  @override
  Widget build(BuildContext context) =>
      BudgetFull(child: SizedBox(height: height));
}

/// 월 총 예산 구역 — 눈썹 + 글 버튼, 큰 숫자, 막대(넘치면 fg-critical), 키-값 줄 셋, 초과 할당 안내.
class _TotalSection extends StatelessWidget {
  const _TotalSection({
    required this.month,
    required this.overallBudget,
    required this.monthlyLimit,
    required this.totalSpent,
    required this.categoryLimitSum,
    required this.remaining,
    required this.masked,
    required this.onEdit,
  });
  final int month;
  final Budget? overallBudget;
  final int monthlyLimit;
  final int totalSpent;
  final int categoryLimitSum;
  final int remaining;
  final bool masked;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    String won(int n, {String sign = ''}) => budgetWon(n, masked, sign: sign);
    final has = overallBudget != null;
    return BudgetSection(
      topPadding: PSpacing.x3,
      children: [
        // 첫 줄: 눈썹 + 오른쪽 글 버튼(수정 · 설정). 글 버튼(36)이 줄을 늘리지 않게 줄 높이는 눈썹(18)이고, 버튼은 위아래로 내민다
        PTouchTargetScope(
          slack: 9,
          child: SizedBox(
            height: 18,
            child: OverflowBox(
              minHeight: kTextButtonHeight,
              maxHeight: kTextButtonHeight,
              child: Row(
                children: [
                  Expanded(child: BudgetEyebrow(l.budgetMonthTotal(month))),
                  PTextButton(
                    label: has ? l.actionEdit : l.budgetSetup,
                    onPressed: onEdit,
                    bleedEnd: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        const _Gap(PSpacing.x3),
        if (has)
          BudgetBigAmount(amount: won(monthlyLimit))
        else
          Text(
            l.budgetNotSet,
            style: PTypography.t5.copyWith(color: c.fgNeutralSubtle),
          ),
        if (has) ...[
          const _Gap(PSpacing.x4),
          // 넘치면 fg-critical — 써서 넘쳐도 파랑이던 것을 고친다
          BudgetBar(
            value: totalSpent.toDouble(),
            max: monthlyLimit.toDouble(),
            label: l.budgetMonthTotal(month),
            meaning: PProgressMeaning.limit,
          ),
        ],
        const _Gap(PSpacing.x3),
        budgetKvList(context, [
          BudgetKv(l.budgetUsed, won(totalSpent)),
          BudgetKv(l.budgetAllocated, won(categoryLimitSum)),
          BudgetKv(
            l.budgetAllocatable,
            won(remaining.abs(), sign: remaining >= 0 ? '+' : '−'),
            color: remaining < 0 ? c.fgCritical : c.fgBrand,
          ),
        ]),
        if (has && remaining < 0) ...[
          const _Gap(PSpacing.x3),
          PCallout(
            tone: PCalloutTone.critical,
            description: l.budgetOverAllocatedWarning(won(-remaining)),
          ),
        ],
      ],
    );
  }
}

/// 로딩 스켈레톤 — 총 예산 구역 + 목록 제목 + 줄 3.
class _TotalSkeleton extends StatelessWidget {
  const _TotalSkeleton();

  @override
  Widget build(BuildContext context) => BudgetSection(
    topPadding: PSpacing.x3,
    children: [
      PSkeleton.text(PTypography.t3, width: 96),
      const _Gap(PSpacing.x3),
      PSkeleton.text(PTypography.t9, width: 160),
      const _Gap(PSpacing.x4),
      const PSkeleton(
        height: PProgressBar.height,
        radius: PSkeletonRadius.full,
      ),
      const _Gap(PSpacing.x3),
      for (var i = 0; i < 3; i++)
        PSkeleton.text(PTypography.t5, width: double.infinity),
    ],
  );
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PSpacing.x6),
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x6,
              vertical: PSpacing.x3,
            ),
            child: Column(
              spacing: PSpacing.x4,
              children: [
                Row(
                  spacing: PSpacing.x3,
                  children: [
                    const PSkeleton(
                      width: 40,
                      height: 40,
                      radius: PSkeletonRadius.r12,
                    ),
                    Expanded(child: PSkeleton.text(PTypography.t5)),
                    PSkeleton.text(PTypography.t5, width: 72),
                  ],
                ),
                const PSkeleton(
                  height: PProgressBar.height,
                  radius: PSkeletonRadius.full,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
