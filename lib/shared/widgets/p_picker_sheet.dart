import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_calendar.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 값 고르는 시트 — 시각은 iOS 휠, 날짜는 달력 그리드. 둘 다 바텀시트로 올린다.
///
/// Material 기본 피커를 안 쓰는 이유가 서로 다르다.
/// - 시각: 시계 다이얼에서 시 → 분을 2단으로 찍어야 해 손가락으로 맞추기 번거롭다.
///   휠은 웹(shadcn 계열 시/분 스크롤 컬럼)과 같은 상호작용이라 앱·웹이 붙는다.
/// - 날짜: 달력 그리드 자체는 그대로가 낫다(월 전체가 한눈에 보인다). 다이얼로그로
///   가운데 뜨던 걸 시트로 내려 시각 피커와 등장 방식만 맞춘다.
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
        // 기본 bodyLg(16)는 휠에서 작아 읽기 힘들다. iOS 기본(21)에 가깝게 올린다.
        dateTimePickerTextStyle: PTypo.bodyLg.copyWith(
          color: t.fgPrimary,
          fontSize: PFontSize.h3,
        ),
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

/// 날짜 달력 시트. 날짜를 누르면 그대로 닫히고 그 값이 올라온다. 취소(X)면 null.
///
/// 휠과 달리 [취소][확인] footer 가 없다 — 날짜 탭은 끊어진 선택이라 한 번에 끝난다.
/// 휠은 굴리는 내내 값이 흐르니 확인이 필요했다.
Future<DateTime?> showPDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showPSheet<DateTime>(
    context,
    title: AppLocalizations.of(context).pickDate,
    shrinkWrap: true,
    // PCalendar 가 자체로 12 를 물고 있어 12 를 더해 시트 좌우 24 에 맞춘다.
    contentBuilder: (ctx, _) => Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.md, 0, PSpace.md, PSpace.lg),
      child: PCalendar.single(
        selected: initial,
        firstDay: firstDate,
        lastDay: lastDate,
        onChanged: (d) => Navigator.pop(ctx, DateTime(d.year, d.month, d.day)),
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
