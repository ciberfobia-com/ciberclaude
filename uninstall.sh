#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  ciberclaude — uninstaller
#  By Ciberfobia · ciberfobia.com
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/ciberfobia-com/ciberclaude/main/uninstall.sh | bash
# ─────────────────────────────────────────────────────────────

set -euo pipefail

INSTALL_PATH="${HOME}/.claude/ciberclaude.sh"
SETTINGS="${HOME}/.claude/settings.json"

printf "\n  ciberclaude — desinstalando...\n\n"

# Eliminar script
if [ -f "$INSTALL_PATH" ]; then
  rm "$INSTALL_PATH"
  printf "  [ok] Script eliminado\n"
else
  printf "  [!]  Script no encontrado (ya desinstalado?)\n"
fi

# Eliminar statusLine de settings.json via mktemp en mismo directorio (mv atómico)
if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  if jq empty "$SETTINGS" 2>/dev/null; then
    TMP=$(mktemp "${HOME}/.claude/settings.XXXXXX")
    if jq 'del(.statusLine)' "$SETTINGS" > "$TMP" && jq empty "$TMP" 2>/dev/null; then
      mv "$TMP" "$SETTINGS"
      printf "  [ok] statusLine eliminado de settings.json\n"
    else
      rm -f "$TMP"
      printf "  [!]  No se pudo actualizar settings.json — edítalo manualmente\n"
    fi
  else
    printf "  [!]  settings.json no es JSON válido — edítalo manualmente\n"
  fi
fi

printf "\n  Reinicia Claude Code para aplicar los cambios.\n"
printf "\n  ciberclaude · by Ciberfobia · ciberfobia.com\n\n"
