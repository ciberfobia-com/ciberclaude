# ⚡ ciberclaude

> Plugin de statusline para [Claude Code](https://claude.ai/code). Muestra información útil de la sesión en la barra inferior del terminal.

---

## Instalación

```bash
curl -fsSL https://ciberfobia.com/ciberclaude | bash
```

**Requisito:** [`jq`](https://jqlang.github.io/jq/) — el installer detecta tu sistema operativo y te dice exactamente cómo instalarlo si no lo tienes.

Reinicia Claude Code después de instalar.

---

## Qué muestra

El statusline ocupa **dos líneas** en la parte inferior de Claude Code:

```
⚡ Opus  ·  ████████░░ 78%  ·  $0.0312  ·  📁 ciberfobia-os (main)
   🤖 frontend-developer  ·  ⏱ 5m00s  ·  5h:82%  ·  7d:41%
```

### Línea 1 — siempre visible

| Elemento | Descripción |
|----------|-------------|
| `⚡ Opus` | Modelo activo: Opus, Sonnet o Haiku |
| `████████░░ 78%` | Uso del contexto. Verde `<50%` → Amarillo `≥50%` → Rojo `≥80%` |
| `$0.0312` | Coste acumulado de la sesión en USD |
| `📁 proyecto` | Nombre del directorio de trabajo actual |
| `(main)` | Rama git activa (solo si el directorio es un repo git) |

### Línea 2 — solo si hay algo que mostrar

| Elemento | Cuándo aparece |
|----------|----------------|
| `🤖 agente` | Cuando hay un agente especializado activo |
| `⏱ 5m00s` | Duración de la sesión (cuando es > 0) |
| `5h:82%  ·  7d:41%` | Rate limits de uso (solo cuando alguno supera el **50%**). Amarillo `≥50%`, Rojo `≥80%` |

> La línea 2 desaparece completamente si no hay agente activo, la sesión acaba de empezar y los rate limits están bajos. Sin ruido innecesario.

---

## Instalación alternativa

Sin `curl`:

```bash
git clone https://github.com/ciberfobia-com/ciberclaude.git
cd ciberclaude
bash install.sh
```

Manual (solo el script):

```bash
# 1. Descargar
curl -fsSL https://raw.githubusercontent.com/ciberfobia-com/ciberclaude/main/ciberclaude.sh \
  -o ~/.claude/ciberclaude.sh
chmod 700 ~/.claude/ciberclaude.sh

# 2. Añadir a ~/.claude/settings.json
# (si ya tienes settings.json, añade solo el campo statusLine)
echo '{"statusLine":{"type":"command","command":"~/.claude/ciberclaude.sh"}}' \
  > ~/.claude/settings.json
```

---

## Desinstalar

```bash
curl -fsSL https://raw.githubusercontent.com/ciberfobia-com/ciberclaude/main/uninstall.sh | bash
```

---

## Compatibilidad

| Plataforma | Estado |
|-----------|--------|
| macOS (Terminal, iTerm2, Warp, Ghostty) | ✓ |
| Linux bash 3.2+ | ✓ |
| Windows WSL2 | ✓ |
| Claude Code CLI | ✓ |
| Claude Code Desktop | ✓ |

---

## Cómo funciona

Claude Code ejecuta el script tras cada respuesta del asistente. Le envía un JSON por stdin con el estado completo de la sesión. El script lo parsea con `jq` y escribe texto a stdout, que Claude Code renderiza en la barra inferior.

```
Claude Code  →  JSON (stdin)  →  ciberclaude.sh  →  texto ANSI (stdout)  →  barra inferior
```

**El script corre 100% local.** No hace peticiones externas, no accede a credenciales, no requiere permisos de administrador, no modifica nada fuera de `~/.claude/`.

---

## Seguridad

- Sin `sudo`. Solo escribe en `~/.claude/` (tu directorio de configuración)
- `umask 077`: archivos instalados solo legibles por ti
- `chmod 700` en el script: solo el propietario puede ejecutarlo
- Descarga a archivo temporal + `mv` atómico: si la descarga falla, tu instalación anterior no se corrompe
- `--proto '=https' --tlsv1.2`: fuerza HTTPS con TLS 1.2 mínimo en la descarga
- Strings de usuario sanitizados antes de `printf %b`: previene inyección de secuencias de escape desde nombres de directorio o agentes maliciosos
- Backup automático de `settings.json` con rollback si el merge falla
- Verificación de que el archivo descargado es un script bash válido antes de instalarlo

---

## Créditos

Hecho por [Ciberfobia](https://ciberfobia.com) — automatización e IA para empresas.

---

## Licencia

MIT
