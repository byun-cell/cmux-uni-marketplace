---
description: GitHub Copilot CLI를 활용해 코드 구현/리뷰 작업을 수행하고 결과를 Claude에게 보고합니다.
---

# /agent-code — Copilot 코드 작업 위임

state.json에서 Copilot surface ID를 읽어 작업을 위임합니다.

## 실행

```bash
HELPER="${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh"
TASK_ID="$(date +%s)"
PROMPT="$@"

OUT_FILE=$(bash $HELPER copilot "$PROMPT" "$TASK_ID")
bash $HELPER wait "$OUT_FILE" "$TASK_ID" "" 180
```

결과를 분석하고 사용자에게 요약 보고합니다.
