# cmux-uni — Claude Code Multi-Agent Orchestrator

Claude Code를 오케스트레이터로 사용하여 **Gemini CLI**(리서치), **GitHub Copilot CLI**(코드), **Perplexity Pro**(심층 검색)를 서브에이전트로 조율하는 멀티에이전트 플러그인입니다.

## Prerequisites

- [cmux](https://cmux.dev) — 터미널 멀티플렉서
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) — `npm install -g @google/gemini-cli` or `brew install gemini`
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) — `gh extension install github/gh-copilot`
- [Perplexity Pro](https://perplexity.ai) — 구독 계정 (반자동 워크플로우)

## Installation

```bash
# Claude Code에서 마켓플레이스 등록
/plugin marketplace add https://github.com/byun-cell/cmux-uni-marketplace

# 플러그인 설치
/plugin install cmux-uni
```

## Commands

### Automated Agents (CLI 자동화)

| Command | Description |
|---------|-------------|
| `/agent-start` | Gemini + Copilot 서브에이전트 구동 (cmux 탭 자동 생성) |
| `/agent-status` | 에이전트 상태 확인 |
| `/delegate gemini "질문"` | Gemini에 리서치 위임 |
| `/delegate copilot "작업"` | Copilot에 코드 작업 위임 |
| `/multi-agent "리서치" "코드"` | Gemini + Copilot 병렬 작업 |
| `/agent-research "질문"` | Gemini 리서치 특화 (URL 자동 감지) |
| `/agent-code "작업"` | Copilot 코드 작업 특화 |

### Semi-Automated Agent (반자동 워크플로우)

| Command | Description |
|---------|-------------|
| `/perplexity "조사 내용"` | Perplexity용 최적화 프롬프트 생성 |
| `/perplexity result` | 최신 결과 파일 읽기 및 분석 |
| `/perplexity result all` | 전체 결과 일괄 분석 |

### Utility

| Command | Description |
|---------|-------------|
| `/clear-ready` | 세션 컨텍스트 저장 후 재개 프롬프트 생성 |

## Architecture

```
Claude Code (Orchestrator)
├── Gemini CLI        → Research, Analysis, Translation, Ideas     [automated]
├── Copilot CLI       → Code Generation, Review, Refactoring       [automated]
├── Perplexity Pro    → Deep Research, Citations, Market Intel      [semi-auto]
└── cmux Browser      → Web Research (optional)                    [automated]
```

### Perplexity 워크플로우

```
1. /perplexity "조사할 내용"
   → Claude가 Perplexity에 최적화된 프롬프트 생성
   → 결과 저장 폴더(~/.cmux-uni/perplexity/) 자동 생성

2. 사용자가 Perplexity에서 프롬프트 실행
   → 결과를 ~/.cmux-uni/perplexity/pplx_{id}.md에 저장
   → 또는 대화에 직접 붙여넣기

3. /perplexity result (또는 "결과 확인해줘")
   → Claude가 결과를 읽고 분석에 통합
```

## Runtime Data

| Path | Purpose |
|------|---------|
| `~/.cmux-uni/state.json` | Agent surface ID 상태 |
| `~/.cmux-uni/results/` | Gemini/Copilot 실행 결과 |
| `~/.cmux-uni/perplexity/` | Perplexity 결과 파일 |

## License

MIT
