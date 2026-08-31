import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 액션 하나의 색·의미 — specs/components/swipe-actions.md Kinds.
enum PSwipeKind { neutral, primary, destructive }

/// 스와이프로 드러나는 액션 하나.
///
/// 고정 목록이 아니다. 항목마다 할 수 있는 일이 달라서(문자함은 편집이 없고 메모는
/// 고정이 있다) 쓰는 쪽이 1~3개를 조립한다.
class PSwipeAction {
  const PSwipeAction({
    required this.label,
    required this.onSelect,
    this.icon,
    this.kind = PSwipeKind.neutral,
    this.confirmTitle,
    this.confirmMessage,
  });

  /// 한글 두 글자 권장 — 그보다 길면 72px 안에서 줄바꿈된다.
  final String label;
  final IconData? icon;
  final PSwipeKind kind;
  final VoidCallback onSelect;

  /// 확인창 제목. **같은 항목을 상세에서 지울 때와 같은 문자열을 넘긴다** —
  /// spec `alert-dialog` 의 "같은 동작이면 어디서 불렀든 제목·설명이 같다".
  ///
  /// 이 위젯은 자기가 감싼 행이 무엇인지 모른다. 그래서 그 행을 아는 호출부가 정한다.
  /// 비우면 액션 라벨로 떨어지지만, destructive 는 채우는 쪽이 규칙이다.
  final String? confirmTitle;

  /// 실행 전 확인받을 문구. [PSwipeKind.destructive] 면 채워야 한다.
  ///
  /// 스와이프는 삭제까지의 거리를 줄인다. 줄인 만큼을 확인 단계로 되돌려 놓지 않으면
  /// 밀다가 손이 미끄러져 지워진다 — 되돌릴 수단이 없다.
  final String? confirmMessage;
}

/// 리스트 행을 왼쪽으로 밀면 오른쪽에서 액션이 드러난다.
///
/// specs/components/swipe-actions.md 미러. 행을 다시 만들지 않고 <b>감싸기만</b> 한다 —
/// 행의 시각도 탭 동작도 그대로다. 걷어내면 원래 리스트로 돌아간다.
///
/// 끝까지 밀어도 액션이 실행되지 않는다(`DismissiblePane` 미사용). iOS Mail 은 그렇게
/// 하지만 그건 되돌리기가 있어서다.
///
/// 한 번에 하나만 열린다 — 리스트 쪽에 [SlidableAutoCloseBehavior] 를 씌워야 한다.
/// 씌우지 않으면 여러 행이 동시에 열린 채로 남는다.
class PSwipeActions extends StatelessWidget {
  const PSwipeActions({
    super.key,
    required this.actions,
    required this.child,
    this.groupTag = 'default',
    this.enabled = true,
  });

  /// 1~3개. 4개 이상이면 트레이가 행 폭을 먹어 무엇을 미는지 안 보인다.
  final List<PSwipeAction> actions;
  final Widget child;

  /// 같은 태그끼리 하나만 열린다. 화면에 리스트가 둘이면 갈라 준다.
  final String groupTag;

  /// false 면 감싸지 않고 행을 그대로 통과시킨다.
  final bool enabled;

  /// 행 내용과 첫 액션 사이. 바짝 붙으면 배지가 행에 얹힌 것처럼 보인다.
  static const double _gapLead = 20;

  /// 액션끼리 사이. 배지 둘이 붙어 있으면 하나의 알약처럼 뭉쳐 보인다.
  static const double _gapBetween = 12;

  /// 액션 하나가 차지하는 폭 — 배지 + <b>그 앞</b> 간격.
  ///
  /// 간격을 배지 앞에만 둔다. 뒤에도 두면 마지막 액션과 화면 끝 사이가 벌어져
  /// 덜 열린 것처럼 보인다 — 오른쪽 끝에는 딱 붙어야 한다.
  static double slotWidth(int index) =>
      _badgeSize + (index == 0 ? _gapLead : _gapBetween);

  /// 액션 최소 높이 — WCAG 2.5.5(AAA, 44×44)를 밑돌지 않게.
  static const double actionMinHeight = 56;

  /// **트레이 폭 대비** 이만큼 밀면 열린 채로 스냅한다(spec swipe-actions.md).
  ///
  /// slidable 에 그대로 넘기면 안 된다 — 그쪽 `openThreshold` 는 **행 전체 폭** 기준이다
  /// (`action_pane.dart` 기본값이 `extentRatio / 2` 인 것에서 드러난다). 트레이는 행의
  /// 일부(액션 2개면 extentRatio ≈ 0.27)라, 0.4 를 그대로 주면
  /// `openThreshold > extentRatio` 가 되어 `action_pane.dart:190` 의
  /// `openThreshold <= extentRatio` 가드에 걸린다. 그러면 드래그로는 절대 스냅하지 못하고
  /// 끝까지 끌어 튕겨야만 열린다 — 실제로 그렇게 동작하고 있었다.
  static const double _openThreshold = 0.4;

  /// 아이콘 원형 지름 — 행 높이 안에 원형 + 라벨이 다 들어가는 최대치.
  /// 40 은 라벨과 합쳐 넘친다(실측).
  static const double _badgeSize = 36;

  @override
  Widget build(BuildContext context) {
    if (!enabled || actions.isEmpty) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        // slidable 은 비율로 받는데 스펙은 액션당 72px 고정이다. 행 폭을 알아야
        // 비율로 바꿀 수 있어 LayoutBuilder 로 감싼다.
        final width = constraints.maxWidth;
        final trayWidth = List.generate(
          actions.length,
          slotWidth,
        ).fold<double>(0, (a, b) => a + b);
        final ratio = width > 0 ? (trayWidth / width).clamp(0.1, 0.9) : 0.5;

        return Slidable(
          key: key ?? ValueKey(identityHashCode(child)),
          groupTag: groupTag,
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: ratio.toDouble(),
            // 트레이 비율(ratio)을 곱해 행 전체 폭 기준으로 환산한다. 위 상수 주석 참고.
            // closeThreshold 는 건드리지 않는다 — "열린 상태에서 되돌려 닫는 지점" 이라
            // 다른 개념이고, 같은 값으로 같이 걸면 두 범위가 맞물려 아예 열리지 않는다(실측).
            openThreshold: (ratio * _openThreshold).toDouble(),
            children: [
              // **역순으로 그린다** — 왼쪽으로 조금 밀면 오른쪽 끝 액션부터 드러나므로,
              // 순서대로 두면 파괴적 액션이 제일 먼저 손에 닿는다. 뒤집어 두면 삭제가
              // 가장 안쪽(멀리)에 놓여 끝까지 밀어야 닿는다. 호출부는 '고정·수정·삭제'
              // 라는 자연스러운 의미 순서를 그대로 쓰면 된다.
              for (final (i, a) in actions.reversed.indexed)
                CustomSlidableAction(
                  // 폭을 각자 다르게 준다 — 첫 액션만 행에서 더 떨어뜨린다.
                  // flex 는 비율이라 정수로 넘겨도 폭 비가 유지된다.
                  flex: slotWidth(i).round(),
                  onPressed: (ctx) => _run(ctx, a),
                  // 트레이에 배경을 두지 않는다 — 색을 깔면 행 옆에 박스가 하나 더
                  // 생긴 것처럼 보인다. 색은 아이콘 원형만 갖는다.
                  backgroundColor: Colors.transparent,
                  foregroundColor: _fg(context, a.kind),
                  // 간격을 왼쪽 padding 으로 만든다 — 배지가 슬롯 오른쪽에 붙어
                  // 마지막 액션이 화면 끝과 딱 맞는다. 상하 여백은 없다(행 높이 그대로).
                  padding: EdgeInsets.only(
                    left: i == 0 ? _gapLead : _gapBetween,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: actionMinHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.icon != null) ...[
                          // 사각 채움이 아니라 원형 — 행을 밀었을 때 색 덩어리가
                          // 화면을 반 가르지 않고 아이콘만 또렷하게 선다.
                          Container(
                            width: _badgeSize,
                            height: _badgeSize,
                            decoration: BoxDecoration(
                              color: _bg(context, a.kind),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              a.icon,
                              size: 18,
                              color: _fg(context, a.kind),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          a.label,
                          textAlign: TextAlign.center,
                          style: PTypo.caption.copyWith(
                            fontWeight: PFontWeight.semi,
                            color: _labelFg(context, a.kind),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  /// 확인이 필요하면 받고 실행한다. 확인 문구가 없으면 바로 실행.
  ///
  /// 트레이는 <b>언제나 먼저</b> 닫는다. 열린 채로 다이얼로그를 띄우면 취소하고 돌아왔을
  /// 때 그대로 열려 있고, 실행한 경우엔 사라진 행 자리에 트레이만 남는다.
  ///
  /// 닫은 뒤에는 이 액션의 context 를 다시 쓰지 않는다 — 트레이가 접히면서 풀려서
  /// `context.mounted` 가 거짓이 되고, 그걸 가드로 걸면 확인을 눌러도 아무 일도
  /// 일어나지 않는다(실측).
  Future<void> _run(BuildContext context, PSwipeAction action) async {
    final message = action.confirmMessage;
    final l = AppLocalizations.of(context);
    // 다이얼로그는 행보다 오래 산다 — 트레이가 접혀도 살아 있는 위쪽 context 로 띄운다.
    final host = Navigator.of(context, rootNavigator: true).context;
    Slidable.of(context)?.close();

    if (message == null) {
      action.onSelect();
      return;
    }

    final ok = await showPConfirmDialog(
      host,
      // 제목은 호출부가 넘긴다 — 상세 경로와 같은 문구여야 한다(spec alert-dialog).
      // 확인 라벨만 액션 라벨 그대로 — 방금 누른 버튼의 연장이라 경로와 무관하다.
      title: action.confirmTitle ?? action.label,
      message: message,
      confirmLabel: action.label,
      destructive: action.kind == PSwipeKind.destructive,
      cancelLabel: l.actionCancel,
    );
    if (ok) action.onSelect();
  }

  /// 아이콘 원형의 채움색. primary 는 brand 가 아니라 info — 버튼 채움과 같은
  /// 기조다(spec button.md Migration notes 2026-08).
  Color _bg(BuildContext context, PSwipeKind kind) {
    final t = context.tokens;
    return switch (kind) {
      PSwipeKind.neutral => t.bgMuted,
      PSwipeKind.primary => t.statusInfo,
      PSwipeKind.destructive => t.statusDanger,
    };
  }

  /// 원형 안 아이콘 색.
  Color _fg(BuildContext context, PSwipeKind kind) {
    final t = context.tokens;
    return switch (kind) {
      PSwipeKind.neutral => t.fgPrimary,
      PSwipeKind.primary => t.fgOnBrand,
      PSwipeKind.destructive => t.fgOnDanger,
    };
  }

  /// 원형 밖 라벨 색 — 채움색과 같은 계열로 두어 무엇을 누르는지 색으로도 읽힌다.
  Color _labelFg(BuildContext context, PSwipeKind kind) {
    final t = context.tokens;
    return switch (kind) {
      PSwipeKind.neutral => t.fgSecondary,
      PSwipeKind.primary => t.statusInfoFg,
      PSwipeKind.destructive => t.statusDangerFg,
    };
  }
}
