---
name: Paraphernalia_claude_cli
description: >-
  Configura Claude Code en su versión de TERMINAL (CLI, sin Zed) para dar
  respuestas breves y con "parafernalia" gráfica: tablas/árboles en ASCII
  (que la terminal alinea de forma nativa) y diagramas renderizados como PNG
  con PlantUML, que se abren en el visor de imágenes del SO. Úsala en un PC
  NUEVO con Claude Code recién instalado. Detecta el SO (macOS / Linux / Windows).
---

# Paraphernalia_claude (variante CLI, sin Zed)

Misma filosofía que la variante Zed —respuestas **breves** con **parafernalia
visual**— pero adaptada a Claude Code corriendo en una **terminal** (sin el panel
del editor Zed).

> **Contexto de uso:** PC nuevo con Claude Code recién instalado y login reciente.
> No asumas nada instalado: verifica e instala.

---

## Diferencia clave con la variante Zed

En una **terminal**:

- ✅ **ASCII se alinea nativo** (fuente monoespaciada garantizada): tablas y árboles
  se ven perfectos. Es el mejor terreno para ASCII.
- ❌ La terminal **no renderiza** imágenes markdown `![](ruta)` en línea (salvo
  emuladores con protocolo de imágenes: iTerm2, kitty, WezTerm). Para que el usuario
  **vea** el diagrama, hay que **abrir el PNG** en el visor del SO.
- El truco del subagente (para ocultar el código PUML) es **opcional** aquí: la
  salida de herramientas en terminal se desplaza y no tapa nada permanente. Se puede
  renderizar directo. Regla que sí se mantiene: **no pegar el código PUML** en la
  respuesta.

---

## Paso 0 — Detectar el sistema operativo

```bash
uname -s 2>/dev/null || echo "Windows_NT: $OS"
```

- `Darwin` → **macOS** (sección A).
- `Linux` → **Linux** (sección B).
- Falla / `MINGW*` / `MSYS*` / `CYGWIN*` / `Windows_NT` → **Windows** (sección C, PowerShell).

---

## Paso 1 — Instalar el toolchain (según SO)

Igual que la variante Zed: **Java (JDK)** + **jar de PlantUML** en `~/.claude/plantuml.jar` + **Graphviz** (`dot`).

### A. macOS

```bash
java -version 2>/dev/null || brew install openjdk
mkdir -p ~/.claude
curl -fsSL -o ~/.claude/plantuml.jar \
  https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar
dot -V 2>/dev/null || brew install graphviz
java -jar ~/.claude/plantuml.jar -version && dot -V
```

### B. Linux

```bash
mkdir -p ~/.claude
# Debian/Ubuntu:
sudo apt-get update && sudo apt-get install -y default-jdk graphviz
# Fedora/RHEL:   sudo dnf install -y java-latest-openjdk graphviz
# Arch:          sudo pacman -S --noconfirm jdk-openjdk graphviz
curl -fsSL -o ~/.claude/plantuml.jar \
  https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar
java -jar ~/.claude/plantuml.jar -version && dot -V
```

### C. Windows (PowerShell)

```powershell
winget install --id Microsoft.OpenJDK.21 -e --accept-source-agreements
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude" | Out-Null
Invoke-WebRequest -Uri "https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar" `
  -OutFile "$env:USERPROFILE\.claude\plantuml.jar"
winget install --id Graphviz.Graphviz -e --accept-source-agreements
java -jar "$env:USERPROFILE\.claude\plantuml.jar" -version ; dot -V
```

---

## Paso 2 — Cómo se muestra un diagrama en terminal (abrir el PNG)

Tras renderizar el `.puml` a PNG, **ábrelo en el visor del SO** y comparte la ruta:

- macOS:   `open <ruta>.png`
- Linux:   `xdg-open <ruta>.png`
- Windows: `Start-Process <ruta>.png`  (o `start <ruta>.png` en cmd)

Render (una línea, sin código PUML en la respuesta):
`java -jar ~/.claude/plantuml.jar -tpng archivo.puml -o carpeta`
(en Windows: `java -jar "$env:USERPROFILE\.claude\plantuml.jar" -tpng archivo.puml -o carpeta`)

---

## Paso 3 — Escribir el `CLAUDE.md` global (reglas de respuesta)

Ruta: `~/.claude/CLAUDE.md` (macOS/Linux) o `%USERPROFILE%\.claude\CLAUDE.md` (Windows).
Si ya existe, integra sin borrar lo demás. Contenido:

```markdown
# Preferencias de respuesta (Claude Code en terminal / CLI)

- **Respuestas breves.** Al grano, sin relleno ni repeticiones.
- **Preferir lo visual** sobre párrafos largos, cuando lo amerite.
- **Formatos según el caso:**
  - **Tabla** (comparar por atributos) → **ASCII en texto plano** dentro de un bloque ```text. La terminal la alinea de forma nativa (monoespaciada). Nunca tabla markdown de pipes `|`.
  - **Árbol / jerarquía** → **ASCII en texto plano** (```text con `├── └──`).
  - **Diagrama** (flujo, secuencia, arquitectura, máquina de estados, relaciones) → **PNG con PlantUML**. PUML es SOLO para diagramas, no para tablas ni árboles.
  - **Resumen de una línea** (`A → B → C`) en prosa: ok.
- **Diagramas PNG en terminal:**
  1. Renderizar: `java -jar ~/.claude/plantuml.jar -tpng <archivo>.puml -o <dir>` (Windows: usar `%USERPROFILE%\.claude\plantuml.jar`).
  2. La terminal no muestra imágenes en línea → **abrir el PNG** en el visor del SO (`open` / `xdg-open` / `Start-Process`) y **decir la ruta** al usuario.
  - NUNCA pegar el código PUML en la respuesta. (Opcional: generar el diagrama dentro de un subagente para mantener el hilo limpio.)
- Graphviz (`dot`) hace falta para diagramas de clases/componentes/estado; secuencia/actividad/mindmap no lo necesitan.
```

---

## Paso 4 — Verificar

Renderiza un diagrama de prueba, ábrelo con el visor del SO y confirma que se ve.
Comprueba también que una tabla y un árbol ASCII se alinean bien en tu terminal.

---

## Checklist final

```text
[ ] SO detectado (macOS / Linux / Windows)
[ ] Java instalado           (java -version)
[ ] ~/.claude/plantuml.jar   (java -jar ... -version)
[ ] Graphviz instalado       (dot -V)
[ ] ~/.claude/CLAUDE.md escrito con las reglas
[ ] Prueba: PNG abre en el visor; tabla/árbol ASCII alineados
```
