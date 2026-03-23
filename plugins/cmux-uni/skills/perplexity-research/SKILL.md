---
name: perplexity-research
description: Perplexity Pro를 반자동 리서치 에이전트로 활용 — 프롬프트 생성, 결과 수집, 분석 통합
version: 1.0.0
---

# Perplexity Research — 반자동 리서치 에이전트

Perplexity Pro(구독제)를 활용한 심층 리서치 워크플로우.
Claude가 최적화된 프롬프트를 생성하고, 사용자가 Perplexity에서 실행한 뒤,
결과를 지정 폴더에 저장하면 Claude가 읽어서 분석에 통합합니다.

## 워크플로우

```
Claude (프롬프트 생성)
  ↓ 프롬프트 출력
User (Perplexity에 붙여넣기 → 실행)
  ↓ 결과 복사/저장
~/.cmux-uni/perplexity/{task_id}.md
  ↓ "결과 확인해줘"
Claude (결과 읽기 → 분석 통합)
```

## 트리거 키워드

다음 키워드가 감지되면 이 스킬을 자동 활성화:

- "perplexity", "퍼플렉시티", "심층 검색", "deep research"
- "최신 정보 조사", "실시간 검색", "소스 포함 조사"
- "/perplexity", "/pplx"

## 프롬프트 생성 규칙

Perplexity Pro에 최적화된 프롬프트를 생성할 때:

1. **Focus Mode 지정**: 프롬프트 상단에 권장 Focus 명시
   - `[Focus: Web]` — 일반 웹 검색
   - `[Focus: Academic]` — 논문/학술 자료
   - `[Focus: Writing]` — 작문/분석
   - `[Focus: Math]` — 수치/계산
   - `[Focus: Video]` — 영상 자료
   - `[Focus: Social]` — SNS/커뮤니티
2. **구조화된 질문**: 배경 → 핵심 질문 → 기대 출력 형식
3. **한국어 우선**: 한국어로 프롬프트 작성 (영문 키워드는 괄호 병기)
4. **출처 요청**: "출처 URL을 반드시 포함해주세요" 문구 추가

## 프롬프트 출력 형식

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Perplexity 리서치 요청 — {task_id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 권장 Focus: {focus_mode}

{프롬프트 내용}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 결과 저장 경로: ~/.cmux-uni/perplexity/{task_id}.md
💡 Perplexity 결과를 위 파일에 저장하거나,
   이 대화에 직접 붙여넣기 해주세요.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 결과 수집

사용자가 결과를 전달하는 3가지 방법:

1. **파일 저장**: `~/.cmux-uni/perplexity/{task_id}.md`에 저장 → "결과 확인해줘"
2. **직접 붙여넣기**: 대화에 직접 Perplexity 결과를 붙여넣기
3. **여러 결과 일괄**: 폴더에 여러 .md 파일 저장 → "perplexity 결과 전부 읽어줘"

## 결과 분석 시 규칙

- Perplexity 출처(Sources)는 반드시 보존하여 인용
- 수치 데이터는 출처와 함께 표로 정리
- 상충되는 정보가 있으면 출처별로 비교 정리
- 현재 작업 컨텍스트에 맞게 핵심만 추출하여 요약

## Do NOT use for

- CLI로 자동화 가능한 단순 검색 (Gemini 사용)
- 코드 관련 질문 (Copilot 사용)
- 실시간성이 필요 없는 일반 지식 질문 (Claude 직접 답변)
