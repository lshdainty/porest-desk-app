import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

/// 카탈로그 데모를 짜는 부품 — debug 빌드 전용(/dev/ds).
///
/// 앱의 스펙 확인은 위젯 테스트가 한다(test/shared/ds/*_spec_test.dart — 스펙 JSON 과 맞춘다).
/// 여기는 사람이 눈으로 보고 눌러 보는 자리다.

/// 데모 한 구역 — 작은 제목 아래 내용.
class DemoBlock extends StatelessWidget {
  const DemoBlock({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x3,
        children: [
          Text(
            title,
            style: PTypography.t3.copyWith(
              color: context.colors.fgNeutralMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// 데모 한 줄 — 이름표 아래 견본들. 폰 폭이라 견본은 줄을 바꿔 흐른다.
class DemoRow extends StatelessWidget {
  const DemoRow({required this.label, required this.children, super.key});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x1_5,
      children: [
        Text(
          label,
          style: PTypography.t2.copyWith(color: context.colors.fgNeutralSubtle),
        ),
        Wrap(
          spacing: PSpacing.x3,
          runSpacing: PSpacing.x3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ],
    );
  }
}
