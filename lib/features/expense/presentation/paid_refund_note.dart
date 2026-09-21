import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/expense/domain/refund_preview.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 삭제·환불 확인창의 **환급 안내 한 줄**(설계 13-2, 닫힌 회차 R6) — 웹
/// `PaidRefundNote` 미러.
///
/// 결제 완료 회차의 카드 거래를 지우거나 환불하면 결제계좌로 돈이 돌아간다 — 돈이
/// 움직이는데 확인창이 아무 말도 안 하면 계좌에 출처 모를 입금이 생긴 것으로 보인다.
/// 결제한 달이 지났으면 반대로 **안 돌아간다**는 것을 말한다.
///
/// 다섯 갈래다. **확인 버튼은 이 조회를 기다리지 않는다** — 느린 네트워크가 삭제·환불을
/// 막으면 안 된다.
///
///   1. 도는 중 — 스켈레톤(줄이 나중에 나타나며 버튼이 밀리지 않게)
///   2. 돌려줄 돈이 있다 — 금액을 말한다(기록용 몫도 같은 문구다)
///   3. 이미 환불된 거래 — 환급은 그때 끝났다고 말한다
///   4. 결제한 달이 지났다 — 기록만 정리되고 계좌로는 안 돌아간다고 말한다
///   5. 실패·3초 초과 — 결제계좌가 있으면 금액 없는 문구, 없으면 줄 없음
class PaidRefundNote extends StatefulWidget {
  const PaidRefundNote({
    super.key,
    required this.preview,
    required this.cardHasPaymentAsset,
    this.onResolved,
  });

  /// null 이면 묻지 않은 것이다 — 결제계좌가 있을 때만 금액 없는 문구를 그린다.
  final Future<RefundPreview>? preview;
  final bool cardHasPaymentAsset;

  /// 답이 오면 부른다(실패면 null) — 확인창이 예고한 금액을 들고 나가는 데 쓴다.
  final ValueChanged<RefundPreview?>? onResolved;

  @override
  State<PaidRefundNote> createState() => _PaidRefundNoteState();
}

class _PaidRefundNoteState extends State<PaidRefundNote> {
  RefundPreview? _preview;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final future = widget.preview;
    if (future == null) return;
    _loading = true;
    future.then(
      (p) {
        if (!mounted) return;
        setState(() {
          _preview = p;
          _loading = false;
        });
        widget.onResolved?.call(p);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _failed = true;
          _loading = false;
        });
        widget.onResolved?.call(null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(top: PSpace.x8),
        child: Container(
          key: const ValueKey('paid-refund-skeleton'),
          height: 14,
          decoration: BoxDecoration(
            color: t.bgMuted,
            borderRadius: PRadius.brXs,
          ),
        ),
      );
    }
    final p = _preview;
    String? text;
    if (p != null && p.alreadyRefunded) {
      text = l.expRefundedDeleteNote;
    } else if (p != null && p.windowClosed) {
      text = l.expWindowClosedNote;
    } else if (p != null && p.hasRefund) {
      text = l.expPaidDeleteNote(krw(p.refundAmount));
    } else if ((_failed || p == null) && widget.cardHasPaymentAsset) {
      // 못 물어봤을 때만 금액 없는 문구로 넘어간다 — 물어봐서 0 이면 조용히 둔다.
      text = l.expPaidDeleteFallback;
    }
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: PSpace.x8),
      child: Text(text, style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
    );
  }
}

/// 저장 확인창의 문장 — 미리보기를 사람 말로 옮긴다. 비면 묻지 않고 저장한다
/// (웹 `AddTxSheet.saveNotes` 미러).
///
/// 환급만 있으면 종전 감액 문구 그대로다(13-2 문구). 결제한 달이 지나 안 돌려주면
/// "기록만 정리돼요", 결제가 끝난 회차에 떨어지면 "기록만 남아요", 오늘이 결제일이면
/// 추가로 빠지는 금액을 말한다.
List<String> saveConfirmNotes(AppLocalizations l, RefundPreview p) {
  final notes = <String>[];
  final record = p.newRecordAmount;
  final sameDay = p.sameDayExtraPayment;
  if (p.hasRefund) {
    notes.add(
      record > 0 || sameDay > 0
          ? l.expPaidDeleteNote(krw(p.refundAmount))
          : l.expPaidReduceNote(krw(p.refundAmount)),
    );
  } else if (p.windowClosed) {
    notes.add(l.expWindowClosedNote);
  }
  if (record > 0) notes.add(l.expClosedCycleNote);
  if (sameDay > 0) notes.add(l.expSameDayPaymentNote(krw(sameDay)));
  return notes;
}
