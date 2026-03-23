---
description: Gemini 또는 Copilot 서브에이전트에 작업을 위임하고 결과를 받아옵니다.
---

# /delegate — 서브에이전트 위임

state.json에서 surface ID를 동적으로 읽어 지정한 에이전트에 위임합니다.

## 사용법

- `/delegate gemini "질문"` → Gemini CLI에 위임
- `/delegate copilot "작업"` → GitHub Copilot에 위임

## 실행

```bash
HELPER="${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh"
AGENT="$1"
PROMPT="$2"
TASK_ID="$(date +%s)"

case "$AGENT" in
  gemini|g)
    OUT_FILE=$(bash $HELPER gemini "$PROMPT" "$TASK_ID")
    bash $HELPER wait "$OUT_FILE" "$TASK_ID" "" 120
    ;;
  copilot|c)
    OUT_FILE=$(bash $HELPER copilot "$PROMPT" "$TASK_ID")
    bash $HELPER wait "$OUT_FILE" "$TASK_ID" "" 180
    ;;
  *)
    echo "에이전트를 지정하세요: gemini 또는 copilot"
    ;;
esac
```

결과를 분석하고 사용자에게 요약 보고합니다.
