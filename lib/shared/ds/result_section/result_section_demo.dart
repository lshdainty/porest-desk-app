import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/result_section/p_result_section.dart';

/// 카탈로그(/dev/ds) — 결과(비어 있음 · 실패 · 완료) × 크기(large · medium), 다시 시도 로딩, 찾을 수 없는 페이지, 카드 안.
class ResultSectionDemo extends StatelessWidget {
  const ResultSectionDemo({super.key});

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: 'large — 화면 전체를 차지하는 결과(제목 22 · 설명 16)',
          children: [
            _row(
              'empty',
              360,
              const PResultSection(
                icon: LucideIcons.receiptText300,
                title: '이번 달 거래가 없어요',
                description: '거래를 기록하면 여기에 모여요.',
                primaryAction: PResultAction(
                  label: '거래 추가',
                  onPressed: _ignore,
                ),
              ),
            ),
            _row(
              'failure',
              360,
              const PResultSection(
                kind: PResultKind.failure,
                title: '문제가 생겼어요',
                description: '잠시 뒤 다시 시도해 주세요.',
                primaryAction: PResultAction(
                  label: '다시 시도',
                  onPressed: _ignore,
                ),
                secondaryAction: PResultAction(
                  label: '홈으로',
                  onPressed: _ignore,
                ),
              ),
            ),
            _row(
              'done',
              360,
              const PResultSection(
                kind: PResultKind.done,
                title: '1,204건을 가져왔어요',
                description: '건너뛴 줄 3 · 실패 0',
                primaryAction: PResultAction(
                  label: '가계부로 가기',
                  onPressed: _ignore,
                ),
                secondaryAction: PResultAction(
                  label: '다른 파일 가져오기',
                  onPressed: _ignore,
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: 'medium — 카드 · 섹션 · 시트 안의 결과(제목 16 · 설명 14)',
          children: [
            _row(
              'empty',
              240,
              const PResultSection(
                size: PResultSize.medium,
                icon: LucideIcons.bell300,
                title: '새 알림이 없어요',
                description: '예산을 넘거나 결제일이 다가오면 알려 드려요.',
              ),
            ),
            _row(
              'failure',
              240,
              const PResultSection(
                kind: PResultKind.failure,
                size: PResultSize.medium,
                title: '거래를 불러오지 못했어요',
                description: '잠시 뒤 다시 시도해 주세요.',
                primaryAction: PResultAction(
                  label: '다시 시도',
                  onPressed: _ignore,
                ),
              ),
            ),
            _row(
              'done',
              240,
              const PResultSection(
                kind: PResultKind.done,
                size: PResultSize.medium,
                title: '모두 분류했어요',
                description: '분류할 거래가 남아 있지 않아요.',
                primaryAction: PResultAction(
                  label: '가계부로 가기',
                  onPressed: _ignore,
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '다시 시도 하는 동안 · 찾을 수 없는 페이지 — 버튼 로딩(loading) · 홈으로',
          children: [
            _row(
              'failure 로딩',
              240,
              const PResultSection(
                kind: PResultKind.failure,
                size: PResultSize.medium,
                title: '거래를 불러오지 못했어요',
                description: '잠시 뒤 다시 시도해 주세요.',
                primaryAction: PResultAction(
                  label: '다시 시도',
                  onPressed: _ignore,
                  loading: true,
                ),
              ),
            ),
            _row(
              '404',
              360,
              const PResultSection(
                icon: LucideIcons.searchX300,
                title: '페이지를 찾을 수 없어요',
                primaryAction: PResultAction(label: '홈으로', onPressed: _ignore),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '카드 안 — 좌우 여백 0(카드의 안 여백 24 가 가장자리를 맡는다) · 목록 카드 24',
          children: [
            _row(
              'card · listCard',
              240,
              const Row(
                children: [
                  Expanded(
                    child: PResultSection(
                      kind: PResultKind.failure,
                      size: PResultSize.medium,
                      placement: PResultPlacement.card,
                      title: '거래를 불러오지 못했어요',
                    ),
                  ),
                  Expanded(
                    child: PResultSection(
                      kind: PResultKind.failure,
                      size: PResultSize.medium,
                      placement: PResultPlacement.listCard,
                      title: '거래를 불러오지 못했어요',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 놓인 자리 — 결과는 이 안에서 가로 · 세로 가운데에 서고 남는 높이를 채운다. 카탈로그 틀이다
  Widget _row(String label, double height, Widget child) {
    return DemoRow(
      label: label,
      children: [
        Builder(
          builder: (context) => Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.strokeNeutralWeak),
              borderRadius: BorderRadius.circular(PRounded.r3),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
