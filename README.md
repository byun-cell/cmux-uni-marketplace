# cmux-uni — Claude Code Multi-Agent Orchestrator

Claude Code를 오케스트레이터로 사용하여 **Gemini CLI**(리서치)와 **GitHub Copilot CLI**(코드)를 서브에이전트로 조율하는 멀티에이전트 플러그인입니다.

## Prerequisites

- [cmux](https://cmux.dev) — 터미널 멀티플렉서
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) — `npm install -g @anthropic-ai/gemini-cli` or `brew install gemini`
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) — `gh extension install github/gh-copilot`

## Installation

```bash
# Claude Code에서 마켓플레이스 등록
/plugin marketplace add https://github.com/eximtech/cmux-uni-marketplace

# 플러그인 설치
/plugin install cmux-uni
```

## Commands

| Command | Description |
|---------|-------------|
| `/agent-start` | Gemini + Copilot 서브에이전트 구동 (cmux 탭 자동 생성) |
| `/agent-status` | 에이전트 상태 확인 |
| `/delegate gemini "질문"` | Gemini에 리서치 위임 |
| `/delegate copilot "작업"` | Copilot에 코드 작업 위임 |
| `/multi-agent "리서치" "코드"` | Gemini + Copilot 병렬 작업 |
| `/agent-research "질문"` | Gemini 리서치 특화 (URL 자동 감지) |
| `/agent-code "작업"` | Copilot 코드 작업 특화 |
| `/clear-ready` | 세션 컨텍스트 저장 후 재개 프롬프트 생성 |

## Architecture

```
Claude Code (Orchestrator)
├── Gemini CLI   → Research, Analysis, Translation, Ideas
├── Copilot CLI  → Code Generation, Review, Refactoring, Tests
└── cmux Browser → Web Research (optional)
```

## How It Works

1. `/agent-start` — cmux 터미널에 새 탭 2개를 자동 생성하고 Gemini/Copilot 실행
2. Surface ID가 `~/.cmux-uni/state.json`에 동적 저장
3. `/delegate` 또는 `/multi-agent`로 작업 위임 시 cmux API로 에이전트에 명령 전달
4. 결과를 `~/.cmux-uni/results/`에 저장하고 Claude가 종합 보고

## License

MIT
