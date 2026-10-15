import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/overlay/overlay_stage.dart';

/// 카탈로그(/dev/ds) — 배치(나란히 · 세로 · 하나)를 딤 위에 정지시켜 그리고, 실제로 띄워 본다(바깥 누르기는 무시 ·
/// 뒤로 가기는 취소 · 확정 기다리기 · 작성 중 나가기).
///
/// 앱에는 웹의 `modal={false}` 가 없다 — 정지한 견본은 표면만 그린 [PAlertDialogView] 를 무대에 놓은 것이다.
class AlertDialogDemo extends StatelessWidget {
  const AlertDialogDemo({super.key});

  // 배치마다 글 — 한쪽 글이 반 폭을 넘으면 세로(확정이 위), 알리기는 버튼 하나
  static const _horizontal = PAlertDialogView(
    title: '거래를 삭제할까요?',
    description: '삭제한 거래는 되돌릴 수 없어요.',
    cancelLabel: '취소',
    actionLabel: '삭제',
    destructive: true,
  );
  static const _vertical = PAlertDialogView(
    title: '작성한 내용이 사라져요',
    description: '나가면 입력한 금액과 날짜가 저장되지 않아요.',
    cancelLabel: '계속 작성하기',
    actionLabel: '저장하지 않고 나가기',
    destructive: true,
  );
  static const _single = PAlertDialogView(
    title: '이미 정산된 거래예요',
    description: '정산이 끝난 거래는 수정할 수 없어요.',
    actionLabel: '거래 보기',
  );
  static const _noTitle = PAlertDialogView(
    semanticLabel: '거래를 삭제할까요?',
    description: '삭제한 거래는 되돌릴 수 없어요.',
    cancelLabel: '취소',
    actionLabel: '삭제',
    destructive: true,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DemoBlock(
          title: '배치 — 나란히(기본) · 글이 길면 세로(확정이 위) · 알리기는 버튼 하나',
          children: [
            DemoRow(
              label: 'horizontal',
              children: [DsOverlayStage(height: 236, child: _horizontal)],
            ),
            DemoRow(
              label: 'vertical',
              children: [DsOverlayStage(height: 296, child: _vertical)],
            ),
            DemoRow(
              label: 'single',
              children: [DsOverlayStage(height: 236, child: _single)],
            ),
          ],
        ),
        const DemoBlock(
          title: '제목 없이 — 설명만(이름은 semanticLabel 로 단다) · 제목 아래 6 이 없다',
          children: [
            DemoRow(
              label: 'no title',
              children: [DsOverlayStage(height: 200, child: _noTitle)],
            ),
          ],
        ),
        DemoBlock(
          title:
              '실제로 띄우기 — 딤 · 바깥 누르기는 무시 · 뒤로 가기는 취소 · 지우기는 Critical · 확정이 끝날 때까지 로딩',
          children: [
            DemoRow(
              label: 'show',
              children: [
                _Try(
                  label: '거래 삭제 열기',
                  run: (context) => PAlertDialog.show(
                    context,
                    title: '거래를 삭제할까요?',
                    description: '삭제한 거래는 되돌릴 수 없어요.',
                    cancelLabel: '취소',
                    actionLabel: '삭제',
                    destructive: true,
                  ),
                ),
                _Try(
                  label: '기다리는 확정 열기',
                  run: (context) => PAlertDialog.show(
                    context,
                    title: '그룹을 삭제할까요?',
                    description: '삭제하면 그룹 안의 종목이 모두 빠져요.',
                    cancelLabel: '취소',
                    actionLabel: '그룹 삭제',
                    destructive: true,
                    onAction: () =>
                        Future<void>.delayed(const Duration(seconds: 2)),
                  ),
                ),
                _Try(
                  label: '작성 중 나가기 열기',
                  run: (context) => PAlertDialog.confirmLeave(
                    context,
                    const PLeaveConfirmCopy(
                      title: '작성한 내용이 사라져요',
                      description: '나가면 입력한 내용이 저장되지 않아요.',
                      stayLabel: '계속 작성',
                      leaveLabel: '나가기',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// 누르면 확인창을 띄우고 고른 것을 아래에 적는다.
class _Try extends StatefulWidget {
  const _Try({required this.label, required this.run});

  final String label;
  final Future<bool> Function(BuildContext context) run;

  @override
  State<_Try> createState() => _TryState();
}

class _TryState extends State<_Try> {
  String _log = '';

  Future<void> _open() async {
    final ok = await widget.run(context);
    if (mounted) setState(() => _log = ok ? '확정했어요' : '취소했어요');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x1_5,
      children: [
        PButton(
          label: widget.label,
          variant: PButtonVariant.neutralWeak,
          size: PButtonSize.small,
          onPressed: _open,
        ),
        if (_log.isNotEmpty)
          Text(
            _log,
            style: PTypography.t3.copyWith(
              color: context.colors.fgNeutralMuted,
            ),
          ),
      ],
    );
  }
}
