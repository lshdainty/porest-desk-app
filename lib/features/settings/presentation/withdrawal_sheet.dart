import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/settings/application/withdrawal_providers.dart';
import 'package:porest_desk_app/features/settings/domain/withdrawal_check.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// desk 이용 해지 — web `WithdrawDialog` 미러.
///
/// **세 번 확인한다.** ① 무엇을 잃는지 개수로 보여 주고 ② 본인 확인을 다시 받고
/// ③ 마지막 버튼이 빨갛다. 되돌릴 수 없는 일이라 한 번의 오조작으로 끝나면 안 된다.
///
/// 문구는 웹과 한 벌이다 — 한쪽만 고치지 마라.
void showWithdrawalSheet(BuildContext context) {
  final controller = PSheetController();
  final bodyKey = GlobalKey<_BodyState>();
  final l = AppLocalizations.of(context);
  showPSheet<void>(
    context,
    title: l.accountWithdrawTitle,
    contentBuilder: (ctx, scrollCtrl) =>
        _Body(key: bodyKey, controller: controller),
    footerBuilder: (ctx) =>
        _WithdrawFooter(controller: controller, bodyKey: bodyKey),
  );
}

/// 본인 확인 방법. 비밀번호가 없는 소셜 전용 계정은 코드 말고 길이 없다.
enum _Method { password, emailCode }

class _Body extends ConsumerStatefulWidget {
  const _Body({super.key, required this.controller});
  final PSheetController controller;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _reasonCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  /// 1 = 무엇을 잃는지, 2 = 본인 확인.
  int _step = 1;
  _Method _method = _Method.password;
  bool _codeSent = false;
  bool _sendingCode = false;
  bool _submitting = false;
  String? _reauthError;

  WithdrawalCheck? _check;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onSubmit = _onPrimary;
    _load();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = await ref.read(withdrawalRepositoryProvider.future);
      final res = await repo.check();
      if (!mounted) return;
      setState(() {
        _check = res;
        _loading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
    _syncFooter();
  }

  void _syncFooter() {
    widget.controller
      ..setCanSubmit(_canSubmit)
      ..setSubmitting(_submitting);
  }

  bool get _blocked => _check?.isBlocked ?? false;

  bool get _canSubmit {
    if (_submitting || _loading) return false;
    // 막혔거나 못 읽었으면 남은 액션은 닫기뿐이다 — 언제나 누를 수 있다.
    if (_loadFailed || _blocked) return true;
    if (_step == 1) return true;
    return _method == _Method.password
        ? _passwordCtrl.text.isNotEmpty
        : RegExp(r'^\d{6}$').hasMatch(_codeCtrl.text);
  }

  void back() {
    setState(() {
      _step = 1;
      _reauthError = null;
    });
    _syncFooter();
  }

  /// footer 의 주 버튼. 단계에 따라 하는 일이 다르다.
  Future<void> _onPrimary() async {
    if (_loadFailed || _blocked) {
      Navigator.of(context).pop();
      return;
    }
    if (_step == 1) {
      setState(() => _step = 2);
      _syncFooter();
      return;
    }
    await _withdraw();
  }

  Future<void> _withdraw() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _reauthError = null;
    });
    _syncFooter();
    try {
      final repo = await ref.read(withdrawalRepositoryProvider.future);
      final ticket = _method == _Method.password
          ? await repo.verifyPassword(_passwordCtrl.text)
          : await repo.verifyEmailCode(_codeCtrl.text);
      await repo.withdraw(reauthToken: ticket, reason: _reasonCtrl.text.trim());
      if (!mounted) return;
      // 순서가 중요하다. pop 하면 이 시트의 context 가 죽어 `context.tokens` 조차 못
      // 읽으므로 **안내를 먼저 띄운다.** messenger 를 넘기는 것은 스낵바가 시트가
      // 아니라 앱 전체에 달리게 하려는 것이다 — 곧이어 시트가 닫히고 로그아웃이
      // 화면을 통째로 바꾸는데, 시트에 달려 있으면 같이 사라진다.
      showPSnackBar(
        context,
        l.withdrawnTitle,
        severity: PSnackSeverity.success,
        messenger: ScaffoldMessenger.of(context),
      );
      Navigator.of(context).pop();
      // 해지가 끝나면 이 세션도 끝이다 — 남겨 두면 이미 없는 계정으로 API 를 부른다.
      ref.read(authProvider.notifier).logout();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 본인 확인 실패는 그 칸의 문제다 — 스낵바로 띄우면 어느 칸을 고쳐야 하는지
      // 안 보인다. 칸 밑에 붙인다(password_change_dialog 와 같은 규칙).
      setState(() {
        _reauthError = e.message.isEmpty ? l.withdrawFailed : e.message;
        _submitting = false;
      });
      _syncFooter();
    }
  }

  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    setState(() => _sendingCode = true);
    try {
      final repo = await ref.read(withdrawalRepositoryProvider.future);
      await repo.sendEmailCode();
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _sendingCode = false;
        _reauthError = null;
      });
      showPSnackBar(context, l.withdrawCodeSent, severity: PSnackSeverity.info);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingCode = false;
        _reauthError = e.message.isEmpty ? l.withdrawFailed : e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final pad = const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.lg);

    if (_loading) {
      return Padding(
        padding: pad,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: PSpace.x32),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_loadFailed) {
      return Padding(
        padding: pad,
        child: Text(
          l.stateError,
          style: PTypo.bodySm.copyWith(color: t.fgSecondary),
        ),
      );
    }

    if (_blocked) return Padding(padding: pad, child: _blockedBody(t, l));

    return Padding(
      padding: pad,
      child: _step == 1 ? _impactBody(t, l) : _reauthBody(t, l),
    );
  }

  Widget _blockedBody(PorestTokens t, AppLocalizations l) {
    final check = _check!;
    // 서버가 시간대 없이 주는 `[UTC]` — 그냥 자르면 KST 에서 하루 이르게 보인다.
    // 구독 시트와 같은 값이라 같은 방식으로 읽어야 두 화면이 다른 날짜를 말하지 않는다.
    final until = check.subscriptionPeriodEnd != null
        ? (localDateKey(check.subscriptionPeriodEnd) ??
              check.subscriptionPeriodEnd!.substring(0, 10))
        : null;
    final headline = check.blockedBySubscription
        ? (until != null
              ? l.withdrawBlockedSubscriptionUntil(until)
              : l.withdrawBlockedSubscription)
        : l.withdrawBlockedOther;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.triangleAlert, size: 18, color: t.statusWarning),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Text(
                headline,
                style: PTypo.bodySm.copyWith(color: t.fgPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        Text(
          l.withdrawBlockedHint,
          style: PTypo.bodySm.copyWith(color: t.fgSecondary),
        ),
      ],
    );
  }

  Widget _impactBody(PorestTokens t, AppLocalizations l) {
    final c = _check!;
    // 0 인 항목은 줄을 안 만든다 — 없는 손실을 세어 겁줄 이유가 없다.
    final impacts = <String>[
      if (c.sharedCalendarsOwned > 0)
        l.withdrawImpactCalendarsOwned(c.sharedCalendarsOwned),
      if (c.calendarMemberships > 0)
        l.withdrawImpactCalendarMemberships(c.calendarMemberships),
      if (c.dutchPaysOwned > 0)
        l.withdrawImpactDutchPaysOwned(c.dutchPaysOwned),
      if (c.dutchPayParticipations > 0)
        l.withdrawImpactDutchPayParticipations(c.dutchPayParticipations),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.withdrawIntro, style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
        if (impacts.isNotEmpty) ...[
          const SizedBox(height: PSpace.lg),
          for (final line in impacts)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpace.x8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.fgTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  Expanded(
                    child: Text(
                      line,
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: PSpace.lg),
        // 되돌릴 수 없는 것 둘 — 여기서 말하지 않으면 사용자가 알 길이 없다.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PSpace.x12),
          decoration: BoxDecoration(
            color: t.bgMuted,
            borderRadius: BorderRadius.circular(PRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.withdrawIrreversibleTitle,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.medium,
                ),
              ),
              const SizedBox(height: PSpace.x4),
              Text(
                l.withdrawIrreversibleRejoin,
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
              ),
              const SizedBox(height: PSpace.x4),
              Text(
                l.withdrawIrreversibleData,
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.lg),
        PSectionLabel(l.withdrawReasonLabel),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _reasonCtrl,
          placeholder: l.withdrawReasonPlaceholder,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
        ),
      ],
    );
  }

  Widget _reauthBody(PorestTokens t, AppLocalizations l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.withdrawReauthIntro,
          style: PTypo.bodySm.copyWith(color: t.fgPrimary),
        ),
        const SizedBox(height: PSpace.lg),
        if (_method == _Method.password) ...[
          PSectionLabel(l.passwordCurrent),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _passwordCtrl,
            secret: true,
            obscureText: true,
            placeholder: l.passwordCurrent,
            errorText: _reauthError,
            onChanged: (_) {
              if (_reauthError != null) setState(() => _reauthError = null);
              _syncFooter();
            },
          ),
          const SizedBox(height: PSpace.x8),
          PButton(
            label: l.withdrawUseEmailCode,
            variant: PButtonVariant.accent,
            size: PButtonSize.sm,
            onPressed: () => setState(() {
              _method = _Method.emailCode;
              _reauthError = null;
              _syncFooter();
            }),
          ),
        ] else ...[
          PSectionLabel(l.withdrawCodeLabel),
          const SizedBox(height: PSpace.x8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PTextInput(
                  controller: _codeCtrl,
                  numbersOnly: true,
                  keyboardType: TextInputType.number,
                  placeholder: l.withdrawCodePlaceholder,
                  errorText: _reauthError,
                  inputFormatters: [LengthLimitingTextInputFormatter(6)],
                  onChanged: (_) {
                    if (_reauthError != null) {
                      setState(() => _reauthError = null);
                    }
                    _syncFooter();
                  },
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton(
                label: _codeSent ? l.withdrawResendCode : l.withdrawSendCode,
                variant: PButtonVariant.secondary,
                loading: _sendingCode,
                onPressed: _sendingCode ? null : _sendCode,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          Text(
            l.withdrawCodeHint,
            style: PTypo.bodySm.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x8),
          PButton(
            label: l.withdrawUsePassword,
            variant: PButtonVariant.accent,
            size: PButtonSize.sm,
            onPressed: () => setState(() {
              _method = _Method.password;
              _reauthError = null;
              _syncFooter();
            }),
          ),
        ],
      ],
    );
  }
}

class _WithdrawFooter extends StatelessWidget {
  const _WithdrawFooter({required this.controller, required this.bodyKey});
  final PSheetController controller;
  final GlobalKey<_BodyState> bodyKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final state = bodyKey.currentState;
        // 아직 점검 결과를 못 읽었으면 진행 버튼을 두지 않는다.
        if (state == null || state._loading) return const SizedBox.shrink();

        // 막힌 자리·못 읽은 자리에는 닫기 하나뿐이다 — 누를 수 없는 버튼을 보여 주는
        // 것보다 아예 없는 편이 낫다.
        if (state._loadFailed || state._blocked) {
          return PButton(
            label: l.actionClose,
            variant: PButtonVariant.secondary,
            size: PButtonSize.lg,
            fullWidth: true,
            onPressed: () => Navigator.of(ctx).pop(),
          );
        }

        final canGo = controller.canSubmit && !controller.submitting;
        // 액션 둘은 화면 폭을 반씩 나눠 갖는다 (spec drawer.md).
        return Row(
          children: [
            Expanded(
              child: PButton(
                label: state._step == 1 ? l.actionCancel : l.actionBack,
                variant: PButtonVariant.secondary,
                size: PButtonSize.lg,
                fullWidth: true,
                onPressed: controller.submitting
                    ? null
                    : (state._step == 1
                          ? () => Navigator.of(ctx).pop()
                          : state.back),
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: PButton(
                label: state._step == 1 ? l.withdrawNext : l.withdrawConfirm,
                variant: PButtonVariant.danger,
                size: PButtonSize.lg,
                fullWidth: true,
                loading: controller.submitting,
                onPressed: canGo ? controller.submitGuarded : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
