import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// iOS 스타일 휠 피커 — Material 의 showDatePicker/showTimePicker 를 대신한다.
///
/// Material 기본 피커는 시계 다이얼(시 → 분 2단)과 달력 그리드라 손가락으로
/// 맞추기 어렵고, 웹(shadcn 계열 스크롤 컬럼)과 조작감이 갈렸다. 휠은 웹의
/// 시/분 컬럼과 같은 상호작용이라 앱·웹이 같은 느낌으로 붙는다.
///
/// 시트는 `showPSheet(shrinkWrap: true)` — 휠 높이만 차지하고 footer 는
/// [취소][확인] 두 개. 휠은 스크롤 중에도 값을 계속 흘려보내므로, 확인을
/// 누르기 전에는 호출부 상태를 바꾸지 않는다(취소로 되돌릴 수 있어야 한다).
const double _wheelHeight = 216;

/// 휠 자체는 시트 배경 위에 떠야 한다 — 피커에 배경색을 주면 다크에서
/// 시트와 다른 판때기가 얹힌 것처럼 보인다.
Widget _themed(BuildContext context, Widget picker) {
  final t = context.tokens;
  return CupertinoTheme(
    data: CupertinoThemeData(
      brightness: Theme.of(context).brightness,
      primaryColor: t.fgBrand,
      textTheme: CupertinoTextThemeData(
        dateTimePickerTextStyle: PTypo.bodyLg.copyWith(color: t.fgPrimary),
      ),
    ),
    child: SizedBox(height: _wheelHeight, child: picker),
  );
}

Widget _footer(
  BuildContext ctx, {
  required VoidCallback onConfirm,
}) {
  final l = AppLocalizations.of(ctx);
  // 취소·확인은 폭을 반씩 나눠 갖는다 — PSheetFooter 와 같은 규칙.
  return Row(
    children: [
      Expanded(
        child: PButton(
          label: l.actionCancel,
          variant: PButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
      const SizedBox(width: PSpace.x8),
      Expanded(
        child: PButton(
          label: l.actionConfirm,
          fullWidth: true,
          onPressed: onConfirm,
        ),
      ),
    ],
  );
}

/// 날짜 휠. 취소하면 null.
Future<DateTime?> showPDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final first = firstDate ?? DateTime(2020);
  final last = lastDate ?? DateTime(2030, 12, 31);
  // 범위 밖 initial 은 CupertinoDatePicker 가 assert 로 죽는다 — 넣기 전에 접는다.
  final start = initial.isBefore(first)
      ? first
      : (initial.isAfter(last) ? last : initial);
  // 시각 성분이 남아 있으면 maximumDate 비교에서 마지막 날이 잘린다.
  var picked = DateTime(start.year, start.month, start.day);

  return showPSheet<DateTime>(
    context,
    title: AppLocalizations.of(context).pickDate,
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _themed(
      ctx,
      CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: picked,
        minimumDate: DateTime(first.year, first.month, first.day),
        maximumDate: DateTime(last.year, last.month, last.day),
        minimumYear: first.year,
        maximumYear: last.year,
        onDateTimeChanged: (v) => picked = v,
      ),
    ),
    footerBuilder: (ctx) => _footer(
      ctx,
      onConfirm: () => Navigator.pop(
        ctx,
        DateTime(picked.year, picked.month, picked.day),
      ),
    ),
  );
}

/// 시각 휠(24시간). 취소하면 null.
Future<TimeOfDay?> showPTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
}) {
  // CupertinoDatePicker 는 DateTime 만 받는다 — 날짜는 아무 날이나 쓰고 시/분만 읽는다.
  var picked = DateTime(2000, 1, 1, initial.hour, initial.minute);

  return showPSheet<TimeOfDay>(
    context,
    title: AppLocalizations.of(context).pickTime,
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _themed(
      ctx,
      CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: picked,
        // 앱 전체가 24시간 표기다(예전 showTimePicker 도 alwaysUse24HourFormat 이었다).
        use24hFormat: true,
        onDateTimeChanged: (v) => picked = v,
      ),
    ),
    footerBuilder: (ctx) => _footer(
      ctx,
      onConfirm: () => Navigator.pop(
        ctx,
        TimeOfDay(hour: picked.hour, minute: picked.minute),
      ),
    ),
  );
}
