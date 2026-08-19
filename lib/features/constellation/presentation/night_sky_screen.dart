import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/features/constellation/application/constellation_providers.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';
import 'package:porest_desk_app/features/constellation/presentation/collection_card.dart';
import 'package:porest_desk_app/features/constellation/presentation/constellation_painter.dart';
import 'package:porest_desk_app/features/constellation/presentation/my_sky_card.dart';
import 'package:porest_desk_app/features/constellation/presentation/night_sky_hero.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

/// 밤하늘 화면 — 성장·수집 전용 공간 (design forest-report.jsx NightSkyPage 미러).
///
/// 히어로 + 관측 리포트 진입(ForestWeekEntry) + 나의 밤하늘 + 별자리 도감 v2.
/// 할일 화면에서는 [밤하늘] 토글 패널의 '도감 · 기록' 버튼으로 진입.
class NightSkyScreen extends ConsumerWidget {
  const NightSkyScreen({super.key});

  static const TodoFilter _allFilter = (status: null, priority: null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final today = ref.watch(constellationTodayProvider).value;
    final sky = ref.watch(constellationSkyProvider).value;
    final collection = ref.watch(constellationCollectionProvider).value;
    final todos = ref.watch(todoListProvider(_allFilter)).value;

    final now = DateTime.now();
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final doneToday = (todos ?? const [])
        .where((x) => x.done && (x.completedAt ?? '').startsWith(todayIso))
        .length;

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.nightSkyTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(constellationTodayProvider);
          ref.invalidate(constellationSkyProvider);
          ref.invalidate(constellationCollectionProvider);
          await ref.read(constellationTodayProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(PSpace.x24, 4, PSpace.x24, 36),
          children: [
            if (today == null)
              const _NightSkySkeleton()
            else ...[
              NightSkyHero(today: today, doneToday: doneToday),
              const SizedBox(height: 14),
              _ForestWeekEntry(
                today: today,
                sky: sky ?? const [],
                onOpen: () => context.push('/forest-report'),
              ),
              if (sky != null && collection != null) ...[
                const SizedBox(height: 14),
                MySkyCard(sky: sky, today: today, entries: collection.entries),
              ],
              if (collection != null) ...[
                const SizedBox(height: 14),
                CollectionCard(
                  collection: collection,
                  todayKey: today.constellation.constellationKey,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// 관측 리포트 진입 카드 — 최근 7일 도트 (design ForestWeekEntry / .frp-entry).
class _ForestWeekEntry extends StatelessWidget {
  const _ForestWeekEntry({
    required this.today,
    required this.sky,
    required this.onOpen,
  });

  final ConstellationToday today;
  final List<SkyDay> sky;
  final VoidCallback onOpen;

  IconData _stageIcon(int points) {
    if (points >= 5) return LucideIcons.star;
    if (points >= 3) return LucideIcons.sparkles;
    if (points >= 1) return LucideIcons.sparkle;
    return LucideIcons.moon;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 최근 7일 — sky 끝(오늘)에서 7개.
    final days = sky.length > 7 ? sky.sublist(sky.length - 7) : sky;
    final todayDate = sky.isNotEmpty ? sky.last.date : '';
    final name = constellationName(today.constellation);

    return InkWell(
      onTap: onOpen,
      borderRadius: PRadius.brLg,
      child: Padding(
        // design .frp-entry — 14px 16px, gap 13 (m-subpage 플랫: 카드 셸 없음).
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D1430), Color(0xFF1F2C5E)],
                ),
              ),
              alignment: Alignment.center,
              child: ConstellationIcon(
                info: today.constellation,
                color: const Color(0xFFDFE7FF),
                size: 30,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l.forestReportTitle,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 15,
                          fontWeight: PFontWeight.bold,
                          letterSpacing: -0.15,
                          color: t.fgPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // rep 뱃지 — 오늘의 목표 별자리명 (design .fcol-badge--rep).
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.bgBrandSolid,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.star,
                                size: 9, color: t.fgOnBrand),
                            const SizedBox(width: 3),
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: t.fgOnBrand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      for (var i = 0; i < days.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        _WeekDot(
                          day: days[i],
                          isToday: days[i].date == todayDate,
                          stageIcon: _stageIcon(today.points),
                          t: t,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 17, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

/// 주간 도트 (22px) — 오늘=단계 아이콘(brand), 수집=★(별자리색 틴트), 흐린 밤=구름, 그 외=요일.
class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.day,
    required this.isToday,
    required this.stageIcon,
    required this.t,
  });

  final SkyDay day;
  final bool isToday;
  final IconData stageIcon;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final grown = day.isGrown && day.colorKey != null;
    final color = grown ? constellationColor(context, day.colorKey!) : null;
    final dowIdx = DateTime.tryParse(day.date)?.weekday; // 1=월..7=일
    final dows = weekdayLabels(mondayFirst: true);

    final Color bg;
    final Color fg;
    if (isToday) {
      bg = t.bgBrandSolid;
      fg = t.fgOnBrand;
    } else if (grown) {
      bg = Color.alphaBlend(color!.withValues(alpha: 0.16), t.bgSurface);
      fg = color;
    } else {
      bg = t.bgMuted;
      fg = t.fgTertiary;
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: isToday
          ? Icon(stageIcon, size: 11, color: fg)
          : grown
              ? Icon(LucideIcons.star, size: 10, color: fg)
              : day.isWithered
                  ? Icon(LucideIcons.cloudy, size: 11, color: fg)
                  : Text(
                      dowIdx == null ? '' : dows[dowIdx - 1],
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: 10,
                        fontWeight: PFontWeight.semi,
                        color: fg,
                      ),
                    ),
    );
  }
}

/// 로딩 스켈레톤 — 히어로 프레임 + 진입 행 + 그리드 placeholder.
class _NightSkySkeleton extends StatelessWidget {
  const _NightSkySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        PSkeleton(width: double.infinity, height: 168, borderRadius: PRadius.brLg),
        SizedBox(height: 14),
        PSkeleton(width: double.infinity, height: 74, borderRadius: PRadius.brLg),
        SizedBox(height: 14),
        PSkeleton(width: double.infinity, height: 180, borderRadius: PRadius.brLg),
        SizedBox(height: 14),
        PSkeleton(width: double.infinity, height: 320, borderRadius: PRadius.brLg),
      ],
    );
  }
}
