import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/avatar/avatar_demo.dart';
import 'package:porest_desk_app/shared/ds/badge/badge_demo.dart';
import 'package:porest_desk_app/shared/ds/button/button_demo.dart';
import 'package:porest_desk_app/shared/ds/content_placeholder/content_placeholder_demo.dart';
import 'package:porest_desk_app/shared/ds/divider/divider_demo.dart';
import 'package:porest_desk_app/shared/ds/notification_badge/notification_badge_demo.dart';
import 'package:porest_desk_app/shared/ds/progress/progress_demo.dart';
import 'package:porest_desk_app/shared/ds/progress_circle/progress_circle_demo.dart';
import 'package:porest_desk_app/shared/ds/scroll_fog/scroll_fog_demo.dart';
import 'package:porest_desk_app/shared/ds/skeleton/skeleton_demo.dart';
import 'package:porest_desk_app/shared/ds/tag_group/tag_group_demo.dart';

/// 컴포넌트 라이브러리(`lib/shared/ds`) 등록부 — debug 빌드 전용 카탈로그(/dev/ds)가 그린다.
///
/// 묶음 차례는 만드는 순서다. porest-design 레시피끼리 가져다 쓰는 관계로 정했다
/// (Button ← Progress Circle, Chip ← Field · Scroll Fog …). 웹(desk-front
/// `src/shared/ds/catalog/registry.ts`)과 같은 차례다.
///
/// 앱은 39개다 — Dialog · Menu · Popover 는 1280 이상 전용이라 앱에서는 Bottom Sheet ·
/// Menu Sheet 가 맡는다.
///
/// 컴포넌트를 만들면 그 줄에 demo 를 단다 — 스펙의 변형 · 크기 · 상태를 모두 그린 위젯.
/// spec 은 porest-design `specs/components/<이름>.md` 의 이름이고, 값은
/// `test/fixtures/design_spec/<이름>.json` 이다(테스트가 위젯이 그 값과 같은지 본다).
class DsEntry {
  const DsEntry(this.name, this.spec, {this.demo});

  final String name;
  final String spec;
  final WidgetBuilder? demo;
}

class DsFamily {
  const DsFamily(this.id, this.title, this.entries);

  final String id;
  final String title;
  final List<DsEntry> entries;
}

const List<DsFamily> dsFamilies = [
  DsFamily('button', '1 버튼', [
    DsEntry('Progress Circle', 'progress-circle', demo: _progressCircle),
    DsEntry('Button', 'button', demo: _button),
  ]),
  DsFamily('loading', '2 로딩', [
    DsEntry('Skeleton', 'skeleton', demo: _skeleton),
    DsEntry('Progress', 'progress', demo: _progress),
    DsEntry('Scroll Fog', 'scroll-fog', demo: _scrollFog),
    DsEntry(
      'Content Placeholder',
      'content-placeholder',
      demo: _contentPlaceholder,
    ),
  ]),
  DsFamily('display', '3 표시', [
    DsEntry('Badge', 'badge', demo: _badge),
    DsEntry(
      'Notification Badge',
      'notification-badge',
      demo: _notificationBadge,
    ),
    DsEntry('Tag Group', 'tag-group', demo: _tagGroup),
    // Avatar Stack(avatar-stack.yaml)은 Avatar 견본 안에 — 웹 등록부도 한 줄이다
    DsEntry('Avatar', 'avatar', demo: _avatar),
    DsEntry('Divider', 'divider', demo: _divider),
  ]),
  DsFamily('text-field', '4 텍스트 필드', [
    DsEntry('Field', 'field'),
    DsEntry('Input', 'input'),
    DsEntry('Textarea', 'textarea'),
  ]),
  DsFamily('selection', '5 선택 컨트롤', [
    DsEntry('Checkbox', 'checkbox'),
    DsEntry('Radio', 'radio-group'),
    DsEntry('Switch', 'switch'),
  ]),
  DsFamily('pickers', '6 고르는 칸', [
    DsEntry('Input Button', 'input-button'),
    DsEntry('Select', 'select'),
    DsEntry('Select Box', 'select-box'),
  ]),
  DsFamily('chips-tabs', '7 칩 · 탭', [
    DsEntry('Chip', 'chip'),
    DsEntry('Tabs', 'tabs'),
    DsEntry('Segmented Control', 'segmented-control'),
  ]),
  DsFamily('overlays', '8 겹침', [
    DsEntry('Alert Dialog', 'alert-dialog'),
    DsEntry('Bottom Sheet', 'bottom-sheet'),
  ]),
  DsFamily('menus', '9 메뉴', [
    DsEntry('Menu Sheet', 'menu-sheet'),
    DsEntry('Help Bubble', 'help-bubble'),
    DsEntry('Tooltip', 'tooltip'),
  ]),
  DsFamily('date-time', '10 날짜 · 시각', [
    DsEntry('Wheel Picker', 'wheel-picker'),
    DsEntry('Time Picker', 'time-picker'),
    DsEntry('Date Picker', 'date-picker'),
  ]),
  DsFamily('feedback', '11 피드백', [
    DsEntry('Snackbar', 'snackbar'),
    DsEntry('Callout', 'callout'),
    DsEntry('Page Banner', 'page-banner'),
    DsEntry('Result Section', 'result-section'),
  ]),
  DsFamily('image', '12 이미지', [
    DsEntry('Aspect Ratio', 'aspect-ratio'),
    DsEntry('Image Frame', 'image-frame'),
    DsEntry('Logo Tile', 'logo-tile'),
  ]),
  DsFamily('list', '13 목록', [DsEntry('List', 'list')]),
];

Widget _progressCircle(BuildContext context) => const ProgressCircleDemo();
Widget _button(BuildContext context) => const ButtonDemo();
Widget _skeleton(BuildContext context) => const SkeletonDemo();
Widget _progress(BuildContext context) => const ProgressDemo();
Widget _scrollFog(BuildContext context) => const ScrollFogDemo();
Widget _contentPlaceholder(BuildContext context) =>
    const ContentPlaceholderDemo();
Widget _badge(BuildContext context) => const BadgeDemo();
Widget _notificationBadge(BuildContext context) =>
    const NotificationBadgeDemo();
Widget _tagGroup(BuildContext context) => const TagGroupDemo();
Widget _avatar(BuildContext context) => const AvatarDemo();
Widget _divider(BuildContext context) => const DividerDemo();

/// 역할 색 한 칸 — 이름과 [PColors] 에서 그 값을 꺼내는 법.
typedef DsSwatch = ({String name, Color Function(PColors c) of});

/// 역할 색 — 카탈로그 첫 화면의 색 판. 새 컴포넌트는 이 이름만 부른다(DESIGN.md v102).
final List<({String group, List<DsSwatch> swatches})> dsRoleSwatches = [
  (
    group: '글자',
    swatches: [
      (name: 'fg-neutral', of: (c) => c.fgNeutral),
      (name: 'fg-neutral-muted', of: (c) => c.fgNeutralMuted),
      (name: 'fg-neutral-subtle', of: (c) => c.fgNeutralSubtle),
      (name: 'fg-placeholder', of: (c) => c.fgPlaceholder),
      (name: 'fg-disabled', of: (c) => c.fgDisabled),
      (name: 'fg-brand', of: (c) => c.fgBrand),
      (name: 'fg-critical', of: (c) => c.fgCritical),
      (name: 'fg-positive', of: (c) => c.fgPositive),
      (name: 'fg-warning', of: (c) => c.fgWarning),
      (name: 'fg-informative', of: (c) => c.fgInformative),
    ],
  ),
  (
    group: '배경',
    swatches: [
      (name: 'bg-layer-basement', of: (c) => c.bgLayerBasement),
      (name: 'bg-layer-default', of: (c) => c.bgLayerDefault),
      (name: 'bg-layer-floating', of: (c) => c.bgLayerFloating),
      (name: 'bg-neutral-weak', of: (c) => c.bgNeutralWeak),
      (name: 'bg-neutral-inverted', of: (c) => c.bgNeutralInverted),
      (name: 'bg-brand-solid', of: (c) => c.bgBrandSolid),
      (name: 'bg-brand-weak', of: (c) => c.bgBrandWeak),
      (name: 'bg-critical-solid', of: (c) => c.bgCriticalSolid),
      (name: 'bg-critical-weak', of: (c) => c.bgCriticalWeak),
      (name: 'bg-positive-weak', of: (c) => c.bgPositiveWeak),
    ],
  ),
  (
    group: '선',
    swatches: [
      (name: 'stroke-neutral-subtle', of: (c) => c.strokeNeutralSubtle),
      (name: 'stroke-neutral-weak', of: (c) => c.strokeNeutralWeak),
      (name: 'stroke-neutral-solid', of: (c) => c.strokeNeutralSolid),
      (name: 'stroke-focus-ring', of: (c) => c.strokeFocusRing),
      (name: 'stroke-brand-solid', of: (c) => c.strokeBrandSolid),
    ],
  ),
];
