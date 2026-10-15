import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/page_banner/p_page_banner.dart';

/// 카탈로그(/dev/ds) — 바탕 둘 × 톤 다섯 × 상호작용 셋(보이기 · 전체 누르기 · 닫기), 버튼이 다음 줄로 내려가는 긴 글.
class PageBannerDemo extends StatelessWidget {
  const PageBannerDemo({super.key});

  // 톤마다 제목 · 본문 · 버튼 — page-banner.md 의 글 규칙(제목은 상태, 버튼은 동작 이름)
  static const _copy = {
    PPageBannerTone.neutral: (
      title: null,
      body: '이 화면의 시세는 하루에 한 번 새로 고쳐져요.',
      button: '새로 고침',
    ),
    PPageBannerTone.informative: (
      title: '새 버전',
      body: '더 빨라진 가계부를 쓸 수 있어요.',
      button: '업데이트',
    ),
    PPageBannerTone.positive: (
      title: '연결됨',
      body: '토스증권과 다시 연결됐어요.',
      button: '보기',
    ),
    PPageBannerTone.warning: (
      title: '곧 만료',
      body: 'Pro 이용이 10월 31일에 끝나요.',
      button: '구독 보기',
    ),
    PPageBannerTone.critical: (
      title: '연결 끊김',
      body: '토스증권 키가 만료돼 시세를 받지 못해요.',
      button: '다시 연결',
    ),
  };

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final variant in PPageBannerVariant.values)
          DemoBlock(
            title: switch (variant) {
              PPageBannerVariant.weak => '옅은 바탕(weak · 기본) — 보이기 · 글 버튼 하나',
              PPageBannerVariant.solid =>
                '짙은 바탕(solid) — 무거운 상태에만 · 보이기 · 글 버튼 하나',
            },
            children: [
              for (final tone in PPageBannerTone.values)
                DemoRow(
                  label: tone.name,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PPageBanner(
                        tone: tone,
                        variant: variant,
                        title: _copy[tone]!.title,
                        description: _copy[tone]!.body,
                        button: PPageBannerButton(
                          label: _copy[tone]!.button,
                          onPressed: _ignore,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        DemoBlock(
          title: '전체 누르기(actionable) — 띠 전체가 버튼 · 뒤 화살표, 누르면 안의 내용만 준다',
          children: [
            for (final variant in PPageBannerVariant.values)
              for (final tone in PPageBannerTone.values)
                DemoRow(
                  label: '${variant.name} ${tone.name}',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PPageBanner(
                        tone: tone,
                        variant: variant,
                        interaction: PPageBannerInteraction.actionable,
                        title: _copy[tone]!.title,
                        description: _copy[tone]!.body,
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
            for (final variant in PPageBannerVariant.values)
              for (final tone in PPageBannerTone.values)
                DemoRow(
                  label: '${variant.name} ${tone.name}',
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _Dismissible(
                        builder: (open, onDismiss) => PPageBanner(
                          tone: tone,
                          variant: variant,
                          interaction: PPageBannerInteraction.dismissible,
                          title: '새 기능',
                          description: '반복 거래를 자동으로 기록할 수 있어요.',
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
          title: '본문과 버튼이 한 줄에 안 들어가면 — 버튼이 다음 줄 본문 시작선으로',
          children: [
            PPageBanner(
              tone: PPageBannerTone.critical,
              title: '연결 끊김',
              description: '토스증권 키가 만료돼 시세를 받지 못해요. 새 키를 발급받아 다시 연결해 주세요.',
              button: PPageBannerButton(label: '다시 연결', onPressed: _ignore),
              alert: true,
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
