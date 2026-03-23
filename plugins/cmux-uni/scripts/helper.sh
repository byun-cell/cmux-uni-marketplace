#!/usr/bin/env bash
# ============================================================
# cmux-uni helper.sh
# Claude Code 오케스트레이터 ↔ Gemini/Copilot 서브에이전트 통신
# surface ID를 동적으로 생성하고 state.json에 저장
# ============================================================

# 플러그인 루트 기준 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# cmux 바이너리 탐색
if command -v cmux &>/dev/null; then
  CMUX="cmux"
elif [ -x "/Applications/cmux.app/Contents/Resources/bin/cmux" ]; then
  CMUX="/Applications/cmux.app/Contents/Resources/bin/cmux"
elif [ -x "$HOME/.local/bin/cmux" ]; then
  CMUX="$HOME/.local/bin/cmux"
else
  echo "[✗] cmux를 찾을 수 없습니다. cmux를 먼저 설치하세요."
  exit 1
fi

# 런타임 디렉토리 (사용자별, 플러그인 밖)
RUNTIME_DIR="$HOME/.cmux-uni"
RESULTS_DIR="$RUNTIME_DIR/results"
PERPLEXITY_DIR="$RUNTIME_DIR/perplexity"
STATE_FILE="$RUNTIME_DIR/state.json"
mkdir -p "$RESULTS_DIR" "$PERPLEXITY_DIR"

# ── 색상 출력 ───────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

log()    { echo -e "${CYAN}[cmux-uni]${NC} $1"; }
success(){ echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; }

# ── state.json에서 surface ID 로드 ──────────────────────────
load_state() {
  if [ ! -f "$STATE_FILE" ]; then
    error "상태 파일 없음: $STATE_FILE"
    error "먼저 './helper.sh start' 로 에이전트를 구동하세요"
    exit 1
  fi
  GEMINI_SURFACE=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d['gemini_surface'])" 2>/dev/null)
  COPILOT_SURFACE=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d['copilot_surface'])" 2>/dev/null)
  AGENT_WORKSPACE=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d['workspace'])" 2>/dev/null)

  if [ -z "$GEMINI_SURFACE" ] || [ -z "$COPILOT_SURFACE" ]; then
    error "상태 파일 파싱 실패: $STATE_FILE"
    exit 1
  fi
}

# ── state.json 저장 ─────────────────────────────────────────
save_state() {
  local gemini="$1" copilot="$2" workspace="$3"
  cat > "$STATE_FILE" <<EOF
{
  "gemini_surface": "$gemini",
  "copilot_surface": "$copilot",
  "workspace": "$workspace",
  "started_at": "$(date '+%Y-%m-%dT%H:%M:%S')"
}
EOF
  success "상태 저장 완료: $STATE_FILE"
}

# ── 에이전트 구동 (동적 surface 생성) ───────────────────────
start_agents() {
  local CALLER_INFO
  CALLER_INFO=$($CMUX identify 2>&1)
  local CALLER_PANE
  CALLER_PANE=$(echo "$CALLER_INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['caller']['pane_ref'])" 2>/dev/null)
  local CALLER_WS
  CALLER_WS=$(echo "$CALLER_INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['caller']['workspace_ref'])" 2>/dev/null)

  log "에이전트 구동 시작 (workspace: $CALLER_WS, pane: $CALLER_PANE)"

  # 구동 전 surface 목록
  local BEFORE
  BEFORE=$($CMUX tree --all 2>/dev/null | grep -oE 'surface:[0-9]+' | sort -t: -k2 -n)

  # 탭 1 생성 (Gemini)
  log "Gemini 탭 생성 중..."
  $CMUX new-surface --pane "$CALLER_PANE" --workspace "$CALLER_WS" > /dev/null 2>&1
  sleep 0.5

  # 탭 2 생성 (Copilot)
  log "Copilot 탭 생성 중..."
  $CMUX new-surface --pane "$CALLER_PANE" --workspace "$CALLER_WS" > /dev/null 2>&1
  sleep 0.5

  # 새로 생성된 surface ID 추출
  local AFTER
  AFTER=$($CMUX tree --all 2>/dev/null | grep -oE 'surface:[0-9]+' | sort -t: -k2 -n)
  local NEW_SURFACES
  NEW_SURFACES=$(comm -13 <(echo "$BEFORE") <(echo "$AFTER"))
  local GEMINI_SURFACE
  GEMINI_SURFACE=$(echo "$NEW_SURFACES" | head -1)
  local COPILOT_SURFACE
  COPILOT_SURFACE=$(echo "$NEW_SURFACES" | tail -1)

  if [ -z "$GEMINI_SURFACE" ] || [ -z "$COPILOT_SURFACE" ]; then
    error "새 surface ID 감지 실패"
    return 1
  fi

  # Gemini 실행
  log "Gemini 실행 → $GEMINI_SURFACE"
  $CMUX send --workspace "$CALLER_WS" --surface "$GEMINI_SURFACE" "gemini"
  $CMUX send-key --workspace "$CALLER_WS" --surface "$GEMINI_SURFACE" Return

  sleep 1

  # Copilot 실행
  log "Copilot 실행 → $COPILOT_SURFACE"
  $CMUX send --workspace "$CALLER_WS" --surface "$COPILOT_SURFACE" "gh copilot"
  $CMUX send-key --workspace "$CALLER_WS" --surface "$COPILOT_SURFACE" Return

  # 상태 저장
  save_state "$GEMINI_SURFACE" "$COPILOT_SURFACE" "$CALLER_WS"

  sleep 2
  echo ""
  success "에이전트 구동 완료!"
  echo "  🔵 Gemini CLI  → $GEMINI_SURFACE"
  echo "  🟢 Copilot CLI → $COPILOT_SURFACE"
  echo "  📁 workspace   → $CALLER_WS"
}

# ── 에이전트 상태 확인 ──────────────────────────────────────
check_agents() {
  load_state
  log "에이전트 상태 확인 중... (workspace: $AGENT_WORKSPACE)"
  echo ""

  # Gemini 확인
  local GEMINI_OUT
  GEMINI_OUT=$($CMUX capture-pane --workspace "$AGENT_WORKSPACE" --surface "$GEMINI_SURFACE" --lines 10 2>&1)
  if echo "$GEMINI_OUT" | grep -qiE "Type your message|workspace|sandbox|gemini"; then
    success "Gemini CLI    [$GEMINI_SURFACE] ✅ 준비됨"
  else
    warn    "Gemini CLI    [$GEMINI_SURFACE] ⚠️  상태 불명"
    echo "   마지막 출력: $(echo "$GEMINI_OUT" | tail -3)"
  fi

  # Copilot 확인
  local COPILOT_OUT
  COPILOT_OUT=$($CMUX capture-pane --workspace "$AGENT_WORKSPACE" --surface "$COPILOT_SURFACE" --lines 10 2>&1)
  if echo "$COPILOT_OUT" | grep -qiE "Type @|❯|~/|shift\+tab"; then
    success "GitHub Copilot[$COPILOT_SURFACE] ✅ 준비됨"
  else
    warn    "GitHub Copilot[$COPILOT_SURFACE] ⚠️  상태 불명"
    echo "   마지막 출력: $(echo "$COPILOT_OUT" | tail -3)"
  fi
  echo ""
}

# ── Gemini에 작업 위임 (비대화형) ───────────────────────────
delegate_gemini() {
  load_state
  local PROMPT="$1"
  local TASK_ID="${2:-$(date +%s)}"
  local OUT_FILE="$RESULTS_DIR/gemini_${TASK_ID}.txt"

  log "Gemini에 작업 위임: $TASK_ID"
  log "프롬프트: ${PROMPT:0:80}..."

  $CMUX send --workspace "$AGENT_WORKSPACE" --surface "$GEMINI_SURFACE" \
    "gemini -p \"$PROMPT\" --yolo 2>&1 | tee $OUT_FILE && echo '[DONE:$TASK_ID]'"
  $CMUX send-key --workspace "$AGENT_WORKSPACE" --surface "$GEMINI_SURFACE" Return

  echo "$OUT_FILE"
}

# ── Copilot에 작업 위임 (비대화형) ──────────────────────────
delegate_copilot() {
  load_state
  local PROMPT="$1"
  local TASK_ID="${2:-$(date +%s)}"
  local OUT_FILE="$RESULTS_DIR/copilot_${TASK_ID}.txt"

  log "Copilot에 작업 위임: $TASK_ID"
  log "프롬프트: ${PROMPT:0:80}..."

  $CMUX send --workspace "$AGENT_WORKSPACE" --surface "$COPILOT_SURFACE" \
    "gh copilot -- -p \"$PROMPT\" --yolo 2>&1 | tee $OUT_FILE && echo '[DONE:$TASK_ID]'"
  $CMUX send-key --workspace "$AGENT_WORKSPACE" --surface "$COPILOT_SURFACE" Return

  echo "$OUT_FILE"
}

# ── 결과 대기 및 수집 ───────────────────────────────────────
wait_for_result() {
  load_state
  local OUT_FILE="$1"
  local TASK_ID="$2"
  local SURFACE="$3"
  local TIMEOUT="${4:-120}"
  local ELAPSED=0

  log "결과 대기 중: $TASK_ID (최대 ${TIMEOUT}초)"

  while [ $ELAPSED -lt $TIMEOUT ]; do
    local SCREEN
    SCREEN=$($CMUX capture-pane --workspace "$AGENT_WORKSPACE" --surface "$SURFACE" --lines 5 2>&1)
    if echo "$SCREEN" | grep -q "\[DONE:$TASK_ID\]"; then
      success "작업 완료: $TASK_ID"
      break
    fi
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    echo -n "."
  done

  echo ""

  if [ -f "$OUT_FILE" ]; then
    cat "$OUT_FILE"
  else
    warn "결과 파일 없음: $OUT_FILE"
    $CMUX capture-pane --workspace "$AGENT_WORKSPACE" --surface "$SURFACE" --lines 50 2>&1
  fi
}

# ── 병렬 작업 위임 ──────────────────────────────────────────
parallel_delegate() {
  local GEMINI_PROMPT="$1"
  local COPILOT_PROMPT="$2"
  local TASK_ID
  TASK_ID="$(date +%s)"

  log "병렬 작업 시작: $TASK_ID"

  local GEMINI_FILE
  GEMINI_FILE=$(delegate_gemini "$GEMINI_PROMPT" "${TASK_ID}_g")
  local COPILOT_FILE
  COPILOT_FILE=$(delegate_copilot "$COPILOT_PROMPT" "${TASK_ID}_c")

  echo ""
  log "═══ Gemini 결과 ════════════════════"
  wait_for_result "$GEMINI_FILE" "${TASK_ID}_g" "$GEMINI_SURFACE" 60

  log "═══ Copilot 결과 ═══════════════════"
  wait_for_result "$COPILOT_FILE" "${TASK_ID}_c" "$COPILOT_SURFACE" 60
}

# ── 브라우저로 리서치 후 Gemini에 전달 ─────────────────────
browser_research_to_gemini() {
  load_state
  local URL="$1"
  local PROMPT="$2"
  local TASK_ID
  TASK_ID="$(date +%s)"

  local BROWSER_SURFACE
  BROWSER_SURFACE=$($CMUX tree --workspace "$AGENT_WORKSPACE" --json 2>/dev/null | \
    python3 -c "
import json,sys
d=json.load(sys.stdin)
for w in d.get('windows',[]):
  for ws in w.get('workspaces',[]):
    for p in ws.get('panes',[]):
      for s in p.get('surfaces',[]):
        if s.get('type')=='browser':
          print(s['ref']); exit()
" 2>/dev/null)

  if [ -z "$BROWSER_SURFACE" ]; then
    warn "브라우저 surface 없음 — 새로 생성"
    $CMUX new-pane --type browser --workspace "$AGENT_WORKSPACE" > /dev/null 2>&1
    sleep 1
    BROWSER_SURFACE=$($CMUX tree --workspace "$AGENT_WORKSPACE" --json 2>/dev/null | \
      python3 -c "
import json,sys
d=json.load(sys.stdin)
for w in d.get('windows',[]):
  for ws in w.get('workspaces',[]):
    for p in ws.get('panes',[]):
      for s in p.get('surfaces',[]):
        if s.get('type')=='browser':
          print(s['ref']); exit()
" 2>/dev/null)
  fi

  log "브라우저 리서치: $URL → $BROWSER_SURFACE"
  $CMUX browser goto "$URL" --surface "$BROWSER_SURFACE"
  sleep 3

  local PAGE_TEXT
  PAGE_TEXT=$($CMUX browser get text --surface "$BROWSER_SURFACE" 2>&1 | head -200)
  local FULL_PROMPT="다음 웹페이지 내용을 참고하여 분석해줘:\n\n$PAGE_TEXT\n\n질문: $PROMPT"

  delegate_gemini "$FULL_PROMPT" "$TASK_ID"
}

# ── 에이전트 화면 캡처 ──────────────────────────────────────
capture_agent() {
  load_state
  local AGENT="${1:-gemini}"
  local LINES="${2:-50}"

  case $AGENT in
    gemini)  $CMUX capture-pane --workspace "$AGENT_WORKSPACE" --surface "$GEMINI_SURFACE" --lines "$LINES" ;;
    copilot) $CMUX capture-pane --workspace "$AGENT_WORKSPACE" --surface "$COPILOT_SURFACE" --lines "$LINES" ;;
    *)       error "알 수 없는 에이전트: $AGENT" ;;
  esac
}

# ── Perplexity 결과 폴더 준비 ────────────────────────────────
pplx_init() {
  local TASK_ID="pplx_$(date +%s)"
  local OUT_FILE="$PERPLEXITY_DIR/${TASK_ID}.md"
  mkdir -p "$PERPLEXITY_DIR"
  success "Perplexity 결과 폴더 준비 완료"
  echo "  📂 저장 경로: $PERPLEXITY_DIR/"
  echo "  📝 결과 파일: $OUT_FILE"
  echo "$TASK_ID"
}

# ── Perplexity 결과 목록 ────────────────────────────────────
pplx_list() {
  if ls "$PERPLEXITY_DIR"/*.md 1>/dev/null 2>&1; then
    log "Perplexity 결과 목록:"
    ls -lt "$PERPLEXITY_DIR"/*.md | head -20
  else
    warn "Perplexity 결과 파일 없음: $PERPLEXITY_DIR/"
  fi
}

# ── Perplexity 최신 결과 읽기 ────────────────────────────────
pplx_latest() {
  local LATEST
  LATEST=$(ls -t "$PERPLEXITY_DIR"/*.md 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    success "최신 결과: $LATEST"
    cat "$LATEST"
  else
    warn "결과 파일 없음: $PERPLEXITY_DIR/"
  fi
}

# ── Perplexity 전체 결과 읽기 ────────────────────────────────
pplx_all() {
  if ls "$PERPLEXITY_DIR"/*.md 1>/dev/null 2>&1; then
    for f in "$PERPLEXITY_DIR"/*.md; do
      log "═══ $(basename "$f") ═══════════════════"
      cat "$f"
      echo ""
    done
  else
    warn "결과 파일 없음: $PERPLEXITY_DIR/"
  fi
}

# ── 메인 디스패처 ───────────────────────────────────────────
case "${1:-help}" in
  start)        start_agents ;;
  status)       check_agents ;;
  gemini)       delegate_gemini "$2" "$3" ;;
  copilot)      delegate_copilot "$2" "$3" ;;
  parallel)     parallel_delegate "$2" "$3" ;;
  capture)      capture_agent "$2" "$3" ;;
  research)     browser_research_to_gemini "$2" "$3" ;;
  wait)         wait_for_result "$2" "$3" "$4" "$5" ;;
  pplx-init)    pplx_init ;;
  pplx-list)    pplx_list ;;
  pplx-latest)  pplx_latest ;;
  pplx-all)     pplx_all ;;
  help|*)
    echo ""
    echo "cmux-uni helper.sh - Claude Code 멀티에이전트 헬퍼"
    echo ""
    echo "사용법:"
    echo "  ./helper.sh start                             # 에이전트 구동 (동적 surface 생성)"
    echo "  ./helper.sh status                            # 에이전트 상태 확인"
    echo "  ./helper.sh gemini \"프롬프트\" [task_id]       # Gemini에 위임"
    echo "  ./helper.sh copilot \"프롬프트\" [task_id]      # Copilot에 위임"
    echo "  ./helper.sh parallel \"g프롬프트\" \"c프롬프트\"  # 병렬 위임"
    echo "  ./helper.sh capture [gemini|copilot] [lines]  # 화면 캡처"
    echo "  ./helper.sh research \"URL\" \"질문\"             # 브라우저 리서치"
    echo "  ./helper.sh pplx-init                          # Perplexity 결과 폴더 준비"
    echo "  ./helper.sh pplx-list                          # Perplexity 결과 목록"
    echo "  ./helper.sh pplx-latest                        # 최신 Perplexity 결과 읽기"
    echo "  ./helper.sh pplx-all                           # 전체 Perplexity 결과 읽기"
    echo ""
    ;;
esac
