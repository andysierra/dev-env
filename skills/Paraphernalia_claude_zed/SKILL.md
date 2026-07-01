---
name: Paraphernalia_claude_zed
description: >-
  Configura Claude Code corriendo DENTRO de Zed para dar respuestas breves y
  con "parafernalia" gráfica: tablas/árboles en ASCII (que Zed alinea en bloque
  ```text) y diagramas SIEMPRE en Mermaid, escritos inline y renderizados en el
  panel del agente. Úsala en un PC NUEVO (Zed + Claude Code recién instalados,
  login reciente) para replicar toda la configuración. No requiere instalar
  ningún toolchain: Mermaid lo renderiza el propio panel de Zed.
---

# Paraphernalia_claude (variante Zed)

Deja a Claude Code —usado dentro del editor **Zed**— respondiendo **breve** y con
**parafernalia visual**: tablas y árboles en **ASCII**, y diagramas en **Mermaid**
escritos directamente en la respuesta y **renderizados en el panel del agente**.
Toda la configuración se reduce a escribir un `CLAUDE.md` global con las reglas.

> **Contexto de uso:** PC nuevo, con Zed recién instalado y Claude Code recién
> instalado + login reciente.

---

## Por qué Mermaid inline (contexto aprendido)

El panel del agente de Zed:

- ✅ **Renderiza Mermaid** escrito como bloque ` ```mermaid ` directamente en la
  respuesta. El diagrama aparece dibujado, sin toolchain externo.
- ✅ Renderiza bien la **prosa**.
- ❌ **Tablas markdown** (`| a | b |`) → las muestra en crudo. Usar **ASCII** en
  bloque ` ```text `.

Consecuencia: **no hace falta instalar nada** (nada de Java, PlantUML, Graphviz ni
PNG) y **no hace falta el truco del subagente** (existía solo para ocultar el
código PlantUML; Mermaid se escribe inline y se dibuja).

---

## Paso 0 — Detectar el sistema operativo

Solo se necesita para ubicar la ruta del `CLAUDE.md` global:

```bash
uname -s 2>/dev/null || echo "Windows_NT: $OS"
```

- `Darwin` → **macOS** · `Linux` → **Linux** → ruta `~/.claude/CLAUDE.md`.
- Falla / `MINGW*` / `MSYS*` / `CYGWIN*` / `Windows_NT` → **Windows** → ruta
  `%USERPROFILE%\.claude\CLAUDE.md`.

---

## Paso 1 — Escribir el `CLAUDE.md` global (reglas de respuesta)

Escribe el archivo global de Claude Code con **exactamente** este contenido.
Ruta: `~/.claude/CLAUDE.md` (macOS/Linux) o `%USERPROFILE%\.claude\CLAUDE.md`
(Windows). Si ya existe, integra estas reglas sin borrar lo demás.

```markdown
# Preferencias de respuesta (Claude Code dentro de Zed)

- **Respuestas breves.** Al grano, sin relleno ni repeticiones.
- **Preferir lo visual** sobre párrafos largos, cuando lo amerite.
- **Formatos según el caso:**
  - **Tabla** (comparar por atributos) → **ASCII en texto plano**, dentro de un bloque ```text. NUNCA tabla markdown de pipes `|` (Zed la muestra cruda). Nunca como diagrama.
  - **Árbol / jerarquía** → **ASCII en texto plano** (```text con `├── └──`). No es un diagrama; nunca en Mermaid.
  - **Diagrama** (flujo, secuencia, arquitectura, máquina de estados, relaciones, clases, componentes) → **SIEMPRE en Mermaid**. Nunca ASCII, nunca PUML/PNG. No confundir diagrama con tabla ni con árbol: esos siguen en ASCII.
  - **Resumen de una línea** (`A → B → C`) en prosa: ok.
- **Mostrar los diagramas Mermaid renderizados en el chat.** Escribir el bloque ```mermaid directamente en la respuesta (no en un subagente, no como imagen); el panel de Zed lo dibuja. Al renderizar archivos `.md` que contengan Mermaid, mostrarlos siempre renderizados en el chat.
```

---

## Paso 2 — Verificar

Pídele a Claude un diagrama de prueba (p. ej. "diagrama el flujo A → B → C"). Debe
aparecer un bloque Mermaid **dibujado** en el panel, sin código a la vista. Comprueba
también que una tabla y un árbol ASCII se muestran alineados dentro de ` ```text `.

---

## Checklist final

```text
[ ] SO detectado (macOS / Linux / Windows) → ruta del CLAUDE.md
[ ] ~/.claude/CLAUDE.md escrito con las reglas (Mermaid inline + ASCII tablas/árboles)
[ ] Prueba: diagrama Mermaid se dibuja en el panel; tabla/árbol ASCII alineados
[ ] (No aplica) sin Java / PlantUML / Graphviz: Mermaid no necesita toolchain
```
