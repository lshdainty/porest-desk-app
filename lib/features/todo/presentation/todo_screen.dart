import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_dropdown_menu.dart';
import 'package:porest_desk_app/shared/widgets/p_floating_action_button.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/constellation/application/constellation_providers.dart';
import 'package:porest_desk_app/features/constellation/presentation/collection_card.dart';
import 'package:porest_desk_app/features/constellation/presentation/my_sky_card.dart';
import 'package:porest_desk_app/features/constellation/presentation/night_sky_hero.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_meta.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_detail_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_project_management_dialog.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_tag_management_dialog.dart';

/// 할일 — 토스 톤 통계/퀵추가/필터/마감일 그룹 리스트 (web `TodoScreen` mobile 미러).
///
/// AppBar 의 리스트/칸반 토글 + 프로젝트/태그 관리 메뉴는 기존 기능 보존.
/// 데이터는 status=null 전체 fetch(칸반과 동일) 후 클라이언트 필터/그룹/통계.
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

/// 리스트 뷰 필터 4종.
enum _TodoFilterTab { today, week, all, done }

class _TodoScreenState extends ConsumerState<TodoScreen> {
  _TodoFilterTab _tab = _TodoFilterTab.today;

  /// 전체(status=null) fetch — 칸반과 동일 family 키 공유.
  static const TodoFilter _allFilter = (status: null, priority: null);

  Future<void> _toggleDone(Todo t) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.setStatus(t.rowId, t.done ? 'PENDING' : 'COMPLETED');
      ref.invalidate(todoListProvider);
      // 별자리 게이미피케이션 — 완료 토글은 별빛 적립/회수 부수효과를 가짐
      invalidateConstellation(ref);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${AppLocalizations.of(context).todoActionFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(todoListProvider(_allFilter));
          await ref.read(todoListProvider(_allFilter).future);
        },
        child: listAsync.when(
          loading: () => _TodoSkeleton(tokens: t),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              Text(
                '${l.todoLoadError}\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger),
              ),
            ],
          ),
          data: (all) => _buildBody(context, t, all),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PorestTokens t, List<Todo> all) {
    // 별자리 게이미피케이션 — 로딩/실패 시 null → 해당 카드 미렌더(graceful)
    final constToday = ref.watch(constellationTodayProvider).value;
    final constSky = ref.watch(constellationSkyProvider).value;
    final constCollection = ref.watch(constellationCollectionProvider).value;
    final l = AppLocalizations.of(context);
    final today = DateTime.now();

    // ── 통계 (전체 기준) ──
    final incomplete = all.where((x) => !x.done).toList();
    final todayCount = incomplete
        .where((x) => x.due != null && _isSameDay(x.due!, today))
        .length;
    final weekCount = incomplete.where((x) {
      if (x.due == null) return false;
      final diff = dateOnly(x.due!).difference(dateOnly(today)).inDays;
      return diff >= 0 && diff <= 7;
    }).length;
    final completedCount = all.where((x) => x.done).length;
    // 오늘 완료 건수 — 완료 이벤트(completedAt) 기준 (히어로 캡션용)
    final todayIso = _fmtDate(today);
    final doneToday = all
        .where((x) => x.done && (x.completedAt ?? '').startsWith(todayIso))
        .length;

    // ── 필터 카운트 ──
    final counts = <_TodoFilterTab, int>{
      _TodoFilterTab.today: todayCount,
      _TodoFilterTab.week: weekCount,
      _TodoFilterTab.all: incomplete.length,
      _TodoFilterTab.done: completedCount,
    };

    // ── 현재 탭 필터 적용 ──
    final filtered = all.where((x) {
      switch (_tab) {
        case _TodoFilterTab.today:
          return !x.done && x.due != null && _isSameDay(x.due!, today);
        case _TodoFilterTab.week:
          if (x.done || x.due == null) return false;
          final diff = dateOnly(x.due!).difference(dateOnly(today)).inDays;
          return diff >= 0 && diff <= 7;
        case _TodoFilterTab.all:
          return !x.done;
        case _TodoFilterTab.done:
          return x.done;
      }
    }).toList();

    // ── 정렬: 우선순위 desc → due asc(없으면 맨 뒤) ──
    filtered.sort((a, b) {
      final pr = todoPrioRank(b.priority).compareTo(todoPrioRank(a.priority));
      if (pr != 0) return pr;
      final ad = a.due, bd = b.due;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });

    // ── due(YYYY-MM-DD)별 그룹 (없으면 맨 뒤) ──
    final groups = <String, List<Todo>>{};
    for (final x in filtered) {
      final key = x.due == null ? '' : _fmtDate(x.due!);
      (groups[key] ??= <Todo>[]).add(x);
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == b) return 0;
        if (a.isEmpty) return 1; // 마감일 없음 → 맨 뒤
        if (b.isEmpty) return -1;
        return a.compareTo(b);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        96,
      ),
      children: [
        // ── 밤하늘 히어로 (별자리 게이미피케이션 — 통계 카드 대체, 디자인 정합) ──
        if (constToday != null) ...[
          NightSkyHero(today: constToday, doneToday: doneToday),
          const SizedBox(height: 14),
        ],

        // ── 필터 칩 4종 → PTabs(pills, sm) (가계부 필터 선례 동일) ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: PTabs<_TodoFilterTab>(
            value: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
            variant: PTabsVariant.pills,
            size: PTabsSize.sm,
            items: [
              for (final tab in _TodoFilterTab.values)
                PTabItem(
                  value: tab,
                  label: '${_tabLabel(tab)} ${counts[tab] ?? 0}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── 리스트 (마감일 그룹) or 빈 상태 — 카드 다이어트: 플랫 (design .p-card 플랫화) ──
        filtered.isEmpty
            ? SizedBox(
                width: double.infinity,
                child: _EmptyTodo(tab: _tab),
              )
            : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final key in groupKeys) ...[
                      _GroupHeader(
                        label: todoGroupLabel(
                          l,
                          key.isEmpty ? null : DateTime.parse(key),
                          groups[key]!.length,
                        ),
                        t: t,
                      ),
                      for (final todo in groups[key]!)
                        _TodoRow(
                          todo: todo,
                          today: today,
                          onToggle: () => _toggleDone(todo),
                          onTap: () => showTodoDetailDialog(context, todo),
                        ),
                    ],
                  ],
                ),
        if (constSky != null &&
            constToday != null &&
            constCollection != null) ...[
          const SizedBox(height: 14),
          MySkyCard(
            sky: constSky,
            today: constToday,
            entries: constCollection.entries,
          ),
        ],
        if (constCollection != null && constToday != null) ...[
          const SizedBox(height: 14),
          CollectionCard(
            collection: constCollection,
            todayKey: constToday.constellation.constellationKey,
          ),
        ],
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _tabLabel(_TodoFilterTab tab) {
    final l = AppLocalizations.of(context);
    return switch (tab) {
      _TodoFilterTab.today => l.calToday,
      _TodoFilterTab.week => l.expPeriodWeek,
      _TodoFilterTab.all => l.todoStatusAll,
      _TodoFilterTab.done => l.todoStatusCompleted,
    };
  }
}

/// 통계 카드 — 라벨(uppercase tracking) + 숫자(.num) + 단위, 완료율은 progress bar.
/// 마감일 그룹 헤더 — '5월 19일 (월) · N건', borderBottom subtle.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.t});
  final String label;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: Text(
        label,
        style: PTypo.micro.copyWith(
          color: t.fgTertiary,
          fontWeight: PFontWeight.bold,
          letterSpacing: 0.44,
        ),
      ),
    );
  }
}

/// 할일 행 — 원형 체크(22) + 제목 + 메타(상대시간·태그·메모) + 우선순위 칩.
class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.today,
    required this.onToggle,
    required this.onTap,
  });
  final Todo todo;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final overdue = !todo.done && isTodoOverdue(todo.due, today);
    final overdueColor = todoOverdueColor(context);
    final prio = todoPrioOf(todo.priority);
    final tag = todoTagOrDefault(todo.category);
    final hasNote = (todo.content ?? '').trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: todo.done ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 원형 체크 22px.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Container(
                  width: 22,
                  height: 22,
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
              // 제목 + 메타.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                        letterSpacing: -0.14,
                        decoration: todo.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          todoRelativeDate(l, todo.due, today),
                          style: PTypo.caption.copyWith(
                            color: overdue ? overdueColor : t.fgTertiary,
                            fontWeight: overdue
                                ? PFontWeight.semi
                                : PFontWeight.medium,
                          ),
                        ),
                        _MetaDot(t: t),
                        Text(
                          tag,
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
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
              // 우선순위 칩.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: prio.bg(context),
                  borderRadius: PRadius.brSm,
                ),
                child: Text(
                  todoPrioLabel(l, todo.priority),
                  style: PTypo.micro.copyWith(
                    color: prio.color(context),
                    fontWeight: PFontWeight.semi,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
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

/// 빈 상태 — 56px 원형 아이콘 + 탭별 문구.
class _EmptyTodo extends StatelessWidget {
  const _EmptyTodo({required this.tab});
  final _TodoFilterTab tab;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final isDone = tab == _TodoFilterTab.done;
    final title = switch (tab) {
      _TodoFilterTab.today => l.todoEmptyToday,
      _TodoFilterTab.week => l.todoEmptyWeek,
      _TodoFilterTab.done => l.todoEmptyDone,
      _TodoFilterTab.all => l.todoEmptyAll,
    };
    final sub = isDone ? l.todoEmptyDoneHint : l.todoEmptyAddHint;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: t.bgSunken,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? LucideIcons.checkCheck : LucideIcons.sparkles,
              size: 24,
              color: t.fgTertiary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: PTypo.body.copyWith(
              fontSize: PFontSize.bodyMd,
              color: t.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 리스트 뷰 skeleton — 실제 `_buildBody`(히어로·퀵추가·필터·플랫 리스트·별자리 카드) 미러.
///
/// 규칙: 정적 UI 틀(퀵추가 입력·필터 탭·그룹 헤더)은 실제 렌더, 서버 데이터 영역
/// (히어로 텍스트·할일 행·별자리 그리드/목록)만 placeholder → 로딩→데이터 전환 점프 최소화.
class _TodoSkeleton extends StatefulWidget {
  const _TodoSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  State<_TodoSkeleton> createState() => _TodoSkeletonState();
}

class _TodoSkeletonState extends State<_TodoSkeleton> {
  // 필터 탭 라벨 — 카운트는 데이터라 로딩 중엔 0(실제 `counts[tab] ?? 0` 폴백 포맷 정합).
  String _tabLabel(BuildContext context, _TodoFilterTab tab) {
    final l = AppLocalizations.of(context);
    final label = switch (tab) {
      _TodoFilterTab.today => l.calToday,
      _TodoFilterTab.week => l.expPeriodWeek,
      _TodoFilterTab.all => l.todoStatusAll,
      _TodoFilterTab.done => l.todoStatusCompleted,
    };
    return '$label 0';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(PSpace.x24, PSpace.x16, PSpace.x24, 96),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // ── 밤하늘 히어로 shell — 고정 다크 프레임(정적) + 데이터 텍스트 placeholder ──
        const _HeroSkeleton(),
        const SizedBox(height: 14),

        // ── 필터 탭 — 정적(로딩 중에도 탭 그대로) ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: PTabs<_TodoFilterTab>(
            value: _TodoFilterTab.today,
            onChanged: (_) {},
            variant: PTabsVariant.pills,
            size: PTabsSize.sm,
            items: [
              for (final tab in _TodoFilterTab.values)
                PTabItem(value: tab, label: _tabLabel(context, tab)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── 리스트 — 데이터 영역: 플랫(카드 미포함), 그룹 헤더 + 행 placeholder ──
        const _ListSkeleton(),

        // ── 나의 밤하늘 / 도감 — 데이터 영역(하단): 섹션 헤더 + 행 placeholder ──
        const SizedBox(height: 14),
        const _MySkySkeleton(),
        const SizedBox(height: 14),
        const _CollectionSkeleton(),
      ],
    );
  }
}

/// 히어로 skeleton — `NightSkyHero`의 고정 다크 그라디언트 프레임(정적)을 그대로 렌더하고,
/// 서버 데이터 의존 텍스트(목표·별자리명·캡션·스트릭)만 흰색 알파 placeholder.
/// (히어로는 라이트/다크 공통 고정 다크 팔레트 → 토큰 기반 PSkeleton 대신 흰색 알파 사용.)
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: PRadius.brLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1430), Color(0xFF17224A), Color(0xFF1F2C5E)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: const Stack(
        children: [
          // 은은한 달빛 (정적)
          Positioned(
            top: -40,
            right: -20,
            child: SizedBox(
              width: 180,
              height: 180,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x299AB0FF), Colors.transparent],
                    stops: [0, 0.65],
                  ),
                ),
              ),
            ),
          ),
          // 달 (정적)
          Positioned(
            top: 14,
            right: 16,
            child: Icon(LucideIcons.moon, size: 15, color: Color(0x8CD2DCFF)),
          ),
          // 좌상단: 오늘의 목표 라벨 + 별자리명 (데이터)
          Positioned(
            top: 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBar(width: 60, height: 9),
                SizedBox(height: 7),
                _HeroBar(width: 110, height: 16),
              ],
            ),
          ),
          // 좌하단: 진행 캡션 (데이터)
          Positioned(
            left: 16,
            bottom: 14,
            child: _HeroBar(width: 150, height: 10),
          ),
          // 우하단: 스트릭 배지 + 보호 (데이터)
          Positioned(
            right: 14,
            bottom: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HeroBar(width: 74, height: 24, radius: 999),
                SizedBox(height: 6),
                _HeroBar(width: 58, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 히어로(고정 다크) 내부 placeholder bar — 흰색 알파(NightSkyHero 배지 톤 정합).
class _HeroBar extends StatelessWidget {
  const _HeroBar({required this.width, required this.height, this.radius = 6});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// 리스트 skeleton — 플랫(카드 미포함), `_GroupHeader` + `_TodoRow` 구조 미러.
class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  // 제목 라인 폭 — 결정적 시퀀스(매 렌더 동일 시각).
  static const _titleWidths = [160.0, 120.0, 184.0, 104.0, 148.0];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 그룹 헤더 placeholder — `_GroupHeader`(하단 보더 + 패딩) 미러.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.borderSubtle)),
          ),
          child: const PSkeleton.line(width: 96, height: 11),
        ),
        // 할일 행 placeholder — `_TodoRow`(원형 체크 + 제목/메타 + 우선순위 칩) 미러.
        for (final w in _titleWidths)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PSkeleton.circle(size: 22),
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
    );
  }
}

/// 나의 밤하늘 skeleton — `MySkyCard`(플랫, inset 10) 섹션 헤더 + 2주 7열 그리드 미러.
class _MySkySkeleton extends StatelessWidget {
  const _MySkySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              PSkeleton.line(width: 96, height: 18),
              Spacer(),
              PSkeleton.line(width: 56, height: 12),
            ],
          ),
          const SizedBox(height: 4),
          const PSkeleton.line(width: 180, height: 11),
          const SizedBox(height: 12),
          // 2주 7열 관측 그리드 — 셀 AspectRatio(1).
          for (int r = 0; r < 2; r++) ...[
            Row(
              children: [
                for (int i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  const Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PSkeleton(borderRadius: PRadius.brMd),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// 도감 skeleton — `CollectionCard`(플랫, inset 10) 섹션 헤더 + `_CollectionRow` 목록 미러.
class _CollectionSkeleton extends StatelessWidget {
  const _CollectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              PSkeleton.line(width: 72, height: 18),
              Spacer(),
              PSkeleton.line(width: 48, height: 12),
            ],
          ),
          const SizedBox(height: 4),
          const PSkeleton.line(width: 200, height: 11),
          const SizedBox(height: 8),
          // 도감 행 placeholder — `_CollectionRow`(아이콘 타일 + 이름/별수 + 횟수 + chevron) 미러.
          for (int i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  PSkeleton(width: 34, height: 34, borderRadius: PRadius.brMd),
                  SizedBox(width: PSpace.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PSkeleton.line(width: 120, height: 13),
                        SizedBox(height: 3),
                        PSkeleton.line(width: 64, height: 11),
                      ],
                    ),
                  ),
                  PSkeleton.line(width: 40, height: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
