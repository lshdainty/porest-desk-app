import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_parent_item.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';

/// 카탈로그(/dev/ds) — 줄의 종류 6(보기만 · 누르는 · 링크 · 스위치 · 체크 · 라디오) × 상태(기본 · 누름 · 비활성), 앞 · 뒤
/// 붙이개, 설명, 맞춤, 강조, 합계에 안 드는 줄, 목록 제목, 줄 사이 선, 하위 줄(꺾쇠 단추 · 들임 104), 가장 나쁜 값(긴 제목 · 1억
/// 넘는 금액 · 긴 낱말 · 접힌 하위 48개). 앱 Logo Tile · Image Frame 은 아직 없어 웹처럼 같은 치수 자리만 그린다. 눌러 보는
/// 견본은 값을 쥐고 직접 바꾼다 — 누름은 [PListPressedPreview] 로 멈춰 그린 것이 아니면 손가락으로 눌러 본다.
class ListDemo extends StatelessWidget {
  const ListDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KindsDemo(),
        _PrefixDemo(),
        _AlignHighlightDemo(),
        _StatesDemo(),
        _HeaderDividerDemo(),
        _NestedDemo(),
        _WorstDemo(),
        _LiveDemo(),
      ],
    );
  }
}

void _noop() {}

// 카테고리 색 타일 — 옅은 바탕(chart-{색}-weak) + 아이콘 색(chart-{색}). 이체 줄은 회색(카테고리가 아니라 돈의 이동)
enum _Tone { orange, blue, green, violet, pink, gray }

Widget _tile(BuildContext context, _Tone tone, IconData icon) {
  final c = context.colors;
  final (bg, fg) = switch (tone) {
    _Tone.orange => (c.chartOrangeWeak, c.chartOrange),
    _Tone.blue => (c.chartBlueWeak, c.chartBlue),
    _Tone.green => (c.chartGreenWeak, c.chartGreen),
    _Tone.violet => (c.chartVioletWeak, c.chartViolet),
    _Tone.pink => (c.chartPinkWeak, c.chartPink),
    _Tone.gray => (c.chartGrayWeak, c.chartGray),
  };
  return PListTile(background: bg, color: fg, child: Icon(icon));
}

/// 금액 — 그 화면이 정한다(가계부 16 · 700). 합계에 안 드는 줄은 `fg-neutral-subtle`.
Widget _amount(
  BuildContext context,
  String text, {
  bool subtle = false,
  bool strike = false,
}) {
  final c = context.colors;
  return Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w700,
      color: subtle ? c.fgNeutralSubtle : c.fgNeutral,
      decoration: strike ? TextDecoration.lineThrough : null,
      decorationColor: c.fgNeutralSubtle,
    ),
  );
}

const _chevron = Icon(LucideIcons.chevronRight);

/// 폰 폭 칸 — 줄은 24 가장자리 여백이라 폭이 그림의 일부다. 폰이 이보다 좁으면 있는 폭만큼.
class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.width = 360});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        SizedBox(width: math.min(width, constraints.maxWidth), child: child),
  );
}

/// 설명 자리의 배지 + 글 — 좁으면 줄을 바꾼다(배지는 보통 대비 그대로).
class _BadgeDetail extends StatelessWidget {
  const _BadgeDetail({required this.badge, required this.text});

  final String badge;
  final String text;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PSpacing.x1,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      PBadge(label: badge),
      Text(text),
    ],
  );
}

// ── 줄의 종류 ───────────────────────────────────────────────

class _KindsDemo extends StatefulWidget {
  const _KindsDemo();

  @override
  State<_KindsDemo> createState() => _KindsDemoState();
}

class _KindsDemoState extends State<_KindsDemo> {
  String _currency = 'KRW';
  String _visibility = 'me';
  bool _switchOn = true;
  final Set<String> _checked = {'거래 내역'};
  final Set<String> _checkedRight = {'카드'};

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '줄의 종류 — 보기만 하는 줄 · 누르는 줄 · 링크 줄 · 컨트롤 줄(스위치 · 체크 · 라디오). 누르는 줄만 누름이 있다',
      children: [
        DemoRow(
          label: '보기만 하는 줄',
          children: [
            _Cell(
              child: PList(
                semanticLabel: '계정 정보',
                children: const [
                  PListItem(title: '가입일', suffix: Text('2026년 3월 2일')),
                  PListItem(title: '이메일', suffix: Text('groo@mail.kr')),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '누르는 줄',
          children: [
            _Cell(
              child: PList(
                semanticLabel: '설정 · 누르는 줄',
                children: [
                  PListButtonItem(
                    prefix: const Icon(LucideIcons.user),
                    title: '계정',
                    suffix: _chevron,
                    onTap: _noop,
                  ),
                  PListButtonItem(
                    prefix: const Icon(LucideIcons.globe),
                    title: '기본 통화',
                    suffix: const PListSuffix(
                      children: [Text('대한민국 원'), _chevron],
                    ),
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '링크 줄',
          children: [
            _Cell(
              child: PList(
                semanticLabel: '도움말 · 링크 줄',
                children: [
                  PListLinkItem(
                    prefix: const Icon(LucideIcons.info),
                    title: '도움말',
                    detail: '설명서에서 자세히 알아보세요',
                    suffix: _chevron,
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '스위치 줄',
          children: [
            _Cell(
              child: PList(
                semanticLabel: '알림 · 스위치 줄',
                children: [
                  PListSwitchItem(
                    prefix: const Icon(LucideIcons.bell),
                    title: '결제 알림',
                    detail: '결제 예정일 D-1, 결제일 당일 알림',
                    checked: _switchOn,
                    onChanged: (v) => setState(() => _switchOn = v),
                  ),
                  PListSwitchItem(
                    prefix: const Icon(LucideIcons.mail),
                    title: '이메일 알림',
                    checked: false,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '체크 줄 · 여럿 고르기 — 앞 체크 · 뒤 체크',
          children: [
            _Cell(
              child: PListCheckGroup(
                semanticLabel: '내보낼 항목 · 앞 체크',
                children: [
                  for (final (name, detail) in const [
                    ('거래 내역', null),
                    ('예산', '카테고리별 한도'),
                  ])
                    PListCheckItem(
                      title: name,
                      detail: detail,
                      checked: _checked.contains(name),
                      onChanged: (v) => setState(
                        () => v ? _checked.add(name) : _checked.remove(name),
                      ),
                    ),
                ],
              ),
            ),
            _Cell(
              child: PListCheckGroup(
                semanticLabel: '내보낼 항목 · 뒤 체크',
                children: [
                  for (final (name, icon) in const [
                    ('카드', LucideIcons.creditCard),
                    ('계좌', LucideIcons.landmark),
                  ])
                    PListCheckItem(
                      markPosition: PListMarkPosition.suffix,
                      prefix: Icon(icon),
                      title: name,
                      checked: _checkedRight.contains(name),
                      onChanged: (v) => setState(
                        () => v
                            ? _checkedRight.add(name)
                            : _checkedRight.remove(name),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '라디오 줄 · 하나 고르기 — 뒤 라디오 · 앞 라디오',
          children: [
            _Cell(
              child: PListRadioGroup<String>(
                semanticLabel: '기본 통화',
                value: _currency,
                onChanged: (v) => setState(() => _currency = v),
                children: const [
                  PListRadioItem<String>(
                    value: 'KRW',
                    title: '대한민국 원',
                    detail: 'KRW',
                  ),
                  PListRadioItem<String>(
                    value: 'USD',
                    title: '미국 달러',
                    detail: 'USD',
                  ),
                  PListRadioItem<String>(
                    value: 'JPY',
                    title: '일본 엔',
                    detail: 'JPY',
                  ),
                ],
              ),
            ),
            _Cell(
              child: PListRadioGroup<String>(
                semanticLabel: '공개 범위 · 앞 라디오',
                value: _visibility,
                onChanged: (v) => setState(() => _visibility = v),
                children: const [
                  PListRadioItem<String>(
                    markPosition: PListMarkPosition.prefix,
                    value: 'me',
                    title: '나만 보기',
                  ),
                  PListRadioItem<String>(
                    markPosition: PListMarkPosition.prefix,
                    value: 'family',
                    title: '가족과 함께',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 앞 붙이개 · 뒤 붙이개 · 설명 ─────────────────────────────

class _PrefixDemo extends StatelessWidget {
  const _PrefixDemo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '앞 붙이개 — 설정 · 메뉴는 아이콘 22 · 내용 줄은 타일 40(모서리 12, 아이콘 20) · 물건 줄은 로고 타일 40 · 카드 그림 56 · 아바타 · 체크 · 라디오. 한 목록 안에서 섞지 않는다',
          children: [
            DemoRow(
              label: '아이콘 22',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '설정',
                    children: [
                      PListButtonItem(
                        prefix: const Icon(LucideIcons.lock),
                        title: '비밀번호',
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '타일 40 · 거래 · 이체 · 아이콘 없는 카테고리',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '거래 · 타일',
                    children: [
                      PListButtonItem(
                        prefix: _tile(
                          context,
                          _Tone.orange,
                          LucideIcons.utensils,
                        ),
                        title: '점심 · 김치찌개',
                        detail: '식비',
                        suffix: _amount(context, '-9,000원'),
                        onTap: _noop,
                      ),
                      PListButtonItem(
                        prefix: _tile(context, _Tone.blue, LucideIcons.car),
                        title: '주유',
                        detail: '교통',
                        suffix: _amount(context, '-62,000원'),
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
                _Cell(
                  child: PList(
                    semanticLabel: '거래 · 이체와 아이콘 없는 카테고리',
                    children: [
                      PListButtonItem(
                        prefix: _tile(
                          context,
                          _Tone.gray,
                          LucideIcons.arrowLeftRight,
                        ),
                        title: '월급통장 → 생활비',
                        detail: '이체',
                        suffix: _amount(context, '500,000원'),
                        onTap: _noop,
                      ),
                      PListButtonItem(
                        prefix: _tile(context, _Tone.violet, LucideIcons.tag),
                        title: '기타',
                        detail: '아이콘이 없는 카테고리는 태그 아이콘',
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '로고 타일 · 카드 그림 — 자리만',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '자산 · 로고 타일 자리',
                    children: [
                      PListButtonItem(
                        // 로고 타일(Logo Tile)은 따로 만든다 — 같은 40 · 모서리 12 의 자리만(기관 색 + 첫 글자)
                        prefix: Container(
                          width: PSpacing.x10,
                          height: PSpacing.x10,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.bgBrandSolid,
                            borderRadius: BorderRadius.circular(PRounded.r3),
                          ),
                          child: Text(
                            '포',
                            style: PTypography.t4.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.staticWhite,
                            ),
                          ),
                        ),
                        title: '포레스트은행 입출금',
                        detail: '1,284,000원',
                        suffix: _chevron,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
                _Cell(
                  child: PList(
                    semanticLabel: '카드 혜택 · 카드 그림 자리',
                    children: [
                      PListButtonItem(
                        // 카드 그림 56(Image Frame 의 카드 그림)은 따로 만든다 — 폭 56 · 카드 비율의 자리만
                        prefix: Container(
                          width: PSpacing.x14,
                          height: PSpacing.x9,
                          decoration: BoxDecoration(
                            color: c.bgNeutralWeak,
                            borderRadius: BorderRadius.circular(PRounded.r1_5),
                          ),
                        ),
                        title: '포레스트 체크카드',
                        detail: '전월 30만원 이상 · 할인형',
                        suffix: _chevron,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '아바타 — 한 줄이면 36 · 이름 + 설명 두 줄이면 42',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '참여자 · 한 줄 36',
                    children: [
                      PListButtonItem(
                        prefix: const PAvatar(
                          name: '김민수',
                          size: PAvatarSize.s36,
                        ),
                        title: '김민수',
                        suffix: _chevron,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
                _Cell(
                  child: PList(
                    semanticLabel: '참여자 · 두 줄 42',
                    children: [
                      PListButtonItem(
                        prefix: const PAvatar(
                          name: '이서연',
                          size: PAvatarSize.s42,
                        ),
                        title: '이서연',
                        detail: '제주 여행 · 더치페이 5명',
                        suffix: _chevron,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '뒤 붙이개 — 값 글자(16 · 옅은 색) · 오른쪽 화살표 18(화면을 옮기는 줄에만) · 스위치 32 · 체크 24 · 라디오 24 · 작은 버튼 · 금액(그 화면이 정한다 — 가계부 16 · 700)',
          children: [
            DemoRow(
              label: '값 글자 · 화살표',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '값 글자',
                    children: [
                      const PListItem(title: '앱 버전', suffix: Text('1.23.1')),
                      PListButtonItem(
                        title: '언어',
                        suffix: const PListSuffix(
                          children: [Text('한국어'), _chevron],
                        ),
                        onTap: _noop,
                      ),
                      PListButtonItem(
                        title: '이용 약관',
                        suffix: _chevron,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '작은 버튼 · 메뉴 — 줄 · 작은 버튼 · 메뉴, 누르는 것 셋',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '줄 안의 누르는 것은 셋까지',
                    children: [
                      PListButtonItem(
                        prefix: _tile(context, _Tone.green, LucideIcons.coffee),
                        title: '카페 · 아메리카노',
                        detail: '줄 · 작은 버튼 · 메뉴 — 셋',
                        suffix: PListSuffix(
                          children: [
                            PListAction(
                              child: PButton(
                                label: '분류',
                                variant: PButtonVariant.neutralWeak,
                                size: PButtonSize.xsmall,
                                onPressed: _noop,
                              ),
                            ),
                            PListAction(
                              child: PButton.icon(
                                icon: LucideIcons.ellipsisVertical,
                                semanticLabel: '카페 · 아메리카노 더 보기',
                                variant: PButtonVariant.ghost,
                                ghostColor: PButtonGhostColor.neutralSubtle,
                                size: PButtonSize.xsmall,
                                onPressed: _noop,
                              ),
                            ),
                          ],
                        ),
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '설명 — 제목 아래 2 떨어져 13 · 옅은 색. 한 줄 · 두 줄까지, 그 이상이면 맞춤을 위로. 여러 메타를 잇는 설명 줄은 Tag Group(t3)',
          children: [
            DemoRow(
              label: '한 줄 · 두 줄 · 메타',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '설명',
                    children: [
                      const PListItem(title: '알림 시각', detail: '오전 9시'),
                      const PListItem(
                        title: '결제 알림',
                        detail:
                            '결제 예정일 D-1, 결제일 당일에 알려요. 설명이 두 줄까지 이어져도 줄 높이만 늘어요',
                      ),
                      PListButtonItem(
                        prefix: _tile(
                          context,
                          _Tone.pink,
                          LucideIcons.shoppingBag,
                        ),
                        title: '무신사 · 가을 코트',
                        detailChild: const PTagGroup(
                          size: PTagGroupSize.t3,
                          items: [
                            PTag('쇼핑'),
                            PTag('포레스트 체크카드'),
                            PTag('10월 2일 오후 2:30'),
                          ],
                        ),
                        suffix: _amount(context, '-89,000원'),
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 맞춤 · 강조 · 합계에 안 드는 줄 ───────────────────────────

const _longTitle =
    '아주 긴 제목은 낱말 단위로만 줄을 바꾸고 말줄임 없이 끝까지 보여요 — 세 줄째부터는 앞 · 뒤를 위로 맞춘다';

class _AlignHighlightDemo extends StatelessWidget {
  const _AlignHighlightDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '맞춤 — 기본 가운데, 제목이 두 줄을 넘거나 설명이 길면 위(한 목록 안에서는 줄마다 섞지 않는다)',
          children: [
            DemoRow(
              label: 'center · top',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '가운데 맞춤',
                    children: [
                      PListButtonItem(
                        prefix: const Icon(LucideIcons.info),
                        title: '가운데 맞춤',
                        detail: '앞 · 뒤가 본문의 세로 가운데',
                        suffix: _chevron,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
                _Cell(
                  child: PList(
                    semanticLabel: '위 맞춤',
                    children: [
                      PListButtonItem(
                        align: PListAlign.top,
                        prefix: const Icon(LucideIcons.info),
                        title: _longTitle,
                        detail: '설명이 길 때도 같다',
                        suffix: _chevron,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '강조 — 바탕만 옅은 브랜드 색(점 · 막대 없음). 누르면 바탕이 짙어지고 설명 · 값 글자만 한 단계 짙다',
          children: [
            DemoRow(
              label: '안 읽은 알림 · 읽은 알림',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '알림 · 안 읽음',
                    children: [
                      PListButtonItem(
                        highlighted: true,
                        prefix: _tile(context, _Tone.orange, LucideIcons.bell),
                        title: '안 읽음 · 예산 80% 도달',
                        detail: '식비 예산의 80%를 썼어요',
                        suffix: const Text('방금'),
                        onTap: _noop,
                      ),
                      PListButtonItem(
                        highlighted: true,
                        prefix: _tile(
                          context,
                          _Tone.blue,
                          LucideIcons.creditCard,
                        ),
                        title: '안 읽음 · 카드 결제 예정',
                        detail: '내일 포레스트 체크카드 214,000원',
                        suffix: const Text('1시간 전'),
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
                _Cell(
                  child: PList(
                    semanticLabel: '알림 · 읽음',
                    children: [
                      PListButtonItem(
                        prefix: _tile(context, _Tone.green, LucideIcons.car),
                        title: '읽음 · 교통 예산 초과',
                        detail: '이번 달 교통 예산을 넘겼어요',
                        suffix: const Text('어제'),
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '합계에 안 드는 줄 — 흐리게 하지 않는다. 제목 · 금액만 fg-neutral-subtle, 환불 금액은 취소선, 배지는 보통 대비. 누름은 보통 줄과 같다(막힌 줄이 아니다)',
          children: [
            DemoRow(
              label: '예정 · 환불',
              children: [
                _Cell(
                  child: PList(
                    semanticLabel: '합계에 안 드는 거래',
                    children: [
                      PListButtonItem(
                        prefix: _tile(
                          context,
                          _Tone.blue,
                          LucideIcons.creditCard,
                        ),
                        title: '넷플릭스',
                        titleColor: context.colors.fgNeutralSubtle,
                        detailChild: const _BadgeDetail(
                          badge: '예정',
                          text: '10월 20일 결제',
                        ),
                        suffix: _amount(context, '-17,000원', subtle: true),
                        onTap: _noop,
                      ),
                      PListButtonItem(
                        prefix: _tile(
                          context,
                          _Tone.pink,
                          LucideIcons.shoppingBag,
                        ),
                        title: '무신사',
                        titleColor: context.colors.fgNeutralSubtle,
                        detailChild: const _BadgeDetail(
                          badge: '환불됨',
                          text: '10월 5일',
                        ),
                        suffix: _amount(
                          context,
                          '-89,000원',
                          subtle: true,
                          strike: true,
                        ),
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 상태 ─────────────────────────────────────────────────────

enum _State { enabled, pressed, disabled }

enum _Kind { button, link, tile, switchRow, check, radio }

const _kindLabel = {
  _Kind.button: '누르는 줄',
  _Kind.link: '링크 줄',
  _Kind.tile: '누르는 줄 · 타일',
  _Kind.switchRow: '스위치 줄',
  _Kind.check: '체크 줄',
  _Kind.radio: '라디오 줄',
};

const _stateLabel = {
  _State.enabled: '기본',
  _State.pressed: '누름(멈춰 그림)',
  _State.disabled: '비활성',
};

/// 한 줄 견본 — 가운데가 줄이어야 누르고 잴 수 있어 줄 하나만 둔다(하나 고르기가 두 줄 이상이어야 한다는 규칙은 실제
/// 화면의 것이다).
class _StateSample extends StatelessWidget {
  const _StateSample({
    required this.kind,
    required this.state,
    this.highlighted = false,
  });

  final _Kind kind;
  final _State state;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final disabled = state == _State.disabled;
    final label = '${_kindLabel[kind]} · ${_stateLabel[state]}';
    final Widget list;
    switch (kind) {
      case _Kind.button:
        list = PList(
          semanticLabel: label,
          children: [
            PListButtonItem(
              highlighted: highlighted,
              prefix: const Icon(LucideIcons.bell),
              title: '결제 알림',
              detail: '결제 예정일 D-1',
              suffix: const PListSuffix(children: [Text('대한민국 원'), _chevron]),
              onTap: disabled ? null : _noop,
            ),
          ],
        );
      case _Kind.link:
        // 링크 줄은 막지 않는다 — 비활성 견본이 없다
        list = PList(
          semanticLabel: label,
          children: [
            PListLinkItem(
              highlighted: highlighted,
              prefix: const Icon(LucideIcons.info),
              title: '도움말',
              detail: '설명서에서 자세히 알아보세요',
              suffix: _chevron,
              onTap: _noop,
            ),
          ],
        );
      case _Kind.tile:
        list = PList(
          semanticLabel: label,
          children: [
            PListButtonItem(
              prefix: _tile(context, _Tone.orange, LucideIcons.utensils),
              title: '점심 · 김치찌개',
              detail: '식비',
              // 금액의 색은 그 화면이 정한다 — 막힌 줄은 값 글자와 같이 비활성 색을 따른다
              suffix: disabled
                  ? const Text(
                      '-9,000원',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    )
                  : _amount(context, '-9,000원'),
              onTap: disabled ? null : _noop,
            ),
          ],
        );
      case _Kind.switchRow:
        list = PList(
          semanticLabel: label,
          children: [
            PListSwitchItem(
              highlighted: highlighted,
              prefix: const Icon(LucideIcons.bell),
              title: '결제 알림',
              detail: '결제 예정일 D-1',
              checked: true,
              onChanged: disabled ? null : (_) {},
            ),
          ],
        );
      case _Kind.check:
        list = PListCheckGroup(
          semanticLabel: label,
          children: [
            PListCheckItem(
              highlighted: highlighted,
              title: '거래 내역',
              detail: '내보낼 항목',
              checked: true,
              onChanged: disabled ? null : (_) {},
            ),
          ],
        );
      case _Kind.radio:
        list = PListRadioGroup<String>(
          semanticLabel: label,
          value: 'KRW',
          onChanged: disabled ? null : (_) {},
          children: [
            PListRadioItem<String>(
              highlighted: highlighted,
              value: 'KRW',
              title: '대한민국 원',
              detail: 'KRW',
            ),
          ],
        );
    }
    return _Cell(
      width: 300,
      child: state == _State.pressed ? PListPressedPreview(child: list) : list,
    );
  }
}

class _StatesDemo extends StatelessWidget {
  const _StatesDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '상태 — 기본 · 누름(손가락으로 누르는 동안의 모습을 멈춰 그렸다 — 직접도 눌러 본다) · 비활성. 올림 · 포커스 링은 웹 상태라 앱에 없다. 링크 줄은 막지 않는다',
      children: [
        for (final kind in _Kind.values)
          DemoRow(
            label: _kindLabel[kind]!,
            children: [
              for (final state in _State.values)
                if (kind != _Kind.link || state != _State.disabled)
                  _StateSample(kind: kind, state: state),
            ],
          ),
        DemoRow(
          label: '강조 · 누르는 줄',
          children: [
            for (final state in _State.values)
              _StateSample(kind: _Kind.button, state: state, highlighted: true),
          ],
        ),
      ],
    );
  }
}

// ── 목록 제목 · 줄 사이 선 ───────────────────────────────────

class _HeaderDividerDemo extends StatelessWidget {
  const _HeaderDividerDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '목록 제목 — mediumWeak(기본 · 14 · 500 · 옅은 색) · boldSolid(화면을 크게 나누는 묶음 · 700 · 짙은 색). 오른쪽에 작은 버튼, 좌우 24 는 줄과 같다',
          children: [
            DemoRow(
              label: 'mediumWeak',
              children: [
                _Cell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PListHeader(title: '일반'),
                      PList(
                        semanticLabel: '일반',
                        children: [
                          PListButtonItem(
                            prefix: const Icon(LucideIcons.user),
                            title: '계정',
                            onTap: _noop,
                          ),
                          PListButtonItem(
                            prefix: const Icon(LucideIcons.globe),
                            title: '기본 통화',
                            onTap: _noop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Cell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PListHeader(
                        title: '카테고리별 예산',
                        action: PTextButton(label: '전체 보기', onPressed: _noop),
                      ),
                      const PList(
                        semanticLabel: '카테고리별 예산',
                        children: [
                          PListItem(title: '식비', suffix: Text('240,000원')),
                          PListItem(title: '교통', suffix: Text('80,000원')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DemoRow(
              label: 'boldSolid',
              children: [
                _Cell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PListHeader(
                        title: '이번 달 지출',
                        variant: PListHeaderVariant.boldSolid,
                      ),
                      const PList(
                        semanticLabel: '이번 달 지출',
                        children: [
                          PListItem(title: '총 지출', suffix: Text('1,284,000원')),
                        ],
                      ),
                    ],
                  ),
                ),
                _Cell(
                  child: PListHeader(
                    title: '자산 · 4개',
                    variant: PListHeaderVariant.boldSolid,
                    action: PButton.icon(
                      icon: LucideIcons.info,
                      semanticLabel: '자산 안내',
                      variant: PButtonVariant.ghost,
                      ghostColor: PButtonGhostColor.neutralSubtle,
                      size: PButtonSize.xsmall,
                      onPressed: _noop,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '줄 사이 선(PListDivider) — 기본은 두지 않는다. 필요할 때만 1px · 줄 폭 전체, 앞 붙이개가 있으면 좌우 24 들인다',
          children: [
            DemoRow(
              label: '없음 · 줄 폭 · 들임',
              children: [
                const _Cell(
                  child: PList(
                    semanticLabel: '구분선 없음',
                    children: [
                      PListItem(title: '가입일', suffix: Text('2026년 3월 2일')),
                      PListItem(title: '이메일', suffix: Text('groo@mail.kr')),
                    ],
                  ),
                ),
                const _Cell(
                  child: PList(
                    semanticLabel: '구분선 · 줄 폭 전체',
                    children: [
                      PListItem(title: '가입일', suffix: Text('2026년 3월 2일')),
                      PListDivider(),
                      PListItem(title: '이메일', suffix: Text('groo@mail.kr')),
                    ],
                  ),
                ),
                _Cell(
                  child: PList(
                    semanticLabel: '구분선 · 들임',
                    children: [
                      PListButtonItem(
                        prefix: const Icon(LucideIcons.user),
                        title: '계정',
                        onTap: _noop,
                      ),
                      const PListDivider(inset: true),
                      PListButtonItem(
                        prefix: const Icon(LucideIcons.globe),
                        title: '기본 통화',
                        onTap: _noop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 하위 줄 ─────────────────────────────────────────────────

const _foodChildren = ['외식', '배달음식', '카페 · 간식', '장보기', '술 · 유흥', '기타 식비'];

/// 하위 줄(타일은 부모 제목 아래에서 시작한다 — 104).
List<Widget> _children(BuildContext context, List<String> names, _Tone tone) =>
    [
      for (final name in names)
        PListButtonItem(
          prefix: _tile(context, tone, LucideIcons.tag),
          title: name,
          detail: '지출',
          onTap: _noop,
        ),
    ];

class _NestedDemo extends StatefulWidget {
  const _NestedDemo();

  @override
  State<_NestedDemo> createState() => _NestedDemoState();
}

class _NestedDemoState extends State<_NestedDemo> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '하위 줄 — 접는 부모 줄. 줄 앞 꺾쇠 단추 44(누르는 영역 = 보이는 상자 · 모서리 10 · 20 chevron-right, 펼치면 90° 300ms) · 앞 붙이개는 52 에서 시작 · 하위 줄은 부모의 제목 자리 104 · 하위가 없는 부모는 같은 폭의 빈 자리 · 이름 고정 + 펼침 상태',
      children: [
        DemoRow(
          label: '카테고리 · 펼침 · 하위 없음',
          children: [
            _Cell(
              width: 400,
              child: PList(
                semanticLabel: '지출 카테고리 · 식비 펼침',
                children: [
                  PListParentItem(
                    prefix: _tile(context, _Tone.orange, LucideIcons.utensils),
                    title: '식비',
                    detail: '지출 · 하위 6개',
                    expandLabel: '식비 하위 카테고리',
                    defaultOpen: true,
                    onTap: _noop,
                    children: _children(context, _foodChildren, _Tone.orange),
                  ),
                  PListParentItem(
                    prefix: _tile(context, _Tone.gray, LucideIcons.tag),
                    title: '기타',
                    detail: '지출 · 하위 없음',
                    expandLabel: '기타 하위 카테고리',
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '카테고리 · 접힘',
          children: [
            _Cell(
              width: 400,
              child: PList(
                semanticLabel: '지출 카테고리 · 접힘',
                children: [
                  PListParentItem(
                    prefix: _tile(context, _Tone.pink, LucideIcons.shoppingBag),
                    title: '쇼핑',
                    detail: '지출 · 하위 6개(접힘)',
                    expandLabel: '쇼핑 하위 카테고리',
                    onTap: _noop,
                    children: _children(context, const [
                      '의류',
                      '신발 · 가방',
                      '화장품',
                      '생활용품',
                      '전자기기',
                      '기타 쇼핑',
                    ], _Tone.pink),
                  ),
                  PListParentItem(
                    prefix: _tile(context, _Tone.blue, LucideIcons.car),
                    title: '교통',
                    detail: '지출 · 하위 2개(접힘)',
                    expandLabel: '교통 하위 카테고리',
                    onTap: _noop,
                    children: _children(context, const [
                      '대중교통',
                      '택시',
                    ], _Tone.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '늘 펼친 화면 · 편집 — collapsible: false 면 꺾쇠 자리를 비우고 늘 펼친다',
          children: [
            _Cell(
              width: 400,
              child: PList(
                semanticLabel: '지출 카테고리 · 편집 모드(꺾쇠 없이 늘 펼침)',
                children: [
                  PListParentItem(
                    prefix: _tile(context, _Tone.violet, LucideIcons.coffee),
                    title: '취미',
                    detail: '꺾쇠 자리를 비우고 늘 펼친다',
                    collapsible: false,
                    onTap: _noop,
                    children: _children(context, const [
                      '영화',
                      '게임',
                    ], _Tone.violet),
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '직접 눌러 보기 — 줄은 편집(여기서는 아무 일 없음), 꺾쇠 단추가 펼치고 접는다',
          children: [
            _Cell(
              width: 400,
              child: PList(
                semanticLabel: '직접 눌러 보기 · 식비',
                children: [
                  PListParentItem(
                    prefix: _tile(context, _Tone.orange, LucideIcons.utensils),
                    title: '식비 · 줄을 누르면 편집',
                    detail: _open ? '하위 6개 펼침' : '하위 6개 접힘',
                    expandLabel: '식비 하위 카테고리',
                    open: _open,
                    onOpenChange: (v) => setState(() => _open = v),
                    onTap: _noop,
                    children: _children(context, _foodChildren, _Tone.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '부모 줄 상태 — 기본 · 누름(멈춰 그림) · 비활성 · 꺾쇠 단추 누름(멈춰 그림)',
          children: [
            for (final state in _State.values)
              _Cell(
                child: _preview(
                  state == _State.pressed ? PListPreviewTarget.row : null,
                  PList(
                    semanticLabel: '부모 줄 · ${_stateLabel[state]}',
                    children: [
                      PListParentItem(
                        prefix: _tile(
                          context,
                          _Tone.orange,
                          LucideIcons.utensils,
                        ),
                        title: '식비',
                        detail: '지출 · 하위 2개',
                        expandLabel: '식비 하위 카테고리 · ${_stateLabel[state]}',
                        onTap: state == _State.disabled ? null : _noop,
                        children: _children(context, const [
                          '외식',
                          '배달음식',
                        ], _Tone.orange),
                      ),
                    ],
                  ),
                ),
              ),
            _Cell(
              child: _preview(
                PListPreviewTarget.expandButton,
                PList(
                  semanticLabel: '부모 줄 · 꺾쇠 단추 누름',
                  children: [
                    PListParentItem(
                      prefix: _tile(
                        context,
                        _Tone.orange,
                        LucideIcons.utensils,
                      ),
                      title: '식비',
                      detail: '꺾쇠 단추만 바탕이 생긴다',
                      expandLabel: '식비 하위 카테고리 · 꺾쇠 누름',
                      onTap: _noop,
                      children: _children(context, const [
                        '외식',
                        '배달음식',
                      ], _Tone.orange),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _preview(PListPreviewTarget? target, Widget child) =>
      target == null
      ? child
      : PListPressedPreview(target: target, child: child);
}

// ── 가장 나쁜 값 ─────────────────────────────────────────────

class _WorstDemo extends StatelessWidget {
  const _WorstDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '가장 나쁜 값 — 아주 긴 제목 · 1억이 넘는 금액 · 띄어쓰기 없는 긴 낱말 · 접힌 하위 줄이 많은 부모. 스펙(Q-001)대로 그린 모습이다 — 글로 넘긴 값은 본문이 1em 이 된 뒤에야 줄고 줄 끝에서 끊으며, 위젯(금액 노드 · 화살표)은 줄지 않고 본문이 양보한다',
      children: [
        DemoRow(
          label: '긴 제목 · 큰 금액 320',
          children: [
            _Cell(
              width: 320,
              child: PList(
                semanticLabel: '가장 나쁜 값 · 거래',
                children: [
                  PListButtonItem(
                    align: PListAlign.top,
                    prefix: _tile(context, _Tone.pink, LucideIcons.shoppingBag),
                    title: '롯데백화점 본점 지하 1층 식품관 프리미엄 한우 선물세트 · 추석 명절 대량 구매',
                    detailChild: const PTagGroup(
                      size: PTagGroupSize.t3,
                      items: [
                        PTag('쇼핑'),
                        PTag('포레스트 체크카드 · 개인 사업자'),
                        PTag('2026년 10월 2일 오후 2:30'),
                      ],
                    ),
                    suffix: _amount(context, '-123,456,789원'),
                    onTap: _noop,
                  ),
                ],
              ),
            ),
            _Cell(
              width: 320,
              child: PList(
                semanticLabel: '가장 나쁜 값 · 큰 금액 한 줄',
                children: [
                  PListButtonItem(
                    title: '입출금 통장',
                    suffix: _amount(context, '-1,234,567,890원'),
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '긴 낱말 360',
          children: [
            const _Cell(
              child: PList(
                semanticLabel: '가장 나쁜 값 · 긴 낱말',
                children: [
                  PListItem(
                    prefix: Icon(LucideIcons.mail),
                    title:
                        'porest-desk-front-design-system-list-component-with-a-very-long-name',
                    detail: '띄어쓰기 없는 낱말은 칸 끝에서만 끊긴다',
                  ),
                  // 글로 넘긴 값 — 본문이 1em 이 된 뒤에야 줄고 줄 끝에서 끊는다
                  PListItem(title: '이메일 주소', suffix: Text('desk@example.kr')),
                  PListItem(
                    title: '이메일 주소',
                    suffix: Text(
                      'porest-desk-front-design-system-list-component-with-a-very-long-name@example.kr',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRow(
          label: '접힌 하위 많음 360 — 하위 48개',
          children: [
            _Cell(
              child: PList(
                semanticLabel: '가장 나쁜 값 · 접힌 하위 줄 많은 부모',
                children: [
                  PListParentItem(
                    prefix: _tile(context, _Tone.orange, LucideIcons.utensils),
                    title: '식비 · 외식 · 배달음식 · 장보기 · 카페 · 간식 · 술 · 유흥 전부',
                    detail: '지출 · 하위 48개',
                    expandLabel:
                        '식비 · 외식 · 배달음식 · 장보기 · 카페 · 간식 · 술 · 유흥 전부 하위 카테고리',
                    onTap: _noop,
                    children: [
                      for (var i = 1; i <= 48; i++)
                        PListButtonItem(
                          prefix: _tile(context, _Tone.orange, LucideIcons.tag),
                          title: '하위 카테고리 $i',
                          detail: '지출',
                          onTap: _noop,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 직접 눌러 보기 ───────────────────────────────────────────

class _LiveDemo extends StatefulWidget {
  const _LiveDemo();

  @override
  State<_LiveDemo> createState() => _LiveDemoState();
}

class _LiveDemoState extends State<_LiveDemo> {
  bool _on = true;
  final Set<String> _picked = {'거래 내역'};
  String _currency = 'KRW';
  int _clicks = 0;

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title: '직접 눌러 보기 — 줄 어디를 눌러도 끼운 컨트롤이 바뀌고, 줄이 줄 때 컨트롤은 따로 줄지 않는다',
      children: [
        DemoRow(
          label: '누르는 줄 · 컨트롤',
          children: [
            _Cell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PListHeader(title: '설정'),
                  PList(
                    semanticLabel: '설정',
                    children: [
                      PListButtonItem(
                        prefix: const Icon(LucideIcons.user),
                        title: '계정',
                        detail: '$_clicks번 눌렀어요',
                        suffix: _chevron,
                        onTap: () => setState(() => _clicks++),
                      ),
                      PListSwitchItem(
                        prefix: const Icon(LucideIcons.bell),
                        title: '결제 알림',
                        detail: _on ? '켜짐' : '꺼짐',
                        checked: _on,
                        onChanged: (v) => setState(() => _on = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Cell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PListHeader(title: '내보낼 항목'),
                  PListCheckGroup(
                    semanticLabel: '내보낼 항목',
                    children: [
                      for (final name in const ['거래 내역', '예산', '메모'])
                        PListCheckItem(
                          title: name,
                          checked: _picked.contains(name),
                          onChanged: (v) => setState(
                            () => v ? _picked.add(name) : _picked.remove(name),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _Cell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PListHeader(title: '기본 통화'),
                  PListRadioGroup<String>(
                    semanticLabel: '기본 통화',
                    value: _currency,
                    onChanged: (v) => setState(() => _currency = v),
                    children: const [
                      PListRadioItem<String>(
                        value: 'KRW',
                        title: '대한민국 원',
                        detail: 'KRW',
                      ),
                      PListRadioItem<String>(
                        value: 'USD',
                        title: '미국 달러',
                        detail: 'USD',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
