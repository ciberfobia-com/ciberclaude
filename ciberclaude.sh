#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  ciberclaude — Claude Code statusline plugin
#  github.com/ciberfobia-com/ciberclaude
#  By Ciberfobia · ciberfobia.com
# ─────────────────────────────────────────────────────────────

INPUT=$(cat)

if ! command -v jq &>/dev/null; then
  printf 'ciberclaude: instala jq → brew install jq / apt install jq\n'
  exit 0
fi

# ── Parsear JSON con fallbacks seguros ────────────────────────
MODEL=$(   printf '%s' "$INPUT" | jq -r '.model.display_name // "–"')
PCT_RAW=$( printf '%s' "$INPUT" | jq -r '.context_window.used_percentage // 0')
COST=$(    printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION=$(printf '%s' "$INPUT" | jq -r '.cost.total_duration_ms // 0')
CWD=$(     printf '%s' "$INPUT" | jq -r '.cwd // ""')
AGENT=$(        printf '%s' "$INPUT" | jq -r '.agent.name // ""')
AGENTS_COUNT=$( printf '%s' "$INPUT" | jq -r 'if (.agents | type) == "array" then (.agents | length) elif ((.agent.name // "") != "") then 1 else 0 end' 2>/dev/null || echo "0")
FIVE_H=$(       printf '%s' "$INPUT" | jq -r 'if (.rate_limits.five_hour.used_percentage  | type) == "number" then .rate_limits.five_hour.used_percentage  else "" end')
SEVEN_D=$(      printf '%s' "$INPUT" | jq -r 'if (.rate_limits.seven_day.used_percentage  | type) == "number" then .rate_limits.seven_day.used_percentage  else "" end')
PERMS=$(        printf '%s' "$INPUT" | jq -r '.permissions.mode // ""')

# ── Sanitizar strings de usuario antes de printf %b ──────────
# printf '%b' interpreta secuencias \NNN, \033, \c, etc.
# Eliminamos backslashes y caracteres de control de cualquier valor
# que provenga de datos externos (CWD, agent name, model name).
_san() { printf '%s' "$1" | tr -d '\\\000-\037'; }
MODEL=$(  _san "$MODEL")
AGENT=$(  _san "$AGENT")
PERMS=$(  _san "$PERMS")
PROJECT=$(basename "${CWD:-/unknown}")
PROJECT=$(_san "$PROJECT")
[ -z "$PROJECT" ] || [ "$PROJECT" = "/" ] && PROJECT="–"

# ── Valores derivados ─────────────────────────────────────────
PCT=$(printf '%.0f' "${PCT_RAW:-0}" 2>/dev/null || echo "0")
COST_NUM=$(printf '%.4f' "${COST:-0}" 2>/dev/null || echo "0.0000")
COST_FMT="\$${COST_NUM}"

# Duración de sesión (solo si > 0)
DUR_SEC=$(( $(printf '%.0f' "${DURATION:-0}" 2>/dev/null || echo "0") / 1000 ))
DUR_FMT=""
if [ "$DUR_SEC" -gt 0 ]; then
  DUR_FMT=$(printf '%dm%02ds' "$(( DUR_SEC / 60 ))" "$(( DUR_SEC % 60 ))")
fi

# Rama git del directorio actual (silencioso si no es un repo)
GIT_BRANCH=""
if [ -n "$CWD" ] && command -v git &>/dev/null; then
  GIT_BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || true)
  GIT_BRANCH=$(_san "$GIT_BRANCH")
fi

# ── Barra de progreso (10 bloques) ────────────────────────────
FILL=$(( PCT / 10 ))
[ "$FILL" -gt 10 ] && FILL=10
BAR=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  [ "$i" -le "$FILL" ] && BAR="${BAR}█" || BAR="${BAR}░"
done

# ── Colores ANSI ──────────────────────────────────────────────
R='\033[0m'; DIM='\033[2m'; CYAN='\033[36m'
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'

[ "$PCT" -ge 80 ] && CBAR="$RED" || { [ "$PCT" -ge 50 ] && CBAR="$YELLOW" || CBAR="$GREEN"; }

SEP="${DIM} · ${R}"

# ── Línea 1: modelo · contexto · coste · proyecto [· rama] [· perms] ─
L1="${CYAN}⚡ ${MODEL}${R}"
L1="${L1}${SEP}${CBAR}${BAR} ${PCT}%${R}"
L1="${L1}${SEP}${DIM}${COST_FMT}${R}"
L1="${L1}${SEP}📁 ${PROJECT}"
[ -n "$GIT_BRANCH" ] && L1="${L1}${DIM} (${GIT_BRANCH})${R}"
[ "$PERMS" = "auto" ] && L1="${L1}${SEP}${YELLOW}🔓 auto${R}"

# ── Línea 2: agente(s) · rate limits ─────────────────────────
L2=""

# Agente(s)
if [ "$AGENTS_COUNT" -gt 1 ] 2>/dev/null; then
  L2="🤖 ${AGENTS_COUNT} agentes"
elif [ -n "$AGENT" ]; then
  L2="🤖 ${AGENT}"
fi

# Rate limits (siempre si hay datos)
if [ -n "$FIVE_H" ] && [ -n "$SEVEN_D" ]; then
  FH=$(printf '%.0f' "$FIVE_H")
  SD=$(printf '%.0f' "$SEVEN_D")
  [ "$FH" -ge 80 ] && C5="$RED" || { [ "$FH" -ge 50 ] && C5="$YELLOW" || C5="$DIM"; }
  [ "$SD" -ge 80 ] && C7="$RED" || { [ "$SD" -ge 50 ] && C7="$YELLOW" || C7="$DIM"; }
  RL="${C5}⏳ 5h ${FH}%${R}${SEP}${C7}📅 7d ${SD}%${R}"
  [ -n "$L2" ] && L2="${L2}${SEP}${RL}" || L2="$RL"
fi

# ── Output ────────────────────────────────────────────────────
printf '%b\n' "$L1"
[ -n "$L2" ] && printf '%b\n' "   ${L2}"
