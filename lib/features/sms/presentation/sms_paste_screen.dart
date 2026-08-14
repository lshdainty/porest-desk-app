import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_alert.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/sms/data/sms_repository.dart';
import 'package:porest_desk_app/features/sms/domain/sms_draft.dart';
import 'package:porest_desk_app/features/sms/domain/sms_prefilter.dart';

/// 결제 문자를 붙여넣어 지출로 기록하는 화면.
///
/// iOS 는 문자에 직접 접근할 수 없고(OS 제약) 안드로이드도 권한을 받기 전이라,
/// 두 플랫폼이 공통으로 쓰는 경로는 "복사해서 붙여넣기" 다. 클립보드 배너나
/// 수신 알림에서 들어오는 자동 경로도 결국 이 화면의 해석·확인 흐름을 탄다.
///
/// [initialText] 가 있으면 열자마자 그 문자를 해석한다(배너·알림에서 들어온 경우).
class SmsPasteScreen extends ConsumerStatefulWidget {
  const SmsPasteScreen({super.key, this.initialText});

  final String? initialText;

  @override
  ConsumerState<SmsPasteScreen> createState() => _SmsPasteScreenState();
}

class _SmsPasteScreenState extends ConsumerState<SmsPasteScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _parsing = false;

  /// 직전 해석에서 알아낸 문제 — 인식 실패·취소 문자. 화면에 그대로 띄운다.
  String? _notice;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialText;
    if (seed != null && seed.trim().isNotEmpty) {
      _textCtrl.text = seed;
      // 해석은 첫 프레임 뒤에 — build 중에 시트를 띄울 수 없다.
      WidgetsBinding.instance.addPostFrameCallback((_) => _parse());
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  /// 클립보드에서 가져오기 — 사용자가 버튼을 눌렀을 때만 읽는다.
  ///
  /// iOS 는 클립보드를 읽을 때마다 "붙여넣기 허용" 배너를 띄운다. 화면에 들어올
  /// 때마다 자동으로 읽으면 그 배너가 계속 떠 사용자를 괴롭힌다.
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (text == null || text.trim().isEmpty) {
      showPSnackBar(context, l.smsClipboardEmpty, severity: PSnackSeverity.info);
      return;
    }
    setState(() {
      _textCtrl.text = text;
      _notice = null;
    });
  }

  Future<void> _parse() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _parsing) return;
    final l = AppLocalizations.of(context);

    // 서버로 보내기 전 로컬 게이트 — 결제 문자가 아닌 텍스트는 아예 올리지 않는다.
    if (!looksLikePaymentSms(text)) {
      setState(() => _notice = l.smsNotRecognized);
      return;
    }

    setState(() {
      _parsing = true;
      _notice = null;
    });
    try {
      final repo = await ref.read(smsRepositoryProvider.future);
      final parsed = await repo.parse(text);
      if (!mounted) return;

      if (!parsed.matched) {
        setState(() => _notice = l.smsNotRecognized);
        return;
      }
      // 취소 문자는 원 거래를 특정할 수 없어 자동 기록하지 않는다.
      // 그냥 지출로 넣으면 결제와 취소가 둘 다 지출로 쌓여 두 배가 된다.
      if (parsed.cancel) {
        setState(() => _notice = l.smsCancelNotice);
        return;
      }

      if (parsed.isLowConfidence) {
        showPSnackBar(context, l.smsLowConfidence, severity: PSnackSeverity.info);
      }
      showAddTxSheet(context, smsDraft: SmsDraft(text: text, parsed: parsed));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _notice = e.message);
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.smsPasteTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.smsPasteDesc,
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
              ),
              const SizedBox(height: PSpace.x16),
              PSectionLabel(l.smsPasteFieldLabel),
              const SizedBox(height: PSpace.x4),
              PTextInput(
                controller: _textCtrl,
                placeholder: l.smsPastePlaceholder,
                maxLines: 8,
                minLines: 5,
                enabled: !_parsing,
              ),
              if (_notice != null) ...[
                const SizedBox(height: PSpace.x12),
                PAlert(
                  title: _notice!,
                  variant: PAlertVariant.warning,
                  onDismiss: () => setState(() => _notice = null),
                ),
              ],
              const SizedBox(height: PSpace.x16),
              PButton(
                label: l.smsPasteFromClipboard,
                variant: PButtonVariant.outline,
                icon: LucideIcons.clipboard,
                fullWidth: true,
                onPressed: _parsing ? null : _pasteFromClipboard,
              ),
              const SizedBox(height: PSpace.x8),
              PButton(
                label: l.smsPasteAction,
                loading: _parsing,
                fullWidth: true,
                onPressed: _parsing ? null : _parse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
