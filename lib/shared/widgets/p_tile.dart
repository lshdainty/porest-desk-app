import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/tile.md 미러.
///
/// swatch(미리보기) + 라벨 + 설명 + 우측 active check 의 카드형 single-select.
/// 테마/기본통화/표시단위 등 **시각적 미리보기가 의미 자체**인 선택지. RadioList
/// 는 텍스트만, Tile은 swatch slot 필수.
///
/// active 시 border 1.5px brand + 8% brand tint bg + check ✓.
enum PTileSize { sm, md, lg }

class PTile extends StatelessWidget {
  const PTile({
    super.key,
    required this.swatch,
    required this.label,
    this.description,
    required this.selected,
    required this.onTap,
    this.size = PTileSize.md,
  });

  /// 좌측 미리보기 박스 — 색/아이콘/이미지 1개. 크기는 size에 따라 자동.
  final Widget swatch;

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback? onTap;
  final PTileSize size;

  (double padX, double padY, double swatchSize, double gap, double check)
      get _metrics => switch (size) {
            PTileSize.sm => (10, 12, 32, 10, 14),
            PTileSize.md => (14, 16, 40, 12, 16),
            PTileSize.lg => (18, 20, 48, 14, 18),
          };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (padX, padY, swatchSize, gap, checkSize) = _metrics;
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: PRadius.brLg,
          child: AnimatedContainer(
            duration: PMotion.fast,
            curve: PMotion.standard,
            padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
            decoration: BoxDecoration(
              // shadow 카드 — border 대신 elevation(shadow-sm). 선택 시에만 브랜드 보더
              // (레이아웃 안정 위해 미선택은 transparent border). desk-front Tile 정합.
              color: selected ? t.bgBrandSubtle : t.bgSurface,
              borderRadius: PRadius.brLg,
              border: Border.all(
                color: selected ? t.borderBrand : Colors.transparent,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: t.shadowSm,
            ),
            // 세로 스택 타일(사용자 결정, 클로드 디자인) — swatch 위 중앙 + 라벨/설명 중앙,
            // 체크는 우상단. desk-front TileItem 동일 수정과 세트.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: swatchSize,
                        height: swatchSize,
                        child: ClipRRect(
                          borderRadius: PRadius.brLg,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: t.borderSubtle),
                              borderRadius: PRadius.brLg,
                            ),
                            child: swatch,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gap),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.semi,
                        color: t.fgPrimary,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.caption,
                          fontWeight: PFontWeight.regular,
                          color: t.fgTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child:
                        Icon(LucideIcons.check, size: checkSize, color: t.fgBrand),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
