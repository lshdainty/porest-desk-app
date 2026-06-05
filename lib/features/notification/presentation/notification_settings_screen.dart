import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_section_label.dart';
import '../../../shared/widgets/p_segmented.dart';
import '../../../shared/widgets/p_select.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_slider.dart';
import '../../../shared/widgets/p_switch.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/user_preferences_providers.dart';
import '../data/user_preferences_repository.dart';

/// 알림 "설정" 화면 — 6개 섹션 (푸시 마스터 / 알림 종류 / 예산 임계값 /
/// 방해 금지 / 소리·진동 / 이메일). 각 컨트롤 변경 시 즉시 부분 PATCH(낙관적).
///
/// 헤더(AppBar)는 고정, content 만 스크롤. 알림 "목록"(/notifications)과 별개.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final prefsAsync = ref.watch(userPreferencesProvider);
    final email = ref.watch(authProvider).value?.userEmail ?? '';

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('알림 설정'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: prefsAsync.when(
        loading: () => const _PrefsSkeleton(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Text(
            '설정을 불러오지 못했습니다\n$e',
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
    final pushOn = prefs.pushEnabled;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
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
        const SizedBox(height: PSpace.x20),

        // 2) 알림 종류
        _SectionCard(
          title: '알림 종류',
          subtitle: '필요한 알림만 켜두면 더 편해요.',
          child: Column(
            children: [
              _ToggleRow(
                icon: LucideIcons.creditCard,
                tone: _Tone.expense,
                title: '결제 알림',
                desc: '결제 예정일 D-1, 결제일 당일 알림',
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
                title: '예산 알림',
                // DB(budget_alert_threshold) 기반 — 아래 임계값 카드와 동일 값.
                desc: '카테고리 예산 ${prefs.budgetAlertThreshold}%·100% 도달',
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
                title: '자동 기록 알림',
                desc: '반복 거래가 자동으로 기록되었을 때',
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
                title: '더치페이 알림',
                desc: '송금 요청 / 정산 완료 알림',
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
                title: '일정 알림',
                desc: '캘린더 이벤트 시작 15분 전',
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
                title: '주간 리포트',
                desc: '매주 월요일 오전 9시',
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
                title: '월간 리포트',
                desc: '매월 1일 오전 9시',
                value: prefs.notifyMonthlyReport,
                enabled: pushOn,
                onChanged: (v) => _patch(ref, {
                  'notifyMonthlyReport': v,
                }, (p) => p.copyWith(notifyMonthlyReport: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x20),

        // 3) 예산 알림 임계값
        _ThresholdCard(
          value: prefs.budgetAlertThreshold,
          onChanged: (v) => _patch(ref, {
            'budgetAlertThreshold': v,
          }, (p) => p.copyWith(budgetAlertThreshold: v)),
        ),
        const SizedBox(height: PSpace.x20),

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
        const SizedBox(height: PSpace.x20),

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
        const SizedBox(height: PSpace.x20),

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
                  '푸시 알림',
                  style: PTypo.bodyLg.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pushEnabled ? '모든 알림이 활성화되어 있어요' : '알림이 꺼져 있어요',
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
              semanticLabel: '푸시 알림',
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공용: 섹션 카드 (제목 + 소제목 + child) ──────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PCard(
      variant: PCardVariant.shadow,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpace.lg,
              PSpace.lg,
              PSpace.lg,
              PSpace.sm,
            ),
            child: Column(
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
          ),
          child,
          // 마지막 행 패딩 12 + 4 = 16 — web CardContent 하단 여백 정합.
          const SizedBox(height: 4),
        ],
      ),
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
        horizontal: PSpace.x16,
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
    return PCard(
      variant: PCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '예산 알림 임계값',
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
                    const TextSpan(text: '현재 '),
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
                const TextSpan(text: '예산 사용률이 이 값을 넘으면 '),
                TextSpan(
                  text: '경고',
                  style: TextStyle(
                    color: t.statusWarningFg,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 상태로 표시되고 알림을 받습니다. 100%는 '),
                TextSpan(
                  text: '초과',
                  style: TextStyle(
                    color: t.statusDangerFg,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const TextSpan(text: '로 별도 알림이 발생합니다.'),
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
      ),
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
    return _SectionCard(
      title: '방해 금지 시간',
      subtitle: '이 시간에는 알림이 소리·진동 없이 표시됩니다.',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x16,
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
                        '방해 금지 사용',
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '시간대를 지정해 자동 무음',
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
                    semanticLabel: '방해 금지 사용',
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
                      label: '시작',
                      value: start,
                      onChanged: onStartChanged,
                    ),
                  ),
                  const SizedBox(width: PSpace.x12),
                  Expanded(
                    child: _TimeField(
                      label: '종료',
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
    return _SectionCard(
      title: '소리·진동',
      child: Column(
        children: [
          // 행1 — 알림음 (Select)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x16,
              vertical: PSpace.x12,
            ),
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
                        '알림음',
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '앱 알림 사운드',
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
                    title: '알림음',
                    onChanged: (v) {
                      if (v != null) onSoundChanged(v);
                    },
                    items: const [
                      PSelectItem(value: NotificationSound.chime, label: '차임'),
                      PSelectItem(
                        value: NotificationSound.defaultSound,
                        label: '기본',
                      ),
                      PSelectItem(value: NotificationSound.none, label: '무음'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _RowDivider(),
          // 행2 — 진동 (Switch)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x16,
              vertical: PSpace.x12,
            ),
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
                        '진동',
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '모바일에서 진동 함께 알림',
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
                    semanticLabel: '진동',
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
    return _SectionCard(
      title: '이메일 알림',
      subtitle: '앱을 잘 안 열어도 이메일로 요약을 받아볼 수 있어요.',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x16,
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
                        '이메일 받기',
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.isNotEmpty ? email : '등록된 이메일이 없습니다',
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
                    semanticLabel: '이메일 받기',
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
                  PSectionLabel('발송 주기'),
                  const SizedBox(height: PSpace.x8),
                  PSegmented<String>(
                    value: frequency,
                    onChanged: onFrequencyChanged,
                    options: const [
                      PSegmentOption(value: EmailFrequency.daily, label: '매일'),
                      PSegmentOption(value: EmailFrequency.weekly, label: '매주'),
                      PSegmentOption(
                        value: EmailFrequency.monthly,
                        label: '매월',
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
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
        vertical: PSpace.x24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (int i = 0; i < 4; i++) ...[
          const PSkeleton(
            width: double.infinity,
            height: 96,
            borderRadius: PRadius.brLg,
          ),
          const SizedBox(height: PSpace.x20),
        ],
      ],
    );
  }
}
