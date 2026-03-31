---
description: Gemini 또는 Copilot 서브에이전트에 작업을 위임하고 결과를 받아옵니다.
---

# /delegate — 서브에이전트 위임

state.json에서 surface ID를 동적으로 읽어 지정한 에이전트에 위임합니다.

## 사용법

- `/delegate gemini "질문"` → Gemini CLI에 위임 (자동)
- `/delegate copilot "작업"` → GitHub Copilot에 위임 (자동)
- `/delegate perplexity "조사"` → Perplexity 프롬프트 생성 (반자동)

## 실행

```bash
HELPER="${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh"
STATE_FILE="$HOME/.claude/cmux-uni/state.json"
AGENT="$1"
PROMPT="$2"
TASK_ID="$(date +%s)"

# state.json에서 surface ID 로드
GEMINI_SURFACE=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['gemini_surface'])" 2>/dev/null)
COPILOT_SURFACE=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['copilot_surface'])" 2>/dev/null)

case "$AGENT" in
  gemini|g)
    OUT_FILE=$(bash $HELPER gemini "$PROMPT" "$TASK_ID")
    bash $HELPER wait "$OUT_FILE" "$TASK_ID" "$GEMINI_SURFACE" 120
    ;;
  copilot|c)
    OUT_FILE=$(bash $HELPER copilot "$PROMPT" "$TASK_ID")
    bash $HELPER wait "$OUT_FILE" "$TASK_ID" "$COPILOT_SURFACE" 180
    ;;
  perplexity|pplx|p)
    # 반자동: 프롬프트 생성 모드로 전환
    bash $HELPER pplx-init
    echo "PROMPT: $PROMPT"
    ;;
  *)
    echo "에이전트를 지정하세요: gemini, copilot, 또는 perplexity"
    ;;
esac
```

결과를 분석하고 사용자에게 요약 보고합니다.
- gemini/copilot: 자동으로 결과 수집
- perplexity: 프롬프트 생성 후, 사용자가 결과를 `~/.claude/cmux-uni/perplexity/`에 저장하면 `/perplexity result`로 수집
