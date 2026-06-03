import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../application/card_providers.dart';

/// 카드(자산) 월 실적 진척 바 — front `CardPerformanceBar` 미러.
///
/// `assetRowId` 가 카드 자산이고 백엔드에 실적 정보가 있을 때 노출.
/// `requiredAmount=null` 또는 `isRequired=false` 면 bar 자체 숨김.
class CardPerformanceBar extends ConsumerWidget {
  const CardPerformanceBar({
    super.key,
    required this.assetRowId,
    required this.yearMonth, // 'YYYY-MM'
    this.masked = false,
  });

  final int assetRowId;
  final String yearMonth;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(cardPerformanceProvider(
        (assetRowId: assetRowId, yearMonth: yearMonth)));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (p) {
        if (!p.isRequired || p.requiredAmount == null) {
          return const SizedBox.shrink();
        }
        final pct = (p.achievementRate.clamp(0.0, 1.5) * 100).toInt();
        final overrun = p.achievementRate >= 1.0;
        final barColor =
            overrun ? t.statusSuccess : t.fgBrand;
        return Container(
          padding: const EdgeInsets.all(PSpace.x12),
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brMd,
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.trendingUp,
                      size: 14, color: t.fgSecondary),
                  const SizedBox(width: 6),
                  Text('$yearMonth 실적',
                      style: PTypo.caption.copyWith(
                          color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                  const Spacer(),
                  Text('$pct%',
                      style: PTypo.caption.copyWith(
                          color: barColor, fontWeight: PFontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: PRadius.brXs,
                child: LinearProgressIndicator(
                  value: p.achievementRate.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: t.bgTrack,
                  color: barColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    // 마스킹 시 '원' 미노출 — web MaskAmount+HideUnit 컨벤션
                    masked
                        ? '••• / •••'
                        : '${krw(p.currentAmount)} / ${krw(p.requiredAmount ?? 0)}원',
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                  const Spacer(),
                  if (!p.isAchieved && p.remainingAmount != null)
                    Text(
                      masked
                          ? '남은 •••'
                          : '남은 ${krw(p.remainingAmount!)}원',
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    )
                  else
                    Text('달성',
                        style: PTypo.caption.copyWith(
                            color: t.statusSuccess,
                            fontWeight: PFontWeight.bold)),
                ],
              ),
              if ((p.requiredText ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(p.requiredText!,
                    style: PTypo.micro.copyWith(color: t.fgTertiary)),
              ],
            ],
          ),
        );
      },
    );
  }
}
