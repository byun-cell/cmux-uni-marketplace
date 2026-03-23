---
description: Claude가 오케스트레이터로서 Gemini와 Copilot을 서브에이전트로 조율하는 멀티에이전트 작업을 실행합니다.
---

# /multi-agent — 멀티에이전트 병렬 작업

state.json에서 surface ID를 동적으로 읽어 Gemini와 Copilot에 병렬로 작업을 위임합니다.

## 아키텍처

```
Claude (오케스트레이터)
├── Gemini  → 리서치/분석
└── Copilot → 코드 구현
```

## 실행

```bash
HELPER="${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh"
GEMINI_PROMPT="$1"
COPILOT_PROMPT="$2"

bash $HELPER parallel "$GEMINI_PROMPT" "$COPILOT_PROMPT"
```

두 결과를 종합하여 사용자에게 통합 보고합니다.
