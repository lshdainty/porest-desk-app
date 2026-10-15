import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/avatar/p_avatar.dart';
import 'package:porest_desk_app/shared/ds/badge/p_badge.dart';
import 'package:porest_desk_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/input_button/p_input_button.dart';
import 'package:porest_desk_app/shared/ds/searchable_list/p_searchable_list.dart';

// 거르는 것은 쓰는 쪽이다 — 공용 규칙(searchable-list.yaml results.filter): NFC · 대소문자 무시 · 공백 무시 · 포함, 이름 + 별칭.
// 초성 검색은 보류(사용자가 나중에 정한다)라 하지 않는다.
String _normalize(String s) =>
    _nfc(s).toLowerCase().replaceAll(RegExp(r'\s+'), '');

bool _matches(String name, String query, {List<String> aliases = const []}) {
  final q = _normalize(query);
  return _normalize(name).contains(q) ||
      aliases.any((a) => _normalize(a).contains(q));
}

/// 한글 NFC — 낱자(초 · 중 · 종성 자모)로 쪼개져 들어온 글을 음절로 모은다(맥 · 일부 키보드의 입력). 한글 밖은 그대로 둔다.
String _nfc(String s) {
  if (!s.runes.any((r) => r >= 0x1100 && r <= 0x11FF)) return s;
  const sBase = 0xAC00, lBase = 0x1100, vBase = 0x1161, tBase = 0x11A7;
  const lCount = 19, vCount = 21, tCount = 28;
  final out = <int>[];
  for (final r in s.runes) {
    if (out.isNotEmpty) {
      final last = out.last;
      // 초성 + 중성 → 음절
      if (last >= lBase &&
          last < lBase + lCount &&
          r >= vBase &&
          r < vBase + vCount) {
        out[out.length - 1] =
            sBase + ((last - lBase) * vCount + (r - vBase)) * tCount;
        continue;
      }
      // 음절(받침 없음) + 종성 → 받침을 얹는다
      if (last >= sBase &&
          last < sBase + lCount * vCount * tCount &&
          (last - sBase) % tCount == 0 &&
          r > tBase &&
          r < tBase + tCount) {
        out[out.length - 1] = last + (r - tBase);
        continue;
      }
    }
    out.add(r);
  }
  return String.fromCharCodes(out);
}

// 별칭 — 사람들이 부르는 줄임말 · 영문 표기. 이름에 없어도 찾아진다
const Map<String, List<String>> _bankAliases = {
  '국민은행': ['KB', 'KB국민은행'],
  '카카오뱅크': ['카뱅', 'kakaobank'],
  '토스뱅크': ['토뱅'],
  '케이뱅크': ['kbank'],
  '신협': ['신용협동조합'],
  '우체국': ['우정사업본부'],
};
const Map<String, List<String>> _cardAliases = {
  'T-Pay 신한카드': ['티페이'],
  '삼성 iD ON 카드': ['아이디온'],
  '현대카드 ZERO Edition2': ['제로'],
  'KB국민 노리2 체크카드': ['노리', '국민카드'],
  'NH농협 올바른 FLEX 카드': ['올바른', '농협'],
};

typedef _Group = ({String label, List<String> banks});
const List<_Group> _bankGroups = [
  (label: '시중은행', banks: ['국민은행', '신한은행', '우리은행', '하나은행', 'SC제일은행']),
  (label: '인터넷은행', banks: ['카카오뱅크', '토스뱅크', '케이뱅크']),
  (label: '지방은행', banks: ['부산은행', '대구은행', '광주은행', '전북은행', '제주은행']),
  (label: '저축기관', banks: ['새마을금고중앙회 전국 지점 통합 계좌 조회 서비스 이용 은행', '신협', '우체국']),
];

// 앞 붙이개 자리표시 — Logo Tile 40 · 카드 그림 56 · Avatar 36(스펙 크기). 진짜 부품은 각자의 스펙이 잰다
class _Logo extends StatelessWidget {
  const _Logo(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.bgNeutralWeak,
        borderRadius: BorderRadius.circular(PRounded.r3),
      ),
      child: Text(
        name.substring(0, 1),
        style: PTypography.t5.copyWith(
          color: c.fgNeutral,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardArt extends StatelessWidget {
  const _CardArt();

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56 / 1.586,
    decoration: BoxDecoration(
      color: context.colors.bgNeutralWeak,
      borderRadius: BorderRadius.circular(PRounded.r2),
    ),
  );
}

enum _Prefix { none, logo, cardArt, avatar }

Widget? _prefixOf(_Prefix prefix, String name) => switch (prefix) {
  _Prefix.none => null,
  _Prefix.logo => _Logo(name),
  _Prefix.cardArt => const _CardArt(),
  _Prefix.avatar => PAvatar(name: name, size: PAvatarSize.s36),
};

/// 견본 한 칸 — 시트 면(floating) · 단계 안 면(default) 위에 놓는다.
class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.sheet = true});

  final Widget child;
  final bool sheet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheet ? c.bgLayerFloating : c.bgLayerDefault,
        borderRadius: BorderRadius.circular(PRounded.r3),
        border: Border.all(color: c.strokeNeutralWeak),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: PSpacing.x2),
        child: child,
      ),
    );
  }
}

/// 줄 셋 — 첫 줄이 고른 값(오른쪽 라디오 켬). [highlightSecond] 는 둘째 줄을 강조한 모습으로 멈춰 그린다.
Widget _sample({
  required PSearchableListPlacement placement,
  _Prefix prefix = _Prefix.none,
  bool current = true,
  bool highlightSecond = false,
}) {
  const rows = ['신한은행', '국민은행', '카카오뱅크'];
  Widget list = PSearchableList(
    placement: placement,
    defaultValue: current ? rows[0] : null,
    children: [
      const PSearchableListInput(
        autofocus: false,
        placeholder: '은행 이름 검색',
        semanticLabel: '검색',
      ),
      PSearchableListResults(
        semanticLabel: '은행',
        children: [
          PSearchableListGroup(
            label: '시중은행',
            children: [
              for (final (i, name) in rows.indexed)
                PSearchableListItem(
                  value: name,
                  title: name,
                  detail: i == 1 ? '계좌 · 카드' : null,
                  prefix: _prefixOf(prefix, name),
                ),
            ],
          ),
        ],
      ),
    ],
  );
  if (highlightSecond) {
    list = PSearchableListHighlightPreview(value: rows[1], child: list);
  }
  return _Surface(
    sheet: placement == PSearchableListPlacement.sheet,
    child: list,
  );
}

/// 카탈로그(/dev/ds) — 놓인 자리(시트 · 단계 안) × 앞 붙이개 · 고름 · 강조, 0건 · 실패 · 불러오는 줄, 직접 골라 보는 은행
/// 시트 · 서버 검색 · 가장 나쁜 값(400개 · 300자 이름 · 빈 목록 · 긴 검색어). 앱은 늘 large(검색칸 40)다.
class SearchableListDemo extends StatelessWidget {
  const SearchableListDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '놓인 자리 — 검색칸 large 40, 시트(floating 면) · 단계 안(default 면). 첫 줄이 지금 값(오른쪽 라디오 켬)',
          children: [
            DemoRow(
              label: 'large · sheet',
              children: [
                SizedBox(
                  width: 330,
                  child: _sample(placement: PSearchableListPlacement.sheet),
                ),
              ],
            ),
            DemoRow(
              label: 'large · inline',
              children: [
                SizedBox(
                  width: 330,
                  child: _sample(placement: PSearchableListPlacement.inline),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '앞 붙이개 · 고름 · 강조 — 로고 타일 40 · 카드 그림 56 · 아바타 36, 고르지 않은 목록, 화살표로 짚은 줄(강조 바탕)',
          children: [
            for (final (label, prefix) in [
              ('logo', _Prefix.logo),
              ('cardArt', _Prefix.cardArt),
              ('avatar', _Prefix.avatar),
            ])
              DemoRow(
                label: label,
                children: [
                  SizedBox(
                    width: 330,
                    child: _sample(
                      placement: PSearchableListPlacement.sheet,
                      prefix: prefix,
                    ),
                  ),
                ],
              ),
            DemoRow(
              label: '고른 것 없음',
              children: [
                SizedBox(
                  width: 330,
                  child: _sample(
                    placement: PSearchableListPlacement.sheet,
                    current: false,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '강조 — 둘째 줄',
              children: [
                SizedBox(
                  width: 330,
                  child: _sample(
                    placement: PSearchableListPlacement.sheet,
                    highlightSecond: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '결과 없음 · 실패 · 불러오는 줄 — 목록 자리에 Result Section(알림). 줄 스켈레톤은 앞 자리 4가지',
          children: [
            DemoRow(
              label: '0건',
              children: [
                SizedBox(
                  width: 330,
                  child: _Surface(
                    child: PSearchableList(
                      defaultQuery: '나루로리롱',
                      children: [
                        const PSearchableListInput(
                          autofocus: false,
                          placeholder: '은행 이름 검색',
                          semanticLabel: '검색',
                        ),
                        PSearchableListEmpty(
                          titleBuilder: (q) => "'$q'에 대한 검색 결과가 없어요",
                          description: '카드사 이름으로도 찾아보세요.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '실패 — 0건과 따로 + 다시 시도',
              children: [
                SizedBox(
                  width: 330,
                  child: _Surface(
                    child: PSearchableList(
                      children: [
                        const PSearchableListInput(
                          autofocus: false,
                          placeholder: '카드 이름 검색',
                          semanticLabel: '검색',
                        ),
                        PSearchableListError(
                          title: '검색 결과를 불러오지 못했어요',
                          retryLabel: '다시 시도',
                          onRetry: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            for (final (label, prefix) in [
              ('불러오는 줄 — logo', PSearchableListSkeletonPrefix.logo),
              ('불러오는 줄 — cardArt', PSearchableListSkeletonPrefix.cardArt),
              ('불러오는 줄 — avatar', PSearchableListSkeletonPrefix.avatar),
              ('불러오는 줄 — none', PSearchableListSkeletonPrefix.none),
            ])
              DemoRow(
                label: label,
                children: [
                  SizedBox(
                    width: 330,
                    child: _Surface(
                      child: PSearchableList(
                        children: [
                          const PSearchableListInput(
                            autofocus: false,
                            placeholder: '검색',
                            semanticLabel: '검색',
                          ),
                          PSearchableListSkeleton(prefix: prefix, rows: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const DemoBlock(
          title:
              '직접 골라 본다 — 은행 고르기: 입력칸을 누르면 검색 시트. 치면 거르고, 줄을 누르면 고르고 닫힌다(하드웨어 키보드는 ↓ ↑ 강조 · Enter · Esc)',
          children: [_BankPicker()],
        ),
        const DemoBlock(
          title:
              '서버 검색(단계 안) — 글자를 쳐도 마지막 입력 뒤 300ms 에 한 번만 보낸다. 옛 결과는 남기고, 실패는 0건과 따로',
          children: [_ServerSearch()],
        ),
        const DemoBlock(
          title:
              '가장 나쁜 값 — 목록 400개 · 300자 이름 · 빈 목록 · 긴 검색어. 높이가 정해진 자리라 검색칸이 위에 붙고 결과만 스크롤한다',
          children: [_WorstCase()],
        ),
      ],
    );
  }
}

// ── 은행 고르기 — Input Button 이 여는 검색 시트 ─────────────

class _BankPicker extends StatefulWidget {
  const _BankPicker();

  @override
  State<_BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<_BankPicker> {
  String? _bank;
  bool _open = false;

  // 검색칸의 초점 노드 — 시트(첫 초점)와 묶음(검색칸)이 같은 노드를 쓴다
  final FocusNode _searchFocus = FocusNode(debugLabel: 'bank search');

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    setState(() => _open = true);
    final result = await PBottomSheet.show<String>(
      context,
      initialFocus: _searchFocus,
      builder: (_) => _BankSheet(initial: _bank, searchFocus: _searchFocus),
    );
    if (!mounted) return;
    setState(() {
      _open = false;
      if (result != null) _bank = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PField(
      label: '은행',
      child: PInputButton(
        placeholder: '은행 선택',
        value: _bank,
        suffixIcon: LucideIcons.chevronDown,
        expanded: _open,
        onPressed: _openSheet,
      ),
    );
  }
}

class _BankSheet extends StatefulWidget {
  const _BankSheet({required this.initial, required this.searchFocus});

  final String? initial;
  final FocusNode searchFocus;

  @override
  State<_BankSheet> createState() => _BankSheetState();
}

class _BankSheetState extends State<_BankSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final g in _bankGroups)
        (
          label: g.label,
          banks: [
            for (final b in g.banks)
              if (_matches(b, _query, aliases: _bankAliases[b] ?? const [])) b,
          ],
        ),
    ].where((g) => g.banks.isNotEmpty).toList();
    final height = MediaQuery.sizeOf(context).height * 0.55;
    return PBottomSheetContent(
      title: '은행 선택',
      closeLabel: '닫기',
      // 본문 좌우 여백을 뺀다 — 검색칸 · 줄이 제 24 를 가진다. 높이를 정해 검색칸이 위에 붙게 한다
      flushBody: true,
      body: SizedBox(
        height: height,
        child: PSearchableList(
          focusNode: widget.searchFocus,
          defaultValue: widget.initial,
          // 고르면 닫는다 — "완료" 없음
          onValueChanged: (v) => PBottomSheet.of(context).close(v),
          onQueryChanged: (q) => setState(() => _query = q),
          children: [
            const PSearchableListInput(
              placeholder: '은행 이름 검색',
              semanticLabel: '검색',
            ),
            if (groups.isEmpty)
              PSearchableListEmpty(titleBuilder: (q) => "'$q'에 대한 검색 결과가 없어요")
            else
              PSearchableListResults(
                semanticLabel: '은행',
                children: [
                  for (final g in groups)
                    PSearchableListGroup(
                      label: g.label,
                      children: [
                        for (final b in g.banks)
                          PSearchableListItem(
                            value: b,
                            title: b,
                            prefix: _Logo(b),
                          ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── 서버 검색 — 단계 안 ──────────────────────────────────────

typedef _Card = ({String id, String name, String issuer, bool discontinued});

const List<_Card> _cards = [
  (id: 'c0', name: 'T-Pay 신한카드', issuer: '신한카드', discontinued: false),
  (id: 'c1', name: '삼성 iD ON 카드', issuer: '삼성카드', discontinued: false),
  (id: 'c2', name: '현대카드 ZERO Edition2', issuer: '현대카드', discontinued: false),
  (id: 'c3', name: 'KB국민 노리2 체크카드', issuer: 'KB국민카드', discontinued: false),
  (id: 'c4', name: '우리카드 7CORE 체크', issuer: '우리카드', discontinued: true),
  (id: 'c5', name: '롯데카드 LOCA 365', issuer: '롯데카드', discontinued: false),
  (id: 'c6', name: '하나카드 1Q 트래블로그', issuer: '하나카드', discontinued: false),
  (id: 'c7', name: 'NH농협 올바른 FLEX 카드', issuer: 'NH농협카드', discontinued: true),
];

class _ServerSearch extends StatefulWidget {
  const _ServerSearch();

  @override
  State<_ServerSearch> createState() => _ServerSearchState();
}

class _ServerSearchState extends State<_ServerSearch> {
  String? _cardId;
  int _requests = 0;
  bool _pending = true;
  bool _failed = false;
  bool _failNext = false;
  bool _retrying = false;
  String _sent = '';
  List<_Card> _data = _cards;
  Timer? _fetch;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _fetch?.cancel();
    super.dispose();
  }

  // 서버 대신 — 400ms 뒤에 돌려준다. 받는 동안은 옛 결과를 남긴다(처음만 스켈레톤)
  void _search(String query) {
    _fetch?.cancel();
    setState(() {
      _requests++;
      _sent = query;
      _retrying = _failed;
    });
    _fetch = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _retrying = false;
        _failed = _failNext;
        if (!_failed) {
          _data = [
            for (final c in _cards)
              if (_matches(
                c.name,
                query,
                aliases: [c.issuer, ...?_cardAliases[c.name]],
              ))
                c,
          ];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PSpacing.x3,
      children: [
        Text(
          '서버로 간 요청 $_requests번 — 마지막 검색어 "$_sent"',
          style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
        ),
        PButton(
          label: _failNext ? '다음 요청 성공시키기' : '다음 요청 실패시키기',
          variant: PButtonVariant.neutralWeak,
          size: PButtonSize.small,
          onPressed: () => setState(() => _failNext = !_failNext),
        ),
        _Surface(
          sheet: false,
          child: SizedBox(
            height: 420,
            child: PSearchableList(
              placement: PSearchableListPlacement.inline,
              defaultValue: null,
              value: _cardId ?? '',
              onValueChanged: (v) => setState(() => _cardId = v),
              onSearch: _search,
              children: [
                const PSearchableListInput(
                  placeholder: '카드 이름 검색',
                  semanticLabel: '검색',
                ),
                if (_pending)
                  const PSearchableListSkeleton(
                    prefix: PSearchableListSkeletonPrefix.cardArt,
                  )
                else if (_failed)
                  PSearchableListError(
                    title: '검색 결과를 불러오지 못했어요',
                    retryLabel: '다시 시도',
                    retrying: _retrying,
                    onRetry: () => _search(_sent),
                  )
                else if (_data.isEmpty)
                  PSearchableListEmpty(
                    titleBuilder: (q) => "'$q'에 대한 검색 결과가 없어요",
                    description: '카드사 이름으로도 찾아보세요.',
                  )
                else
                  PSearchableListResults(
                    semanticLabel: '카드 상품',
                    children: [
                      for (final card in _data)
                        PSearchableListItem(
                          value: card.id,
                          title: card.name,
                          prefix: const _CardArt(),
                          detailChild: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: PSpacing.x1_5,
                            children: [
                              Flexible(child: Text(card.issuer)),
                              if (card.discontinued) const PBadge(label: '단종'),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        PButton(
          label: '다음',
          size: PButtonSize.large,
          variant: PButtonVariant.neutralSolid,
          onPressed: _cardId == null ? null : () {},
        ),
      ],
    );
  }
}

// ── 가장 나쁜 값 ─────────────────────────────────────────────

final List<String> _many = [
  for (var i = 1; i <= 400; i++) '종목 ${i.toString().padLeft(3, '0')}',
];
final String _longName = '가나다라마바사아자차카타파하 ' * 20;

class _WorstCase extends StatefulWidget {
  const _WorstCase();

  @override
  State<_WorstCase> createState() => _WorstCaseState();
}

class _WorstCaseState extends State<_WorstCase> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final names = [_longName, ..._many];
    final shown = [
      for (final n in names)
        if (_matches(n, _query)) n,
    ];
    return _Surface(
      child: SizedBox(
        height: 420,
        child: PSearchableList(
          defaultValue: _many[120],
          defaultQuery: '',
          onQueryChanged: (q) => setState(() => _query = q),
          children: [
            const PSearchableListInput(
              autofocus: false,
              placeholder: '종목 검색',
              semanticLabel: '검색',
            ),
            if (shown.isEmpty)
              PSearchableListEmpty(
                titleBuilder: (q) =>
                    q.isEmpty ? '검색 결과가 없어요' : "'$q'에 대한 검색 결과가 없어요",
              )
            else
              PSearchableListResults(
                semanticLabel: '종목',
                children: [
                  for (final n in shown)
                    PSearchableListItem(
                      value: n,
                      title: n,
                      detail: n == _longName
                          ? '긴 이름 — 한 줄에 안 들어가면 줄이 늘어난다'
                          : null,
                      prefix: _Logo(n),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
