// 3 표시 묶음(Badge · Notification Badge · Tag Group · Avatar · Avatar Stack · Divider)이 스펙 값대로인지 — 조합 ×
// 라이트 · 다크. 값은 test/fixtures/design_spec/*.json, 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/ds/avatar/p_avatar.dart';
import 'package:porest_desk_app/shared/ds/badge/p_badge.dart';
import 'package:porest_desk_app/shared/ds/divider/p_divider.dart';
import 'package:porest_desk_app/shared/ds/notification_badge/p_notification_badge.dart';
import 'package:porest_desk_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light(),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: 320, child: Center(child: child)),
    ),
  ),
);

/// 실패를 모으는 작은 도우미 — 색 · 수를 스펙과 맞춘다.
class _Check {
  _Check(this.mode, this.want, this.where);
  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return;
    if (!sameColor(specColor(w), actual)) {
      failures.add('$where — $key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      failures.add('$where — $key: 스펙 $w · 실제 $actual');
    }
  }

  void typo(String key, TextStyle style) {
    final t = want[key] as Map?;
    if (t == null) return;
    final lineHeight = style.fontSize! * (style.height ?? 1);
    if (t['fontSize'] != style.fontSize ||
        ((t['lineHeight'] as num) - lineHeight).abs() > 0.01) {
      failures.add(
        '$where — $key: 스펙 ${t['fontSize']}/${t['lineHeight']} · 실제 ${style.fontSize}/$lineHeight',
      );
    }
  }

  void weight(String key, TextStyle style) {
    final w = want[key];
    if (w is num && style.fontWeight?.value != w) {
      failures.add('$where — $key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }
}

void main() {
  group('Badge', () {
    final spec = DesignSpec.load('badge');
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 변형 × 톤 × 크기', (tester) async {
        final failures = <String>[];
        for (final combo in spec.combos(['variant', 'tone', 'size'])) {
          await tester.pumpWidget(
            _host(
              mode,
              PBadge(
                key: UniqueKey(),
                label: '연체',
                prefixIcon: LucideIcons.clock,
                variant: PBadgeVariant.values.byName(combo['variant']!),
                tone: PBadgeTone.values.byName(combo['tone']!),
                size: PBadgeSize.values.byName(combo['size']!),
              ),
            ),
          );
          final k = _Check(mode, spec.resolve(combo, 'enabled'), '$combo');
          final box = tester.widget<Container>(
            find.descendant(
              of: find.byType(PBadge),
              matching: find.byType(Container),
            ),
          );
          final deco = box.decoration! as BoxDecoration;
          k.color('root.background', deco.color!);
          k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
          k.px('root.minHeight', box.constraints!.minHeight);
          k.px('root.minHeight', tester.getSize(find.byType(PBadge)).height);
          final pad = box.padding! as EdgeInsets;
          k.px('root.paddingX', pad.left);
          k.px('root.paddingY', pad.top);
          final border =
              (box.foregroundDecoration as BoxDecoration?)?.border as Border?;
          if (k.want.containsKey('root.borderColor')) {
            if (border == null) {
              k.failures.add('${k.where} — root.borderColor: 테두리가 없다');
            } else {
              k.color('root.borderColor', border.top.color);
              k.px('root.borderWidth', border.top.width);
            }
          } else if (border != null) {
            k.failures.add('${k.where} — 스펙에 없는 테두리');
          }
          final text = tester.widget<Text>(find.text('연체'));
          k.typo('label.typography', text.style!);
          k.weight('label.fontWeight', text.style!);
          k.color('root.foreground', text.style!.color!);
          final icon = tester.widget<Icon>(find.byType(Icon));
          k.px('prefixIcon.size', icon.size!);
          k.color('root.foreground', icon.color!);
          k.px(
            'root.gap',
            tester
                .widget<Row>(
                  find.descendant(
                    of: find.byType(PBadge),
                    matching: find.byType(Row),
                  ),
                )
                .spacing,
          );
          failures.addAll(k.failures);
        }
        if (failures.isNotEmpty) fail(failures.join('\n'));
      });
    }

    testWidgets('묶음은 사이 4, 넘치면 각자 말줄임한다', (tester) async {
      final want = spec.resolve({}, 'enabled');
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PBadgeGroup(
            children: [
              PBadge(label: '아주 긴 배지 글이 들어간다'),
              PBadge(label: '또 다른 긴 배지 글'),
            ],
          ),
        ),
      );
      final row = tester.widget<Row>(
        find
            .descendant(
              of: find.byType(PBadgeGroup),
              matching: find.byType(Row),
            )
            .first,
      );
      expect(row.spacing, want['group.gap']);
      expect(tester.takeException(), isNull);
    });
  });

  group('Notification Badge', () {
    final spec = DesignSpec.load('notification-badge');

    test('숫자 글 — 0 이면 없고 100 이상이면 99+', () {
      expect(notificationBadgeLabel(0), isNull);
      expect(notificationBadgeLabel(1), '1');
      expect(notificationBadgeLabel(99), '99');
      expect(notificationBadgeLabel(128), '99+');
    });

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기 × 붙는 자리', (tester) async {
        final failures = <String>[];
        for (final combo in spec.combos(['size', 'attach'])) {
          final large = combo['size'] == 'large';
          final onIcon = combo['attach'] == 'icon';
          await tester.pumpWidget(
            _host(
              mode,
              PNotificationBadge(
                key: UniqueKey(),
                count: large ? 8 : null,
                size: PNotificationBadgeSize.values.byName(combo['size']!),
                attach: PNotificationBadgeAttach.values.byName(
                  combo['attach']!,
                ),
                child: onIcon
                    ? const SizedBox(width: 24, height: 24)
                    : const Text('알림', style: PTypography.t4),
              ),
            ),
          );
          final k = _Check(mode, spec.resolve(combo, 'enabled'), '$combo');
          final badge = find.byKey(const ValueKey('notification-badge'));
          final deco =
              tester.widget<Container>(badge).decoration! as BoxDecoration;
          k.color('root.background', deco.color!);
          k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
          final rect = tester.getRect(badge);
          final host = tester.getRect(
            find
                .descendant(
                  of: find.byType(PNotificationBadge),
                  matching: onIcon ? find.byType(SizedBox) : find.byType(Text),
                )
                .first,
          );
          if (large) {
            // 폭은 글자에 따라 자란다 — 테스트 글꼴은 글자 폭이 글자 크기라 한 자리도 18 을 넘으니 최소값을 잰다
            final pill = tester.widget<Container>(badge);
            k.px('root.minWidth', pill.constraints!.minWidth);
            k.px('root.minHeight', pill.constraints!.minHeight);
            k.px('root.minHeight', rect.height);
            k.px('root.paddingX', (pill.padding! as EdgeInsets).left);
            k.px('root.paddingX', (pill.padding! as EdgeInsets).right);
            final label = tester.widget<Text>(find.text('8'));
            k.typo('label.typography', label.style!);
            k.weight('label.fontWeight', label.style!);
            k.color('label.foreground', label.style!.color!);
            if (label.textScaler != TextScaler.noScaling) {
              k.failures.add('${k.where} — 숫자는 글자 크기 설정을 따르지 않는다');
            }
          } else {
            k.px('root.size', rect.width);
            k.px('root.size', rect.height);
          }
          if (onIcon && !large) {
            k.px('root.top', rect.top - host.top);
            k.px('root.right', host.right - rect.right);
          }
          if (onIcon && large) {
            // 왼쪽 아래 꼭짓점 = (아이콘 폭 − 8, 14)
            if ((rect.left - (host.right - 8)).abs() > 0.5 ||
                (rect.bottom - (host.top + 14)).abs() > 0.5) {
              k.failures.add(
                '${k.where} — 숫자 자리: ${rect.bottomLeft - host.topLeft}',
              );
            }
          }
          if (!onIcon) {
            // 글 끝 + 2 · 줄 상자 위 끝
            if ((rect.left - (host.right + 2)).abs() > 0.5 ||
                (rect.top - host.top).abs() > 0.5) {
              k.failures.add(
                '${k.where} — 글에 붙는 자리: ${rect.topLeft - host.topRight}',
              );
            }
          }
          // 자리를 차지하지 않는다
          if (tester.getSize(find.byType(PNotificationBadge)) != host.size) {
            k.failures.add('${k.where} — 붙은 대상의 크기가 바뀌었다');
          }
          failures.addAll(k.failures);
        }
        if (failures.isNotEmpty) fail(failures.join('\n'));
      });
    }

    testWidgets('읽지 않는다 — 붙은 버튼의 이름이 알린다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PNotificationBadge(
            count: 3,
            size: PNotificationBadgeSize.large,
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      );
      expect(find.bySemanticsLabel('3'), findsNothing);
      semantics.dispose();
    });
  });

  group('Tag Group', () {
    final spec = DesignSpec.load('tag-group');
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기 × 톤 × 굵기 × 넘침', (tester) async {
        final failures = <String>[];
        for (final combo in spec.combos([
          'size',
          'tone',
          'weight',
          'overflow',
        ])) {
          final truncate = combo['overflow'] == 'truncate';
          await tester.pumpWidget(
            _host(
              mode,
              PTagGroup(
                key: UniqueKey(),
                size: PTagGroupSize.values.byName(combo['size']!),
                tone: PTagTone.values.byName(combo['tone']!),
                weight: PTagWeight.values.byName(combo['weight']!),
                overflow: PTagGroupOverflow.values.byName(combo['overflow']!),
                items: const [
                  PTag('식비', icon: LucideIcons.utensils),
                  PTag('신한카드'),
                ],
              ),
            ),
          );
          final k = _Check(mode, spec.resolve(combo, 'enabled'), '$combo');
          final TextStyle item;
          final TextStyle separator;
          if (truncate) {
            item = tester.widget<Text>(find.text('식비')).style!;
            separator = tester
                .widget<Text>(find.text(tagGroupSeparator))
                .style!;
          } else {
            final rich = tester.widget<Text>(
              find
                  .descendant(
                    of: find.byType(PTagGroup),
                    matching: find.byType(Text),
                  )
                  .first,
            );
            final spans = (rich.textSpan! as TextSpan).children!
                .whereType<TextSpan>()
                .toList();
            item = spans.firstWhere((s) => s.text == keepAll('식비')).style!;
            separator = spans
                .firstWhere((s) => s.text == tagGroupSeparator)
                .style!;
          }
          k.typo('item.typography', item);
          k.color('item.foreground', item.color!);
          k.weight('item.fontWeight', item);
          k.typo('separator.typography', separator);
          k.color('separator.foreground', separator.color!);
          k.weight('separator.fontWeight', separator);
          final icon = tester.widget<Icon>(find.byType(Icon));
          k.px('icon.size', icon.size!);
          k.color('item.foreground', icon.color!);
          failures.addAll(k.failures);
        }
        if (failures.isNotEmpty) fail(failures.join('\n'));
      });
    }

    testWidgets('묶음 하나로 ", " 를 이어 읽는다 — 아이콘의 뜻은 srLabel', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PTagGroup(
            items: [
              PTag('식비'),
              PTag('2', icon: LucideIcons.split, srLabel: '분할 2건'),
              PTag('오후 2:10'),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('식비, 분할 2건, 오후 2:10'), findsOneWidget);
      semantics.dispose();
    });

    test('구분은 줄이 안 바뀌는 공백 · 가운뎃점 · 공백', () {
      final want = spec.resolve({}, 'enabled');
      expect('${want['separator.glyph']}'.trim(), '·');
      expect(tagGroupSeparator, ' · ');
    });

    test('낱말 안에서는 줄을 바꾸지 않는다 — 이음 문자', () {
      expect(keepAll('신한 카드'), '신⁠한 카⁠드');
    });
  });

  group('Avatar', () {
    final spec = DesignSpec.load('avatar');

    test('이니셜 · 이름 색 — 웹과 같은 규칙', () {
      expect(avatarInitial('  김민수 '), '김');
      expect(avatarInitial('kim minsu'), 'K');
      expect(avatarInitial('7월 모임'), '7');
      // 코드 포인트 합 % 10 — "김민수" = 44608 + 48124 + 49688
      expect(avatarHueIndex('김민수'), (44608 + 48124 + 49688) % 10);
      // 이모지는 코드 포인트 하나로 센다(UTF-16 둘이 아니다)
      expect(avatarHueIndex('😀'), 0x1F600 % 10);
    });

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기마다 지름 · 이니셜 · 테두리', (tester) async {
        final failures = <String>[];
        for (final combo in spec.combos(['size'])) {
          final size = PAvatarSize.values.byName('s${combo['size']}');
          await tester.pumpWidget(
            _host(mode, PAvatar(key: UniqueKey(), name: '김민수', size: size)),
          );
          final k = _Check(mode, spec.resolve(combo, 'enabled'), '$combo');
          final rect = tester.getSize(find.byType(PAvatar));
          k.px('root.size', rect.width);
          k.px('root.size', rect.height);
          final initial = tester.widget<Text>(find.text('김')).style!;
          k.px('initial.fontSize', initial.fontSize!);
          k.weight('initial.fontWeight', initial);
          k.color('initial.foreground', initial.color!);
          if (initial.height != 1) k.failures.add('${k.where} — 이니셜 줄 높이 1');
          final face = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(PAvatar),
                  matching: find.byType(Container),
                )
                .first,
          );
          final border =
              (face.foregroundDecoration! as BoxDecoration).border! as Border;
          k.px('border.borderWidth', border.top.width);
          k.color('border.borderColor', border.top.color);
          // 이름 색 바탕 — 차트 색(라이트 700 · 다크 800-dark)
          final c = mode == Brightness.dark ? PColors.dark : PColors.light;
          // 가장 가까운 ColoredBox — 더 바깥은 앱 · 화면의 바탕이다
          final bg = tester
              .widget<ColoredBox>(
                find
                    .ancestor(
                      of: find.text('김'),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color;
          if (bg != avatarHueColor(c, '김민수')) {
            k.failures.add('${k.where} — 이름 색이 다르다');
          }
          failures.addAll(k.failures);
        }
        if (failures.isNotEmpty) fail(failures.join('\n'));
      });
    }

    testWidgets('옆에 이름이 있으면 읽지 않고, 혼자면 이름을 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, const PAvatar(name: '김민수')),
      );
      expect(find.bySemanticsLabel('김민수'), findsNothing);
      await tester.pumpWidget(
        _host(Brightness.light, const PAvatar(name: '김민수', decorative: false)),
      );
      expect(find.bySemanticsLabel('김민수'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('Avatar Stack', () {
    final spec = DesignSpec.load('avatar-stack');
    final people = [
      for (final n in ['김민수', '이서연', '박지훈', '최유진', '정다은', '한지민'])
        (name: n, image: null),
    ];

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기마다 겹침 · 링 · "+N"', (tester) async {
        final failures = <String>[];
        for (final combo in spec.combos(['size'])) {
          final size = PAvatarSize.values.byName('s${combo['size']}');
          await tester.pumpWidget(
            _host(
              mode,
              PAvatarStack(key: UniqueKey(), people: people, size: size),
            ),
          );
          final k = _Check(mode, spec.resolve(combo, 'enabled'), '$combo');
          final avatars = find.byType(PAvatar);
          if (avatars.evaluate().length !=
              spec.resolve(combo, 'enabled')['root.items']) {
            k.failures.add('${k.where} — 앞 4명만 보인다');
          }
          final a = tester.getRect(avatars.at(0));
          final b = tester.getRect(avatars.at(1));
          k.px('item.size', a.width);
          // 겹침 = 다음 아바타의 왼쪽 바깥 여백(음수)
          k.px('root.gap', b.left - a.right);
          final ring = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(PAvatarStack),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .map((d) => d.decoration as BoxDecoration)
              .firstWhere((d) => d.boxShadow != null)
              .boxShadow!
              .single;
          k.px('item.outlineWidth', ring.spreadRadius);
          k.color('item.outlineColor', ring.color);
          final more = find.byKey(const ValueKey('avatar-stack-overflow'));
          final moreDeco =
              tester.widget<Container>(more).decoration! as BoxDecoration;
          k.color('overflow.background', moreDeco.color!);
          k.px('overflow.size', tester.getSize(more).width);
          final moreText = tester.widget<Text>(find.text('+2')).style!;
          k.px('overflow.fontSize', moreText.fontSize!);
          k.weight('overflow.fontWeight', moreText);
          k.color('overflow.foreground', moreText.color!);
          failures.addAll(k.failures);
        }
        if (failures.isNotEmpty) fail(failures.join('\n'));
      });
    }

    testWidgets('"+N" 은 99 를 넘지 않고, 4명 이하면 없다', (tester) async {
      final many = [for (var i = 0; i < 120; i++) (name: '사람$i', image: null)];
      await tester.pumpWidget(
        _host(Brightness.light, PAvatarStack(people: many)),
      );
      expect(find.text('+99'), findsOneWidget);
      await tester.pumpWidget(
        _host(Brightness.light, PAvatarStack(people: people.take(4).toList())),
      );
      expect(find.byKey(const ValueKey('avatar-stack-overflow')), findsNothing);
    });
  });

  group('Divider', () {
    final spec = DesignSpec.load('divider');
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 방향 × 들임', (tester) async {
        final failures = <String>[];
        for (final combo in spec.combos(['orientation', 'inset'])) {
          final vertical = combo['orientation'] == 'vertical';
          final divider = PDivider(
            key: UniqueKey(),
            axis: vertical ? Axis.vertical : Axis.horizontal,
            inset: PDividerInset.values.byName(combo['inset']!),
          );
          // 쓰는 자리 그대로 — 가로 선은 세로로 쌓인 내용 사이(폭 200), 세로 선은 높이가 정해진 줄 안(높이 100)
          await tester.pumpWidget(
            _host(
              mode,
              vertical
                  ? SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [divider],
                      ),
                    )
                  : SizedBox(
                      width: 200,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [divider],
                      ),
                    ),
            ),
          );
          final k = _Check(mode, spec.resolve(combo, 'enabled'), '$combo');
          final line = find.descendant(
            of: find.byType(PDivider),
            matching: find.byType(ColoredBox),
          );
          k.color('root.background', tester.widget<ColoredBox>(line).color);
          final size = tester.getSize(line);
          k.px('root.thickness', vertical ? size.width : size.height);
          final inset =
              (k.want['root.marginX'] ?? k.want['root.marginY'] ?? 0) as num;
          final length = vertical ? size.height : size.width;
          if (length != (vertical ? 100 : 200) - inset * 2) {
            k.failures.add('${k.where} — 들임 $inset: 선 길이 $length');
          }
          failures.addAll(k.failures);
        }
        if (failures.isNotEmpty) fail(failures.join('\n'));
      });
    }

    testWidgets('세로 선은 줄 높이를 따르고, 높이가 없으면 0 이다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 40, height: 56),
                PDivider(axis: Axis.vertical),
                SizedBox(width: 40, height: 32),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PDivider)), const Size(1, 56));
      // 높이를 정하지 않은 목록 안의 줄 — 웹처럼 0, 무한 높이로 깨지지 않는다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          ListView(
            children: const [
              Row(children: [PDivider(axis: Axis.vertical)]),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // 높이 0 인 목록 항목은 화면 밖으로 친다 — skipOffstage 를 끈다
      expect(
        tester.getSize(find.byType(PDivider, skipOffstage: false)).height,
        0,
      );
    });
  });
}
