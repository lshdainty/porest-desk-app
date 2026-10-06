import 'package:flutter/material.dart';

import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/progress/p_progress.dart';

/// 카탈로그(/dev/ds) — 한도(기본 · 넘침) · 목표(기본 · 달성), 값을 바꿔 채움이 따라 차는 것을 본다.
class ProgressDemo extends StatefulWidget {
  const ProgressDemo({super.key});

  @override
  State<ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<ProgressDemo> {
  double _spent = 350000;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '한도 — 쓸수록 찬다, 넘으면 위험 색 + "N원 초과"',
          children: [
            PProgress(label: '식비 예산', value: _spent, max: 400000),
            const PProgress(label: '쇼핑 예산', value: 420000, max: 400000),
            Align(
              alignment: Alignment.centerLeft,
              child: PButton(
                label: '값 바꾸기',
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.small,
                onPressed: () => setState(
                  () => _spent = _spent >= 400000 ? 120000 : _spent + 90000,
                ),
              ),
            ),
          ],
        ),
        const DemoBlock(
          title: '목표 — 모을수록 찬다, 닿으면 "달성"(색은 그대로)',
          children: [
            PProgress(
              label: '여행 자금',
              value: 1200000,
              max: 2000000,
              meaning: PProgressMeaning.goal,
            ),
            PProgress(
              label: '비상금',
              value: 1000000,
              max: 1000000,
              meaning: PProgressMeaning.goal,
            ),
          ],
        ),
      ],
    );
  }
}
