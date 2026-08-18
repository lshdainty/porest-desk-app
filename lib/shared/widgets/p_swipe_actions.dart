import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
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
    this.confirmMessage,
  });

  /// 한글 두 글자 권장 — 그보다 길면 72px 안에서 줄바꿈된다.
  final String label;
  final IconData? icon;
  final PSwipeKind kind;
  final VoidCallback onSelect;

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

  /// 액션 하나의 폭 — 한글 두 글자 + 20px 아이콘이 겹치지 않는 최소치.
  static const double actionWidth = 72;

  /// 액션 최소 높이 — WCAG 2.5.5(AAA, 44×44)를 밑돌지 않게.
  static const double actionMinHeight = 56;

  /// 이 비율 이상 밀면 열린 채로 스냅한다.
  static const double _openThreshold = 0.4;

  @override
  Widget build(BuildContext context) {
    if (!enabled || actions.isEmpty) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        // slidable 은 비율로 받는데 스펙은 액션당 72px 고정이다. 행 폭을 알아야
        // 비율로 바꿀 수 있어 LayoutBuilder 로 감싼다.
        final width = constraints.maxWidth;
        final trayWidth = actions.length * actionWidth;
        final ratio = width > 0 ? (trayWidth / width).clamp(0.1, 0.9) : 0.5;

        return Slidable(
          key: key ?? ValueKey(identityHashCode(child)),
          groupTag: groupTag,
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: ratio.toDouble(),
            // 이만큼 밀어야 열린 채로 스냅한다. closeThreshold 는 건드리지 않는다 —
            // "열린 상태에서 되돌려 닫는 지점" 이라 다른 개념이고, 같은 값으로 같이
            // 걸면 두 범위가 맞물려 아예 열리지 않는다(실측).
            openThreshold: _openThreshold,
            children: [
              for (final a in actions)
                CustomSlidableAction(
                  onPressed: (ctx) => _run(ctx, a),
                  backgroundColor: _bg(context, a.kind),
                  foregroundColor: _fg(context, a.kind),
                  padding: const EdgeInsets.all(PSpace.x8),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minHeight: actionMinHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.icon != null) ...[
                          Icon(a.icon, size: 20),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          a.label,
                          textAlign: TextAlign.center,
                          style: PTypo.caption
                              .copyWith(fontWeight: PFontWeight.semi),
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
      title: action.label,
      message: message,
      confirmLabel: action.label,
      destructive: action.kind == PSwipeKind.destructive,
      cancelLabel: l.actionCancel,
    );
    if (ok) action.onSelect();
  }

  Color _bg(BuildContext context, PSwipeKind kind) {
    final t = context.tokens;
    return switch (kind) {
      PSwipeKind.neutral => t.bgCanvas,
      PSwipeKind.primary => t.bgBrandSolid,
      PSwipeKind.destructive => t.statusDanger,
    };
  }

  Color _fg(BuildContext context, PSwipeKind kind) {
    final t = context.tokens;
    return switch (kind) {
      PSwipeKind.neutral => t.fgPrimary,
      PSwipeKind.primary => t.fgOnBrand,
      PSwipeKind.destructive => t.fgOnDanger,
    };
  }
}
