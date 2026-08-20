#!/usr/bin/env bash
#
# 릴리스 노트 — 커밋을 사용자가 읽는 목록으로 정리한다.
#
# 앱 업데이트 화면과 GitHub 릴리스 본문이 같은 글을 쓴다.
#
# 글은 두 군데서 온다.
#
#   1. `Release-Note:` 트레일러 — 있으면 이것을 그대로 쓴다.
#
#        fix(recurring): 스냅 임계값 단위를 트레이 기준으로 환산한다
#
#        Release-Note: 반복 거래 행이 어중간하게 열리던 문제를 고쳤어요
#
#      커밋 제목은 `git log`·`blame`·리뷰에서 개발자가 읽는 자리다. 거기를 사용자
#      말투로 바꾸면 그쪽이 망가진다. 그래서 사용자용 문장을 따로 단다.
#
#      `Release-Note: skip` 이면 그 커밋은 아예 뺀다 — feat·fix 로 찍혔지만 쓰는
#      사람 눈에는 아무 일도 안 일어난 변경(내부 정리, 테스트 보강 등)에 쓴다.
#
#   2. 트레일러가 없으면 제목에서 `type(scope):` 를 떼어 쓴다. 개발자 말투가 남지만
#      빈 줄보다는 낫다 — 트레일러를 빠뜨려도 노트가 통째로 사라지지 않게.
#
# 그리고 feat·fix 만 남겨 타입별로 묶는다(ci·docs·test·chore·refactor 는 우리 사정).
#
# 사용: scripts/release_notes.sh <git-range>
#   예: scripts/release_notes.sh v1.12.0..HEAD
#
# 범위 대신 `-` 를 주면 커밋 제목을 stdin 으로 받는다 — 손으로 확인해 볼 때 쓴다.
# 이 모드에는 트레일러가 없으므로 제목 폴백만 확인된다.
#   예: printf 'fix(a): 가\nchore: 나\n' | scripts/release_notes.sh -
set -euo pipefail

RANGE="${1:?usage: release_notes.sh <git-range>}"

# 한 릴리스에 담을 최대 줄 수. 넘치면 화면이 스크롤만 길어지고 아무도 안 읽는다.
MAX_LINES="${RELEASE_NOTES_MAX:-40}"

# 레코드: 제목 US 트레일러 RS. 트레일러가 여러 줄이어도 한 필드로 접혀 들어온다.
US=$'\037'
RS=$'\036'

if [ "${RANGE}" = "-" ]; then
  # stdin 은 제목만 온다 — 트레일러 필드를 비워 같은 파서를 태운다.
  RAW=$(awk -v us="${US}" -v rs="${RS}" '{ printf "%s%s%s", $0, us, rs }')
else
  RAW=$(git log --no-merges \
    --pretty="format:%s${US}%(trailers:key=Release-Note,valueonly,separator=%x3B%x20)${RS}" \
    "${RANGE}")
fi

FORMATTED=$(printf '%s' "${RAW}" | awk -v RS="${RS}" -v FS="${US}" -v max="${MAX_LINES}" '
  {
    subject = $1
    note    = $2
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", subject)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", note)
    if (subject == "") next

    # feat·fix 만. 타입은 제목에서 읽는다 — 트레일러는 문장일 뿐 분류를 모른다.
    if (!match(subject, /^(feat|fix)(\([^)]*\))?!?:[[:space:]]*/)) next
    type = substr(subject, 1, 3) == "fix" ? "fix" : "feat"

    if (tolower(note) == "skip" || tolower(note) == "none") next
    body = note != "" ? note : substr(subject, RSTART + RLENGTH)
    if (body == "") next

    key = type "\034" body
    if (key in seen) next        # 같은 문장이 두 번(리버트·재적용) 나오면 한 번만
    seen[key] = 1
    if (++n > max) next
    if (type == "feat") feats[++fc] = body
    else                fixes[++xc] = body
  }
  END {
    out = 0
    if (fc) {
      print "새 기능"
      for (i = 1; i <= fc; i++) print "- " feats[i]
      out = 1
    }
    if (xc) {
      if (out) print ""
      print "버그 수정"
      for (i = 1; i <= xc; i++) print "- " fixes[i]
    }
  }
')

if [ -n "${FORMATTED}" ]; then
  printf '%s\n' "${FORMATTED}"
else
  # feat·fix 가 하나도 없거나 전부 skip — 원본 제목이라도 보여 준다. 빈 화면보다 낫다.
  printf '%s' "${RAW}" \
    | awk -v RS="${RS}" -v FS="${US}" '{ if ($1 != "") print "- " $1 }' \
    | head -n "${MAX_LINES}"
fi
