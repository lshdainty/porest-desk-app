import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';

/// Porest Detail — 상세 다이얼로그/드로어 공통 레이아웃.
/// 웹 shared/ui/porest/detail.tsx 미러 — design dialogs.jsx TxDetailDialog
/// 신판(토스 톤 플랫). 값은 porest 토큰 스냅(31/29→h1, 14.5→body, 15→14,
/// 12.5→caption, 46→44). 카드 박스 없는 플랫 구성 — 구획은 border-top 만.
///
///   PDetailHero(icon: …, title: '가맹점', meta: '2026-07-18 · 12:30',
///               amount: Text('−12,600원'))
///   PDetailFieldGroup(children: [PDetailField(label: '카테고리', child: …)])
///   PDetailSection(title: …, trailing: …, child: …)
///   PDetailQuickAction(icon: …, label: '내역 분할', active: true, badge: '2개')
///   PDetailStatSplit(items: [PDetailStat(label: …, value: …)])

/// 플랫 좌측 정렬 히어로 — [아이콘+제목] → 금액 → 메타.
class PDetailHero extends StatelessWidget {
  const PDetailHero({
    super.key,
    this.icon,
    required this.title,
    required this.amount,
    this.meta,
  });

  /// 좌측 카테고리/종류 아이콘 노드 (32 타일 등).
  final Widget? icon;
  final String title;

  /// 큰 금액 슬롯 — 색·마스킹은 사용처가 지정(h1/800 권장).
  final Widget amount;

  /// 하단 보조 줄 (날짜·시간 등).
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: PSpace.x8)],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.body.copyWith(
                    color: t.fgSecondary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          amount,
          if (meta != null) ...[
            const SizedBox(height: PSpace.x4),
            Text(
              meta!,
              style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 필드 묶음 — 히어로와 border-top 으로 구분되는 플랫 영역.
class PDetailFieldGroup extends StatelessWidget {
  const PDetailFieldGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.only(top: PSpace.x4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Column(children: children),
    );
  }
}

/// 플랫 label·값 행 — label 좌(고정폭 76) / 값 우측 정렬.
class PDetailField extends StatelessWidget {
  const PDetailField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: PTypo.body.copyWith(color: t.fgTertiary),
            ),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}

/// border-top 구분 섹션 — 선택적 제목 행(title 좌 / trailing 우).
class PDetailSection extends StatelessWidget {
  const PDetailSection({
    super.key,
    this.title,
    this.trailing,
    required this.child,
  });
  final Widget? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(top: PSpace.x16),
      padding: const EdgeInsets.only(top: PSpace.x16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpace.x8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (title != null)
                    DefaultTextStyle.merge(
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                      child: title!,
                    ),
                  const Spacer(),
                  ?trailing,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// 원형 퀵 액션 — 44 원(sunken / active brand-subtle) + 라벨, 우상단 뱃지.
class PDetailQuickAction extends StatelessWidget {
  const PDetailQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.badge,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onTap == null;
    final circleColor = active ? t.bgBrandSubtle : t.bgSunken;
    final iconColor = disabled
        ? t.fgTertiary
        : active
            ? t.fgBrand
            : t.fgSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PSpace.x12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x4, vertical: PSpace.x8),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: PMotion.fast,
                  curve: PMotion.standard,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: iconColor),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: PBadge(
                      label: badge!,
                      variant: PBadgeVariant.softBrand,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: PSpace.x8),
            Text(
              label,
              style: PTypo.caption.copyWith(
                color: disabled
                    ? t.fgTertiary
                    : active
                        ? t.fgBrandStrong
                        : t.fgSecondary,
                fontWeight: active ? PFontWeight.bold : PFontWeight.semi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PDetailStat {
  const PDetailStat({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
}

/// 중앙 스플릿 통계 — N열 균등, 사이 세로 구분선.
class PDetailStatSplit extends StatelessWidget {
  const PDetailStatSplit({super.key, required this.items});
  final List<PDetailStat> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                decoration: i < items.length - 1
                    ? BoxDecoration(
                        border: Border(
                          right: BorderSide(color: t.borderSubtle),
                        ),
                      )
                    : null,
                child: Column(
                  children: [
                    Text(
                      items[i].label,
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                    const SizedBox(height: PSpace.x4),
                    Text(
                      items[i].value,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.h4,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.36,
                        color: items[i].valueColor ?? t.fgPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
