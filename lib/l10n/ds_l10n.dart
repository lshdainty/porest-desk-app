import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 이 자리의 로케일 문구 — 로케일 위임자가 없는 호스트(위젯 테스트 · 카탈로그 일부)에서는 null 이라 호출부가 한국어 기본값으로
/// 돌아간다. 새 문구는 arb 의 `ds…` 키로 두고(ko · en 한 쌍), 코드에는 한국어 상수를 새로 만들지 않는다(01-043).
AppLocalizations? dsL(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations);
