import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/overlay/overlay_stage.dart';

// 정지한 견본의 무대 높이 — 폰 화면 아래에 시트가 붙는다
const double _stage = 560;

/// 메모 줄 ⋮ — 이름만으로 충분한 줄 셋 한 묶음 + 위험한 동작은 맨 아래 묶음에.
PMenuSheetContent _memoRow() => PMenuSheetContent(
  title: '주간 회의 메모',
  groups: const [
    PMenuSheetGroup([
      PMenuSheetItem(label: '수정', icon: LucideIcons.pencil),
      PMenuSheetItem(label: '복사', icon: LucideIcons.copy),
      PMenuSheetItem(label: '이동', icon: LucideIcons.folderInput),
    ]),
    PMenuSheetGroup([
      PMenuSheetItem(
        label: '삭제',
        icon: LucideIcons.trash2,
        tone: PMenuSheetTone.critical,
      ),
    ]),
  ],
);

/// 머리 더보기 — 제목 + 줄 설명, 막힌 줄.
PMenuSheetContent _header() => PMenuSheetContent(
  title: '메모',
  description: '메모 전체에 해당하는 동작이에요.',
  groups: const [
    PMenuSheetGroup([
      PMenuSheetItem(
        label: '가져오기',
        description: '다른 앱에서 내보낸 파일을 불러와요.',
        icon: LucideIcons.folderInput,
      ),
      PMenuSheetItem(
        label: '내보내기',
        description: '메모를 파일로 저장해요.',
        icon: LucideIcons.folderOutput,
      ),
      PMenuSheetItem(
        label: '정렬 바꾸기',
        icon: LucideIcons.arrowDownUp,
        enabled: false,
      ),
    ]),
  ],
);

/// 글만 — 가운데 정렬, 줄 설명 · 아이콘을 두지 않는다.
PMenuSheetContent _textOnly() => PMenuSheetContent(
  title: '사진',
  layout: PMenuSheetLayout.textOnly,
  groups: const [
    PMenuSheetGroup([
      PMenuSheetItem(label: '앨범에서 고르기'),
      PMenuSheetItem(label: '사진 찍기'),
    ]),
    PMenuSheetGroup([
      PMenuSheetItem(label: '사진 지우기', tone: PMenuSheetTone.critical),
    ]),
  ],
);

/// 카탈로그(/dev/ds) — 아이콘 + 글 · 글만 · 머리(제목 + 설명) · 위험한 동작 · 막힌 줄을 딤 위에 정지시켜 그리고, 실제로 띄워 본다
/// (바깥 · 끌기 · 손잡이 · 뒤로 가기로 닫힘 · 줄을 누르면 닫히고 동작이 불린다).
///
/// 앱에는 웹의 `modal={false}` 가 없다 — 정지한 견본은 표면만 그린 [PMenuSheetView] 를 무대에 놓은 것이다. 앱은 Menu 를 만들지
/// 않는다(1280 이상 전용) — 줄의 동작은 늘 이 시트다.
class MenuSheetDemo extends StatefulWidget {
  const MenuSheetDemo({super.key});

  @override
  State<MenuSheetDemo> createState() => _MenuSheetDemoState();
}

class _MenuSheetDemoState extends State<MenuSheetDemo> {
  String _last = '아직 고른 줄이 없어요.';

  Future<void> _open(PMenuSheetContent sheet) async {
    final picked = await PMenuSheet.show(
      context,
      title: sheet.title,
      description: sheet.description,
      semanticLabel: sheet.semanticLabel,
      layout: sheet.layout,
      groups: [
        for (final g in sheet.groups)
          PMenuSheetGroup([
            for (final i in g.items)
              PMenuSheetItem(
                label: i.label,
                description: i.description,
                icon: i.icon,
                tone: i.tone,
                enabled: i.enabled,
                onSelect: () {
                  if (mounted) setState(() => _last = '"${i.label}" 이 불렸어요.');
                },
              ),
          ]),
      ],
    );
    if (picked == null && mounted) setState(() => _last = '줄을 고르지 않고 닫았어요.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '줄 ⋮ — 아이콘 + 글(글은 왼쪽) · 위험한 동작은 맨 아래 묶음에 critical',
          children: [
            DemoRow(
              label: 'textWithIcon · 두 묶음',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PMenuSheetView(content: _memoRow()),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '머리 더보기 — 제목 + 설명 · 줄 설명 · 막힌 줄(전용 색 · 눌러도 닫히지 않는다)',
          children: [
            DemoRow(
              label: 'description · disabled',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PMenuSheetView(content: _header()),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '글만 — 가운데 정렬 · 줄 설명 · 아이콘 없음',
          children: [
            DemoRow(
              label: 'textOnly',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PMenuSheetView(content: _textOnly()),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '실제로 띄우기 — 바깥 · 손잡이 · 아래로 끌기 · 뒤로 가기로 닫힌다. 줄을 누르면 닫히고 다 닫힌 뒤 동작이 불린다',
          children: [
            DemoRow(
              label: 'show',
              children: [
                PButton(
                  label: '메모 줄 ⋮',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () => _open(_memoRow()),
                ),
                PButton(
                  label: '머리 더보기',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () => _open(_header()),
                ),
                PButton(
                  label: '글만',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () => _open(_textOnly()),
                ),
              ],
            ),
            Text(
              _last,
              key: const ValueKey('menu-sheet-demo-last'),
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
        ),
      ],
    );
  }
}
