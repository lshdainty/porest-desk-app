import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/aspect_ratio/aspect_ratio_demo.dart';
import 'package:porest_desk_app/shared/ds/alert_dialog/alert_dialog_demo.dart';
import 'package:porest_desk_app/shared/ds/avatar/avatar_demo.dart';
import 'package:porest_desk_app/shared/ds/badge/badge_demo.dart';
import 'package:porest_desk_app/shared/ds/bottom_navigation/bottom_navigation_demo.dart';
import 'package:porest_desk_app/shared/ds/bottom_sheet/bottom_sheet_demo.dart';
import 'package:porest_desk_app/shared/ds/button/button_demo.dart';
import 'package:porest_desk_app/shared/ds/callout/callout_demo.dart';
import 'package:porest_desk_app/shared/ds/card/card_demo.dart';
import 'package:porest_desk_app/shared/ds/chart/chart_demo.dart';
import 'package:porest_desk_app/shared/ds/checkbox/checkbox_demo.dart';
import 'package:porest_desk_app/shared/ds/chip/chip_demo.dart';
import 'package:porest_desk_app/shared/ds/content_placeholder/content_placeholder_demo.dart';
import 'package:porest_desk_app/shared/ds/date_picker/date_picker_demo.dart';
import 'package:porest_desk_app/shared/ds/divider/divider_demo.dart';
import 'package:porest_desk_app/shared/ds/field/field_demo.dart';
import 'package:porest_desk_app/shared/ds/help_bubble/help_bubble_demo.dart';
import 'package:porest_desk_app/shared/ds/floating_action_button/floating_action_button_demo.dart';
import 'package:porest_desk_app/shared/ds/image_frame/image_frame_demo.dart';
import 'package:porest_desk_app/shared/ds/input/input_demo.dart';
import 'package:porest_desk_app/shared/ds/input_button/input_button_demo.dart';
import 'package:porest_desk_app/shared/ds/input_otp/input_otp_demo.dart';
import 'package:porest_desk_app/shared/ds/list/list_demo.dart';
import 'package:porest_desk_app/shared/ds/logo_tile/logo_tile_demo.dart';
import 'package:porest_desk_app/shared/ds/menu_sheet/menu_sheet_demo.dart';
import 'package:porest_desk_app/shared/ds/notification_badge/notification_badge_demo.dart';
import 'package:porest_desk_app/shared/ds/page_banner/page_banner_demo.dart';
import 'package:porest_desk_app/shared/ds/progress/progress_demo.dart';
import 'package:porest_desk_app/shared/ds/progress_circle/progress_circle_demo.dart';
import 'package:porest_desk_app/shared/ds/radio/radio_demo.dart';
import 'package:porest_desk_app/shared/ds/result_section/result_section_demo.dart';
import 'package:porest_desk_app/shared/ds/scroll_fog/scroll_fog_demo.dart';
import 'package:porest_desk_app/shared/ds/searchable_list/searchable_list_demo.dart';
import 'package:porest_desk_app/shared/ds/segmented_control/segmented_control_demo.dart';
import 'package:porest_desk_app/shared/ds/select/select_demo.dart';
import 'package:porest_desk_app/shared/ds/select_box/select_box_demo.dart';
import 'package:porest_desk_app/shared/ds/skeleton/skeleton_demo.dart';
import 'package:porest_desk_app/shared/ds/slider/slider_demo.dart';
import 'package:porest_desk_app/shared/ds/snackbar/snackbar_demo.dart';
import 'package:porest_desk_app/shared/ds/swipe_actions/swipe_actions_demo.dart';
import 'package:porest_desk_app/shared/ds/switch/switch_demo.dart';
import 'package:porest_desk_app/shared/ds/tabs/tabs_demo.dart';
import 'package:porest_desk_app/shared/ds/tag_group/tag_group_demo.dart';
import 'package:porest_desk_app/shared/ds/textarea/textarea_demo.dart';
import 'package:porest_desk_app/shared/ds/time_picker/time_picker_demo.dart';
import 'package:porest_desk_app/shared/ds/toggle/toggle_demo.dart';
import 'package:porest_desk_app/shared/ds/top_navigation/top_navigation_demo.dart';
import 'package:porest_desk_app/shared/ds/tooltip/tooltip_demo.dart';
import 'package:porest_desk_app/shared/ds/wheel_picker/wheel_picker_demo.dart';

/// 컴포넌트 라이브러리(`lib/shared/ds`) 등록부 — debug 빌드 전용 카탈로그(/dev/ds)가 그린다.
///
/// 묶음 차례는 만드는 순서다. porest-design 레시피끼리 가져다 쓰는 관계로 정했다
/// (Button ← Progress Circle, Chip ← Field · Scroll Fog …). 웹(desk-front
/// `src/shared/ds/catalog/registry.ts`)과 같은 차례다.
///
/// 앱은 51개다 — Dialog · Menu · Popover · Table · Table Pagination · Pagination · Side Navigation 은 1280 · 768 이상 전용이라 앱에서는
/// Bottom Sheet · Menu Sheet · List 줄이 맡는다.
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
    DsEntry('Field', 'field', demo: _field),
    DsEntry('Input', 'input', demo: _input),
    DsEntry('Textarea', 'textarea', demo: _textarea),
  ]),
  DsFamily('selection', '5 선택 컨트롤', [
    DsEntry('Checkbox', 'checkbox', demo: _checkbox),
    DsEntry('Radio', 'radio-group', demo: _radio),
    DsEntry('Switch', 'switch', demo: _switch),
  ]),
  DsFamily('pickers', '6 고르는 칸', [
    DsEntry('Input Button', 'input-button', demo: _inputButton),
    DsEntry('Searchable List', 'searchable-list', demo: _searchableList),
    DsEntry('Select', 'select', demo: _select),
    DsEntry('Select Box', 'select-box', demo: _selectBox),
  ]),
  DsFamily('chips-tabs', '7 칩 · 탭', [
    DsEntry('Chip', 'chip', demo: _chip),
    DsEntry('Tabs', 'tabs', demo: _tabs),
    DsEntry('Segmented Control', 'segmented-control', demo: _segmentedControl),
    DsEntry('Toggle', 'toggle', demo: _toggle),
  ]),
  DsFamily('overlays', '8 겹침', [
    DsEntry('Alert Dialog', 'alert-dialog', demo: _alertDialog),
    DsEntry('Bottom Sheet', 'bottom-sheet', demo: _bottomSheet),
  ]),
  DsFamily('menus', '9 메뉴', [
    DsEntry('Menu Sheet', 'menu-sheet', demo: _menuSheet),
    DsEntry('Help Bubble', 'help-bubble', demo: _helpBubble),
    DsEntry('Tooltip', 'tooltip', demo: _tooltip),
  ]),
  DsFamily('date-time', '10 날짜 · 시각', [
    DsEntry('Wheel Picker', 'wheel-picker', demo: _wheelPicker),
    DsEntry('Time Picker', 'time-picker', demo: _timePicker),
    DsEntry('Date Picker', 'date-picker', demo: _datePicker),
  ]),
  DsFamily('feedback', '11 피드백', [
    DsEntry('Snackbar', 'snackbar', demo: _snackbar),
    DsEntry('Callout', 'callout', demo: _callout),
    DsEntry('Page Banner', 'page-banner', demo: _pageBanner),
    DsEntry('Result Section', 'result-section', demo: _resultSection),
  ]),
  DsFamily('image', '12 이미지', [
    DsEntry('Aspect Ratio', 'aspect-ratio', demo: _aspectRatio),
    DsEntry('Image Frame', 'image-frame', demo: _imageFrame),
    DsEntry('Logo Tile', 'logo-tile', demo: _logoTile),
  ]),
  DsFamily('list', '13 목록', [DsEntry('List', 'list', demo: _list)]),
  // Table · Table Pagination · Pagination 은 768 이상 전용이라 폰은 List 줄 · 끝없이 불러오기가 맡는다
  DsFamily('data', '14 데이터', [
    DsEntry('Card', 'card', demo: _card),
    DsEntry('Chart', 'chart', demo: _chart),
    DsEntry('Swipe Actions', 'swipe-actions', demo: _swipeActions),
  ]),
  // Side Navigation 은 768 이상 전용이라 폰은 Bottom Navigation 이 맡는다(HR 의 Side Panel 은 HR 전용)
  DsFamily('frame-nav', '15 화면 틀 · 이동', [
    DsEntry('Top Navigation', 'top-navigation', demo: _topNavigation),
    DsEntry('Bottom Navigation', 'bottom-navigation', demo: _bottomNavigation),
    DsEntry(
      'Floating Action Button',
      'floating-action-button',
      demo: _floatingActionButton,
    ),
  ]),
  DsFamily('input', '16 입력', [
    DsEntry('Slider', 'slider', demo: _slider),
    DsEntry('Input OTP', 'input-otp', demo: _inputOtp),
    DsEntry('Color Swatch', 'color-swatch'),
    DsEntry('Icon Picker', 'icon-picker'),
  ]),
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
Widget _field(BuildContext context) => const FieldDemo();
Widget _input(BuildContext context) => const InputDemo();

Widget _inputButton(BuildContext context) => const InputButtonDemo();

Widget _searchableList(BuildContext context) => const SearchableListDemo();
Widget _textarea(BuildContext context) => const TextareaDemo();
Widget _checkbox(BuildContext context) => const CheckboxDemo();
Widget _radio(BuildContext context) => const RadioDemo();
Widget _switch(BuildContext context) => const SwitchDemo();
Widget _snackbar(BuildContext context) => const SnackbarDemo();
Widget _callout(BuildContext context) => const CalloutDemo();
Widget _pageBanner(BuildContext context) => const PageBannerDemo();
Widget _resultSection(BuildContext context) => const ResultSectionDemo();
Widget _aspectRatio(BuildContext context) => const AspectRatioDemo();
Widget _imageFrame(BuildContext context) => const ImageFrameDemo();
Widget _logoTile(BuildContext context) => const LogoTileDemo();
Widget _chip(BuildContext context) => const ChipDemo();
Widget _segmentedControl(BuildContext context) => const SegmentedControlDemo();
Widget _tabs(BuildContext context) => const TabsDemo();
Widget _toggle(BuildContext context) => const ToggleDemo();
Widget _helpBubble(BuildContext context) => const HelpBubbleDemo();
Widget _wheelPicker(BuildContext context) => const WheelPickerDemo();
Widget _timePicker(BuildContext context) => const TimePickerDemo();
Widget _datePicker(BuildContext context) => const DatePickerDemo();
Widget _select(BuildContext context) => const SelectDemo();
Widget _selectBox(BuildContext context) => const SelectBoxDemo();
Widget _list(BuildContext context) => const ListDemo();
Widget _card(BuildContext context) => const CardDemo();
Widget _chart(BuildContext context) => const ChartDemo();
Widget _swipeActions(BuildContext context) => const SwipeActionsDemo();
Widget _topNavigation(BuildContext context) => const TopNavigationDemo();
Widget _bottomNavigation(BuildContext context) => const BottomNavigationDemo();
Widget _floatingActionButton(BuildContext context) =>
    const FloatingActionButtonDemo();
Widget _slider(BuildContext context) => const SliderDemo();
Widget _inputOtp(BuildContext context) => const InputOtpDemo();
Widget _alertDialog(BuildContext context) => const AlertDialogDemo();
Widget _bottomSheet(BuildContext context) => const BottomSheetDemo();

Widget _menuSheet(BuildContext context) => const MenuSheetDemo();

Widget _tooltip(BuildContext context) => const TooltipDemo();

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
