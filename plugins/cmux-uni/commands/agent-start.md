---
description: cmux-uni 에이전트 구동 — 현재 pane에 탭 2개를 동적으로 생성하고 Gemini와 Copilot을 각각 실행합니다.
---

# /agent-start — 에이전트 구동

현재 Claude 터미널의 pane에 새 탭 2개를 동적으로 생성하고
Gemini CLI와 GitHub Copilot을 실행한 뒤 surface ID를 state.json에 저장합니다.

## 트리거 키워드
- "에이전트 구동"
- "에이전트 시작"
- "agent start"
- "/agent-start"

## 실행

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh start
```

결과에서 Gemini/Copilot의 surface ID와 상태를 확인하고 사용자에게 보고합니다.
