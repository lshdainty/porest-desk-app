import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 별자리 상세(I-11 23 · Q2-A) — ds Bottom Sheet 조회. 제목은 별자리 이름이고 바깥 누름 · 끌어내림으로 닫힌다(바닥 버튼 없음).
///
/// 하늘 패널 240(하늘 그림과 같은 역할 색 그라디언트 · 별자리 그림 180) → 설명 → 보기만 하는 줄 둘(별 개수 · 수집).
/// 못 모은 별자리는 실루엣 + 패널 아래 "아직 만나지 못한 별자리예요"(불투명, 흐리지 않는다) · 수집 줄은 "미수집".
Future<void> showConstellationDetail(
  BuildContext context,
  CollectionEntry entry,
) {
  return PBottomSheet.show<void>(
    context,
    builder: (_) => ConstellationDetailSheet(entry: entry),
  );
}

class ConstellationDetailSheet extends StatelessWidget {
  const ConstellationDetailSheet({super.key, required this.entry});

  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final info = entry.constellation;
    final name = constellationName(info);
    final collected = entry.collected;
    final desc = constellationDesc(info);
    final valueStyle = PTypography.t5.copyWith(
      color: c.fgNeutral,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return PBottomSheetContent(
      title: name,
      closeLabel: l.actionClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            image: true,
            label: l.constDetailSkyName(name),
            child: ExcludeSemantics(
              child: Container(
                key: const ValueKey('constellation-detail-sky'),
                height: 240,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PRounded.r4),
                  gradient: skyGradient(c, three: true),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ConstellationIcon(
                        info: info,
                        color: skyInk(c, collected ? 0xFF : 0x66),
                        size: 180,
                        lit: collected ? null : 0,
                        glow: collected,
                      ),
                    ),
                    if (!collected)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: PSpacing.x3_5,
                        child: Text(
                          keepAll(l.constDetailNotMet),
                          textAlign: TextAlign.center,
                          style: PTypography.t3.copyWith(
                            color: c.fgNeutralInverted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: PSpacing.x4,
                bottom: PSpacing.x1,
              ),
              child: Text(
                keepAll(desc),
                style: PTypography.t5.copyWith(color: c.fgNeutralMuted),
              ),
            ),
          PList(
            semanticLabel: name,
            children: [
              PListItem(
                title: l.constDetailStarCountLabel,
                titleColor: c.fgNeutralMuted,
                gutter: 0,
                suffix: Text(
                  l.constDetailStarCountValue(info.starCount),
                  style: valueStyle,
                  softWrap: false,
                ),
              ),
              PListItem(
                title: l.constDetailCollectLabel,
                titleColor: c.fgNeutralMuted,
                gutter: 0,
                suffix: Text(
                  collected
                      ? l.constDetailCollectValue(entry.collectCount)
                      : l.constCollectionNotCollected,
                  style: valueStyle,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
