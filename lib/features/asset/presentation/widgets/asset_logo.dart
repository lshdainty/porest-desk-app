import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';

/// 자산 로고 — ds Logo Tile 이다(03E-010). 기관 이름(없으면 자산 이름)으로 기관 색 표 하나(institution-colors.yaml)에서
/// 면 색 · 글자색을 찾고, 표에 없으면 Avatar 와 같은 이름 색이다. 저장된 자산 색(asset.color)과 이름 해시 색은 읽지 않는다.
///
/// 카드 정식 이미지(카탈로그)가 있으면 옅은 판 위에 카드 비율로 올리고, 받는 동안 · 못 받으면 첫 글자 면 그대로다.
/// 크기는 Logo Tile 의 32 · 40 · 48 중 가장 가까운 큰 쪽이다([size] 가 32 이하면 32, 40 이하면 40, 그 위는 48).
class AssetLogo extends StatelessWidget {
  const AssetLogo({super.key, required this.asset, this.size = 40});

  final Asset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final institution = asset.institution?.trim() ?? '';
    final imgUrl = asset.cardCatalog?.imgUrl;
    return PLogoTile(
      // 기관이 있으면 기관 색 표에서, 없으면 사용자가 지은 자산 이름이라 표를 보지 않는다(짧은 별칭이 걸리지 않게)
      name: institution.isNotEmpty ? institution : asset.assetName,
      face: institution.isNotEmpty
          ? PLogoTileFace.institution
          : PLogoTileFace.name,
      size: size <= 32
          ? PLogoTileSize.s32
          : size <= 40
          ? PLogoTileSize.s40
          : PLogoTileSize.s48,
      image: imgUrl != null && imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
      imageType: PLogoTileImageType.card,
    );
  }
}
