---
description: Perplexity Pro용 최적화 리서치 프롬프트를 생성하고 결과를 수집합니다.
---

# /perplexity — Perplexity 리서치 위임

Perplexity Pro(구독제)는 CLI 자동화가 불가능하므로,
Claude가 최적화된 프롬프트를 생성하고 사용자가 수동 실행 후 결과를 전달하는 반자동 워크플로우입니다.

## 사용법

- `/perplexity "조사할 내용"` → 프롬프트 생성 + 결과 폴더 준비
- `/perplexity result` → 저장된 결과 파일 읽어서 분석
- `/perplexity result all` → 폴더 내 모든 결과 일괄 분석

## 실행

### 프롬프트 생성 모드 (기본)

인자가 "result"가 아닌 경우:

1. 결과 저장 폴더를 생성합니다:

```bash
PPLX_DIR="$HOME/.cmux-uni/perplexity"
mkdir -p "$PPLX_DIR"
```

2. TASK_ID를 생성합니다: `pplx_{timestamp}`

3. 사용자의 조사 요청을 분석하여 Perplexity Pro에 최적화된 프롬프트를 생성합니다.

프롬프트 생성 규칙:
- **Focus Mode 지정**: 프롬프트 상단에 권장 Focus 명시 ([Focus: Web], [Focus: Academic] 등)
- **구조화**: 배경 → 핵심 질문 → 기대 출력 형식 순서
- **한국어 우선**: 영문 키워드는 괄호 병기
- **출처 요청**: "출처 URL을 반드시 포함해주세요" 문구 추가

4. 아래 형식으로 출력합니다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Perplexity 리서치 요청 — {task_id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 권장 Focus: {focus_mode}

{최적화된 프롬프트}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 결과 저장 경로: ~/.cmux-uni/perplexity/{task_id}.md
💡 Perplexity 결과를 위 파일에 저장하거나,
   이 대화에 직접 붙여넣기 해주세요.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 결과 수집 모드

인자가 "result"인 경우:

1. `~/.cmux-uni/perplexity/` 폴더의 .md 파일 목록을 확인합니다:

```bash
ls -lt "$HOME/.cmux-uni/perplexity/"*.md 2>/dev/null | head -10
```

2. "all" 인자가 있으면 모든 파일을, 없으면 가장 최근 파일을 읽습니다.

3. 결과를 분석하여 현재 작업 컨텍스트에 맞게 요약합니다:
   - Perplexity 출처(Sources)는 반드시 보존하여 인용
   - 수치 데이터는 출처와 함께 표로 정리
   - 상충되는 정보는 출처별로 비교
