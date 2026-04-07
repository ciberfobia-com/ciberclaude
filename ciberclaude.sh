#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  ciberclaude — AI coding statusline
#  Compatibilidad: Claude Code · Gemini CLI · Codex CLI
#  github.com/ciberfobia-com/ciberclaude
#  By Ciberfobia · ciberfobia.com
# ─────────────────────────────────────────────────────────────

INPUT=$(head -c 65536)

if ! command -v jq &>/dev/null; then
  printf 'ciberclaude: instala jq → brew install jq / apt install jq\n'
  exit 0
fi

# ── Detectar herramienta ──────────────────────────────────────
# Claude Code:  tiene context_window
# Codex CLI:    tiene permission_mode (sin context_window)
# Gemini CLI:   tiene hook_event_name (sin permission_mode ni context_window)
TOOL="unknown"
if printf '%s' "$INPUT" | jq -e '.context_window' &>/dev/null; then
  TOOL="claude"
elif printf '%s' "$INPUT" | jq -e '.permission_mode' &>/dev/null; then
  TOOL="codex"
elif printf '%s' "$INPUT" | jq -e '.hook_event_name' &>/dev/null; then
  TOOL="gemini"
fi

# ── Sanitizar strings de usuario antes de printf %b ──────────
_san() { printf '%s' "$1" | tr -d '\\\000-\037\177'; }

# ── Colores ANSI ──────────────────────────────────────────────
R='\033[0m'; DIM='\033[2m'; CYAN='\033[36m'
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
SEP="${DIM} · ${R}"

# ── Corazón animado (rota de color cada 20 segundos) ─────────
_TS=$(date +%s)
_HI=$(( (_TS / 20) % 7 ))
case "$_HI" in
  0) HEART="❤️"  ;; 1) HEART="🧡" ;; 2) HEART="💛" ;;
  3) HEART="💚" ;; 4) HEART="💙" ;; 5) HEART="💜" ;; 6) HEART="🩷" ;;
esac

# ── Rama git del directorio actual ───────────────────────────
_git_branch() {
  local dir="$1"
  if [ -n "$dir" ] && command -v git &>/dev/null; then
    git -C "$dir" branch --show-current 2>/dev/null || true
  fi
}

# ═══════════════════════════════════════════════════════════════
#  CLAUDE CODE
# ═══════════════════════════════════════════════════════════════
if [ "$TOOL" = "claude" ]; then
  MODEL=$(   printf '%s' "$INPUT" | jq -r '.model.display_name // "–"')
  PCT_RAW=$( printf '%s' "$INPUT" | jq -r '.context_window.used_percentage // 0')
  COST=$(    printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // 0')
  CWD=$(     printf '%s' "$INPUT" | jq -r '.cwd // ""')
  FIVE_H=$(  printf '%s' "$INPUT" | jq -r 'if (.rate_limits.five_hour.used_percentage | type) == "number" then .rate_limits.five_hour.used_percentage else "" end')
  SEVEN_D=$( printf '%s' "$INPUT" | jq -r 'if (.rate_limits.seven_day.used_percentage | type) == "number" then .rate_limits.seven_day.used_percentage else "" end')
  PERMS=$(   printf '%s' "$INPUT" | jq -r '.permissions.mode // ""')

  MODEL=$(_san "$MODEL"); PERMS=$(_san "$PERMS")
  PROJECT=$(_san "$(basename "${CWD:-/unknown}")")
  [ -z "$PROJECT" ] || [ "$PROJECT" = "/" ] && PROJECT="–"
  GIT_BRANCH=$(_san "$(_git_branch "$CWD")")

  PCT=$(printf '%.0f' "${PCT_RAW:-0}" 2>/dev/null || echo "0")
  COST_FMT="\$$(printf '%.2f' "${COST:-0}" 2>/dev/null || echo "0.00")"

  FILL=$(( PCT / 10 )); [ "$FILL" -gt 10 ] && FILL=10
  BAR=""
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ "$i" -le "$FILL" ] && BAR="${BAR}█" || BAR="${BAR}░"
  done
  [ "$PCT" -ge 80 ] && CBAR="$RED" || { [ "$PCT" -ge 50 ] && CBAR="$YELLOW" || CBAR="$GREEN"; }

  L1="${CYAN}⚡ ${MODEL}${R}"
  L1="${L1}${SEP}${CBAR}${BAR} ${PCT}%${R}"
  L1="${L1}${SEP}${DIM}${COST_FMT}${R}"
  L1="${L1}${SEP}📁 ${PROJECT}"
  [ -n "$GIT_BRANCH" ] && L1="${L1}${DIM} (${GIT_BRANCH})${R}"
  [ "$PERMS" = "auto" ] && L1="${L1}${SEP}${YELLOW}🔓 auto${R}"

  L2="${HEART}"
  if [ -n "$FIVE_H" ] && [ -n "$SEVEN_D" ]; then
    FH=$(printf '%.0f' "$FIVE_H"); SD=$(printf '%.0f' "$SEVEN_D")
    [ "$FH" -ge 80 ] && C5="$RED" || { [ "$FH" -ge 50 ] && C5="$YELLOW" || C5="$DIM"; }
    [ "$SD" -ge 80 ] && C7="$RED" || { [ "$SD" -ge 50 ] && C7="$YELLOW" || C7="$DIM"; }
    L2="${L2} ${DIM}RESET${R} ${C5}⏳ 5h ${FH}%${R}${SEP}${C7}📅 7d ${SD}%${R}"
  fi

  printf '%b\n' "$L1"
  printf '%b\n' "   ${L2}"

# ═══════════════════════════════════════════════════════════════
#  CODEX CLI
# ═══════════════════════════════════════════════════════════════
elif [ "$TOOL" = "codex" ]; then
  MODEL=$(printf '%s' "$INPUT" | jq -r '.model // "–"')
  CWD=$(  printf '%s' "$INPUT" | jq -r '.cwd // ""')
  PERMS=$(printf '%s' "$INPUT" | jq -r '.permission_mode // ""')

  MODEL=$(_san "$MODEL"); PERMS=$(_san "$PERMS")
  PROJECT=$(_san "$(basename "${CWD:-/unknown}")")
  [ -z "$PROJECT" ] || [ "$PROJECT" = "/" ] && PROJECT="–"
  GIT_BRANCH=$(_san "$(_git_branch "$CWD")")

  L1="${CYAN}◆ ${MODEL}${R}"
  L1="${L1}${SEP}📁 ${PROJECT}"
  [ -n "$GIT_BRANCH" ] && L1="${L1}${DIM} (${GIT_BRANCH})${R}"
  [ -n "$PERMS" ] && L1="${L1}${SEP}${DIM}${PERMS}${R}"

  printf '%b\n' "$L1"
  printf '%b\n' "   ${HEART}"

# ═══════════════════════════════════════════════════════════════
#  GEMINI CLI
# ═══════════════════════════════════════════════════════════════
elif [ "$TOOL" = "gemini" ]; then
  CWD=$(  printf '%s' "$INPUT" | jq -r '.cwd // ""')
  EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // ""')

  EVENT=$(_san "$EVENT")
  PROJECT=$(_san "$(basename "${CWD:-/unknown}")")
  [ -z "$PROJECT" ] || [ "$PROJECT" = "/" ] && PROJECT="–"
  GIT_BRANCH=$(_san "$(_git_branch "$CWD")")

  L1="${CYAN}♊ Gemini${R}"
  L1="${L1}${SEP}📁 ${PROJECT}"
  [ -n "$GIT_BRANCH" ] && L1="${L1}${DIM} (${GIT_BRANCH})${R}"
  [ -n "$EVENT" ] && L1="${L1}${SEP}${DIM}${EVENT}${R}"

  printf '%b\n' "$L1"
  printf '%b\n' "   ${HEART}"

# ═══════════════════════════════════════════════════════════════
#  FALLBACK — JSON desconocido
# ═══════════════════════════════════════════════════════════════
else
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
  PROJECT=$(_san "$(basename "${CWD:-/unknown}")")
  [ -z "$PROJECT" ] || [ "$PROJECT" = "/" ] && PROJECT="–"
  printf '%b\n' "${CYAN}⚡ ciberclaude${R}${SEP}📁 ${PROJECT}"
fi
