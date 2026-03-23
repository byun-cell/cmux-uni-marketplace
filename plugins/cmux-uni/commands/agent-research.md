---
description: Gemini CLI를 활용해 리서치/분석 작업을 수행하고 결과를 Claude에게 보고합니다.
---

# /agent-research — Gemini 리서치 위임

state.json에서 Gemini surface ID를 읽어 작업을 위임합니다.

## 실행

```bash
HELPER="${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh"
TASK_ID="$(date +%s)"
PROMPT="$@"

# URL이 포함된 경우 브라우저 리서치
if echo "$PROMPT" | grep -qE "https?://"; then
  URL=$(echo "$PROMPT" | grep -oE "https?://[^ ]+")
  QUESTION=$(echo "$PROMPT" | sed "s|$URL||" | xargs)
  bash $HELPER research "$URL" "$QUESTION"
else
  OUT_FILE=$(bash $HELPER gemini "$PROMPT" "$TASK_ID")
  bash $HELPER wait "$OUT_FILE" "$TASK_ID" "" 120
fi
```

결과를 분석하고 사용자에게 요약 보고합니다.
