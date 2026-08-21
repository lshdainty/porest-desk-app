import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_slider.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/notification/data/user_preferences_repository.dart';

/// 알림 "설정" 화면 — 6개 섹션 (푸시 마스터 / 알림 종류 / 예산 임계값 /
/// 방해 금지 / 소리·진동 / 이메일). 각 컨트롤 변경 시 즉시 부분 PATCH(낙관적).
///
/// 헤더(AppBar)는 고정, content 만 스크롤. 알림 "목록"(/notifications)과 별개.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final email = ref.watch(authProvider).value?.userEmail ?? '';

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.notiSettings),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: prefsAsync.when(
        loading: () => const _PrefsSkeleton(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Text(
            '${l.notiSettingsLoadError}\n$e',
            style: PTypo.bodySm.copyWith(color: t.statusDanger),
          ),
        ),
        data: (prefs) => _Content(prefs: prefs, email: email),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.prefs, required this.email});
  final UserPreferences prefs;
  final String email;

  void _patch(
    WidgetRef ref,
    Map<String, dynamic> fields,
    UserPreferences Function(UserPreferences prev) optimistic,
  ) {
    ref
        .read(userPreferencesProvider.notifier)
        .patch(fields, optimistic: optimistic);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pushOn = prefs.pushEnabled;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x24,
        vertical: PSpace.x24,
      ),
      children: [
        // 1) 푸시 알림 (마스터)
        _MasterCard(
          pushEnabled: pushOn,
          onChanged: (v) => _patch(ref, {
            'pushEnabled': v,
          }, (p) => p.copyWith(pushEnabled: v)),
        ),
        const SizedBox(height: PSpace.x32),

        // 2) 알림 종류
        _SectionCard(
          gap: PSpace.x0, // 알림 종류 label↔content gap 삭제(사용자 결정)
          title: l.notiKindTitle,
          subtitle: l.notiKindSubtitle,
          child: Column(
            children: [
              _ToggleRow(
                icon: LucideIcons.creditCard,
                tone: _Tone.expense,
                title: l.notiPayment,
                desc: l.notiPaymentDesc,
                value: prefs.notifyPayment,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyPayment': v,
                }, (p) => p.copyWith(notifyPayment: v)),
              ),
              const _RowDivider(),
              _ToggleRow(
                icon: LucideIcons.target,
                tone: _Tone.warning,
                title: l.notiTypeBudgetAlert,
                // DB(budget_alert_threshold) 기반 — 아래 임계값 카드와 동일 값.
                desc: l.notiBudgetDesc(prefs.budgetAlertThreshold),
                value: prefs.notifyBudget,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyBudget': v,
                }, (p) => p.copyWith(notifyBudget: v)),
              ),
              const _RowDivider(),
              _ToggleRow(
                icon: LucideIcons.zap,
                tone: _Tone.info,
                title: l.notiAutoRecord,
                desc: l.notiAutoRecordDesc,
                value: prefs.notifyAutoRecord,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyAutoRecord': v,
                }, (p) => p.copyWith(notifyAutoRecord: v)),
              ),
              const _RowDivider(),
              _ToggleRow(
                icon: LucideIcons.users,
                tone: _Tone.brand,
                title: l.notiDutchPay,
                desc: l.notiDutchPayDesc,
                value: prefs.notifyDutchPay,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyDutchPay': v,
                }, (p) => p.copyWith(notifyDutchPay: v)),
              ),
              const _RowDivider(),
              _ToggleRow(
                icon: LucideIcons.calendarClock,
                tone: _Tone.success,
                title: l.notiTypeEventReminder,
                desc: l.notiCalendarDesc,
                value: prefs.notifyCalendar,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyCalendar': v,
                }, (p) => p.copyWith(notifyCalendar: v)),
              ),
              const _RowDivider(),
              _ToggleRow(
                icon: LucideIcons.barChart3,
                tone: _Tone.info,
                title: l.notiWeeklyReport,
                desc: l.notiWeeklyReportDesc,
                value: prefs.notifyWeeklyReport,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyWeeklyReport': v,
                }, (p) => p.copyWith(notifyWeeklyReport: v)),
              ),
              const _RowDivider(),
              _ToggleRow(
                icon: LucideIcons.fileBarChart,
                tone: _Tone.info,
                title: l.notiMonthlyReport,
                desc: l.notiMonthlyReportDesc,
                value: prefs.notifyMonthlyReport,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyMonthlyReport': v,
                }, (p) => p.copyWith(notifyMonthlyReport: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x32),

        // 3) 예산 알림 임계값
        _ThresholdCard(
          value: prefs.budgetAlertThreshold,
          onChanged: (v) => _patch(ref, {
            'budgetAlertThreshold': v,
          }, (p) => p.copyWith(budgetAlertThreshold: v)),
        ),
        const SizedBox(height: PSpace.x32),

        // 4) 방해 금지 시간
        _QuietHoursCard(
          enabled: prefs.quietHoursEnabled,
          start: prefs.quietHoursStart,
          end: prefs.quietHoursEnd,
          onEnabledChanged: (v) => _patch(ref, {
            'quietHoursEnabled': v,
          }, (p) => p.copyWith(quietHoursEnabled: v)),
          onStartChanged: (v) => _patch(ref, {
            'quietHoursStart': v,
          }, (p) => p.copyWith(quietHoursStart: v)),
          onEndChanged: (v) => _patch(ref, {
            'quietHoursEnd': v,
          }, (p) => p.copyWith(quietHoursEnd: v)),
        ),
        const SizedBox(height: PSpace.x32),

        // 5) 소리·진동
        _SoundCard(
          sound: prefs.notificationSound,
          vibration: prefs.vibrationEnabled,
          onSoundChanged: (v) => _patch(ref, {
            'notificationSound': v,
          }, (p) => p.copyWith(notificationSound: v)),
          onVibrationChanged: (v) => _patch(ref, {
            'vibrationEnabled': v,
          }, (p) => p.copyWith(vibrationEnabled: v)),
        ),
        const SizedBox(height: PSpace.x32),

        // 6) 이메일 알림
        _EmailCard(
          enabled: prefs.emailEnabled,
          email: email,
          frequency: prefs.emailFrequency,
          onEnabledChanged: (v) => _patch(ref, {
            'emailEnabled': v,
          }, (p) => p.copyWith(emailEnabled: v)),
          onFrequencyChanged: (v) => _patch(ref, {
            'emailFrequency': v,
          }, (p) => p.copyWith(emailFrequency: v)),
        ),

        const SizedBox(height: PSpace.x32),
      ],
    );
  }
}

// ── tone helper ─────────────────────────────────────────────────────────────

/// 행 아이콘 tone — semantic *-subtle 배경 + *-fg 전경 조합.
/// (brand 는 brand-subtle + brandStrong — 별도 purple 토큰 없음, 브랜드 톤 사용.)
enum _Tone { expense, warning, info, brand, success }

(Color bg, Color fg) _toneColors(_Tone tone, PorestTokens t) => switch (tone) {
  _Tone.expense => (t.bgExpenseSubtle, t.fgExpense),
  _Tone.warning => (t.statusWarningSubtle, t.statusWarningFg),
  _Tone.info => (t.statusInfoSubtle, t.statusInfoFg),
  // brand: bgBrandSubtle 은 다크에서 surface 와 거의 같아 박스가 묻힘 —
  // fgBrand(다크=primary-light 자동 swap) 15% 틴트로 양 모드 가시성 확보.
  _Tone.brand => (t.fgBrand.withValues(alpha: 0.15), t.fgBrand),
  _Tone.success => (t.statusSuccessSubtle, t.statusSuccessFg),
};

/// 행 좌측 tone 아이콘 박스 — layout + tone색은 Container 로 직접 구성(OK).
class _ToneIcon extends StatelessWidget {
  const _ToneIcon({
    required this.icon,
    required this.tone,
    this.enabled = true,
  });
  final IconData icon;
  final _Tone tone;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = _toneColors(tone, t);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, borderRadius: PRadius.brMd),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }
}

// ── 1) 마스터 카드 ────────────────────────────────────────────────────────────

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.pushEnabled, required this.onChanged});
  final bool pushEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return PCard(
      variant: PCardVariant.brand,
      padding: const EdgeInsets.all(PSpace.lg),
      child: Row(
        children: [
          const _ToneIcon(icon: LucideIcons.bell, tone: _Tone.brand),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.notiPush,
                  style: PTypo.bodyLg.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pushEnabled ? l.notiPushOn : l.notiPushOff,
                  style: PTypo.caption.copyWith(color: t.fgSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x12),
          // 44px 탭 타깃이 행 높이를 키우지 않게 트랙 높이(24)로 클램프 — web 행 높이 정합.
          SizedBox(
            height: 24,
            child: PSwitch(
              value: pushEnabled,
              onChanged: onChanged,
              semanticLabel: l.notiPush,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공용: 섹션 카드 (제목 + 소제목 + child) ──────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.gap = PSpace.sm,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 카드 다이어트 — design .m-subpage SettingsGroup 플랫: 카드 없이 타이틀 + 행.
    // 섹션 label↔content 간격을 padding → Column gap(spacing)으로(사용자 결정, 섹션별 gap).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: PTypo.bodyLg.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ],
        ),
        child,
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  // 아이콘 밑에서부터 행 전체 폭 — indent 없는 full-width 구분선 (web 정합).
  Widget build(BuildContext context) => const PDivider();
}

// ── 알림 종류 토글 행 ─────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.desc,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final IconData icon;
  final _Tone tone;
  final String title;
  final String desc;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: PSpace.x12,
      ),
      child: Row(
        children: [
          _ToneIcon(icon: icon, tone: tone, enabled: enabled),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: PTypo.bodySm.copyWith(
                    color: enabled ? t.fgPrimary : t.fgDisabled,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: PTypo.caption.copyWith(
                    color: enabled ? t.fgTertiary : t.fgDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x12),
          // 44px 탭 타깃이 행 높이를 키우지 않게 트랙 높이(24)로 클램프 — web 행 높이 정합.
          SizedBox(
            height: 24,
            child: PSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
              semanticLabel: title,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3) 예산 임계값 ────────────────────────────────────────────────────────────

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 카드 다이어트 — 플랫 섹션.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.notiThresholdTitle,
                  style: PTypo.bodyLg.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
              ),
              // web 정합 — '현재 N%' (caption tertiary + brand strong).
              Text.rich(
                TextSpan(
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                  children: [
                    TextSpan(text: l.notiThresholdCurrent),
                    TextSpan(
                      text: '$value%',
                      style: TextStyle(
                        color: t.fgBrandStrong,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              style: PTypo.caption.copyWith(color: t.fgTertiary),
              children: [
                TextSpan(text: l.notiThresholdDesc1),
                TextSpan(
                  text: l.notiThresholdWarning,
                  style: TextStyle(
                    color: t.statusWarningFg,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                TextSpan(text: l.notiThresholdDesc2),
                TextSpan(
                  text: l.notiThresholdOver,
                  style: TextStyle(
                    color: t.statusDangerFg,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                TextSpan(text: l.notiThresholdDesc3),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PSlider(
            value: value.toDouble().clamp(50, 100),
            min: 50,
            max: 100,
            // web step=5 정합 — 71% 같은 1단위 값 방지.
            divisions: 10,
            semanticLabel: '$value%',
            onChanged: (v) => onChanged(v.round()),
          ),
          // web 정합 — 50~100 을 10단위 눈금으로 상세 표시 (text-badge/fg-tertiary).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tick in const [50, 60, 70, 80, 90, 100])
                Text('$tick', style: PTypo.micro.copyWith(color: t.fgTertiary)),
            ],
          ),
        ],
    );
  }
}

// ── 4) 방해 금지 ──────────────────────────────────────────────────────────────

class _QuietHoursCard extends StatelessWidget {
  const _QuietHoursCard({
    required this.enabled,
    required this.start,
    required this.end,
    required this.onEnabledChanged,
    required this.onStartChanged,
    required this.onEndChanged,
  });
  final bool enabled;
  final String start;
  final String end;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return _SectionCard(
      gap: PSpace.x0, // 방해 금지 label↔content gap 삭제(사용자 결정)
      title: l.notiQuietTitle,
      subtitle: l.notiQuietSubtitle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: PSpace.x12,
            ),
            child: Row(
              children: [
                const _ToneIcon(icon: LucideIcons.moon, tone: _Tone.info),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.notiQuietToggle,
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.notiQuietToggleDesc,
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PSpace.x12),
                // 44px 탭 타깃이 행 높이를 키우지 않게 트랙 높이(24)로 클램프 — web 행 높이 정합.
                SizedBox(
                  height: 24,
                  child: PSwitch(
                    value: enabled,
                    onChanged: onEnabledChanged,
                    semanticLabel: l.notiQuietToggle,
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpace.x16,
                0,
                PSpace.x16,
                PSpace.x12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: l.notiQuietStart,
                      value: start,
                      onChanged: onStartChanged,
                    ),
                  ),
                  const SizedBox(width: PSpace.x12),
                  Expanded(
                    child: _TimeField(
                      label: l.notiQuietEnd,
                      value: end,
                      onChanged: onEndChanged,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "HH:mm" 시간 필드 — readonly PTextInput(suffix Clock) 탭 시 showTimePicker.
class _TimeField extends StatefulWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(_TimeField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _fmt(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parse(widget.value),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) widget.onChanged(_fmt(picked));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PSectionLabel(widget.label),
        const SizedBox(height: PSpace.x4),
        // PTextInput 자체는 onTap 미지원이라 GestureDetector(IgnorePointer)로 래핑.
        GestureDetector(
          // IgnorePointer 자식이면 기본 deferToChild 로는 히트테스트가 전부 실패해 탭이 죽는다.
          behavior: HitTestBehavior.opaque,
          onTap: () => _pick(context),
          child: IgnorePointer(
            child: PTextInput(
              controller: _ctrl,
              enabled: true,
              suffix: Icon(LucideIcons.clock, size: 16, color: t.fgTertiary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 5) 소리·진동 ──────────────────────────────────────────────────────────────

class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.sound,
    required this.vibration,
    required this.onSoundChanged,
    required this.onVibrationChanged,
  });
  final String sound;
  final bool vibration;
  final ValueChanged<String> onSoundChanged;
  final ValueChanged<bool> onVibrationChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return _SectionCard(
      gap: PSpace.md, // 소리·진동 label↔content gap md(사용자 결정)
      title: l.notiSoundTitle,
      child: Column(
        children: [
          // 행1 — 알림음 (Select) — 상단 padding 없음(label gap md 만, web 정합).
          Padding(
            padding: const EdgeInsets.only(bottom: PSpace.x12),
            child: Row(
              children: [
                const _ToneIcon(icon: LucideIcons.volume2, tone: _Tone.info),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.notiSound,
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.notiSoundDesc,
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PSpace.x12),
                SizedBox(
                  width: 120,
                  child: PSelect<String>(
                    value: sound,
                    title: l.notiSound,
                    onChanged: (v) {
                      if (v != null) onSoundChanged(v);
                    },
                    items: [
                      PSelectItem(value: NotificationSound.chime, label: l.notiSoundChime),
                      PSelectItem(
                        value: NotificationSound.defaultSound,
                        label: l.notiSoundDefault,
                      ),
                      PSelectItem(value: NotificationSound.none, label: l.notiSoundNone),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _RowDivider(),
          // 행2 — 진동 (Switch) — 상단 12(web paddingTop 정합).
          Padding(
            padding: const EdgeInsets.only(top: PSpace.x12),
            child: Row(
              children: [
                const _ToneIcon(icon: LucideIcons.vibrate, tone: _Tone.brand),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.notiVibration,
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.notiVibrationDesc,
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PSpace.x12),
                // 44px 탭 타깃이 행 높이를 키우지 않게 트랙 높이(24)로 클램프 — web 행 높이 정합.
                SizedBox(
                  height: 24,
                  child: PSwitch(
                    value: vibration,
                    onChanged: onVibrationChanged,
                    semanticLabel: l.notiVibration,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6) 이메일 ─────────────────────────────────────────────────────────────────

class _EmailCard extends StatelessWidget {
  const _EmailCard({
    required this.enabled,
    required this.email,
    required this.frequency,
    required this.onEnabledChanged,
    required this.onFrequencyChanged,
  });
  final bool enabled;
  final String email;
  final String frequency;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return _SectionCard(
      gap: PSpace.x0, // 이메일 알림 label↔content gap 삭제(사용자 결정)
      title: l.notiEmailTitle,
      subtitle: l.notiEmailSubtitle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: PSpace.x12,
            ),
            child: Row(
              children: [
                const _ToneIcon(icon: LucideIcons.mail, tone: _Tone.info),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.notiEmailToggle,
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.isNotEmpty ? email : l.notiEmailNone,
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PSpace.x12),
                // 44px 탭 타깃이 행 높이를 키우지 않게 트랙 높이(24)로 클램프 — web 행 높이 정합.
                SizedBox(
                  height: 24,
                  child: PSwitch(
                    value: enabled,
                    onChanged: onEnabledChanged,
                    semanticLabel: l.notiEmailToggle,
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpace.x16,
                0,
                PSpace.x16,
                PSpace.x12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PSectionLabel(l.notiEmailFreq),
                  const SizedBox(height: PSpace.x8),
                  PTabs<String>(
                    value: frequency,
                    onChanged: onFrequencyChanged,
                    variant: PTabsVariant.container,
                    size: PTabsSize.sm,
                    expand: true,
                    items: [
                      PTabItem(value: EmailFrequency.daily, label: l.notiEmailDaily),
                      PTabItem(value: EmailFrequency.weekly, label: l.notiEmailWeekly),
                      PTabItem(
                        value: EmailFrequency.monthly,
                        label: l.notiEmailMonthly,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── skeleton ──────────────────────────────────────────────────────────────────

class _PrefsSkeleton extends StatelessWidget {
  const _PrefsSkeleton();

  @override
  Widget build(BuildContext context) {
    // 실제 _Content 정합 — 카드 다이어트 후 플랫 섹션 구조(brand 마스터 카드만 카드).
    // 스켈레톤도 동일 플랫 셸에 PSkeleton 프리미티브로 구조를 미러.
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x24,
        vertical: PSpace.x24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        // 1) 마스터 카드 — 아이콘(36) + 제목/소제목 + 스위치 행.
        _SkeletonRowCard(),
        SizedBox(height: PSpace.x32),
        // 2) 알림 종류 — 제목/소제목 헤더 + 토글 행 ×7.
        _SkeletonSectionCard(rows: 7),
        SizedBox(height: PSpace.x32),
        // 3) 예산 임계값 — 제목 + 본문 2줄 + 슬라이더 트랙.
        _SkeletonThresholdCard(),
        SizedBox(height: PSpace.x32),
        // 4) 방해 금지 — 제목/소제목 헤더 + 행 ×1.
        _SkeletonSectionCard(rows: 1),
        SizedBox(height: PSpace.x20),
        // 5) 소리·진동 — 제목 + 행 ×2.
        _SkeletonSectionCard(rows: 2, showSubtitle: false),
        SizedBox(height: PSpace.x20),
        // 6) 이메일 — 제목/소제목 헤더 + 행 ×1.
        _SkeletonSectionCard(rows: 1),
        SizedBox(height: PSpace.x32),
      ],
    );
  }
}

/// 마스터 카드 스켈레톤 — _MasterCard(아이콘 36 + 제목/소제목 + 스위치) 정합.
class _SkeletonRowCard extends StatelessWidget {
  const _SkeletonRowCard();

  @override
  Widget build(BuildContext context) {
    // 카드 다이어트 — 플랫 스켈레톤.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
      child: Row(
        children: const [
          PSkeleton(width: 36, height: 36, borderRadius: PRadius.brMd),
          SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PSkeleton.line(width: 96, height: 16),
                SizedBox(height: 4),
                PSkeleton.line(width: 160, height: 12),
              ],
            ),
          ),
          SizedBox(width: PSpace.x12),
          // 스위치(트랙 44x24) 자리.
          PSkeleton(width: 44, height: 24, borderRadius: PRadius.brFull),
        ],
      ),
    );
  }
}

/// 섹션 카드 스켈레톤 — _SectionCard(제목/소제목 헤더 + 토글 행 ×N + 구분선) 정합.
class _SkeletonSectionCard extends StatelessWidget {
  const _SkeletonSectionCard({required this.rows, this.showSubtitle = true});
  final int rows;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    // 카드 다이어트 — 플랫 스켈레톤 셸.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 — 제목(bodyLg) + 소제목(caption).
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, PSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PSkeleton.line(width: 80, height: 16),
                if (showSubtitle) ...const [
                  SizedBox(height: 4),
                  PSkeleton.line(width: 180, height: 12),
                ],
              ],
            ),
          ),
          // 토글 행 — 아이콘(36) + 제목/설명 2줄 + 스위치, 사이 PDivider.
          for (int i = 0; i < rows; i++) ...[
            if (i > 0) const PDivider(),
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: PSpace.x12,
              ),
              child: Row(
                children: [
                  PSkeleton(width: 36, height: 36, borderRadius: PRadius.brMd),
                  SizedBox(width: PSpace.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PSkeleton.line(width: 88, height: 14),
                        SizedBox(height: 4),
                        PSkeleton.line(width: 150, height: 12),
                      ],
                    ),
                  ),
                  SizedBox(width: PSpace.x12),
                  PSkeleton(
                    width: 44,
                    height: 24,
                    borderRadius: PRadius.brFull,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
    );
  }
}

/// 임계값 카드 스켈레톤 — _ThresholdCard(제목+'현재 N%' / 본문 2줄 / 슬라이더 트랙) 정합.
class _SkeletonThresholdCard extends StatelessWidget {
  const _SkeletonThresholdCard();

  @override
  Widget build(BuildContext context) {
    // 카드 다이어트 — 플랫 스켈레톤.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              PSkeleton.line(width: 112, height: 16),
              Spacer(),
              PSkeleton.line(width: 48, height: 12),
            ],
          ),
          SizedBox(height: 6),
          PSkeleton.line(width: double.infinity, height: 12),
          SizedBox(height: 4),
          PSkeleton.line(width: 220, height: 12),
          SizedBox(height: PSpace.x8),
          // 슬라이더 트랙 자리.
          PSkeleton(width: double.infinity, height: 4, borderRadius: PRadius.brFull),
        ],
    );
  }
}
