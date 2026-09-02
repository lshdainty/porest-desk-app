import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 표준 footer — 좌측 보조(삭제 또는 [leftSlot]) / 우측 취소 + 저장. controller listen.
///
/// **액션은 2개까지**(spec drawer.md 액션 구성) — 편집 폼은 `취소`·`저장` 이고 삭제를
/// 두지 않는다(삭제는 상세에서). 좌측 보조 액션이 이미 있는 화면은 [showCancel] 을 꺼
/// `취소` 를 우상단 X 에 맡긴다.
///
/// [leftSlot] 지정 시 좌측 삭제 버튼 대신 임의 위젯(초기화 버튼·요약 텍스트 등)을 둔다
/// (삭제가 아닌 좌측 보조 액션용 — 삭제 슬롯과 동시 사용 시 leftSlot 우선).
class PSheetFooter extends StatelessWidget {
  const PSheetFooter({
    super.key,
    required this.controller,
    required this.submitLabel,
    this.cancelLabel,
    this.deleteLabel,
    this.leftSlot,
    this.showCancel,
  });
  final PSheetController controller;
  final String submitLabel;
  final String? cancelLabel;
  final String? deleteLabel;
  final Widget? leftSlot;

  /// 취소 버튼 표시 — 지정하지 않으면 **좌측 액션(삭제·[leftSlot])이 있을 때 자동으로
  /// 숨긴다**. 액션 2개 규칙을 위젯이 지키게 해 호출부가 잊어도 3개가 되지 않는다.
  /// 우상단 X 와 드래그 내리기가 취소를 대신한다(spec drawer.md 액션 구성).
  final bool? showCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        // 취소·저장은 화면 폭을 반씩 나눠 갖는다 — 한 손으로 누를 폭을 확보한다
        // (spec drawer.md). 우측 정렬로 두면 화면 구석의 작은 알약이 된다.
        //
        // 좌측 액션(삭제·leftSlot)도 균등 분배에 든다. 액션이 2개까지로 묶여 있어
        // 셋이 나뉠 일이 없고, 좌측만 내용 폭이면 그쪽이 버튼으로 안 보인다.
        final hasLeft = leftSlot != null || controller.onDelete != null;
        // 좌측 액션이 있으면 취소를 뺀다 — 그러지 않으면 액션이 3개가 된다.
        final cancel = showCancel ?? !hasLeft;
        return Row(
          children: [
            if (leftSlot != null) ...[
              // leftSlot 도 화면 폭을 나눠 갖는다 — 필터 '초기화' 처럼 비파괴 보조
              // 액션이 좌측에 작은 글씨로 붙으면 버튼인지 알아보기 어렵다
              // (spec drawer.md "flex:1 평등 분배"). 넘겨받는 위젯이 fullWidth 를
              // 켜야 실제로 채워진다.
              Expanded(child: leftSlot!),
              const SizedBox(width: PSpace.x8),
            ] else if (controller.onDelete != null) ...[
              // 삭제는 error 솔리드 채움(danger) + 균등 분배 — 삭제 확인 다이얼로그의
              // 삭제 버튼과 같은 색이라, 같은 동작이 같은 색으로 이어진다.
              // 옅은 채움(dangerSoft)은 다크에서 어두운 자주로 가라앉아 버렸다.
              Expanded(
                child: PButton(
                  label: deleteLabel ?? l.actionDelete,
                  variant: PButtonVariant.danger,
                  size: PButtonSize.lg,
                  fullWidth: true,
                  onPressed:
                      controller.submitting || controller.onDelete == null
                      ? null
                      : controller.deleteGuarded,
                ),
              ),
              const SizedBox(width: PSpace.x8),
            ],
            if (cancel) ...[
              Expanded(
                child: PButton(
                  label: cancelLabel ?? l.actionCancel,
                  // ghost 는 배경이 없어 전체 폭 배치에서 버튼으로 안 보인다 — 테두리
                  // 없는 회색 채움(spec button.md Migration notes 2026-08).
                  variant: PButtonVariant.secondary,
                  size: PButtonSize.lg,
                  fullWidth: true,
                  onPressed: controller.submitting
                      ? null
                      : () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(width: PSpace.x8),
            ],
            Expanded(
              child: PButton(
                label: submitLabel,
                size: PButtonSize.lg,
                fullWidth: true,
                loading: controller.submitting,
                onPressed:
                    controller.canSubmit &&
                        !controller.submitting &&
                        controller.onSubmit != null
                    ? controller.submitGuarded
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 뷰(읽기전용) 다이얼로그 footer — 좌측 보조(삭제 danger 또는 [leading] 위젯) /
/// 우측 편집. 폼 제출이 없는 상세 시트용(거래·자산·카드 상세 등).
/// PSheetController 불필요 — 직접 콜백.
///
/// **액션은 2개까지**(spec drawer.md 액션 구성). 상세는 `삭제`·`편집` 이고 확인은 두지
/// 않는다 — 우상단 X 와 드래그 내리기가 이미 닫기라 같은 동작에 입구가 둘이 된다.
/// 확인 버튼은 [confirmLabel] 이나 [onConfirm] 을 준 경우에만 그린다(닫기 단독 footer 용).
class PViewFooter extends StatelessWidget {
  const PViewFooter({
    super.key,
    this.onDelete,
    this.deleteLabel,
    this.deleting = false,
    this.leading,
    this.onEdit,
    this.editLabel,
    this.confirmLabel,
    this.confirmVariant = PButtonVariant.primary,
    this.onConfirm,
  });

  /// 좌측 삭제(파괴적) — ghost danger flush-left. [leading] 과 동시 사용 금지.
  final VoidCallback? onDelete;
  final String? deleteLabel;
  final bool deleting;

  /// 삭제 대신 좌측에 둘 임의 위젯(금액 가리기 토글 등).
  final Widget? leading;

  /// 우측 편집(opt) — ghost pencil.
  final VoidCallback? onEdit;
  final String? editLabel;

  /// 우측 끝 확인/닫기 — **둘 다 없으면 버튼을 그리지 않는다**(상세의 기본).
  /// 읽기전용 단독 닫기 footer 처럼 X 말고 버튼이 따로 필요한 화면만 지정한다.
  final String? confirmLabel;
  final PButtonVariant confirmVariant;
  final VoidCallback? onConfirm;

  bool get _hasConfirm => confirmLabel != null || onConfirm != null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 남은 폭은 우측 액션들이 나눠 갖는다(spec drawer.md — 한 손 조작 폭).
    // 삭제·leading 은 좌측 고정 — 파괴적 액션이 주 액션과 같은 무게로 보이면 안 된다.
    return Row(
      children: [
        if (onDelete != null) ...[
          Expanded(
            child: PButton(
              label: deleteLabel ?? l.actionDelete,
              // 폼 시트 footer 와 같은 규칙 — error 솔리드 채움.
              variant: PButtonVariant.danger,
              size: PButtonSize.lg,
              fullWidth: true,
              loading: deleting,
              onPressed: deleting ? null : onDelete,
            ),
          ),
          const SizedBox(width: PSpace.x8),
        ] else
          ?leading,
        if (onEdit != null)
          Expanded(
            child: PButton(
              label: editLabel ?? l.actionEdit,
              // 상세의 주 액션은 편집 — 확인이 없으면 이게 유일한 채움 버튼이다.
              variant: _hasConfirm
                  ? PButtonVariant.ghost
                  : PButtonVariant.primary,
              size: PButtonSize.lg,
              fullWidth: true,
              onPressed: onEdit,
            ),
          ),
        if (onEdit != null && _hasConfirm) const SizedBox(width: PSpace.x8),
        if (_hasConfirm)
          Expanded(
            child: PButton(
              label: confirmLabel ?? l.actionConfirm,
              variant: confirmVariant,
              size: PButtonSize.lg,
              fullWidth: true,
              onPressed: onConfirm ?? () => Navigator.of(context).pop(),
            ),
          ),
      ],
    );
  }
}

/// content 와 footer 가 공유하는 작업 상태 (showPSheet 표준 컨트롤러).
///
/// content 측 (입력 폼) 의 setState 시 [setCanSubmit]/[setSubmitting] 호출 →
/// footer 의 AnimatedBuilder 가 listen → 버튼 활성/로딩 상태 자동 반영.
/// footer 측의 onPressed 는 [onSubmit] 을 호출.
class PSheetController extends ChangeNotifier {
  bool submitting = false;
  bool canSubmit = false;
  Future<void> Function()? onSubmit;
  Future<void> Function()? onDelete;

  // 따닥 탭 방어 — submitting 으로 버튼이 죽는 건 다음 프레임 뒤라, 같은 프레임 안에
  // 들어온 두 번째 탭이 onSubmit 을 한 번 더 불렀다(위젯 테스트로 확인, 2026-09-03).
  // 탭 즉시 동기적으로 잠그고 핸들러가 끝나면 푼다. 핸들러가 setSubmitting 을 안 써도 막힌다.
  bool _inFlight = false;

  /// footer 의 제출 버튼이 부른다 — 진행 중이면 무시.
  Future<void> submitGuarded() => _guard(onSubmit);

  /// footer 의 삭제 버튼이 부른다 — 진행 중이면 무시.
  Future<void> deleteGuarded() => _guard(onDelete);

  Future<void> _guard(Future<void> Function()? action) async {
    if (action == null || _inFlight || submitting) return;
    _inFlight = true;
    try {
      await action();
    } finally {
      _inFlight = false;
    }
  }

  void setSubmitting(bool v) {
    if (submitting == v) return;
    submitting = v;
    notifyListeners();
  }

  void setCanSubmit(bool v) {
    if (canSubmit == v) return;
    canSubmit = v;
    notifyListeners();
  }

  /// content snapshot 등이 바뀌어 footer 가 다시 그려져야 할 때 호출.
  /// (canSubmit/submitting 외에 footer 가 참조하는 값이 바뀐 경우)
  void bump() => notifyListeners();
}

/// add_tx_sheet 와 동일한 표준 bottom sheet helper.
///
/// 구조 (모두 helper 가 강제):
///   - drag handle (고정)
///   - header: 좌측 큰 제목 + headerActions + 우측 X (고정 높이)
///   - content: 스크롤 영역. `contentBuilder(ctx, scrollController)` 가 ListView/CustomScrollView 직접 구성
///   - footer: optional, 고정 높이. `footerBuilder(ctx)` 로 Row 등 액션 위젯 전달
///
/// **본문 좌우 여백은 `contentBuilder` 가 준다.** 헤더·푸터는 24 를 갖지만 content 는
/// 안 감싼다 — 리스트형 본문이 구분선·스크롤바를 시트 끝까지 뻗어야 하기 때문이다.
/// 그래서 호출처가 헤더와 같은 24 를 직접 물린다:
/// `padding: EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16)`
///
/// 두 sizing 모드:
///   - [shrinkWrap]=false (default): `DraggableScrollableSheet` 로 sheet 가
///     화면 [initialChildSize] 비율 만큼 강제 점유. content 짧아도 sheet
///     크기 유지 (긴 form 의 add_tx_sheet 등 표준 — drag 로 min/max 조정).
///   - [shrinkWrap]=true: sheet 가 content 자연 합산 height 로 wrap. content
///     이 짧은 picker/단순 액션 시트 (range picker 등) 에 사용. caller 의
///     `contentBuilder` 는 ListView 대신 Column (or shrinkWrap ListView) 사용.
///     [initialChildSize]/[minChildSize]/[maxChildSize] 무시.
Future<T?> showPSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, ScrollController) contentBuilder,
  Widget Function(BuildContext)? footerBuilder,
  List<Widget> headerActions = const [],
  double initialChildSize = 0.85,
  double minChildSize = 0.5,
  double maxChildSize = 0.95,
  bool shrinkWrap = false,

  /// 제목이 시트 안 상태에 따라 바뀌는 경우(단계형 시트). 주면 [title] 대신 이걸 그린다.
  ValueListenable<String>? titleListenable,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // 셸 branch Navigator 가 아닌 root 에 띄운다 — 플로팅 탭바
    // (셸 bottomNavigationBar) 가 시트 위에 그려져 하단 액션을 가리는
    // 문제 방지(웹은 시트 z-index 가 탭바 위, 동일 정합).
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.tokens.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PRadius.xl2)),
    ),
    builder: (sheetCtx) {
      if (shrinkWrap) {
        // wrap-content 모드 — content 자연 합산 height + max-h 88% cap.
        final mq = MediaQuery.of(sheetCtx);
        final bottomInset = mq.viewInsets.bottom > 0
            ? mq.viewInsets.bottom
            : mq.viewPadding.bottom;
        // dummy scroll controller — shrinkWrap 모드에선 caller 가 사용 안 함.
        final dummyCtrl = ScrollController();
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: mq.size.height * 0.88),
            child: SingleChildScrollView(
              child: _buildSheetColumn(
                sheetCtx,
                title: title,
                titleListenable: titleListenable,
                headerActions: headerActions,
                content: contentBuilder(sheetCtx, dummyCtrl),
                footerBuilder: footerBuilder,
                expanded: false,
              ),
            ),
          ),
        );
      }
      // default — DraggableScrollableSheet (긴 form 표준).
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (innerCtx, scrollCtrl) {
          final mq = MediaQuery.of(innerCtx);
          final bottomInset = mq.viewInsets.bottom > 0
              ? mq.viewInsets.bottom
              : mq.viewPadding.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: _buildSheetColumn(
              innerCtx,
              title: title,
              titleListenable: titleListenable,
              headerActions: headerActions,
              content: contentBuilder(innerCtx, scrollCtrl),
              footerBuilder: footerBuilder,
              expanded: true,
            ),
          );
        },
      );
    },
  );
}

/// showPSheet 의 두 모드 (DraggableScrollableSheet / shrinkWrap) 가 공유하는
/// 내부 Column 골격 (drag handle + header + content + optional footer).
///
/// [expanded] true 면 content 영역을 `Expanded` 로 감싸 부모가 강제한 높이를
/// 다 차지 (Draggable 모드). false 면 자연 wrap (shrinkWrap 모드).
Widget _buildSheetColumn(
  BuildContext ctx, {
  required String title,
  required ValueListenable<String>? titleListenable,
  required List<Widget> headerActions,
  required Widget content,
  required Widget Function(BuildContext)? footerBuilder,
  required bool expanded,
}) {
  final t = ctx.tokens;
  return Column(
    mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
    // 가로를 채운다. 기본값(center)이면 폭을 스스로 안 채우는 본문(Column mainAxisSize.min
    // 등)이 시트 가운데로 쪼그라들어, 호출처가 좌우 24 를 줘도 그 여백이 화면 기준으로
    // 서지 않는다. 시트 본문은 시트 폭을 쓰는 게 맞다.
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Drag handle — spec: 40×4 / surface-input / radius-full
      Container(
        margin: const EdgeInsets.only(top: PSpace.x8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: t.bgMuted,
          borderRadius: PRadius.brFull,
        ),
      ),
      // Header (제목 + 액션 + close) — 좌우 xl(24).
      // 우측은 sm(8) — 닫기 아이콘 버튼이 자체 padding 을 가져 광학적으로 24 에 선다.
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpace.xl,
          PSpace.md,
          PSpace.sm,
          PSpace.xs,
        ),
        child: Row(
          children: [
            Expanded(
              // sheet spec(title-md 18/600) 정합 — 웹 SheetTitle/DrawerTitle 와 동일.
              child: titleListenable == null
                  ? Text(title, style: PTypo.h4.copyWith(color: t.fgPrimary))
                  : ValueListenableBuilder<String>(
                      valueListenable: titleListenable,
                      builder: (_, v, _) =>
                          Text(v, style: PTypo.h4.copyWith(color: t.fgPrimary)),
                    ),
            ),
            ...headerActions,
            IconButton(
              icon: Icon(LucideIcons.x, color: t.fgTertiary, size: PSpace.x20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
      // Content — Draggable 모드면 Expanded 로 영역 강제, shrinkWrap 모드면 자연 wrap.
      //
      // **좌우 여백은 여기서 주지 않는다. 호출처(contentBuilder) 책임이다.**
      // 리스트형 본문이 스크롤바·구분선·hover 를 시트 끝까지 뻗어야 해서 바깥에서
      // 일괄로 물릴 수 없다. 대신 호출처가 헤더·푸터와 같은 24 를 직접 준다:
      //
      //   ListView(padding: EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16))
      //
      // 이걸 빠뜨리면 본문만 화면 끝에 붙는다 — 실제로 카드 상세의 '지금 결제'·
      // '기간 선택' 시트가 그렇게 나갔다.
      if (expanded) Expanded(child: content) else content,
      // Footer (옵션, 고정)
      if (footerBuilder != null)
        Container(
          padding: const EdgeInsets.fromLTRB(
            PSpace.xl,
            PSpace.md,
            PSpace.xl,
            PSpace.lg,
          ),
          color: t.bgSurface,
          child: footerBuilder(ctx),
        ),
    ],
  );
}

/// 표준 form-입력 AlertDialog wrapper — 비밀번호/저금 추가/그룹 수정 등.
///
/// title + content slot + actions slot 골격만 통일. 각 도메인 content
/// (입력 필드, validation 등) 는 사용처 직접 구성.
///
/// 액션이 2개 이상이면 화면 폭을 균등하게 나눠 깐다 — AlertDialog 기본 actions 는
/// OverflowBar 라 버튼이 내용 폭으로 우측에 몰린다(spec dialog.md 모바일 규칙 위반).
/// 각 버튼에 `fullWidth: true` 를 주어야 Expanded 를 채운다.
///
/// 취소는 `secondary`(테두리 없는 회색 채움) — ghost 는 배경이 없어 전체 폭 배치에서
/// 버튼으로 안 보인다(spec button.md Migration notes 2026-08).
///
/// 사용 예:
/// ```dart
/// showDialog<bool>(
///   context: context,
///   builder: (_) => PFormAlertDialog(
///     title: '그룹 수정',
///     content: Column(...),
///     actions: [
///       PButton(label: '취소', variant: PButtonVariant.secondary,
///               size: PButtonSize.lg, fullWidth: true, onPressed: ...),
///       PButton(label: '저장', size: PButtonSize.lg, fullWidth: true,
///               onPressed: ...),
///     ],
///   ),
/// );
/// ```
class PFormAlertDialog extends StatelessWidget {
  const PFormAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.titleLeading,
  });

  final String title;

  /// title 좌측 prefix (예: 아이콘). 8px gap 후 title 텍스트.
  final Widget? titleLeading;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AlertDialog(
      backgroundColor: t.bgSurface,
      // shape 은 dialogTheme(radius-lg 12) 을 따른다 — 여기서 또 지정하면
      // 테마가 바뀌어도 이 다이얼로그만 옛 값에 남는다. 실제로 확인 다이얼로그와
      // 모서리가 갈렸던 원인이다.
      title: titleLeading != null
          ? Row(
              children: [
                titleLeading!,
                const SizedBox(width: PSpace.sm),
                Expanded(child: Text(title)),
              ],
            )
          : Text(title),
      content: content,
      // AlertDialog 기본 actions 는 OverflowBar 라 버튼이 내용 폭으로 우측에 몰린다.
      // 2개 이상이면 Row + Expanded 로 직접 깔아 화면 폭을 반씩 나눈다
      // (spec dialog.md 모바일 규칙 — _PConfirmDialog 과 같은 처리).
      // 1개면 OverflowBar 그대로 둔다 — 나눌 상대가 없다.
      actions: actions.length < 2
          ? actions
          : [
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: PSpace.x8),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            ],
    );
  }
}

/// 표준 확인 다이얼로그 — 위험 액션이면 [destructive]=true.
/// 확인 다이얼로그. [onConfirm] 미제공 시 확인 탭 즉시 닫고 true 반환(기존 동작).
///
/// [onConfirm] 제공 시(웹 ConfirmDialog `loading` 정합): 확인 탭 → 다이얼로그를
/// 연 채 **확인(저장) 버튼에만** 스피너를 표시하며 [onConfirm] 을 실행하고, 성공하면
/// 닫고 true. 예외가 발생하면 다이얼로그를 유지(스피너만 해제) — 에러 메시지는
/// [onConfirm] 내부에서 처리. 취소 버튼·바깥 탭은 실행 중에도 원래대로 동작한다.
///
/// [acknowledge]=true 면 **확인 하나만** 그린다(spec alert-dialog.md Variants).
/// 전제 조건이 안 맞아 액션이 아예 차단된 통지 — 고를 것이 없는데 취소를 나란히
/// 두면 두 버튼이 같은 일(닫기)을 한다. 제목은 결과 명사구(`삭제 불가`)로 쓴다.
/// 반환값은 의미가 없다(항상 true) — 호출부는 그냥 await 하고 흘려보낸다.
Future<bool> showPConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  bool acknowledge = false,
  Future<void> Function()? onConfirm,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _PConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? AppLocalizations.of(context).actionConfirm,
      cancelLabel: cancelLabel ?? AppLocalizations.of(context).actionCancel,
      destructive: destructive,
      acknowledge: acknowledge,
      onConfirm: onConfirm,
    ),
  );
  return ok == true;
}

class _PConfirmDialog extends StatefulWidget {
  const _PConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.acknowledge,
    this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final bool acknowledge;
  final Future<void> Function()? onConfirm;

  @override
  State<_PConfirmDialog> createState() => _PConfirmDialogState();
}

class _PConfirmDialogState extends State<_PConfirmDialog> {
  bool _busy = false;

  Future<void> _confirm() async {
    // 같은 프레임 안의 두 번째 탭 — 버튼이 loading 으로 죽기 전에 들어온다.
    if (_busy) return;
    final action = widget.onConfirm;
    if (action == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      // 실패 — 다이얼로그 유지, 스피너만 해제 (에러 표시는 onConfirm 내부에서).
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AlertDialog(
      backgroundColor: t.bgSurface,
      title: Text(widget.title),
      content: Text(widget.message),
      // AlertDialog 기본 actions 는 OverflowBar 라 버튼이 내용 폭으로 우측에 몰린다.
      // Row + Expanded 로 직접 깔아 화면 폭을 반씩 나눈다(spec dialog.md 모바일 규칙).
      actions: [
        Row(
          children: [
            // acknowledge 는 고를 것이 없는 통지라 취소를 두지 않는다 — 나란히 두면
            // 두 버튼이 같은 일(닫기)을 한다(spec alert-dialog.md Variants).
            if (!widget.acknowledge) ...[
              // 취소는 작업 중에도 원래 상태 유지 — 비동기 작업은 확인 버튼 스피너로만 표시.
              Expanded(
                child: PButton(
                  label: widget.cancelLabel,
                  // ghost 는 배경이 없어 전체 폭 배치에서 버튼으로 안 보인다 — 테두리
                  // 없는 회색 채움(spec alert-dialog.md · button.md 2026-08).
                  variant: PButtonVariant.secondary,
                  size: PButtonSize.lg,
                  fullWidth: true,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: PSpace.x8),
            ],
            Expanded(
              child: PButton(
                label: widget.confirmLabel,
                variant: widget.destructive
                    ? PButtonVariant.danger
                    : PButtonVariant.primary,
                size: PButtonSize.lg,
                fullWidth: true,
                loading: _busy,
                onPressed: _busy ? null : _confirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
