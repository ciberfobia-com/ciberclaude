# ⚡ ciberclaude

Barra de estado para herramientas de AI coding. Muestra modelo, contexto, coste, proyecto y rate limits — en tiempo real, en la parte inferior de tu terminal.

---

## Instalar

```bash
curl -fsSL https://ciberfobia.com/ciberclaude | bash
```

Eso es todo. El installer detecta tu sistema, instala lo necesario y activa la barra automáticamente.

> **Requisito:** [`jq`](https://jqlang.github.io/jq/) — si no lo tienes, el installer te dice exactamente cómo instalarlo.

---

## Qué verás

```
⚡ Sonnet  ·  ████████░░ 78%  ·  $0.03  ·  📁 mi-proyecto (main)
💚 RESET ⏳ 5h 18%  ·  📅 7d 41%
```

| Elemento | Qué es |
|----------|--------|
| `⚡ Sonnet` | Modelo activo |
| `████░░░░░░ 78%` | Uso del contexto (verde → amarillo → rojo) |
| `$0.03` | Coste acumulado de la sesión |
| `📁 proyecto (main)` | Directorio y rama git |
| `🔓 auto` | Aparece cuando el modo de permisos es auto-approve |
| `💚` | Corazón animado — cambia de color cada 20 segundos |
| `RESET ⏳ 5h` / `📅 7d` | Rate limits de uso (se colorean al acercarse al límite) |

---

## Desinstalar

```bash
curl -fsSL https://raw.githubusercontent.com/ciberfobia-com/ciberclaude/main/uninstall.sh | bash
```

---

## Compatibilidad

| Herramienta | Soporte | Qué muestra |
|-------------|---------|-------------|
| **Claude Code** | ✅ Completo | Modelo · Contexto · Coste · Proyecto · Rate limits |
| **Codex CLI** (OpenAI) | ✅ Básico | Modelo · Proyecto · Modo de permisos |
| **Gemini CLI** (Google) | ✅ Básico | Proyecto · Evento activo |

macOS · Linux · Windows WSL2

### Configurar en Gemini CLI

Añade en `~/.gemini/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "~/.claude/ciberclaude.sh"}]}]
  }
}
```

### Configurar en Codex CLI

Añade `~/.claude/ciberclaude.sh` como comando para el hook `sessionStart` en tu configuración de Codex.

---

## Cómo funciona

La herramienta AI ejecuta el script y le pasa el estado de la sesión como JSON por stdin. El script detecta de qué herramienta viene, extrae los datos relevantes con `jq` y devuelve el texto de la barra.

100% local. Sin peticiones externas, sin credenciales, sin `sudo`.

---

## Seguridad

- Solo escribe en `~/.claude/` — nada fuera de tu config
- `umask 077` + `chmod 700`: archivos solo legibles por ti
- Descarga atómica con backup automático de `settings.json`
- HTTPS con TLS 1.2 mínimo en la descarga
- Inputs sanitizados antes de procesarse

---

Hecho por [Ciberfobia](https://ciberfobia.com) · MIT
