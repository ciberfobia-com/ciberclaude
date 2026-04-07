#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  ciberclaude — installer
#  By Ciberfobia · ciberfobia.com
#
#  Usage:
#    curl -fsSL https://ciberfobia.com/ciberclaude | bash
#    curl -fsSL https://raw.githubusercontent.com/ciberfobia-com/ciberclaude/main/install.sh | bash
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Permisos mínimos: archivos creados solo legibles por el dueño
umask 077

# ── Globals ───────────────────────────────────────────────────────────────────
GITHUB_RAW="https://raw.githubusercontent.com/ciberfobia-com/ciberclaude/main"
INSTALL_PATH="${HOME}/.claude/ciberclaude.sh"

# ── Colores (desactivados automáticamente en pipe) ────────────────────────────
if [ -t 1 ]; then
  CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'
  YELLOW='\033[0;33m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
else
  CYAN=''; GREEN=''; RED=''; YELLOW=''; BOLD=''; DIM=''; RESET=''
fi

step() { printf "${CYAN}  -> %s${RESET}\n" "$*"; }
ok()   { printf "${GREEN}  [ok] %s${RESET}\n" "$*"; }
warn() { printf "${YELLOW}  [!]  %s${RESET}\n" "$*"; }
fail() { printf "${RED}  [x]  %s${RESET}\n" "$*"; exit 1; }
skip() { printf "${DIM}  --   %s${RESET}\n" "$*"; }

# ── Banner ────────────────────────────────────────────────────────────────────
printf "${BOLD}${CYAN}"
cat <<'BANNER'

       _ _                    _                 _
   ___(_) |__   ___ _ __ ___| | __ _ _   _  __| | ___
  / __| | '_ \ / _ \ '__/ __| |/ _` | | | |/ _` |/ _ \
 | (__| | |_) |  __/ | | (__| | (_| | |_| | (_| |  __/
  \___|_|_.__/ \___|_|  \___|_|\__,_|\__,_|\__,_|\___|

  AI coding statusline · by ciberfobia.com

BANNER
printf "${RESET}"

# ── 1. Verificar jq ───────────────────────────────────────────────────────────
step "Comprobando jq..."

if command -v jq >/dev/null 2>&1; then
  ok "jq $(jq --version 2>/dev/null || echo '') encontrado"
else
  printf "\n"
  printf "${RED}  [x]  jq es necesario y no está instalado.${RESET}\n\n"
  case "$(uname -s)" in
    Darwin) printf "${YELLOW}       macOS  →  brew install jq${RESET}\n" ;;
    Linux)
      if grep -qi "microsoft" /proc/version 2>/dev/null; then
        printf "${YELLOW}       WSL    →  sudo apt-get install -y jq${RESET}\n"
      elif [ -f /etc/debian_version ] || grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
        printf "${YELLOW}       Ubuntu →  sudo apt-get install -y jq${RESET}\n"
      elif grep -qi "fedora\|rhel\|centos" /etc/os-release 2>/dev/null; then
        printf "${YELLOW}       Fedora →  sudo dnf install -y jq${RESET}\n"
      elif [ -f /etc/arch-release ]; then
        printf "${YELLOW}       Arch   →  sudo pacman -S jq${RESET}\n"
      else
        printf "${YELLOW}       Otros  →  https://jqlang.github.io/jq/download/${RESET}\n"
      fi ;;
  esac
  printf "\n"
  exit 1
fi

# ── 2. Crear ~/.claude/ si no existe ─────────────────────────────────────────
if [ ! -d "${HOME}/.claude" ]; then
  step "Creando directorio ~/.claude/..."
  mkdir -p "${HOME}/.claude"
  ok "Directorio creado"
fi

# ── 3. Descargar ciberclaude.sh ───────────────────────────────────────────────
if [ -f "$INSTALL_PATH" ]; then
  step "Instalación existente detectada — actualizando..."
else
  step "Descargando ciberclaude.sh..."
fi

TMP_DOWNLOAD=$(mktemp "${HOME}/.claude/ciberclaude.XXXXXX")
TMP_CURL_ERR=$(mktemp)
trap 'rm -f "$TMP_DOWNLOAD" "$TMP_CURL_ERR"' EXIT

curl_exit=0
curl -fsSL --max-time 30 \
     --proto '=https' \
     --tlsv1.2 \
     -o "$TMP_DOWNLOAD" \
     "${GITHUB_RAW}/ciberclaude.sh" 2>"$TMP_CURL_ERR" || curl_exit=$?

if [ "$curl_exit" -ne 0 ]; then
  err_msg=$(cat "$TMP_CURL_ERR" 2>/dev/null | head -1 || echo "error desconocido")
  fail "No se pudo descargar ciberclaude.sh — ${err_msg}"
fi

file_size=$(wc -c < "$TMP_DOWNLOAD" | tr -d ' ')
if [ "${file_size:-0}" -eq 0 ]; then
  fail "Archivo descargado vacío. Verifica tu conexión."
fi

first_line=$(head -1 "$TMP_DOWNLOAD")
if [ "${first_line#\#!}" = "$first_line" ]; then
  fail "El archivo descargado no parece un script bash válido."
fi

mv "$TMP_DOWNLOAD" "$INSTALL_PATH"
chmod 700 "$INSTALL_PATH"
ok "Script descargado (${file_size} bytes) → ${INSTALL_PATH}"

# ── Función: merge seguro de settings.json ────────────────────────────────────
# $1 = ruta al settings.json  $2 = clave jq  $3 = valor JSON
_merge_json() {
  local settings="$1" key="$2" val="$3"
  local bak="${settings}.bak" tmp

  if [ -f "$settings" ] && ! jq empty "$settings" 2>/dev/null; then
    warn "$(basename "$settings") no es JSON válido — reemplazando (backup en .bak)"
    cp "$settings" "$bak"
    printf '%s\n' "{${key}:${val}}" > "$settings"
    return 0
  fi

  tmp=$(mktemp "$(dirname "$settings")/ciberclaude.XXXXXX")
  if [ -f "$settings" ]; then
    cp "$settings" "$bak"
    jq --argjson v "$val" "${key} = \$v" "$bak" > "$tmp" && jq empty "$tmp" 2>/dev/null || {
      rm -f "$tmp"; cp "$bak" "$settings"
      warn "No se pudo actualizar $(basename "$settings") — sin cambios"
      return 1
    }
  else
    mkdir -p "$(dirname "$settings")"
    printf '%s\n' "{}" | jq --argjson v "$val" "${key} = \$v" > "$tmp"
  fi
  mv "$tmp" "$settings"
}

SCRIPT_REF='"~/.claude/ciberclaude.sh"'
CONFIGURED=()

# ── 4. Claude Code ────────────────────────────────────────────────────────────
step "Buscando Claude Code..."
claude_found=0
command -v claude >/dev/null 2>&1 && claude_found=1
[ -d "${HOME}/.claude" ] && claude_found=1

if [ "$claude_found" -eq 1 ]; then
  SETTINGS="${HOME}/.claude/settings.json"
  STATUS_JSON="{\"type\":\"command\",\"command\":${SCRIPT_REF}}"
  if _merge_json "$SETTINGS" '.statusLine' "$STATUS_JSON"; then
    ok "Claude Code configurado → ${SETTINGS}"
    CONFIGURED+=("Claude Code")
  fi
else
  skip "Claude Code no detectado"
fi

# ── 5. Gemini CLI ─────────────────────────────────────────────────────────────
step "Buscando Gemini CLI..."
gemini_found=0
command -v gemini >/dev/null 2>&1 && gemini_found=1
[ -d "${HOME}/.gemini" ] && gemini_found=1

if [ "$gemini_found" -eq 1 ]; then
  GEMINI_SETTINGS="${HOME}/.gemini/settings.json"
  # Hook para SessionStart: ejecuta ciberclaude.sh
  HOOK_JSON='{"hooks":[{"type":"command","command":"~/.claude/ciberclaude.sh"}]}'
  HOOKS_JSON="{\"SessionStart\":[${HOOK_JSON}]}"
  if _merge_json "$GEMINI_SETTINGS" '.hooks' "$HOOKS_JSON"; then
    ok "Gemini CLI configurado → ${GEMINI_SETTINGS}"
    CONFIGURED+=("Gemini CLI")
  fi
else
  skip "Gemini CLI no detectado"
fi

# ── 6. Verificación del script ────────────────────────────────────────────────
step "Verificando script..."

TEST_JSON='{"cwd":"/tmp","model":{"display_name":"Sonnet"},"context_window":{"used_percentage":42},"cost":{"total_cost_usd":0.031},"rate_limits":{"five_hour":{"used_percentage":18,"resets_at":1738425600},"seven_day":{"used_percentage":41,"resets_at":1738857600}}}'
verify_out=$(printf '%s' "$TEST_JSON" | "$INSTALL_PATH" 2>/dev/null) || true

if [ -n "$verify_out" ]; then
  ok "Script funciona correctamente"
  printf "  ${DIM}%s${RESET}\n" "$verify_out"
else
  warn "El script no produjo output en el test"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n"
printf "${BOLD}${GREEN}  ✓ ciberclaude instalado correctamente${RESET}\n"
printf "\n"
printf "  ${DIM}Script   →${RESET}  %s\n" "$INSTALL_PATH"

if [ "${#CONFIGURED[@]}" -gt 0 ]; then
  printf "  ${DIM}Activo en →${RESET}  %s\n" "$(printf '%s  ' "${CONFIGURED[@]}")"
else
  printf "  ${YELLOW}  [!]  Ninguna herramienta detectada — instala Claude Code, Gemini CLI o Codex CLI${RESET}\n"
fi

printf "\n"
printf "  ${DIM}ciberclaude · by Ciberfobia · ciberfobia.com${RESET}\n"
printf "\n"
