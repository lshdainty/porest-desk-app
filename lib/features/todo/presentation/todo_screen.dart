import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/constellation/application/constellation_providers.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';
import 'package:porest_desk_app/features/constellation/presentation/constellation_painter.dart';
import 'package:porest_desk_app/features/constellation/presentation/night_sky_hero.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_meta.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_detail_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_project_management_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_tag_management_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_dropdown_menu.dart';
import 'package:porest_desk_app/shared/widgets/p_floating_action_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 할일 — 모바일 원장 (design todo-mobile.jsx TodoMobileLedger 미러).
///
/// 상단 고정: 월 네비+필터 / 오늘 남은 할 일+별빛 인사이트+[밤하늘] 토글 /
/// 접이식 캘린더(선택 주 1줄 ↔ 월 전체, 셀에 별자리★·구름·건수 마크).
/// 아래: 일별 그룹 리스트 — 스크롤 스파이 ↔ 캘린더 선택 동기화.
/// 밤하늘 게임 요소는 [밤하늘] 패널 + 전용 화면(/night-sky, /forest-report)으로 분리.
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  /// 전체(status=null) fetch — 상세/칸반과 동일 family 키 공유.
  static const TodoFilter _allFilter = (status: null, priority: null);

  late DateTime _month = monthStart(DateTime.now());
  String? _selected;
  bool _expanded = false;
  bool _skyOpen = false;
  bool _compact = false; // 스크롤 시 상태 영역 접힘 (design txm-pin--compact)

  // 필터 시트 상태 — 태그·우선순위 다중 + 완료 숨김.
  Set<String> _fTags = {};
  Set<String> _fPrios = {};
  bool _hideDone = false;
  bool get _filterActive =>
      _fTags.isNotEmpty || _fPrios.isNotEmpty || _hideDone;

  final Map<String, GlobalKey> _dayKeys = {};
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _collapseKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  bool _lock = false;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selected = _ymd(today);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 태그 — 서버 태그명 그대로(빈 값은 기본 태그).
  static String _tagOf(Todo x) {
    final v = x.category?.trim();
    return (v == null || v.isEmpty) ? kTodoDefaultTag : v;
  }

  /// 별빛 가중치 — 중요 3 · 보통 2 · 여유 1 (design FOREST_WEIGHT).
  static int _weight(String? prio) => switch (prio) {
        'HIGH' => 3,
        'LOW' => 1,
        _ => 2,
      };

  void _lockFor(int ms) {
    _lock = true;
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(milliseconds: ms), () => _lock = false);
  }

  /// 스크롤 스파이 — compact 히스테리시스(72/24) + 맨 위 그룹 → 선택일 동기.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final st = _scrollCtrl.offset;
    // 콘텐츠가 짧으면 접힘(−collapse 높이) 순간 offset이 maxScrollExtent에
    // clamp돼 해제 임계 아래로 떨어지며 접힘↔펼침 무한 플리커 — 접힌 뒤에도
    // 진입 임계(72) 위에 남을 스크롤 여유가 있을 때만 진입.
    final collapseH = _compact
        ? 0.0
        : (_collapseKey.currentContext?.size?.height ?? 0.0);
    final canStay =
        _scrollCtrl.position.maxScrollExtent - collapseH > 72;
    final next = _compact ? st > 24 : st > 72 && canStay;
    if (next != _compact) {
      setState(() {
        _compact = next;
        if (next) _expanded = false;
      });
    }
    if (_lock) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    final listTop = listBox.localToGlobal(Offset.zero).dy;
    double best = double.negativeInfinity;
    String? cur;
    for (final e in _dayKeys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy - listTop;
      if (top <= 28 && top > best) {
        best = top;
        cur = e.key;
      }
    }
    if (cur != null && cur != _selected) {
      setState(() => _selected = cur);
    }
  }

  void _goMonth(int dir) {
    final next = DateTime(_month.year, _month.month + dir, 1);
    final today = DateTime.now();
    setState(() {
      _month = next;
      _expanded = false;
      _selected = (today.year == next.year && today.month == next.month)
          ? _ymd(today)
          : null;
    });
    _lockFor(800);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _scrollToDay(String ds) {
    _lockFor(800);
    setState(() {
      _expanded = false;
      _compact = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _dayKeys[ds]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300), alignment: 0.02);
    });
  }

  Future<void> _toggleDone(Todo x) async {
    final l = AppLocalizations.of(context);
    final wasDone = x.done;
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.setStatus(x.rowId, wasDone ? 'PENDING' : 'COMPLETED');
      ref.invalidate(todoListProvider);
      // 별빛 적립/회수 부수효과 — 별자리 상태 일괄 갱신.
      final constToday = ref.read(constellationTodayProvider).value;
      invalidateConstellation(ref);
      if (!mounted) return;
      // 완료 전환 시 별빛 토스트 (design starToast) — 서버 재계산 전 클라 예측.
      if (!wasDone && constToday != null && !constToday.collected) {
        final gain = _weight(x.priority);
        final left = constToday.goal - (constToday.points + gain);
        showPSnackBar(
          context,
          left <= 0
              ? l.tdmStarToastCollected(gain)
              : l.tdmStarToastGain(gain, left),
          severity: PSnackSeverity.success,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${l.todoActionFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    }
  }

  Future<void> _openFilter(List<Todo> all) async {
    final tags = <String>{for (final x in all) _tagOf(x)}.toList()..sort();
    await showPSheet<void>(
      context,
      title: AppLocalizations.of(context).expFilter,
      shrinkWrap: true,
      contentBuilder: (ctx, _) => _FilterSheetBody(
        allTags: tags,
        tags: _fTags,
        prios: _fPrios,
        hideDone: _hideDone,
        onApply: (tags, prios, hideDone) {
          setState(() {
            _fTags = tags;
            _fPrios = prios;
            _hideDone = hideDone;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(todoListProvider(_allFilter));

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.todoTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PDropdownMenu(
            iconColor: t.fgSecondary,
            iconSize: 24,
            entries: [
              PDropdownItem(
                label: l.todoProjectMgmt,
                onTap: () => showTodoProjectManagementDialog(context),
              ),
              PDropdownItem(
                label: l.todoTagMgmt,
                onTap: () => showTodoTagManagementDialog(context),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        tooltip: l.todoAdd,
        onPressed: () => showTodoEditDialog(context),
      ),
      body: listAsync.when(
        loading: () => const _LedgerSkeleton(),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(PSpace.x16),
          children: [
            Text(
              '${l.todoLoadError}\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDanger),
            ),
          ],
        ),
        data: (all) => _buildBody(context, t, l, all),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, PorestTokens t, AppLocalizations l, List<Todo> all) {
    final constToday = ref.watch(constellationTodayProvider).value;
    final sky = ref.watch(constellationSkyProvider).value ?? const <SkyDay>[];
    final skyByDate = {for (final d in sky) d.date: d};

    final today = DateTime.now();
    final todayYmd = _ymd(today);
    final ymPrefix =
        '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';

    bool passFilter(Todo x) =>
        (_fTags.isEmpty || _fTags.contains(_tagOf(x))) &&
        (_fPrios.isEmpty || _fPrios.contains(x.priority ?? 'MEDIUM')) &&
        (!_hideDone || !x.done);

    // 이 달 할일(마감일 기준) + 마감일 없는 할일(맨 아래 별도 그룹 — 유실 방지).
    final monthTodos = all
        .where((x) => x.due != null && _ymd(x.due!).startsWith(ymPrefix))
        .where(passFilter)
        .toList();
    final noDue = all.where((x) => x.due == null).where(passFilter).toList();

    // 일별 그룹 (asc) — 캘린더 마크·리스트 공유.
    final byDay = <String, List<Todo>>{};
    for (final x in monthTodos) {
      (byDay[_ymd(x.due!)] ??= <Todo>[]).add(x);
    }
    final dayKeysSorted = byDay.keys.toList()..sort();
    for (final g in byDay.values) {
      g.sort((a, b) {
        final pr =
            todoPrioRank(b.priority).compareTo(todoPrioRank(a.priority));
        if (pr != 0) return pr;
        return (a.due ?? today).compareTo(b.due ?? today);
      });
    }
    _dayKeys.removeWhere(
        (k, _) => !byDay.containsKey(k) && k != _kNoDueGroup);
    for (final k in dayKeysSorted) {
      _dayKeys.putIfAbsent(k, () => GlobalKey());
    }
    if (noDue.isNotEmpty) {
      _dayKeys.putIfAbsent(_kNoDueGroup, () => GlobalKey());
    }

    final todayLeft =
        all.where((x) => !x.done && x.due != null && _ymd(x.due!) == todayYmd).length;

    // ── 상단 고정(pin) ──
    final pin = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _MonthNav(
          label: monthOnly(_month),
          onPrev: () => _goMonth(-1),
          onNext: () => _goMonth(1),
          filterActive: _filterActive,
          filterCount: _fTags.length + _fPrios.length + (_hideDone ? 1 : 0),
          onOpenFilter: () => _openFilter(all),
          tokens: t,
        ),
        // 오늘 상태 + [밤하늘] 토글 — 스크롤 시 접힘.
        ClipRect(
          key: _collapseKey,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _compact
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(PSpace.x24, 8, PSpace.x24, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    todayLeft > 0
                                        ? l.tdmTodayLeft(todayLeft)
                                        : l.tdmTodayDone,
                                    style: TextStyle(
                                      fontFamily: PTypo.sans,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.56,
                                      height: 1.15,
                                      color: t.fgPrimary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  if (constToday != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 7),
                                      child: _StarlightHint(
                                          today: constToday, t: t),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: PSpace.x12),
                            _SkyToggleBtn(
                              on: _skyOpen,
                              label: l.tdmNightSkyBtn,
                              onTap: () =>
                                  setState(() => _skyOpen = !_skyOpen),
                              tokens: t,
                            ),
                          ],
                        ),
                      ),
                      // 밤하늘 패널 — 히어로 + 관측 리포트/도감 진입 (design .tdm-sky).
                      if (_skyOpen && constToday != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              PSpace.x24, 14, PSpace.x24, 0),
                          child: Column(
                            children: [
                              NightSkyHero(
                                today: constToday,
                                doneToday: all
                                    .where((x) =>
                                        x.done &&
                                        (x.completedAt ?? '')
                                            .startsWith(todayYmd))
                                    .length,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: PButton(
                                      label: l.forestReportTitle,
                                      icon: LucideIcons.telescope,
                                      variant: PButtonVariant.outline,
                                      size: PButtonSize.sm,
                                      onPressed: () =>
                                          context.push('/forest-report'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: PButton(
                                      label: l.nightSkyTitle,
                                      icon: LucideIcons.sparkles,
                                      variant: PButtonVariant.outline,
                                      size: PButtonSize.sm,
                                      onPressed: () =>
                                          context.push('/night-sky'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        // 접이식 캘린더 — 셀 마크: 수집★/구름/남은 건수/완료 체크.
        _LedgerCalendar(
          month: _month,
          selected: _selected,
          expanded: _expanded,
          byDay: byDay,
          skyByDate: skyByDate,
          constToday: constToday,
          onSelect: (ds) {
            setState(() => _selected = ds);
            if (byDay.containsKey(ds)) _scrollToDay(ds);
          },
          onToggleExpand: () => setState(() => _expanded = !_expanded),
          tokens: t,
        ),
        Container(height: 1, color: t.borderDefault),
      ],
    );

    // ── 일별 리스트 ──
    final listChildren = <Widget>[
      if (dayKeysSorted.isEmpty && noDue.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.x24, 56, PSpace.x24, 20),
          child: Center(
            child: Column(
              children: [
                Icon(
                  _filterActive ? LucideIcons.filterX : LucideIcons.checkCheck,
                  size: 36,
                  color: t.fgTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  _filterActive
                      ? l.tdmEmptyFilter
                      : l.tdmEmptyMonth(monthOnly(_month)),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _filterActive ? l.tdmEmptyFilterDesc : l.tdmEmptyMonthDesc,
                  textAlign: TextAlign.center,
                  style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
        )
      else ...[
        for (final key in dayKeysSorted)
          KeyedSubtree(
            key: _dayKeys[key],
            child: _DayGroup(
              ymd: key,
              items: byDay[key]!,
              today: today,
              onToggle: _toggleDone,
              onTap: (x) => showTodoDetailDialog(context, x),
            ),
          ),
        if (noDue.isNotEmpty)
          KeyedSubtree(
            key: _dayKeys[_kNoDueGroup],
            child: _DayGroup(
              ymd: null,
              items: noDue,
              today: today,
              onToggle: _toggleDone,
              onTap: (x) => showTodoDetailDialog(context, x),
            ),
          ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pin,
        Expanded(
          child: RefreshIndicator(
            color: t.bgBrand,
            onRefresh: () async {
              ref.invalidate(todoListProvider(_allFilter));
              invalidateConstellation(ref);
              await ref.read(todoListProvider(_allFilter).future);
            },
            child: ListView(
              key: _listKey,
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(PSpace.x24, 0, PSpace.x24, 96),
              children: listChildren,
            ),
          ),
        ),
      ],
    );
  }
}

const _kNoDueGroup = '__no_due__';

/// 별빛 인사이트 한 줄 — "별빛 l/g · N개 더 모으면 {별자리} 수집" / 수집 완료.
class _StarlightHint extends StatelessWidget {
  const _StarlightHint({required this.today, required this.t});
  final ConstellationToday today;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = constellationName(today.constellation);
    final lit = today.points > today.goal ? today.goal : today.points;
    final text = today.collected
        ? l.tdmCollectedHint(name, today.streak)
        : l.tdmStarlightHint(lit, today.goal, today.goal - lit, name);
    // 하이라이트(별빛 n/g · 별자리명)는 문장 통짜 색 대신 브랜드 굵게 — l10n 어순 안전.
    return Text(
      text,
      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
    );
  }
}

/// 월 네비 — ‹ M월 › + 우측 필터 (design .txm-monthnav, 할일은 추가 버튼 없음 — FAB 담당).
class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.filterActive,
    required this.filterCount,
    required this.onOpenFilter,
    required this.tokens,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool filterActive;
  final int filterCount;
  final VoidCallback onOpenFilter;
  final PorestTokens tokens;

  Widget _btn(IconData icon, VoidCallback onTap,
      {Color? bg, Color? fg, Widget? badge}) {
    return Material(
      color: bg ?? Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 19, color: fg ?? tokens.fgSecondary),
              if (badge != null) Positioned(right: -2, top: -2, child: badge),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpace.x24),
      child: Row(
        children: [
          _btn(LucideIcons.chevronLeft, onPrev),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.17,
                color: t.fgPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _btn(LucideIcons.chevronRight, onNext),
          const Spacer(),
          _btn(
            LucideIcons.slidersHorizontal,
            onOpenFilter,
            bg: filterActive ? t.bgBrandSubtle : null,
            fg: filterActive ? t.fgBrandStrong : t.fgSecondary,
            badge: filterActive && filterCount > 0
                ? PBadge(label: '$filterCount', variant: PBadgeVariant.primary)
                : null,
          ),
        ],
      ),
    );
  }
}

/// [밤하늘] 토글 버튼 (design .txm-sumbtn 재사용 + sparkles).
class _SkyToggleBtn extends StatelessWidget {
  const _SkyToggleBtn({
    required this.on,
    required this.label,
    required this.onTap,
    required this.tokens,
  });
  final bool on;
  final String label;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Material(
      color: on ? t.bgBrandSubtle : Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: on ? t.borderBrand : t.borderDefault),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 13,
                color: on ? t.fgBrandStrong : t.fgPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: PTypo.bodySm.copyWith(
                  color: on ? t.fgBrandStrong : t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 접이식 캘린더 — 접힘: 선택 주 1줄 / 펼침: 월 전체 (design .txm-cal + 할일 마크).
class _LedgerCalendar extends StatelessWidget {
  const _LedgerCalendar({
    required this.month,
    required this.selected,
    required this.expanded,
    required this.byDay,
    required this.skyByDate,
    required this.constToday,
    required this.onSelect,
    required this.onToggleExpand,
    required this.tokens,
  });
  final DateTime month;
  final String? selected;
  final bool expanded;
  final Map<String, List<Todo>> byDay;
  final Map<String, SkyDay> skyByDate;
  final ConstellationToday? constToday;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleExpand;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final today = DateTime.now();
    final todayStr = _TodoScreenState._ymd(today);
    final firstDow = DateTime(month.year, month.month, 1).weekday % 7;
    final dim = DateTime(month.year, month.month + 1, 0).day;
    final cells = <({int d, String ds})?>[];
    for (var i = 0; i < firstDow; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= dim; d++) {
      cells.add((
        d: d,
        ds: '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <List<({int d, String ds})?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    var selWeek =
        weeks.indexWhere((w) => w.any((c) => c != null && c.ds == selected));
    if (selWeek < 0) {
      selWeek =
          weeks.indexWhere((w) => w.any((c) => c != null && c.ds == todayStr));
    }
    if (selWeek < 0) selWeek = 0;

    Color numColor(String ds, int dow) {
      if (ds.compareTo(todayStr) > 0) return t.fgTertiary;
      // 일요일 — 다크에서 light variant 스왑(웹 --color-cat-red 정합, 사용자 결정)
      if (dow == 0) return chartRedOf(context);
      if (dow == 6) return t.fgBrand;
      return t.fgPrimary;
    }

    /// 셀 아래 마크 — 오늘: 수집★/남은 N건, 과거: 수집★·구름, 그 외: N건/완료 체크.
    Widget mark(String ds) {
      final items = byDay[ds];
      final left = items == null ? 0 : items.where((x) => !x.done).length;
      final isToday = ds == todayStr;
      final sky = skyByDate[ds];

      if (isToday) {
        if (constToday?.collected == true) {
          return Icon(
            LucideIcons.star,
            size: 10,
            color: constellationColor(
                context, constToday!.constellation.colorKey),
          );
        }
        if (left > 0) {
          return Text(
            l.frpTileDoneVal(left),
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: 10,
              fontWeight: PFontWeight.bold,
              color: t.fgBrand,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );
        }
        return const SizedBox.shrink();
      }
      if (sky != null && sky.isGrown && sky.colorKey != null) {
        return Icon(
          LucideIcons.star,
          size: 10,
          color: constellationColor(context, sky.colorKey!),
        );
      }
      if (sky != null && sky.isWithered) {
        return Icon(LucideIcons.cloudy, size: 10, color: t.fgTertiary);
      }
      if (items != null) {
        return left > 0
            ? Text(
                l.frpTileDoneVal(left),
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 10,
                  fontWeight: PFontWeight.semi,
                  color: t.fgTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            : Icon(
                LucideIcons.check,
                size: 10,
                color: constellationColor(context, 'green'),
              );
      }
      return const SizedBox.shrink();
    }

    Widget cell(({int d, String ds})? c, int i) {
      if (c == null) return const Expanded(child: SizedBox(height: 56));
      final isSel = c.ds == selected;
      final future = c.ds.compareTo(todayStr) > 0;
      return Expanded(
        child: InkWell(
          onTap: () => onSelect(c.ds),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            child: Column(
              children: [
                Container(
                  width: 33,
                  height: 33,
                  alignment: Alignment.center,
                  decoration: isSel
                      ? BoxDecoration(
                          color: t.bgBrandSolid, shape: BoxShape.circle)
                      : null,
                  child: Opacity(
                    opacity: !isSel && future ? 0.55 : 1,
                    child: Text(
                      '${c.d}',
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.bodyMd,
                        fontWeight: isSel ? PFontWeight.bold : PFontWeight.semi,
                        color: isSel ? t.fgOnBrand : numColor(c.ds, i % 7),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(height: 12, child: Center(child: mark(c.ds))),
              ],
            ),
          ),
        ),
      );
    }

    final dows = weekdayLabels();
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 12, PSpace.x16, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                    child: Text(
                      dows[i],
                      textAlign: TextAlign.center,
                      style: PTypo.caption.copyWith(
                        fontWeight: PFontWeight.semi,
                        color: i == 0
                            ? chartRedOf(context)
                            : i == 6
                                ? t.fgBrand
                                : t.fgTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final w in expanded ? weeks : [weeks[selWeek]])
            Row(children: [for (var i = 0; i < 7; i++) cell(w[i], i)]),
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
              child: Center(
                child: Icon(
                  expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 20,
                  color: t.fgTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 일별 그룹 — 날짜 헤더("yy. m. d(dow) · 오늘" + N/N 완료) + tdm 행.
class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.ymd,
    required this.items,
    required this.today,
    required this.onToggle,
    required this.onTap,
  });

  /// null = 마감일 없음 그룹.
  final String? ymd;
  final List<Todo> items;
  final DateTime today;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final doneN = items.where((x) => x.done).length;

    String head;
    String? rel;
    if (ymd == null) {
      head = l.todoNoDue;
    } else {
      final d = DateTime.parse(ymd!);
      head = '${d.year % 100}. ${d.month}. ${d.day}(${formatDay(d).dow})';
      final diff = dateOnly(d).difference(dateOnly(today)).inDays;
      rel = diff == 0
          ? l.dateToday
          : diff == 1
              ? l.dateTomorrow
              : diff == -1
                  ? l.dateYesterday
                  : null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: PSpace.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                head,
                style: PTypo.bodySm.copyWith(
                  color: t.fgSecondary,
                  fontWeight: PFontWeight.semi,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (rel != null)
                Text(
                  ' · $rel',
                  style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                ),
              const Spacer(),
              Text(
                l.tdmDoneRatio(doneN, items.length),
                style: PTypo.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: PFontWeight.semi,
                  color: doneN == items.length
                      ? constellationColor(context, 'green')
                      : t.fgTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          for (var i = 0; i < items.length; i++)
            _TodoRow(
              todo: items[i],
              today: today,
              last: i == items.length - 1,
              onToggle: () => onToggle(items[i]),
              onTap: () => onTap(items[i]),
            ),
        ],
      ),
    );
  }
}

/// 할일 행 (design .tdm-row) — 체크(24, 연체 빨강 테두리) + 제목/메타 + 우선순위 pill.
class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.today,
    required this.last,
    required this.onToggle,
    required this.onTap,
  });
  final Todo todo;
  final DateTime today;
  final bool last;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final overdue = !todo.done && isTodoOverdue(todo.due, today);
    final overdueColor = todoOverdueColor(context);
    final prio = todoPrioOf(todo.priority);
    final l = AppLocalizations.of(context);
    final tag = _TodoScreenState._tagOf(todo);
    final hasNote = (todo.content ?? '').trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: t.borderSubtle)),
        ),
        child: Opacity(
          opacity: todo.done ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: todo.done ? t.bgBrandSolid : Colors.transparent,
                      shape: BoxShape.circle,
                      border: todo.done
                          ? null
                          : Border.all(
                              color: overdue ? overdueColor : t.borderStrong,
                              width: 2,
                            ),
                    ),
                    child: todo.done
                        ? const Icon(
                            LucideIcons.check,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 15,
                          fontWeight: PFontWeight.semi,
                          letterSpacing: -0.15,
                          color: t.fgPrimary,
                          decoration:
                              todo.done ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            tag,
                            style: PTypo.caption.copyWith(
                                color: t.fgTertiary, fontSize: 12.5),
                          ),
                          if (hasNote) ...[
                            _MetaDot(t: t),
                            Icon(
                              LucideIcons.alignLeft,
                              size: 11,
                              color: t.fgTertiary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: prio.bg(context),
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    todoPrioLabel(l, todo.priority),
                    style: PTypo.micro.copyWith(
                      color: prio.color(context),
                      fontWeight: PFontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 메타 구분 dot (2px).
class _MetaDot extends StatelessWidget {
  const _MetaDot({required this.t});
  final PorestTokens t;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Container(
        width: 2,
        height: 2,
        decoration: BoxDecoration(
          color: t.borderStrong,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// 필터 시트 — 태그·우선순위 칩 + 완료 숨김 + 초기화/완료 (design 필터 시트).
class _FilterSheetBody extends StatefulWidget {
  const _FilterSheetBody({
    required this.allTags,
    required this.tags,
    required this.prios,
    required this.hideDone,
    required this.onApply,
  });
  final List<String> allTags;
  final Set<String> tags;
  final Set<String> prios;
  final bool hideDone;
  final void Function(Set<String>, Set<String>, bool) onApply;

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  late Set<String> _tags = {...widget.tags};
  late Set<String> _prios = {...widget.prios};
  late bool _hideDone = widget.hideDone;

  bool get _active => _tags.isNotEmpty || _prios.isNotEmpty || _hideDone;

  /// 변경 즉시 반영(시트 밖 리스트도 갱신) — 완료 버튼은 닫기만.
  void _sync() =>
      widget.onApply({..._tags}, {..._prios}, _hideDone);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.x24, 0, PSpace.x24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.tdmFilterTag,
            style: PTypo.caption.copyWith(
              fontSize: 12.5,
              fontWeight: PFontWeight.bold,
              color: t.fgTertiary,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.allTags)
                _FilterChip(
                  label: tag,
                  on: _tags.contains(tag),
                  onTap: () => setState(() {
                    _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag);
                    _sync();
                  }),
                  t: t,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l.todoPriorityLabel,
            style: PTypo.caption.copyWith(
              fontSize: 12.5,
              fontWeight: PFontWeight.bold,
              color: t.fgTertiary,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in kTodoPrios)
                _FilterChip(
                  label: todoPrioLabel(l, p.code),
                  dotColor: p.color(context),
                  on: _prios.contains(p.code),
                  onTap: () => setState(() {
                    _prios.contains(p.code)
                        ? _prios.remove(p.code)
                        : _prios.add(p.code);
                    _sync();
                  }),
                  t: t,
                ),
            ],
          ),
          const SizedBox(height: 18),
          _FilterChip(
            label: l.tdmHideDone,
            icon: LucideIcons.check,
            on: _hideDone,
            onTap: () => setState(() {
              _hideDone = !_hideDone;
              _sync();
            }),
            t: t,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PButton(
                  label: l.actionReset,
                  variant: PButtonVariant.outline,
                  onPressed: !_active
                      ? null
                      : () => setState(() {
                            _tags = {};
                            _prios = {};
                            _hideDone = false;
                            _sync();
                          }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: PButton(
                  label: l.actionDone,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 필터 칩 (design .tdm-chip) — 선택 시 brand 틴트.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.on,
    required this.onTap,
    required this.t,
    this.dotColor,
    this.icon,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;
  final PorestTokens t;
  final Color? dotColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? t.bgBrandSubtle : Colors.transparent,
      borderRadius: PRadius.brFull,
      child: InkWell(
        onTap: onTap,
        borderRadius: PRadius.brFull,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: on ? t.borderBrand : t.borderDefault),
            borderRadius: PRadius.brFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[
                Icon(icon, size: 12, color: on ? t.fgBrandStrong : t.fgPrimary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: PTypo.bodySm.copyWith(
                  fontSize: 13.5,
                  fontWeight: PFontWeight.semi,
                  color: on ? t.fgBrandStrong : t.fgPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 원장 skeleton — 정적 틀(월네비·요일 헤더) 실렌더, 데이터 영역만 placeholder.
class _LedgerSkeleton extends StatelessWidget {
  const _LedgerSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dows = weekdayLabels();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _MonthNav(
          label: monthOnly(DateTime.now()),
          onPrev: () {},
          onNext: () {},
          filterActive: false,
          filterCount: 0,
          onOpenFilter: () {},
          tokens: t,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(PSpace.x24, 8, PSpace.x24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PSkeleton.line(width: 180, height: 32),
              SizedBox(height: 8),
              PSkeleton.line(width: 220, height: 16),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.x16, 12, PSpace.x16, 0),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                    child: Text(
                      dows[i],
                      textAlign: TextAlign.center,
                      style: PTypo.caption.copyWith(
                        fontWeight: PFontWeight.semi,
                        color: i == 0
                            ? chartRedOf(context)
                            : i == 6
                                ? t.fgBrand
                                : t.fgTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, 10),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: PSkeleton(width: 33, height: 33),
                  ),
                ),
            ],
          ),
        ),
        Container(height: 1, color: t.borderDefault),
        Expanded(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(PSpace.x24, 24, PSpace.x24, 28),
            children: [
              const PSkeleton.line(width: 140, height: 13),
              const SizedBox(height: 8),
              for (final w in const [160.0, 120.0, 184.0, 104.0, 148.0])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      PSkeleton.circle(size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PSkeleton.line(width: w),
                            const SizedBox(height: 4),
                            const PSkeleton.line(width: 80, height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const PSkeleton(width: 40, height: 20),
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
