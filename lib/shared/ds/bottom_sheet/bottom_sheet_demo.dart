import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/overlay/overlay_stage.dart';

// 정지한 견본의 무대 높이 — 폰 화면 아래에 시트가 붙는다
const double _stage = 560;

const _leaveCopy = PLeaveConfirmCopy(
  title: '작성한 내용이 사라져요',
  description: '나가면 입력한 내용이 저장되지 않아요.',
  stayLabel: '계속 작성',
  leaveLabel: '나가기',
);

const _periods = ['오늘', '이번 주', '이번 달', '지난 달'];

// 긴 목록 — 데이터에 따라 길어지는 본문(끝 흐림 위 20 · 아래 80)
final _many = [for (var i = 1; i <= 24; i++) '카테고리 $i'];

void _noop() {}

PButton _button(String label, {bool weak = false, VoidCallback? onPressed}) =>
    PButton(
      label: label,
      size: PButtonSize.large,
      variant: weak ? PButtonVariant.neutralWeak : PButtonVariant.neutralSolid,
      onPressed: onPressed ?? _noop,
    );

/// 카탈로그(/dev/ds) — 쓰임(고르기 · 입력 폼) · 끝 흐림 · 손잡이 · 닫기 버튼의 누름을 딤 위에 정지시켜 그리고, 실제로
/// 띄워 본다(바깥 · 끌기로 닫힘 · 입력 폼은 안 닫히고 값이 있으면 묻는다 · 스냅 높이).
///
/// 앱에는 웹의 `modal={false}` 가 없다 — 정지한 견본은 표면만 그린 [PBottomSheetView] 를 무대에 놓은 것이다.
class BottomSheetDemo extends StatelessWidget {
  const BottomSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '쓰임 — 고르기(조회) 시트 · 입력 폼 시트(바닥은 저장 하나)',
          children: [
            DemoRow(
              label: '고르기',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PBottomSheetView(content: _pick()),
                ),
              ],
            ),
            const DemoRow(
              label: '입력 폼',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PBottomSheetView(content: _FormContent()),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '끝 흐림(scrollFog) — 넘칠 수 있는 본문 · 위 20 · 아래 80 이 늘 흐리다',
          children: [
            DemoRow(
              label: 'scrollFog on',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PBottomSheetView(content: _fog()),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '손잡이(handle shown) — 스냅 높이를 둘 때만 · 36 × 4',
          children: [
            DemoRow(
              label: 'handle shown',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PBottomSheetView(showHandle: true, content: _detail()),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '상태 — 닫기 버튼 누름(원 바탕 + 2px 거리 축소)',
          children: [
            DemoRow(
              label: 'pressed',
              children: [
                DsOverlayStage(
                  height: _stage,
                  alignment: Alignment.bottomCenter,
                  child: PBottomSheetView(content: _pick(closePressed: true)),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '실제로 띄우기 — 조회는 바깥 · 끌기로 닫힌다 · 입력 폼은 안 닫히고 값이 있으면 닫기 전에 묻는다 · 스냅 높이는 손잡이로 올린다',
          children: [
            DemoRow(
              label: 'show',
              children: [
                PButton(
                  label: '조회 시트 열기',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () => PBottomSheet.show<void>(
                    context,
                    builder: (_) => _detail(),
                  ),
                ),
                PButton(
                  label: '고르기 시트 열기',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () =>
                      PBottomSheet.show<void>(context, builder: (_) => _pick()),
                ),
                PButton(
                  label: '입력 폼 시트 열기',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () => _openForm(context),
                ),
                PButton(
                  label: '스냅 높이 시트 열기',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () => PBottomSheet.show<void>(
                    context,
                    snapPoints: const [0.4, 0.9],
                    builder: (_) => _detail(fills: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _openForm(BuildContext context) {
    final memo = TextEditingController();
    return PBottomSheet.show<void>(
      context,
      form: true,
      isDirty: () => memo.text.isNotEmpty,
      leaveCopy: _leaveCopy,
      builder: (_) => _FormContent(controller: memo, saveCloses: true),
    ).whenComplete(memo.dispose);
  }

  /// 고르기 — 기간. 위 닫기 + 바닥 초기화 · 적용(초기화는 왼쪽).
  static PBottomSheetContent _pick({bool closePressed = false}) =>
      PBottomSheetContent(
        title: '기간',
        description: '고른 기간의 거래만 보여요.',
        closeLabel: '닫기',
        closePressed: closePressed,
        flushBody: true,
        body: const _Periods(),
        footer: [_button('초기화', weak: true), _button('적용')],
      );

  static PBottomSheetContent _fog() => PBottomSheetContent(
    title: '카테고리',
    closeLabel: '닫기',
    scrollFog: true,
    flushBody: true,
    body: PList(children: [for (final c in _many) PListItem(title: c)]),
  );

  static PBottomSheetContent _detail({bool fills = false}) =>
      PBottomSheetContent(
        title: '거래 상세',
        closeLabel: '닫기',
        flushBody: true,
        body: PList(
          children: [
            const PListItem(title: '금액', suffix: Text('12,000원')),
            const PListItem(title: '날짜', suffix: Text('10월 15일')),
            const PListItem(title: '카테고리', suffix: Text('식비')),
            if (fills)
              for (final c in _many.take(8)) PListItem(title: c),
          ],
        ),
      );
}

/// 기간 고르기 본문 — 하나 고르기.
class _Periods extends StatefulWidget {
  const _Periods();

  @override
  State<_Periods> createState() => _PeriodsState();
}

class _PeriodsState extends State<_Periods> {
  String _value = '이번 달';

  @override
  Widget build(BuildContext context) {
    return PListRadioGroup<String>(
      semanticLabel: '기간',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      children: [for (final p in _periods) PListRadioItem(value: p, title: p)],
    );
  }
}

/// 입력 폼 — 위 닫기 + 바닥 저장 하나. 메모를 적고 닫으면 묻는다.
class _FormContent extends StatelessWidget {
  const _FormContent({this.controller, this.saveCloses = false});

  final TextEditingController? controller;
  final bool saveCloses;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PBottomSheetContent(
      title: '거래 추가',
      closeLabel: '닫기',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x3,
        children: [
          const PInput(placeholder: '금액', semanticLabel: '금액'),
          PInput(
            controller: controller,
            placeholder: saveCloses ? '메모를 적고 닫아 보세요' : '메모',
            semanticLabel: '메모',
          ),
          Text(
            '바깥을 눌러도 아래로 끌어도 닫히지 않아요.',
            style: PTypography.t3.copyWith(color: c.fgNeutralMuted),
          ),
        ],
      ),
      footer: [
        _button(
          '저장',
          onPressed: saveCloses ? () => PBottomSheet.of(context).close() : null,
        ),
      ],
    );
  }
}
