import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/format_locale.dart';
import 'package:porest_desk_app/features/constellation/application/constellation_providers.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';
import 'package:porest_desk_app/features/constellation/presentation/constellation_painter.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_meta.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

/// 관측 리포트 — 주간 스트립 + 일별 관측 결과/별빛/분석/못다 켠 별
/// (design forest-report.jsx ForestReport / .frp-* 미러).
///
/// 데이터: 관측 결과·모은 별빛 = 서버(sky/today), 우선순위 분해·못다 켠 별 =
/// 할일 목록 클라 집계(completedAt·due 기준).
class ForestReportScreen extends ConsumerStatefulWidget {
  const ForestReportScreen({super.key});

  @override
  ConsumerState<ForestReportScreen> createState() => _ForestReportScreenState();
}

class _ForestReportScreenState extends ConsumerState<ForestReportScreen> {
  static const TodoFilter _allFilter = (status: null, priority: null);

  /// 0=지난주, 1=이번주 (월요일 시작).
  int _week = 1;
  late String _sel = _ymd(DateTime.now());

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime get _thisMonday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  List<DateTime> _weekDays(int week) {
    final start = _thisMonday.subtract(Duration(days: week == 0 ? 7 : 0));
    return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  /// 우선순위 가중치 — 중요 3 · 보통 2 · 여유 1 (design FOREST_WEIGHT).
  static int _weight(String? prio) => switch (prio) {
        'HIGH' => 3,
        'LOW' => 1,
        _ => 2,
      };

  /// 그날 완료한 할일 (completedAt 기준).
  ///
  /// [ymd] 는 로컬 달력으로 만든 주간 스트립 칸이다. completedAt 은 서버 `[UTC]` 라
  /// 문자열을 자르면 UTC 날짜가 나와 KST(+9) 새벽 0~9시 완료가 전날 칸에 붙었다.
  /// 웹 `ForestReport.doneKey` 와 같은 규칙 — 로컬 날짜로 바꿔서 비교한다.
  List<Todo> _doneOn(List<Todo> todos, String ymd) => todos
      .where((x) => x.done && localDateKey(x.completedAt) == ymd)
      .toList();

  /// 그날 못다 켠 별 — due=그날 && 미완료.
  List<Todo> _missedOn(List<Todo> todos, String ymd) => todos
      .where((x) =>
          !x.done && x.due != null && _ymd(x.due!) == ymd)
      .toList();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final today = ref.watch(constellationTodayProvider).value;
    final sky = ref.watch(constellationSkyProvider).value ?? const <SkyDay>[];
    final collection = ref.watch(constellationCollectionProvider).value;
    final todos = ref.watch(todoListProvider(_allFilter)).value;

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.forestReportTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: today == null || todos == null
          ? ListView(
              padding: const EdgeInsets.all(PSpace.x20),
              children: const [
                PSkeleton(width: double.infinity, height: 90, borderRadius: PRadius.brLg),
                SizedBox(height: 12),
                PSkeleton(width: double.infinity, height: 64, borderRadius: PRadius.brLg),
                SizedBox(height: 12),
                PSkeleton(width: double.infinity, height: 150, borderRadius: PRadius.brLg),
                SizedBox(height: 12),
                PSkeleton(width: double.infinity, height: 220, borderRadius: PRadius.brLg),
              ],
            )
          : _body(context, t, l, today, sky, collection, todos),
    );
  }

  Widget _body(
    BuildContext context,
    PorestTokens t,
    AppLocalizations l,
    ConstellationToday today,
    List<SkyDay> sky,
    ConstellationCollectionData? collection,
    List<Todo> todos,
  ) {
    final todayYmd = _ymd(DateTime.now());
    final days = _weekDays(_week);
    final dows = weekdayLabels(mondayFirst: true);
    final skyByDate = {for (final d in sky) d.date: d};
    final entryByKey = {
      if (collection != null)
        for (final e in collection.entries) e.constellation.constellationKey: e,
    };

    final isToday = _sel == todayYmd;
    final isFuture = _sel.compareTo(todayYmd) > 0;
    final selSky = skyByDate[_sel];
    final selDate = DateTime.parse(_sel);

    // 선택일 별빛/완료 — 오늘=서버 points(메모 포함), 과거=sky.points(없으면 클라 가중 합).
    final doneList = _doneOn(todos, _sel);
    final clientPts =
        doneList.fold<int>(0, (s, x) => s + _weight(x.priority));
    final pts = isToday
        ? today.points
        : (selSky != null ? selSky.points : clientPts);
    final goal = isToday
        ? today.goal
        : (selSky?.constellationKey != null
            ? (entryByKey[selSky!.constellationKey!]
                    ?.constellation.starCount ??
                today.goal)
            : today.goal);
    final pct = goal <= 0 ? 0 : ((pts / goal) * 100).clamp(0, 100).round();
    final missed = _missedOn(todos, _sel);
    final selEntry = selSky?.constellationKey != null
        ? entryByKey[selSky!.constellationKey!]
        : null;

    // 주간 바 최대값 — goal 이상 보장.
    var weekMax = goal;
    for (final d in days) {
      final ds = _ymd(d);
      final v = ds == todayYmd
          ? today.points
          : (skyByDate[ds]?.points ??
              _doneOn(todos, ds)
                  .fold<int>(0, (s, x) => s + _weight(x.priority)));
      if (v > weekMax) weekMax = v;
    }

    final rangeLabel =
        '${_ymd(days.first).replaceAll('-', '.')} ~ ${_ymd(days.last).replaceAll('-', '.')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(PSpace.x24, 0, PSpace.x24, 36),
      children: [
        // ── 주간 네비 + 스트립 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _WeekNavBtn(
                icon: LucideIcons.chevronLeft,
                enabled: _week == 1,
                onTap: () => setState(() => _week = 0),
                t: t,
              ),
              Text(
                rangeLabel,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 13.5,
                  fontWeight: PFontWeight.bold,
                  color: t.fgPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              _WeekNavBtn(
                icon: LucideIcons.chevronRight,
                enabled: _week == 0,
                onTap: () => setState(() => _week = 1),
                t: t,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14, top: 6),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _StripDay(
                    ymd: _ymd(days[i]),
                    day: days[i].day,
                    dow: dows[i],
                    isToday: _ymd(days[i]) == todayYmd,
                    selected: _ymd(days[i]) == _sel,
                    future: _ymd(days[i]).compareTo(todayYmd) > 0,
                    onTap: () => setState(() => _sel = _ymd(days[i])),
                    t: t,
                  ),
                ),
            ],
          ),
        ),

        // ── 날짜 헤더 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${selDate.year % 100}.${selDate.month}.${selDate.day} ${formatDay(selDate).dow}',
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.15,
                  color: t.fgPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              if (isToday)
                Text(
                  l.frpAsOf(formatDateTimeMinute(DateTime.now())),
                  style: PTypo.caption.copyWith(
                      color: t.fgTertiary, fontSize: 11),
                ),
            ],
          ),
        ),

        if (isFuture)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(LucideIcons.moon, size: 30, color: t.fgTertiary),
                const SizedBox(height: 12),
                Text(
                  l.frpFuture,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // ── 관측 결과 ──
          PCard(
            variant: PCardVariant.raised,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    _CardIco(icon: LucideIcons.telescope, t: t),
                    const SizedBox(width: 8),
                    Text(l.frpObsResult,
                        style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: isToday
                          ? Text(
                              l.frpObsToday(
                                constellationName(today.constellation),
                                today.points > today.goal
                                    ? today.goal
                                    : today.points,
                                today.goal,
                              ),
                              style: _obsStyle(t.fgPrimary),
                            )
                          : selEntry != null
                              ? Row(
                                  children: [
                                    ConstellationIcon(
                                      info: selEntry.constellation,
                                      color: constellationColor(context,
                                          selEntry.constellation.colorKey),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        l.frpObsCollected(constellationName(
                                            selEntry.constellation)),
                                        style: _obsStyle(constellationColor(
                                            context,
                                            selEntry.constellation.colorKey)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  selSky?.isWithered == true
                                      ? l.frpObsWithered
                                      : l.frpObsRest,
                                  style: _obsStyle(t.fgTertiary),
                                ),
                    ),
                    if (isToday) const SizedBox(width: 56),
                  ],
                ),
                // 연속 관측 스탬프 (design .frp-stamp — 기울어진 도장).
                if (isToday && today.streak > 0)
                  Positioned(
                    right: -4,
                    top: -18,
                    child: Transform.rotate(
                      angle: -0.157,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: todoOverdueColor(context),
                            width: 1.5,
                          ),
                          color: todoOverdueColor(context)
                              .withValues(alpha: 0.04),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l.frpStampDays(today.streak),
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: todoOverdueColor(context),
                              ),
                            ),
                            Text(
                              l.frpStampLabel,
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: todoOverdueColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 별빛 모으기 ──
          PCard(
            variant: PCardVariant.raised,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CardIco(icon: LucideIcons.trophy, t: t),
                    const SizedBox(width: 8),
                    Text(
                      l.frpStarGather,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: t.borderBrand, width: 1.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l.frpPctBadge(pct),
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: t.fgBrand,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icoBg: t.bgBrandSubtle,
                        icoFg: t.fgBrand,
                        icon: LucideIcons.sparkles,
                        label: l.frpTileStar,
                        value: l.frpTileStarVal(pts),
                        t: t,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        icoBg: Color.alphaBlend(
                          constellationColor(context, 'green')
                              .withValues(alpha: 0.14),
                          t.bgSurface,
                        ),
                        icoFg: constellationColor(context, 'green'),
                        icon: LucideIcons.checkCheck,
                        label: l.frpTileDone,
                        value: l.frpTileDoneVal(doneList.length),
                        t: t,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 별빛 분석 ──
          PCard(
            variant: PCardVariant.raised,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CardIco(icon: LucideIcons.chartColumnBig, t: t),
                    const SizedBox(width: 8),
                    Text(
                      l.frpAnalysis,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final p in kTodoPrios)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.color(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.frpLegendItem(
                            todoPrioLabel(l, p.code),
                            doneList
                                .where((x) =>
                                    (x.priority ?? 'MEDIUM') == p.code)
                                .length,
                          ),
                          style: PTypo.caption.copyWith(
                              color: t.fgSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${_weight(p.code)}',
                          style: PTypo.caption.copyWith(
                              color: t.fgTertiary, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _AnalysisBar(
                            todos: todos,
                            ymd: _ymd(days[i]),
                            dow: dows[i],
                            todayYmd: todayYmd,
                            selected: _ymd(days[i]) == _sel,
                            weekMax: weekMax,
                            weight: _weight,
                            doneOn: _doneOn,
                            t: t,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 못다 켠 별 ──
          if (missed.isNotEmpty || isToday)
            PCard(
              variant: PCardVariant.raised,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CardIco(icon: LucideIcons.moonStar, t: t),
                      const SizedBox(width: 8),
                      Text(
                        l.frpMissed,
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (missed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
                      child: Text(
                        l.frpMissedAllDone,
                        style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
                      child: Center(
                        child: Text(
                          l.frpMissedCount(missed.length),
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.48,
                            color: t.fgPrimary,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < missed.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _MissedRow(todo: missed[i], weight: _weight, t: t),
                    ],
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }

  TextStyle _obsStyle(Color color) => TextStyle(
        fontFamily: PTypo.sans,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.14,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// "YYYY.M.D 오전/오후 H:MM" — as-of 라벨 (ko 관례, en은 24h).
String formatDateTimeMinute(DateTime d) {
  final mm = d.minute.toString().padLeft(2, '0');
  if (localeIsEn()) {
    return '${d.year}.${d.month}.${d.day} ${d.hour}:$mm';
  }
  final isPm = d.hour >= 12;
  var h = d.hour % 12;
  if (h == 0) h = 12;
  return '${d.year}.${d.month}.${d.day} ${isPm ? '오후' : '오전'} $h:$mm';
}

class _WeekNavBtn extends StatelessWidget {
  const _WeekNavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.t,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: PRadius.brSm,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Opacity(
          opacity: enabled ? 1 : 0.25,
          child: Icon(icon, size: 16, color: t.fgSecondary),
        ),
      ),
    );
  }
}

/// 주간 스트립 하루 — 요일 + 날짜 원 (선택=brand 채움, 미래=disabled).
class _StripDay extends StatelessWidget {
  const _StripDay({
    required this.ymd,
    required this.day,
    required this.dow,
    required this.isToday,
    required this.selected,
    required this.future,
    required this.onTap,
    required this.t,
  });
  final String ymd;
  final int day;
  final String dow;
  final bool isToday;
  final bool selected;
  final bool future;
  final VoidCallback onTap;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: future ? null : onTap,
      borderRadius: PRadius.brMd,
      child: Opacity(
        opacity: future ? 0.4 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                isToday ? l.dateToday : dow,
                style: PTypo.caption.copyWith(
                  fontSize: 11.5,
                  fontWeight:
                      isToday ? PFontWeight.bold : PFontWeight.semi,
                  color: isToday ? t.fgBrand : t.fgTertiary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 34,
                height: 34,
                decoration: selected
                    ? BoxDecoration(
                        color: t.bgBrandSolid, shape: BoxShape.circle)
                    : null,
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w800 : PFontWeight.semi,
                    color: selected ? t.fgOnBrand : t.fgPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

/// 카드 아이콘 타일 (design .frp-card__ico — 26px sunken).
class _CardIco extends StatelessWidget {
  const _CardIco({required this.icon, required this.t});
  final IconData icon;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: t.bgMuted,
        borderRadius: PRadius.brSm,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 15, color: t.fgSecondary),
    );
  }
}

/// 별빛 모으기 타일 (design .frp-tile — bordered).
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icoBg,
    required this.icoFg,
    required this.icon,
    required this.label,
    required this.value,
    required this.t,
  });
  final Color icoBg;
  final Color icoFg;
  final IconData icon;
  final String label;
  final String value;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    return PCard(
      variant: PCardVariant.bordered,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: icoBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: icoFg),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: PTypo.caption.copyWith(
              fontSize: 11.5,
              fontWeight: PFontWeight.semi,
              color: t.fgTertiary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.38,
              color: t.fgPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 주간 분석 막대 하루 — 우선순위 stacked (아래부터 중요→보통→여유).
class _AnalysisBar extends StatelessWidget {
  const _AnalysisBar({
    required this.todos,
    required this.ymd,
    required this.dow,
    required this.todayYmd,
    required this.selected,
    required this.weekMax,
    required this.weight,
    required this.doneOn,
    required this.t,
  });
  final List<Todo> todos;
  final String ymd;
  final String dow;
  final String todayYmd;
  final bool selected;
  final int weekMax;
  final int Function(String?) weight;
  final List<Todo> Function(List<Todo>, String) doneOn;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final done = doneOn(todos, ymd);
    final parts = [
      for (final p in kTodoPrios)
        (
          color: p.color(context),
          value: done
                  .where((x) => (x.priority ?? 'MEDIUM') == p.code)
                  .length *
              weight(p.code),
        ),
    ];
    final total = parts.fold<int>(0, (s, p) => s + p.value);
    final frac = weekMax <= 0 ? 0.0 : (total / weekMax).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: total == 0 ? 0 : (frac < 0.08 ? 0.08 : frac),
              child: Container(
                width: 14,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Column(
                  children: [
                    // 위→아래 = 여유→보통→중요 (design column-reverse 정합).
                    for (final p in parts.reversed)
                      if (p.value > 0)
                        Expanded(
                          flex: p.value,
                          child: Container(color: p.color),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 20,
          height: 20,
          decoration: selected
              ? BoxDecoration(color: t.bgBrandSolid, shape: BoxShape.circle)
              : null,
          alignment: Alignment.center,
          child: Text(
            dow,
            style: PTypo.caption.copyWith(
              fontSize: 11,
              fontWeight: selected ? PFontWeight.bold : PFontWeight.semi,
              color: selected ? t.fgOnBrand : t.fgTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 못다 켠 별 행 (design .frp-missed__row) — 코너 우선순위 + 제목 + 가중치.
class _MissedRow extends StatelessWidget {
  const _MissedRow({
    required this.todo,
    required this.weight,
    required this.t,
  });
  final Todo todo;
  final int Function(String?) weight;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prio = todoPrioOf(todo.priority);
    final color = prio.color(context);
    final label = todoPrioLabel(l, todo.priority);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: t.borderSubtle),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    todo.title,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.body.copyWith(
                      fontWeight: PFontWeight.semi,
                      color: t.fgPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '+${weight(todo.priority)}',
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 11.5,
                    fontWeight: PFontWeight.bold,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          // 좌상단 코너 우선순위 (design .frp-missed__corner).
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label.isEmpty ? '' : label[0],
                style: const TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
