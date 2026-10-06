// porest-design 에서 가져온 것(scripts/sync_design.sh)이 서로 맞는지 본다.
//
// 토큰(lib/app/theme/porest_tokens.g.dart)과 스펙 값(test/fixtures/design_spec)은 한 번에
// 같은 DESIGN 에서 만든다. 하나만 손으로 고치거나 반만 가져오면 위젯은 새 토큰으로 그리는데
// 테스트는 옛 스펙 값과 비교하게 된다 — 그 어긋남을 여기서 먼저 잡는다.
//
// 옛 이름(PorestTokens)은 역할 색(PColors)에서 만든다(앱 적용 5A, 2026-10-06). 웹 index.css 와
// 같은 짝이라 두 제품이 같은 값을 쓴다 — 짝이 바뀌면 웹도 같이 바꿔야 하니 여기 적어 둔다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';

void main() {
  test('토큰과 스펙 값은 같은 DESIGN 에서 왔다', () {
    final index =
        jsonDecode(
              File('test/fixtures/design_spec/index.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final design = index['design'] as Map<String, dynamic>;
    expect(design['file'], PDesignSource.file);
    expect(design['sha256'], PDesignSource.sha256);
  });

  for (final (mode, tokens, c) in [
    ('라이트', PorestTokens.light, PColors.light),
    ('다크', PorestTokens.dark, PColors.dark),
  ]) {
    test('$mode — 옛 이름은 역할 색을 따른다', () {
      // 글자
      expect(tokens.fgPrimary, c.fgNeutral);
      expect(tokens.fgSecondary, c.fgNeutralMuted);
      expect(tokens.fgTertiary, c.fgNeutralSubtle);
      expect(tokens.fgOnBrand, c.staticWhite);
      expect(tokens.fgBrandStrong, c.fgBrandContrast);
      // 배경
      expect(tokens.bgCanvas, c.bgLayerBasement);
      expect(tokens.bgSurface, c.bgLayerDefault);
      expect(tokens.bgSurfaceRaised, c.bgLayerFloating);
      expect(tokens.bgMuted, c.bgNeutralWeak);
      expect(tokens.bgBrandSolid, c.bgBrandSolid);
      expect(tokens.bgBrandSubtle, c.bgBrandWeak);
      // 선
      expect(tokens.borderSubtle, c.strokeNeutralSubtle);
      expect(tokens.borderDefault, c.strokeNeutralWeak);
      expect(tokens.borderFocus, c.strokeFocusRing);
      // 상태 — 채움 · 글자 · 선이 다른 역할이다
      expect(tokens.statusDanger, c.bgCriticalSolid);
      expect(tokens.statusDangerFg, c.fgCritical);
      expect(tokens.statusDangerBorder, c.strokeCriticalSolid);
      expect(tokens.statusDangerSubtle, c.bgCriticalWeak);
    });
  }

  test('앱의 bgBrand 는 강조색이라 글자 역할(fg-brand)을 따른다 — 다크에서 밝다', () {
    expect(PorestTokens.light.bgBrand, PColors.light.fgBrand);
    expect(PorestTokens.dark.bgBrand, PColors.dark.fgBrand);
    // 흰 글자를 얹는 채움은 bgBrandSolid — 다크에서도 어둡다
    expect(
      PorestTokens.dark.bgBrandSolid.computeLuminance(),
      lessThan(PorestTokens.dark.bgBrand.computeLuminance()),
    );
  });
}
