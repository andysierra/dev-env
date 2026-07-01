---
name: Paraphernalia_claude_cli
description: >-
  Configura Claude Code en su versión de TERMINAL (CLI, sin Zed) para dar
  respuestas breves y con "parafernalia" gráfica: tablas/árboles en ASCII (que
  la terminal alinea de forma nativa) y diagramas SIEMPRE en Mermaid escritos
  inline. Los clientes que renderizan markdown (Zed, claude.ai, extensiones IDE)
  dibujan el Mermaid; en una terminal pura el bloque Mermaid es el entregable
  (portable a cualquier visor). Úsala en un PC NUEVO con Claude Code recién
  instalado. Detecta el SO (macOS / Linux / Windows).
---

# Paraphernalia_claude (variante CLI, sin Zed)

Misma filosofía que la variante Zed —respuestas **breves** con **parafernalia
visual**— adaptada a Claude Code en una **terminal** (sin el panel de Zed).

> **Contexto de uso:** PC nuevo con Claude Code recién instalado y login reciente.

---

## Diferencia clave con la variante Zed

- ✅ **ASCII se alinea nativo** en la terminal (monoespaciada garantizada): tablas
  y árboles se ven perfectos. Es el mejor terreno para ASCII.
- ⚠️ **Mermaid no se dibuja en una terminal pura.** El bloque ` ```mermaid ` se
  muestra como texto. Aun así es el formato correcto: es el **entregable portable**
  (se pega en Zed, claude.ai, GitHub, VS Code o cualquier visor Mermaid y se
  dibuja). Si el cliente sí renderiza markdown (Zed, claude.ai, extensiones IDE),
  el diagrama aparece dibujado directamente.
- ✅ **Sin toolchain:** Mermaid no necesita Java, PlantUML ni Graphviz. La
  instalación del jar de PlantUML queda **eliminada**.

---

## Paso 0 — Detectar el sistema operativo

```bash
uname -s 2>/dev/null || echo "Windows_NT: $OS"
```

- `Darwin` → **macOS** · `Linux` → **Linux** → ruta `~/.claude/CLAUDE.md`.
- Falla / `MINGW*` / `MSYS*` / `CYGWIN*` / `Windows_NT` → **Windows** → ruta
  `%USERPROFILE%\.claude\CLAUDE.md`.

---

## Paso 1 — Escribir el `CLAUDE.md` global (reglas de respuesta)

Ruta: `~/.claude/CLAUDE.md` (macOS/Linux) o `%USERPROFILE%\.claude\CLAUDE.md`
(Windows). Si ya existe, integra sin borrar lo demás. Contenido:

```markdown
# Preferencias de respuesta (Claude Code en terminal / CLI)

- **Respuestas breves.** Al grano, sin relleno ni repeticiones.
- **Preferir lo visual** sobre párrafos largos, cuando lo amerite.
- **Formatos según el caso:**
  - **Tabla** (comparar por atributos) → **ASCII en texto plano** dentro de un bloque ```text. La terminal la alinea de forma nativa (monoespaciada). Nunca tabla markdown de pipes `|`.
  - **Árbol / jerarquía** → **ASCII en texto plano** (```text con `├── └──`). No es un diagrama; nunca en Mermaid.
  - **Diagrama** (flujo, secuencia, arquitectura, máquina de estados, relaciones, clases, componentes) → **SIEMPRE en Mermaid**, escrito como bloque ```mermaid inline. Nunca ASCII, nunca PUML/PNG. No confundir diagrama con tabla ni con árbol.
  - **Resumen de una línea** (`A → B → C`) en prosa: ok.
- **Mostrar los diagramas Mermaid renderizados en el chat** cuando el cliente los soporte (Zed, claude.ai, extensiones IDE); en una terminal pura, el bloque ```mermaid es el entregable (portable a cualquier visor Mermaid). Al renderizar archivos `.md` que contengan Mermaid, mostrarlos siempre renderizados en el chat.
```

---

## Paso 2 (OPCIONAL) — Ver el diagrama como PNG en una terminal pura

Solo si necesitas **imágenes** en una terminal que no renderiza Mermaid. Usa
`mmdc` (mermaid-cli), que reemplaza al viejo flujo de PlantUML:

```bash
npm install -g @mermaid-js/mermaid-cli      # requiere Node.js
mmdc -i diagrama.mmd -o diagrama.png        # renderiza el .mmd a PNG
```

Abrir el PNG en el visor del SO:

- macOS:   `open diagrama.png`
- Linux:   `xdg-open diagrama.png`
- Windows: `Start-Process diagrama.png`  (o `start diagrama.png` en cmd)

> Esto es un extra para terminales puras; el formato de respuesta sigue siendo el
> bloque ` ```mermaid ` inline, no el PNG.

---

## Paso 3 — Verificar

Pídele a Claude un diagrama de prueba y confirma que responde con un bloque
` ```mermaid ` bien formado. Comprueba que una tabla y un árbol ASCII se alinean en
tu terminal. Si instalaste `mmdc`, renderiza un `.mmd` de prueba y ábrelo.

---

## Checklist final

```text
[ ] SO detectado (macOS / Linux / Windows) → ruta del CLAUDE.md
[ ] ~/.claude/CLAUDE.md escrito con las reglas (Mermaid inline + ASCII tablas/árboles)
[ ] Prueba: Claude responde diagramas en bloque ```mermaid; tabla/árbol ASCII alineados
[ ] (Opcional) mmdc instalado si se quieren PNG en terminal pura
[ ] (No aplica) sin Java / PlantUML / Graphviz: Mermaid no necesita ese toolchain
```
