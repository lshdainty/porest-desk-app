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

/// 별자리 도감 v2 — 실루엣 잠금 + 뱃지 수집 리스트 (design forest-report.jsx
/// ForestCollectionV2 / .fcol-* 미러). 행 탭 CTA → 상세 감상 시트.
class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.todayKey,
  });

  final ConstellationCollectionData collection;
  final String todayKey;

  /// 'NEW' — 가장 최근 첫 수집(수집 1회 중 lastCollectedDate 최신).
  String? _newestKey() {
    String? key;
    String latest = '';
    for (final e in collection.entries) {
      if (e.collectCount != 1) continue;
      final d = e.lastCollectedDate ?? '';
      if (d.compareTo(latest) > 0) {
        latest = d;
        key = e.constellation.constellationKey;
      }
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final newest = _newestKey();

    // 카드 다이어트(.m-subpage 플랫) — sec-head + 헤어라인 행 리스트.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
          child: Row(
            children: [
              Text(
                l.constCollectionTitle,
                style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.sparkles, size: 12, color: t.fgTertiary),
              const SizedBox(width: 4),
              Text(
                l.constCollectionProgress(
                  collection.collectedKinds,
                  collection.entries.length,
                ),
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
        for (var i = 0; i < collection.entries.length; i++)
          _FcolRow(
            entry: collection.entries[i],
            isToday:
                collection.entries[i].constellation.constellationKey ==
                todayKey,
            isNew:
                collection.entries[i].constellation.constellationKey == newest,
            first: i == 0,
            t: t,
            onOpen: () =>
                showConstellationDetailSheet(context, collection.entries[i]),
          ),
      ],
    );
  }
}

/// 도감 행 (design .fcol-row) — 78px 아트 + 이름/뱃지 + 설명·잠금힌트 + CTA.
class _FcolRow extends StatelessWidget {
  const _FcolRow({
    required this.entry,
    required this.isToday,
    required this.isNew,
    required this.first,
    required this.t,
    required this.onOpen,
  });

  final CollectionEntry entry;
  final bool isToday;
  final bool isNew;
  final bool first;
  final PorestTokens t;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = entry.collected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: PSpace.x16),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아트 — owned: 밤하늘 그라디언트 점등 / locked: sunken 실루엣.
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              gradient: owned
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D1430), Color(0xFF1F2C5E)],
                    )
                  : null,
              color: owned ? null : t.bgMuted,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: owned ? 1 : 0.85,
              child: ConstellationIcon(
                info: entry.constellation,
                color: owned ? const Color(0xFFDFE7FF) : t.fgTertiary,
                size: owned ? 56 : 56,
                dim: !owned,
                lit: owned ? null : 0,
                glow: owned,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      constellationName(entry.constellation),
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                        color: owned ? t.fgPrimary : t.fgTertiary,
                      ),
                    ),
                    if (isToday)
                      _FcolBadge(
                        icon: LucideIcons.crown,
                        label: l.constCollectionTodayBadge,
                        bg: t.bgBrandSolid,
                        fg: t.fgOnBrand,
                      ),
                    if (isNew && owned)
                      _FcolBadge(
                        label: 'NEW',
                        bg: constellationColor(context, 'orange'),
                        fg: Colors.white,
                      ),
                    if (owned)
                      _FcolBadge(
                        label: l.fcolOwnBadge(entry.collectCount),
                        bg: t.bgBrandSubtle,
                        fg: t.fgBrandStrong,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  owned
                      ? constellationDesc(entry.constellation)
                      : l.fcolLockedHint(entry.constellation.starCount),
                  style: PTypo.caption.copyWith(
                    color: t.fgTertiary,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 9),
                // CTA — 감상하기/미리보기 (design .fcol-cta pill).
                Material(
                  color: Colors.transparent,
                  borderRadius: PRadius.brFull,
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: PRadius.brFull,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: t.borderDefault),
                        borderRadius: PRadius.brFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            owned ? l.fcolViewCta : l.fcolPreviewCta,
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: 12.5,
                              fontWeight: PFontWeight.bold,
                              color: t.fgPrimary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 12,
                            color: t.fgPrimary,
                          ),
                        ],
                      ),
                    ),
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

class _FcolBadge extends StatelessWidget {
  const _FcolBadge({
    this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData? icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
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
        padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x24),
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
                  colors: [
                    Color(0xFF0D1430),
                    Color(0xFF17224A),
                    Color(0xFF1F2C5E),
                  ],
                  stops: [0, 0.6, 1],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: ConstellationIcon(
                      info: entry.constellation,
                      color: collected
                          ? const Color(0xFFDFE7FF)
                          : const Color(0x66BECDFF),
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
                    style: PTypo.caption.copyWith(
                      color: t.fgTertiary,
                      fontSize: 12.5,
                    ),
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
