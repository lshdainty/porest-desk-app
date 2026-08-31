import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/avatar.md 미러.
///
/// 사용자/팀원의 시각 identity 원형 단위. 이미지 우선, 실패 시 한글 1글자
/// (또는 영문 2글자) fallback. sm(32)/md(40)/lg(48)/xl(64) × 2 fills
/// (neutral/primary). 클릭 가능해야 하면 외부에서 `<button>` wrap.
enum PAvatarSize { sm, md, lg, xl }

enum PAvatarFill { neutral, primary }

class PAvatar extends StatelessWidget {
  const PAvatar({
    super.key,
    this.imageProvider,
    this.fallbackText,
    this.size = PAvatarSize.md,
    this.fill = PAvatarFill.neutral,
    this.semanticLabel,
  });

  /// 이미지가 있으면 우선 표시. 로딩/에러 시 fallback.
  final ImageProvider? imageProvider;

  /// 이미지 없을 때 표시할 1–2글자.
  final String? fallbackText;

  final PAvatarSize size;
  final PAvatarFill fill;
  final String? semanticLabel;

  double get _size => switch (size) {
    PAvatarSize.sm => 32,
    PAvatarSize.md => 40,
    PAvatarSize.lg => 48,
    PAvatarSize.xl => 64,
  };

  double get _fontSize => switch (size) {
    PAvatarSize.sm => PFontSize.bodySm, // 13
    PAvatarSize.md => PFontSize.titleSm, // 16
    PAvatarSize.lg => PFontSize.titleMd, // 18
    PAvatarSize.xl => PFontSize.h2, // 24 (display-sm)
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // fill 은 다크에서도 primary 고정(bgBrandSolid) — bgBrand 는 다크 cobalt400 으로 밝아짐(web 정합).
    final bg = fill == PAvatarFill.primary ? t.bgBrandSolid : t.bgMuted;
    final fg = fill == PAvatarFill.primary ? t.fgOnBrand : t.fgPrimary;

    return Semantics(
      label: semanticLabel ?? fallbackText,
      image: true,
      child: SizedBox(
        width: _size,
        height: _size,
        child: ClipOval(
          child: Container(
            color: bg,
            alignment: Alignment.center,
            child: imageProvider != null
                ? Image(
                    image: imageProvider!,
                    fit: BoxFit.cover,
                    width: _size,
                    height: _size,
                    errorBuilder: (context, error, stackTrace) => _fallback(fg),
                  )
                : _fallback(fg),
          ),
        ),
      ),
    );
  }

  Widget _fallback(Color fg) {
    final letters = (fallbackText ?? '?').trim();
    final display = letters.isEmpty
        ? '?'
        : (letters.runes.length > 2
              ? letters.characters.take(2).toString()
              : letters);
    return Text(
      display,
      style: TextStyle(
        fontFamily: PTypo.sans,
        fontSize: _fontSize,
        fontWeight: PFontWeight.semi,
        color: fg,
      ),
    );
  }
}

/// 여러 avatar 겹침 그룹. 4–5개까지 + `+N` fallback. 각 avatar 사이 8px 겹침.
class PAvatarGroup extends StatelessWidget {
  const PAvatarGroup({
    super.key,
    required this.avatars,
    this.overflowCount = 0,
    this.size = PAvatarSize.md,
  });

  final List<PAvatar> avatars;

  /// `+N` 추가 표시. 0 이면 미표시.
  final int overflowCount;

  final PAvatarSize size;

  double get _avatarSize => switch (size) {
    PAvatarSize.sm => 32,
    PAvatarSize.md => 40,
    PAvatarSize.lg => 48,
    PAvatarSize.xl => 64,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final overlap = 8.0;
    final all = [
      ...avatars,
      if (overflowCount > 0)
        PAvatar(
          fallbackText: '+$overflowCount',
          size: size,
          fill: PAvatarFill.neutral,
        ),
    ];
    return SizedBox(
      height: _avatarSize,
      width: _avatarSize + (all.length - 1) * (_avatarSize - overlap),
      child: Stack(
        children: [
          for (int i = 0; i < all.length; i++)
            Positioned(
              left: i * (_avatarSize - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.bgSurface, width: 2),
                ),
                child: all[i],
              ),
            ),
        ],
      ),
    );
  }
}
