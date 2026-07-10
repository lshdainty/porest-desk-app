import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// 모바일 카드 다이어트 플랫 섹션 — design app.css `.sec-head` / `.flat-group__head` 매핑.
///
/// 카드(배경·그림자·radius·내부 padding) 없이 [헤드: 타이틀 15/bold(+trailing 액션),
/// 아래 12px] + [콘텐츠]만으로 섹션을 구성한다. 화면 여백은 페이지 컨테이너 padding과
/// 섹션 사이 gap(디자인 화면별 16~36px)이 담당한다.
///
/// 강조 요약/히어로는 이 위젯이 아니라 `PCard(variant: PCardVariant.raised)`(keep 카드)를
/// 쓴다 — design `.m-scroll .p-card--keep`.
class PFlatSection extends StatelessWidget {
  const PFlatSection({
    super.key,
    required this.title,
    this.titleSuffix,
    this.trailing,
    this.headGap = 12,
    this.contentPadding = EdgeInsets.zero,
    required this.child,
  });

  /// 섹션 타이틀 — design `.sec-head h2` 모바일 15 / bold.
  final String title;

  /// 타이틀 우측에 바짝 붙는 보조 위젯 (예: 오늘 쓴 돈 합계).
  final Widget? titleSuffix;

  /// 헤드 우측 끝 액션 (예: '전체' 링크).
  final Widget? trailing;

  /// 헤드 아래 여백 — design `.sec-head` margin-bottom (기본 12, 화면별 6~14).
  final double headGap;

  /// 콘텐츠 inset — 행 기반 리스트는 행이 자체 padding(가로 10)을 갖고,
  /// 그 외 콘텐츠는 design `padding: '0 10px'` 처럼 가로 10 inset 을 준다.
  final EdgeInsetsGeometry contentPadding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: headGap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 15,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.15,
                  color: t.fgPrimary,
                ),
              ),
              if (titleSuffix != null) ...[
                const SizedBox(width: 8),
                titleSuffix!,
              ],
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
        ),
        Padding(padding: contentPadding, child: child),
      ],
    );
  }
}

/// 플랫 섹션 헤드의 '전체 보기' 류 우측 링크 — design `.sec-head .all`
/// (12.5 tertiary + chevron, hover 시 primary).
class PFlatSectionLink extends StatelessWidget {
  const PFlatSectionLink({
    super.key,
    required this.label,
    this.chevron = true,
    required this.onTap,
  });

  final String label;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
          if (chevron) ...[
            const SizedBox(width: 2),
            Icon(LucideIcons.chevronRight, size: 14, color: t.fgTertiary),
          ],
        ],
      ),
    );
  }
}
