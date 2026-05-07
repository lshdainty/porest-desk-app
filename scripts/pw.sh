#!/usr/bin/env bash
# pw.sh — explore_driver 에 명령 보내고 응답 받기
# 사용: pw.sh '<json>' [timeout_sec]
set -e
CMD_JSON="$1"
TIMEOUT="${2:-15}"
CMD_DIR=/tmp/pw-cmd
OUT_DIR=/tmp/pw-out
mkdir -p "$CMD_DIR" "$OUT_DIR"

# 다음 seq 결정 (cmd-N.json 에서 가장 큰 N + 1)
SEQ=0
for f in "$OUT_DIR"/cmd-*.json; do
  [ -e "$f" ] || break
  n=$(basename "$f" | sed 's/cmd-\([0-9]*\)\.json/\1/')
  if [ "$n" -ge "$SEQ" ]; then SEQ=$((n+1)); fi
done

CMD_FILE="$CMD_DIR/cmd-$SEQ.json"
OUT_FILE="$OUT_DIR/cmd-$SEQ.json"
echo "$CMD_JSON" > "$CMD_FILE"

WAITED=0
while [ ! -f "$OUT_FILE" ]; do
  sleep 0.25
  WAITED=$((WAITED+1))
  if [ $WAITED -gt $((TIMEOUT*4)) ]; then
    echo '{"ok":false,"error":"timeout"}' >&2
    exit 1
  fi
done

cat "$OUT_FILE"
echo
