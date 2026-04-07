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
# Gemini CLI:   tiene hook_event_name (sin los anteriores)
TOOL="unknown"
if printf '%s' "$INPUT" | jq -e '.context_window' &>/dev/null; then
  TOOL="claude"
elif printf '%s' "$INPUT" | jq -e '.permission_mode' &>/dev/null; then
  TOOL="codex"
elif printf '%s' "$INPUT" | jq -e '.hook_event_name' &>/dev/null; then
  TOOL="gemini"
fi

# ── Sanitizar strings externos antes de printf %b ────────────
# Elimina backslashes y caracteres de control (0x00-0x1F, 0x7F)
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
  [ -n "$1" ] && command -v git &>/dev/null &&
    git -C "$1" branch --show-current 2>/dev/null || true
}

# ── Tiempo restante desde epoch Unix ─────────────────────────
# $1 = resets_at (epoch segundos)  $2 = "h" para horas, "d" para días
_remaining() {
  local epoch="$1" mode="$2" diff hrs mins days
  # Solo dígitos (seguridad: evitar inyección en aritmética bash)
  case "$epoch" in ''|*[!0-9]*) echo ""; return ;; esac
  diff=$(( epoch - _TS ))
  [ "$diff" -le 0 ] && echo "" && return
  if [ "$mode" = "d" ]; then
    days=$(( diff / 86400 )); hrs=$(( (diff % 86400) / 3600 ))
    [ "$days" -gt 0 ] && echo "${days}d${hrs}h" || echo "${hrs}h"
  else
    hrs=$(( diff / 3600 )); mins=$(( (diff % 3600) / 60 ))
    [ "$hrs" -gt 0 ] && echo "${hrs}h${mins}m" || echo "${mins}m"
  fi
}

# ═══════════════════════════════════════════════════════════════
#  CLAUDE CODE
# ═══════════════════════════════════════════════════════════════
if [ "$TOOL" = "claude" ]; then
  MODEL=$(    printf '%s' "$INPUT" | jq -r '.model.display_name // "–"')
  PCT_RAW=$(  printf '%s' "$INPUT" | jq -r '.context_window.used_percentage // 0')
  COST=$(     printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // 0')
  CWD=$(      printf '%s' "$INPUT" | jq -r '.cwd // ""')
  PERMS=$(    printf '%s' "$INPUT" | jq -r '.permissions.mode // ""')
  FIVE_H=$(   printf '%s' "$INPUT" | jq -r 'if (.rate_limits.five_hour.used_percentage | type) == "number" then .rate_limits.five_hour.used_percentage else "" end')
  SEVEN_D=$(  printf '%s' "$INPUT" | jq -r 'if (.rate_limits.seven_day.used_percentage | type) == "number" then .rate_limits.seven_day.used_percentage else "" end')
  FH_RESET=$( printf '%s' "$INPUT" | jq -r '.rate_limits.five_hour.resets_at // ""')
  SD_RESET=$( printf '%s' "$INPUT" | jq -r '.rate_limits.seven_day.resets_at // ""')

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

  # Línea 1
  L1="${CYAN}⚡ ${MODEL}${R}"
  L1="${L1}${SEP}${CBAR}${BAR} ${PCT}%${R}"
  L1="${L1}${SEP}${DIM}${COST_FMT}${R}"
  L1="${L1}${SEP}📁 ${PROJECT}"
  [ -n "$GIT_BRANCH" ] && L1="${L1}${DIM} (${GIT_BRANCH})${R}"
  [ "$PERMS" = "auto" ] && L1="${L1}${SEP}${YELLOW}🔓 auto${R}"

  # Línea 2 — rate limits con tiempo restante
  L2="${HEART}"
  if [ -n "$FIVE_H" ] && [ -n "$SEVEN_D" ]; then
    FH=$(printf '%.0f' "$FIVE_H"); SD=$(printf '%.0f' "$SEVEN_D")
    [ "$FH" -ge 80 ] && C5="$RED" || { [ "$FH" -ge 50 ] && C5="$YELLOW" || C5="$DIM"; }
    [ "$SD" -ge 80 ] && C7="$RED" || { [ "$SD" -ge 50 ] && C7="$YELLOW" || C7="$DIM"; }

    FH_REM=$(_remaining "$FH_RESET" "h")
    SD_REM=$(_remaining "$SD_RESET" "d")

    FH_DISP="${FH}%"; [ -n "$FH_REM" ] && FH_DISP="${FH}% (${FH_REM})"
    SD_DISP="${SD}%"; [ -n "$SD_REM" ] && SD_DISP="${SD}% (${SD_REM})"

    L2="${L2} ${DIM}RESET${R} ${C5}⏳ 5h ${FH_DISP}${R}${SEP}${C7}📅 7d ${SD_DISP}${R}"
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

  L1="${CYAN}◆ ${MODEL}${R}${SEP}📁 ${PROJECT}"
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

  L1="${CYAN}♊ Gemini${R}${SEP}📁 ${PROJECT}"
  [ -n "$GIT_BRANCH" ] && L1="${L1}${DIM} (${GIT_BRANCH})${R}"
  [ -n "$EVENT" ] && L1="${L1}${SEP}${DIM}${EVENT}${R}"

  printf '%b\n' "$L1"
  printf '%b\n' "   ${HEART}"

# ═══════════════════════════════════════════════════════════════
#  FALLBACK
# ═══════════════════════════════════════════════════════════════
else
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
  PROJECT=$(_san "$(basename "${CWD:-/unknown}")")
  [ -z "$PROJECT" ] || [ "$PROJECT" = "/" ] && PROJECT="–"
  printf '%b\n' "${CYAN}⚡ ciberclaude${R}${SEP}📁 ${PROJECT}"
fi
