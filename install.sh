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
SETTINGS="${HOME}/.claude/settings.json"
SETTINGS_BAK="${HOME}/.claude/settings.json.bak"

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

# ── Banner ────────────────────────────────────────────────────────────────────
printf "${BOLD}${CYAN}"
cat <<'BANNER'


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::-+#%%%@@@@@%%#*=::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::=#@@@@@@@@@@@@@@@@@@@@@@#+:::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::-+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-:::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+:::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+-::::::::::::::::::::::::::::::::
:::::::::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:::::::::::::::::::::::::::::::
:::::::::::::::::::::-+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-:::::::::::::::::::::::::::::
:::::::::::::::::::--#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-::::::::::::::::::::::::::::
:::::::::::::::::::-#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-:::::::::::::::::::::::::::
:::::::::::::::::::+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:::::::::::::::::::::::::::
::::::::::::::::::=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=::::::::::::::::::::::::::
::::::::::::::::::*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::::::::::::::::::::::::::
:::::::::::::::::-%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@::::::::::::::::::::::::::
::::::::::::::::::@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:::::::::::::::::::::::::
:::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+:::::::::::::::::::::::::
:::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+:::::::::::::::::::::::::
:::::::::::::::::=@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@+:::::::::::::::::::::::::
:::::::::::::::-=@@@@@@%-:::::::=#@@@@@@@@@@@@@@@@@@@@@@%+-::::::-#@@@@@@*::::::::::::::::::::::::::
:::::::::::::::::=@@@@@#:::------:::::=#@@@@@@@@@@@@%+-::::------:::#@@@@@*:::::::::::::::::::::::::
:::::::::::::::::+@@@@@*::%@@@@@@@@%-::::::::::::::::::-#@@@@@@@@@::+@@@@@#:::::::::::::::::::::::::
:::::::::::::::::#@@@@@*:::---+@@@@@@@@*-:::::::-::-*@@@@@@@@+---:::+@@@@@@-::::::::::::::::::::::::
::::::::::::::::-%@@@@@%::::::-@@@@@@#=#@#-:::::::*@%=+@@@@@@=::-:::#@@@@@@-::::::::::::::::::::::::
::::::::::::::::-@@@@@@@%-:::::-=##+-::::::::::::::::::-+##+-:::::-#@@@@@@@=::::::::::::::::::::::::
::::::::::::::::-@@@@@@@@@=:::::::::::::-+#@@@@@@%+-:::::::::::::=@@@@@@@@@=::::::::::::::::::::::::
::::::::::::::::-@@@@@@@@@@@#+-:::::-+#@@@@@@@@@@@@@@#+-:::::-+#@@@@@@@@@@@=::::::::::::::::::::::::
::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=::::::::::::::::::::::::
:::::::::::::::::#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-::::::::::::::::::::::::
:::::::::::::::::=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:::::::::::::::::::::::::
::::::::::::::::::#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:-::::::::::::::::::::::::
::::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+-:::::::::::::::::::::::::
:::::::::::::::::::=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::::::::::::::::::::::::
::::::::::::::::::::#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-:::::::::::::::::::::::::::
::::::::::::::::::::-#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-::::::::::::::::::::::::::::
:::::::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:::::::::::::::::::::::::::::
::::::::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*::::::::::::::::::::::::::::::
:::::::::::::::::::::::#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:::::::::::::::::::::::::::::::
:::::::::::::::::::::::#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::::::::::::::::::::::::::::
::::::::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=::::::::::::::::::::::::::::::
:::::::::::::::::::::=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+-::::::::::::::::::::::::::::
:::::::::::::::::::-%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:::::::::::::::::::::::::::
::::::::::::::::::=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+::::::::::::::::::::::::::
::::::::::::::::::*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::::::::::::::::::::::::::
::::::::::::::::::+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*::::::::::::::::::::::::::
::::::::::::::::::*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-:::::::::::::::::::::::::::
:::::::::::::::::::+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-::::::::::::::::::::::::::::
::::::::::::::::::::-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=::::::::::::::::::::::::::::::
:::::::::::::::::::::-#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:::::::::::::::::::::::::::::::::
:::::::::::::::::::::::-*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=:::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::-=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::-+%@@@@@@@@@@@@@@@@@@@@@@@@@@%*-:::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::-=*%%@@@@@@@@@@@%#+-:::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

  statusline for claude code · by ciberfobia.com

BANNER
printf "${RESET}"

# ── 1. Detectar Claude Code ───────────────────────────────────────────────────
step "Comprobando Claude Code..."

claude_found=0
command -v claude >/dev/null 2>&1 && claude_found=1
[ -d "${HOME}/.claude" ]          && claude_found=1

if [ "$claude_found" -eq 1 ]; then
  ok "Claude Code detectado"
else
  warn "Claude Code no detectado — instálalo en https://claude.ai/code"
  warn "Continuando de todos modos (puedes instalarlo después)"
fi

# ── 2. Verificar jq ───────────────────────────────────────────────────────────
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

# ── 3. Crear ~/.claude/ si no existe ─────────────────────────────────────────
if [ ! -d "${HOME}/.claude" ]; then
  step "Creando directorio ~/.claude/..."
  mkdir -p "${HOME}/.claude"
  ok "Directorio creado"
fi

# ── 4. Descargar ciberclaude.sh ───────────────────────────────────────────────
if [ -f "$INSTALL_PATH" ]; then
  step "Instalación existente detectada — actualizando..."
else
  step "Descargando ciberclaude.sh..."
fi

# Usar mktemp en el mismo directorio destino → mv atómico garantizado (mismo filesystem)
TMP_DOWNLOAD=$(mktemp "${HOME}/.claude/ciberclaude.XXXXXX")
trap 'rm -f "$TMP_DOWNLOAD"' EXIT

# Archivo temporal para el error de curl (mktemp, no nombre fijo en /tmp)
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

# Verificar que es un script bash (protección mínima contra respuesta inesperada)
first_line=$(head -1 "$TMP_DOWNLOAD")
if [ "${first_line#\#!}" = "$first_line" ]; then
  fail "El archivo descargado no parece un script bash válido."
fi

mv "$TMP_DOWNLOAD" "$INSTALL_PATH"
chmod 700 "$INSTALL_PATH"

ok "Script descargado (${file_size} bytes) → ${INSTALL_PATH}"

# ── 5. Configurar settings.json ───────────────────────────────────────────────
step "Configurando settings.json..."

STATUS_LINE_JSON='{"type":"command","command":"~/.claude/ciberclaude.sh"}'

if [ -f "$SETTINGS" ]; then
  if ! jq empty "$SETTINGS" 2>/dev/null; then
    warn "settings.json no es JSON válido — se reemplaza (backup en .bak)"
    cp "$SETTINGS" "${SETTINGS_BAK}"
    printf '%s\n' "{\"statusLine\":${STATUS_LINE_JSON}}" > "$SETTINGS"
    ok "settings.json creado (backup guardado)"
  else
    cp "$SETTINGS" "${SETTINGS_BAK}"
    # mktemp en el mismo directorio → mv atómico en mismo filesystem
    TMP_SETTINGS=$(mktemp "${HOME}/.claude/settings.XXXXXX")
    if jq --argjson sl "$STATUS_LINE_JSON" '.statusLine = $sl' "$SETTINGS_BAK" > "$TMP_SETTINGS" \
       && jq empty "$TMP_SETTINGS" 2>/dev/null; then
      mv "$TMP_SETTINGS" "$SETTINGS"
      ok "settings.json actualizado (backup en settings.json.bak)"
    else
      rm -f "$TMP_SETTINGS"
      cp "${SETTINGS_BAK}" "$SETTINGS"
      fail "Error al actualizar settings.json — restaurado desde backup"
    fi
  fi
else
  printf '%s\n' "{\"statusLine\":${STATUS_LINE_JSON}}" > "$SETTINGS"
  ok "settings.json creado"
fi

# ── 6. Verificación ───────────────────────────────────────────────────────────
step "Verificando instalación..."

TEST_JSON='{"cwd":"/tmp","model":{"display_name":"Opus"},"context_window":{"used_percentage":42},"cost":{"total_cost_usd":0.0021,"total_duration_ms":90000}}'
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
printf "  ${DIM}Archivo  →${RESET}  %s\n" "$INSTALL_PATH"
printf "  ${DIM}Config   →${RESET}  %s\n" "$SETTINGS"
printf "\n"
printf "${BOLD}  Reinicia Claude Code para activar el statusline.${RESET}\n"
printf "\n"
printf "  ${DIM}ciberclaude · by Ciberfobia · ciberfobia.com${RESET}\n"
printf "\n"
