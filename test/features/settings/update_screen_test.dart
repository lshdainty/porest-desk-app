// 설정 > 업데이트(I-05 21 ~ 25 · 74) — 실제 화면을 띄운 채로 잰다.
//
//  - 머리 = ds 상단 바(56, ←)
//  - 한 장 띠가 머리 바로 아래부터(틈 0 · 74)
//  - 상태 줄 = List 줄(앞 타일 40, 모서리 12), 새 버전이면 bgBrandWeak
//  - 받기 버튼 = ds Button large · neutralSolid, 받는 중 = 값 있는 원 24
//  - 삼성 자동 차단 안내 = Callout(warning) + 링크 "설정 열기"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/update/apk_installer.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/settings/presentation/update_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

class _FakeInstaller extends ApkInstaller {
  _FakeInstaller(this.progress);
  final ApkProgress progress;

  @override
  ApkProgress build() => progress;
}

Future<void> _pump(
  WidgetTester tester, {
  bool dark = false,
  bool hasUpdate = true,
  double scale = 1,
  ApkProgress progress = const ApkProgress(),
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final status = UpdateStatus(
    currentBuild: 100,
    latest: hasUpdate
        ? const AppRelease(
            version: '9.9.9',
            buildNumber: 101,
            androidFile: 'a.apk',
            iosFile: 'a.ipa',
            notes: '새 기능\n- 지어낸 변경 내용이에요\n\n버그 수정\n- 또 다른 변경이에요',
            minBuildNumber: 0,
          )
        : null,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        updateStatusProvider.overrideWith((ref) async => status),
        apkInstallerProvider.overrideWith(() => _FakeInstaller(progress)),
      ],
      child: MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const UpdateScreen(),
      ),
    ),
  );
  if (progress.isBusy) {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('${dark ? "다크" : "라이트"} — 상단 바 56 · 띠가 바로 아래 · 상태 줄 타일', (
      tester,
    ) async {
      await _pump(tester, dark: dark);
      final c = (dark ? GrooTheme.dark() : GrooTheme.light())
          .extension<PColors>()!;
      final bar = tester.getRect(find.byType(PTopNavigation));
      final band = tester.getRect(
        find.byKey(const ValueKey('screen-band-body')),
      );
      expect(bar.height, 56);
      expect(band.top, bar.bottom, reason: '머리 바로 아래부터 띠 — 틈 0 (74)');
      expect(find.byType(PTopNavigationIconButton), findsOneWidget);
      final tile = find.byKey(const ValueKey('plist-tile'));
      expect(tester.getSize(tile), const Size(40, 40));
      final deco =
          tester.widget<DecoratedBox>(tile).decoration as BoxDecoration;
      expect(deco.color, c.bgBrandWeak, reason: '새 버전');
      expect(deco.borderRadius, BorderRadius.circular(12));
      expect(find.byType(PListItem), findsOneWidget);
      final button = tester.widget<PButton>(find.byType(PButton));
      expect(button.size, PButtonSize.large);
      expect(button.variant, PButtonVariant.neutralSolid);
      expect(
        tester.getSize(find.byType(PButton)).width,
        360.0 - 48,
        reason: '전체 폭',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('최신이면 상태 타일이 bgNeutralWeak', (tester) async {
    await _pump(tester, hasUpdate: false);
    final c = GrooTheme.light().extension<PColors>()!;
    final deco =
        tester
                .widget<DecoratedBox>(find.byKey(const ValueKey('plist-tile')))
                .decoration
            as BoxDecoration;
    expect(deco.color, c.bgNeutralWeak);
    expect(find.byType(PButton), findsNothing);
  });

  testWidgets('삼성 자동 차단 안내는 Callout(warning) + 링크 "설정 열기"', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AutoBlockerNotice(debugShow: true)),
      ),
    );
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.warning);
    expect(callout.link?.label, '설정 열기');
    expect(find.byType(PButton), findsNothing, reason: '버튼이 아니라 링크');
  });

  testWidgets('받는 중 37% — 값 있는 원 24', (tester) async {
    await _pump(
      tester,
      progress: const ApkProgress(
        stage: ApkStage.downloading,
        received: 37,
        total: 100,
      ),
    );
    final circle = tester.widget<PProgressCircle>(find.byType(PProgressCircle));
    expect(circle.size, PProgressCircleSize.s24);
    expect(circle.value, closeTo(37, 0.001));
    expect(find.byType(PButton), findsNothing);
  });

  testWidgets('글자 200% · 폭 360 — 넘치지 않는다', (tester) async {
    await _pump(tester, scale: 2);
    expect(tester.takeException(), isNull);
  });
}
