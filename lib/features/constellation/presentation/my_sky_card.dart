import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';
import 'package:porest_desk_app/features/constellation/presentation/constellation_painter.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 나의 밤하늘 — 최근 2주 관측 그리드 (GROWN=별자리 미니 아이콘 · 흐린 밤 · 쉼 · 오늘 단계).
/// 웹 MySkyCard 미러 (디자인 SoT: forest.jsx MyForest).
class MySkyCard extends StatelessWidget {
  const MySkyCard({
    super.key,
    required this.sky,
    required this.today,
    required this.entries,
  });

  final List<SkyDay> sky;
  final ConstellationToday today;
  final List<CollectionEntry> entries;

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
    final byKey = {for (final e in entries) e.constellation.constellationKey: e};
    final todayDate = sky.isNotEmpty ? sky.last.date : '';

    // 7열 그리드 — 주 단위 행으로 분할
    final rows = <List<SkyDay>>[];
    for (var i = 0; i < sky.length; i += 7) {
      rows.add(sky.sublist(i, i + 7 > sky.length ? sky.length : i + 7));
    }

    // 카드 다이어트 — design forest.jsx MyForest/ForestCollection(.p-card)는
    // 모바일에서 플랫: 카드 없이 sec-head + 콘텐츠만 (inset 10).
    // 좌우는 페이지가 쥔다(24). 섹션이 여기서 더 얹으면 제목과 내용이 어긋난다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.constMySkyTitle,
              style: PTypo.h4.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              l.constMySkyTotal(today.totalCollected),
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l.constMySkySubtitle,
          style: PTypo.caption.copyWith(color: t.fgTertiary, fontSize: 11.5),
        ),
        const SizedBox(height: 12),
        for (final week in rows) ...[
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: i < week.length
                      ? _DayCell(
                          day: week[i],
                          isToday: week[i].date == todayDate,
                          todayPoints: today.points,
                          entry: week[i].constellationKey != null
                              ? byKey[week[i].constellationKey]
                              : null,
                          stageIcon: _stageIcon(today.points),
                          t: t,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.todayPoints,
    required this.entry,
    required this.stageIcon,
    required this.t,
  });

  final SkyDay day;
  final bool isToday;
  final int todayPoints;
  final CollectionEntry? entry;
  final IconData stageIcon;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final dayNum = day.date.length >= 10 ? int.tryParse(day.date.substring(8, 10)) ?? 0 : 0;
    final grownColor = day.colorKey != null
        ? constellationColor(context, day.colorKey!)
        : t.fgTertiary;

    final Color bg;
    final Color fg;
    if (isToday) {
      bg = Color.alphaBlend(t.fgBrand.withValues(alpha: 0.10), t.bgSurface);
      fg = t.fgBrand;
    } else if (day.isGrown) {
      bg = Color.alphaBlend(grownColor.withValues(alpha: 0.13), t.bgSurface);
      fg = grownColor;
    } else {
      bg = t.bgSunken;
      fg = t.fgTertiary;
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: PRadius.brMd,
              border: isToday ? Border.all(color: t.fgBrand, width: 1.5) : null,
            ),
            child: Center(
              child: Opacity(
                opacity: day.isWithered && !isToday ? 0.75 : 1,
                child: isToday
                    ? Icon(stageIcon, size: 16, color: fg)
                    : day.isGrown && entry != null
                        ? ConstellationIcon(info: entry!.constellation, color: fg, size: 22, linesOnly: true)
                        : day.isWithered
                            ? Icon(LucideIcons.cloudy, size: 15, color: fg)
                            : Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: fg,
                                ),
                              ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$dayNum',
          style: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: 10,
            fontWeight: isToday ? PFontWeight.bold : FontWeight.w500,
            color: isToday ? t.fgBrand : t.fgTertiary,
          ),
        ),
      ],
    );
  }
}
