import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';

/// 카탈로그(/dev/ds) — 톤 다섯 × 상호작용 셋(보이기 · 전체 누르기 · 닫기), 나중에 나타나는 경고(alert).
class CalloutDemo extends StatelessWidget {
  const CalloutDemo({super.key});

  // 톤마다 제목 · 본문 — callout.md 의 글 규칙(제목은 성격, 본문은 해요체 문장)
  static const _copy = {
    PCalloutTone.neutral: (title: '안내', body: '카드 결제일이 지나면 이번 달 사용액이 확정돼요.'),
    PCalloutTone.informative: (
      title: '안내',
      body: '가져온 데이터는 기존 거래에 더해지고 덮어쓰지 않아요.',
    ),
    PCalloutTone.positive: (title: '혜택', body: '이번 달 예산을 지켜 목표에 3만 원을 더 모았어요.'),
    PCalloutTone.warning: (title: '주의', body: '분할 금액의 합이 거래 금액과 달라요.'),
    PCalloutTone.critical: (
      title: null,
      body: '저장하지 못했어요. 입력한 내용은 그대로 있어요. 잠시 뒤 다시 저장해 주세요.',
    ),
  };

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '톤 — 보이기(display) · 제목 · 링크(보조 내용으로 갈 때만)',
          children: [
            for (final tone in PCalloutTone.values)
              DemoRow(
                label: tone.name,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PCallout(
                      tone: tone,
                      title: _copy[tone]!.title,
                      description: _copy[tone]!.body,
                      link: const PCalloutLink(
                        label: '자세히',
                        onPressed: _ignore,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '전체 누르기(actionable) — 상자 전체가 버튼 · 뒤 화살표, 링크는 두지 않는다',
          children: [
            for (final tone in PCalloutTone.values)
              DemoRow(
                label: tone.name,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PCallout(
                      tone: tone,
                      interaction: PCalloutInteraction.actionable,
                      description: '토스증권을 연결하면 보유 주식이 자산에 더해져요.',
                      onPressed: _ignore,
                    ),
                  ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '닫기(dismissible) — 한 번 보면 되는 안내에만. 닫으면 바로 걷는다',
          children: [
            for (final tone in PCalloutTone.values)
              DemoRow(
                label: tone.name,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _Dismissible(
                      builder: (open, onDismiss) => PCallout(
                        tone: tone,
                        title: '새 기능',
                        description: '반복 거래를 자동으로 기록할 수 있어요.',
                        interaction: PCalloutInteraction.dismissible,
                        dismissLabel: '닫기',
                        open: open,
                        onDismiss: onDismiss,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const DemoBlock(
          title: '저장 실패 — 폼 맨 위 critical, 나중에 나타나므로 alert(보조 기술이 읽는다)',
          children: [
            PCallout(
              tone: PCalloutTone.critical,
              alert: true,
              description: '저장하지 못했어요. 입력한 내용은 그대로 있어요. 잠시 뒤 다시 저장해 주세요.',
            ),
          ],
        ),
      ],
    );
  }
}

/// 닫으면 그 자리에 다시 보이는 버튼을 둔다 — 견본을 다시 그리려고.
class _Dismissible extends StatefulWidget {
  const _Dismissible({required this.builder});

  final Widget Function(bool open, VoidCallback onDismiss) builder;

  @override
  State<_Dismissible> createState() => _DismissibleState();
}

class _DismissibleState extends State<_Dismissible> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.builder(_open, () => setState(() => _open = false)),
        if (!_open)
          PButton(
            label: '다시 보이기',
            variant: PButtonVariant.neutralWeak,
            size: PButtonSize.small,
            onPressed: () => setState(() => _open = true),
          ),
      ],
    );
  }
}
