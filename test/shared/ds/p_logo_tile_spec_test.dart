// Logo Tile · 기관 색 표가 스펙 값(logo-tile.json · institution-colors.json)대로인지 — 크기 셋 × 면 둘 × 그림 셋 × 라이트 · 다크의
// 타일 크기 · 모서리 · 첫 글자 · 면 색 · 글자색 · 윤곽 · 판, 카드 그림 폭(크기 − 8) · 모서리 · 세로 돌림, 첫 글자 먼저 · 늦은 그림 · 실패,
// 이름(장식 · 읽는 이름), 기관 색 찾기(공백 · 별칭 · 가장 긴 이름 · 거꾸로 안 맞춤)와 78곳의 글자 대비 4.5. 웹은 같은 JSON 을 크로미움에서 잰다.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/ds/avatar/p_avatar.dart';
import 'package:porest_desk_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:porest_desk_app/shared/ds/institution_colors/institution_colors.dart';
import 'package:porest_desk_app/shared/ds/logo_tile/p_logo_tile.dart';

import '../../support/design_spec.dart';
import '../../support/fake_image.dart';

final _spec = DesignSpec.load('logo-tile');
final _table = PInstitutionTable.fromSpecJson(
  jsonDecode(
        File(
          'test/fixtures/design_spec/institution-colors.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light(),
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

PLogoTileSize _sizeOf(String s) =>
    PLogoTileSize.values.firstWhere((v) => v.name == 's$s');

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final hi = math.max(_lum(a), _lum(b));
  final lo = math.min(_lum(a), _lum(b));
  return (hi + 0.05) / (lo + 0.05);
}

Finder _tile() => find.byType(PLogoTile);
Finder _in(Finder f) => find.descendant(of: _tile(), matching: f);

void main() {
  setUpAll(() => PInstitutionColors.table = _table);
  tearDownAll(() => PInstitutionColors.table = PInstitutionTable.empty);

  group('기관 색 표', () {
    test('스펙 JSON 의 78곳을 그대로 읽는다(표가 둘이 아니다)', () {
      final json =
          jsonDecode(
                File(
                  'test/fixtures/design_spec/institution-colors.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final names = [
        for (final e in (json['data'] as Map)['entries'] as List)
          (e as Map)['name'],
      ];
      expect(_table.entries, hasLength(78));
      expect(_table.entries.map((e) => e.name), names);
    });

    test(
      '글자색이 78곳 모두 4.5:1 이상이다 — white 는 흰색, dark 는 라이트 fg-neutral · 다크 fg-neutral-inverted 로 잰다',
      () {
        final failures = <String>[];
        for (final e in _table.entries) {
          final texts = e.text == PInstitutionText.white
              ? [PColors.light.staticWhite, PColors.dark.staticWhite]
              : [PColors.light.fgNeutral, PColors.dark.fgNeutralInverted];
          for (final t in texts) {
            final r = _contrast(e.color, t);
            if (r < 4.5) failures.add('${e.name} ${r.toStringAsFixed(2)}');
          }
        }
        expect(failures, isEmpty, reason: failures.join(', '));
      },
    );

    test('공백을 빼고 같은 이름 · 별칭이면 그 기관이다', () {
      expect(_table.find('신한')!.color, const Color(0xFF0046FF));
      expect(_table.find('신한은행')!.name, '신한');
      expect(_table.find(' KB 국민 ')!.name, 'KB국민');
    });

    test('아니면 이름에 든 가장 긴 이름 — 거꾸로 맞추지 않는다', () {
      expect(_table.find('NH농협카드 올원')!.name, 'NH농협카드');
      expect(_table.find('IBK기업은행')!.name, 'IBK기업');
      // 표의 "NH농협" 이 찾는 이름 "NH" 를 품는 거꾸로 맞추기는 하지 않는다
      expect(_table.find('NH'), isNull);
    });

    test('같은 회사는 한 색', () {
      expect(_table.find('하나')!.color, const Color(0xFF008485));
      expect(_table.find('하나카드')!.color, const Color(0xFF008485));
      expect(_table.find('NH농협')!.color, const Color(0xFF00A651));
    });

    test('없거나 비면 null', () {
      expect(_table.find('어떤은행'), isNull);
      expect(_table.find(''), isNull);
      expect(_table.find(null), isNull);
      expect(PInstitutionTable.empty.find('신한'), isNull);
    });
  });

  test('축 · 기본값이 스펙과 같다', () {
    expect(_spec.axes['size'], ['32', '40', '48']);
    expect(_spec.defaults, {
      'size': '40',
      'face': 'institution',
      'image': 'none',
    });
    const tile = PLogoTile(name: '신한');
    expect(tile.size, PLogoTileSize.s40);
    expect(tile.face, PLogoTileFace.institution);
    expect(tile.decorative, isTrue);
    expect(tile.imageType, PLogoTileImageType.logo);
  });

  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} — 크기 × 면 × 그림이 스펙 값이다(타일 · 모서리 · 첫 글자 · 면 · 글자 · 윤곽 · 판)',
      (tester) async {
        final cardPic = await testPicture(tester, 856, 540);
        final logoPic = await testPicture(tester, 200, 120);
        final c = mode == Brightness.dark ? PColors.dark : PColors.light;
        final failures = <String>[];
        for (final combo in _spec.combos(['size', 'face', 'image'])) {
          final want = _spec.resolve(combo, 'enabled');
          final size = _sizeOf(combo['size']!);
          // 기관 색 면은 표의 기관 이름으로, 이름 색 면은 표에 없는 이름으로
          final name = combo['face'] == 'institution' ? '신한' : '비상금';
          final isCard = combo['image'] == 'card';
          await tester.pumpWidget(
            _host(
              mode,
              PLogoTile(
                key: UniqueKey(),
                name: name,
                face: combo['face'] == 'institution'
                    ? PLogoTileFace.institution
                    : PLogoTileFace.name,
                size: size,
                image: combo['image'] == 'none'
                    ? null
                    : FakeImage(isCard ? cardPic : logoPic),
                imageType: isCard
                    ? PLogoTileImageType.card
                    : PLogoTileImageType.logo,
              ),
            ),
          );
          void check(String what, Object? expected, Object? actual) {
            if (expected != actual) {
              failures.add('$combo $what: 스펙 $expected · 위젯 $actual');
            }
          }

          final box = (want['root.size'] as num).toDouble();
          check('크기', Size(box, box), tester.getSize(_tile()));
          final clip = tester.widget<ClipRRect>(
            _in(find.byType(ClipRRect)).first,
          );
          check(
            '모서리',
            (want['root.radius'] as num).toDouble(),
            (clip.borderRadius as BorderRadius).topLeft.x,
          );
          final stroke =
              tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: _in(find.byType(PImageStroke)).last,
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          final side = (stroke.border as Border).top;
          check(
            '윤곽 두께',
            (want['stroke.borderWidth'] as num).toDouble(),
            side.width,
          );
          if (!sameColor(
            specColor(pickMode(want['stroke.borderColor'], mode)),
            side.color,
          )) {
            failures.add('$combo 윤곽 색');
          }
          check(
            '윤곽 모서리',
            (want['root.radius'] as num).toDouble(),
            (stroke.borderRadius as BorderRadius).topLeft.x,
          );

          if (combo['image'] == 'none') {
            // 첫 글자 — 크기의 40% · 700 · 줄 높이 1
            final text = tester.widget<Text>(_in(find.byType(Text)));
            check('글자', avatarInitial(name), text.data);
            check(
              '글자 크기',
              (want['initial.fontSize'] as num).toDouble(),
              text.style!.fontSize,
            );
            check('글자 굵기', FontWeight.w700, text.style!.fontWeight);
            check('줄 높이', 1.0, text.style!.height);
            check('글자 크기 설정', TextScaler.noScaling, text.textScaler);
            final face = tester.widget<ColoredBox>(
              _in(find.byType(ColoredBox)).first,
            );
            if (combo['face'] == 'institution') {
              check('기관 색', _table.find(name)!.color, face.color);
              // 흰 글자(static-white)
              check('기관 글자', c.staticWhite, text.style!.color);
            } else {
              check('이름 색', avatarHueColor(c, name), face.color);
              final fg = specColor(pickMode(want['initial.foreground'], mode));
              if (!sameColor(fg, text.style!.color!))
                failures.add('$combo 이름 글자 색');
            }
          } else {
            // 그림이 덮는다 — 판 색 · 안쪽 4
            final plate = tester.widget<ColoredBox>(
              find.byKey(
                ValueKey('logo-tile-plate-${isCard ? 'card' : 'logo'}'),
              ),
            );
            if (!sameColor(
              specColor(pickMode(want['plate.background'], mode)),
              plate.color,
            )) {
              failures.add('$combo 판 색');
            }
            final pad = tester.widget<Padding>(
              find
                  .descendant(
                    of: find.byWidget(plate),
                    matching: find.byType(Padding),
                  )
                  .first,
            );
            check(
              '판 안쪽',
              EdgeInsets.all((want['plate.padding'] as num).toDouble()),
              pad.padding,
            );
            // 첫 글자는 덮여 가려진다 — 이름 글은 더 읽지 않는다
            if (isCard) {
              final w = box - 8;
              final card = tester.getSize(
                find.byKey(const ValueKey('logo-tile-card')),
              );
              check('카드 그림 폭', w, card.width);
              if ((card.height - w / 1.586).abs() > 0.01)
                failures.add('$combo 카드 그림 높이 ${card.height}');
              final cardClip = tester.widget<ClipRRect>(
                find.descendant(
                  of: find.byKey(const ValueKey('logo-tile-card')),
                  matching: find.byType(ClipRRect),
                ),
              );
              check(
                '카드 그림 모서리',
                imageFrameRadius(w),
                (cardClip.borderRadius as BorderRadius).topLeft.x,
              );
            } else {
              final image = tester.widget<Image>(
                find.byKey(const ValueKey('logo-tile-image')),
              );
              check('로고 맞춤', BoxFit.contain, image.fit);
              final inner = tester.getSize(
                find.byKey(const ValueKey('logo-tile-image')),
              );
              check('로고 상자', Size(box - 8, box - 8), inner);
            }
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );

    testWidgets('${mode.name} — 기관 색 78곳이 표의 면 색 · 글자색이다', (tester) async {
      final c = mode == Brightness.dark ? PColors.dark : PColors.light;
      await tester.pumpWidget(
        _host(
          mode,
          SingleChildScrollView(
            child: Wrap(
              children: [
                for (final e in _table.entries)
                  PLogoTile(key: ValueKey(e.name), name: e.name),
              ],
            ),
          ),
        ),
      );
      final failures = <String>[];
      for (final e in _table.entries) {
        final tile = find.byKey(ValueKey(e.name));
        final face = tester.widget<ColoredBox>(
          find.descendant(of: tile, matching: find.byType(ColoredBox)).first,
        );
        final text = tester.widget<Text>(
          find.descendant(of: tile, matching: find.byType(Text)),
        );
        final want = e.text == PInstitutionText.white
            ? c.staticWhite
            : (mode == Brightness.dark ? c.fgNeutralInverted : c.fgNeutral);
        if (face.color != e.color) failures.add('${e.name} 면');
        if (text.style!.color != want) failures.add('${e.name} 글자');
      }
      expect(failures, isEmpty, reason: failures.join(', '));
    });
  }

  group('첫 글자 · 면', () {
    testWidgets('이름의 첫 글자 하나 — 로마자는 대문자, 긴 이름 · 그림 글자도 하나', (tester) async {
      for (final (name, want) in [
        ('신한', '신'),
        ('KB국민', 'K'),
        ('Upbit', 'U'),
        ('이것은아주아주아주긴기관이름이라타일안에서넘치지않아야합니다', '이'),
        ('👨‍👩‍👧 우리집', '👨‍👩‍👧'),
      ]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PLogoTile(key: UniqueKey(), name: name, face: PLogoTileFace.name),
          ),
        );
        expect(
          tester.widget<Text>(_in(find.byType(Text))).data,
          want,
          reason: name,
        );
      }
    });

    testWidgets(
      'face 가 name 이면 표를 보지 않는다 — "우리 아이 적금" · "하나투어" 에 별칭이 걸리지 않는다',
      (tester) async {
        final c = PColors.light;
        await tester.pumpWidget(
          _host(
            Brightness.light,
            const PLogoTile(name: '하나투어', face: PLogoTileFace.name),
          ),
        );
        var face = tester.widget<ColoredBox>(
          _in(find.byType(ColoredBox)).first,
        );
        expect(face.color, avatarHueColor(c, '하나투어'));
        // 기관 면이면 든 가장 긴 이름("하나")에 걸린다 — 그래서 호출하는 쪽이 name 으로 보낸다
        await tester.pumpWidget(
          _host(Brightness.light, PLogoTile(key: UniqueKey(), name: '하나투어')),
        );
        face = tester.widget<ColoredBox>(_in(find.byType(ColoredBox)).first);
        expect(face.color, _table.find('하나')!.color);
      },
    );

    testWidgets('표에 없는 기관은 이름 색, 이름이 비면 글자 없이 chart-gray', (tester) async {
      final c = PColors.light;
      await tester.pumpWidget(
        _host(Brightness.light, const PLogoTile(name: '어떤은행')),
      );
      expect(
        tester.widget<ColoredBox>(_in(find.byType(ColoredBox)).first).color,
        avatarHueColor(c, '어떤은행'),
      );
      expect(
        tester.widget<Text>(_in(find.byType(Text))).style!.color,
        c.fgNeutralInverted,
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PLogoTile(key: UniqueKey(), name: '', face: PLogoTileFace.name),
        ),
      );
      expect(
        tester.widget<ColoredBox>(_in(find.byType(ColoredBox)).first).color,
        c.chartGray,
      );
      expect(_in(find.byType(Text)), findsNothing);
    });
  });

  group('그림', () {
    testWidgets('첫 글자를 먼저 그리고(스켈레톤 없음) 다 받으면 덮고, 못 받으면 첫 글자 그대로', (
      tester,
    ) async {
      final pic = await testPicture(tester, 200, 120);
      final late = FakeImage();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PLogoTile(name: '새회사', face: PLogoTileFace.name, image: late),
        ),
      );
      expect(_in(find.byType(Text)), findsOneWidget);
      expect(find.byKey(const ValueKey('logo-tile-image')), findsNothing);
      late.emit(pic);
      await tester.pump();
      // 전환 없이 바로 — 판이 있고 곧바로 그림이 보인다
      expect(find.byKey(const ValueKey('logo-tile-image')), findsOneWidget);
      expect(find.byType(Opacity), findsNothing);

      final bad = FakeImage.failing();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PLogoTile(
            key: UniqueKey(),
            name: '현대카드',
            image: bad,
            imageType: PLogoTileImageType.card,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('logo-tile-card')), findsNothing);
      expect(_in(find.byType(Text)), findsOneWidget);
      expect(
        tester.widget<ColoredBox>(_in(find.byType(ColoredBox)).first).color,
        _table.find('현대카드')!.color,
      );
    });

    testWidgets('카드 그림이 세로면 90° 돌려 채운다 — 가로 · 정사각은 그대로', (tester) async {
      for (final (w, h, rotated) in [
        (540, 856, true),
        (856, 540, false),
        (500, 500, false),
      ]) {
        final pic = await testPicture(tester, w, h);
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PLogoTile(
              key: UniqueKey(),
              name: '삼성카드',
              image: FakeImage(pic),
              imageType: PLogoTileImageType.card,
            ),
          ),
        );
        expect(
          _in(find.byType(RotatedBox)),
          rotated ? findsOneWidget : findsNothing,
          reason: '$w x $h',
        );
        if (rotated) {
          expect(
            tester
                .widget<RotatedBox>(_in(find.byType(RotatedBox)))
                .quarterTurns,
            1,
          );
        }
      }
    });
  });

  group('이름', () {
    testWidgets('이름 옆(기본)이면 타일 전체를 숨기고, 혼자면 이름 하나로 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final pic = await testPicture(tester, 200, 120);
      await tester.pumpWidget(
        _host(Brightness.light, const PLogoTile(name: '신한')),
      );
      expect(find.bySemanticsLabel('신한'), findsNothing);
      expect(find.bySemanticsLabel('신'), findsNothing);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PLogoTile(key: UniqueKey(), name: '신한', decorative: false),
        ),
      );
      expect(find.bySemanticsLabel('신한'), findsOneWidget);
      // 첫 글자 "신" 은 따로 읽지 않는다
      expect(find.bySemanticsLabel('신'), findsNothing);
      // 그림이 있어도 같은 이름
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PLogoTile(
            key: UniqueKey(),
            name: '신한',
            decorative: false,
            image: FakeImage(pic),
          ),
        ),
      );
      expect(find.bySemanticsLabel('신한'), findsOneWidget);
      semantics.dispose();
    });
  });
}
