import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/month_picker/p_month_picker.dart';

/// 예산 달 고르기 — 연 | 월 휠 시트(I-27). 부품은 ds `showPMonthPicker` 이고 이 함수는 예산 화면의 부르는 이름만 남겼다.
Future<DateTime?> showMonthPickerSheet(
  BuildContext context,
  DateTime initial,
) => showPMonthPicker(context, initial: initial);
