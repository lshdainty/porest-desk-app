import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';
import 'package:porest_desk_app/features/constellation/presentation/constellation_painter.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 별자리 도감 — 전체 목록(수집 횟수/미수집), 탭 시 상세 감상 시트.
/// 웹 CollectionCard 미러 (디자인 SoT: forest.jsx ForestCollection).
class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.todayKey,
  });

  final ConstellationCollectionData collection;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    // 카드 다이어트 — design forest.jsx MyForest/ForestCollection(.p-card)는
    // 모바일에서 플랫: 카드 없이 sec-head + 콘텐츠만 (inset 10).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.constCollectionTitle,
                style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                l.constCollectionProgress(
                    collection.collectedKinds, collection.entries.length),
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.constCollectionSubtitle,
            style: PTypo.caption.copyWith(color: t.fgTertiary, fontSize: 11.5),
          ),
          const SizedBox(height: 8),
          // 도감 리스트 — 페이지 전체 스크롤 방지, 리스트 안에서 스크롤(웹 420 동기).
          SizedBox(
            height: 420,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final entry in collection.entries)
                  _CollectionRow(
                    entry: entry,
                    isToday: entry.constellation.constellationKey == todayKey,
                    t: t,
                    onTap: () => showConstellationDetailSheet(context, entry),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.entry,
    required this.isToday,
    required this.t,
    required this.onTap,
  });

  final CollectionEntry entry;
  final bool isToday;
  final PorestTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final collected = entry.collected;
    final color = constellationColor(context, entry.constellation.colorKey);
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: collected
                    ? Color.alphaBlend(color.withValues(alpha: 0.14), t.bgSurface)
                    // 웹 --bg-sunken(=앱 bgMuted) 정합 — 앱 bgSunken 은 페이지색이라 과진.
                    : t.bgMuted,
                borderRadius: PRadius.brMd,
              ),
              alignment: Alignment.center,
              child: ConstellationIcon(
                info: entry.constellation,
                color: collected ? color : t.fgTertiary,
                size: 24,
                dim: !collected,
                linesOnly: true,
              ),
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
                          constellationName(entry.constellation),
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.bodySm.copyWith(
                            fontSize: 13.5,
                            fontWeight: PFontWeight.semi,
                            color: collected ? t.fgPrimary : t.fgTertiary,
                          ),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                                t.fgBrand.withValues(alpha: 0.10), t.bgSurface),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l.constCollectionTodayBadge,
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: 10,
                              fontWeight: PFontWeight.bold,
                              color: t.fgBrand,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l.constCollectionStarCount(entry.constellation.starCount),
                    style: PTypo.caption.copyWith(color: t.fgTertiary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Text(
              collected
                  ? l.constCollectionTimes(entry.collectCount)
                  : l.constCollectionNotCollected,
              style: PTypo.caption.copyWith(
                fontWeight: PFontWeight.semi,
                color: collected ? t.fgSecondary : t.fgTertiary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 14, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

/// 별자리 상세 감상 시트 — 밤하늘 패널(수집=점등+글로우, 미수집=실루엣) + 수집 이력.
Future<void> showConstellationDetailSheet(
  BuildContext context,
  CollectionEntry entry,
) {
  return showPSheet<void>(
    context,
    title: AppLocalizations.of(context).constDetailTitle,
    shrinkWrap: true,
    contentBuilder: (ctx, _) {
      final t = ctx.tokens;
      final l = AppLocalizations.of(ctx);
      final collected = entry.collected;
      final color = constellationColor(ctx, entry.constellation.colorKey);
      return Padding(
        padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 밤하늘 감상 패널 — 고정 다크 팔레트 (라이트/다크 공통)
            Container(
              height: 240,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: PRadius.brLg,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D1430), Color(0xFF17224A), Color(0xFF1F2C5E)],
                  stops: [0, 0.6, 1],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: ConstellationIcon(
                      info: entry.constellation,
                      color: collected ? const Color(0xFFDFE7FF) : const Color(0x66BECDFF),
                      size: 180,
                      lit: collected ? null : 0,
                      glow: collected,
                    ),
                  ),
                  if (!collected)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 14,
                      child: Text(
                        l.constDetailNotMet,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 12,
                          fontWeight: PFontWeight.semi,
                          color: const Color(0xA6CDD8FF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: PSpace.x16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  constellationName(entry.constellation),
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.34,
                    color: t.fgPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.constCollectionStarCount(entry.constellation.starCount),
                  style: PTypo.caption.copyWith(
                    fontWeight: PFontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              constellationDesc(entry.constellation),
              style: PTypo.bodySm.copyWith(color: t.fgSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  collected ? LucideIcons.circleCheck : LucideIcons.lock,
                  size: 13,
                  color: t.fgTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    collected
                        ? l.constDetailCollectedTimes(entry.collectCount)
                        : l.constDetailHint(entry.constellation.starCount),
                    style: PTypo.caption.copyWith(color: t.fgTertiary, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
