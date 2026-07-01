---
name: Paraphernalia_claude_zed
description: >-
  Configura Claude Code corriendo DENTRO de Zed para dar respuestas breves y
  con "parafernalia" gráfica: tablas/árboles en ASCII y diagramas renderizados
  como PNG con PlantUML (vía subagente) e incrustados en el panel del agente.
  Úsala en un PC NUEVO (Zed + Claude Code recién instalados, login reciente)
  para replicar toda la configuración. Detecta el SO (macOS / Linux / Windows).
---

# Paraphernalia_claude (variante Zed)

Deja a Claude Code —usado dentro del editor **Zed**— respondiendo **breve** y con
**parafernalia visual**: tablas y árboles en ASCII, y diagramas como **imágenes PNG**
(PlantUML) incrustadas en el panel del agente. Todo esto se logra instalando un
toolchain (Java + PlantUML + Graphviz) y escribiendo un `CLAUDE.md` global con las
reglas de respuesta.

> **Contexto de uso:** PC nuevo, con Zed recién instalado y Claude Code recién
> instalado + login reciente. No asumas nada instalado: verifica e instala.

---

## Por qué cada pieza (contexto aprendido)

El panel del agente de Zed tiene límites que definen las reglas:

- ✅ Renderiza bien: **prosa** e **imágenes PNG** incrustadas con markdown de ruta
  local `![desc](/ruta/al.png)`.
- ❌ **Tablas markdown** (`| a | b |`) → las muestra en crudo. Usar **ASCII**.
- ❌ **No hay ajuste** para colapsar las tarjetas de herramientas. Si el hilo
  principal crea el `.puml`, el **código PlantUML queda visible** y tapa el dibujo.
  Solución: generar el diagrama **dentro de un subagente** (su código queda en el
  hilo del subagente, no en el tuyo).

---

## Paso 0 — Detectar el sistema operativo

Ejecuta y ramifica según el resultado:

```bash
uname -s 2>/dev/null || echo "Windows_NT: $OS"
```

- `Darwin` → **macOS** (sección A).
- `Linux` → **Linux** (sección B).
- Falla / `MINGW*` / `MSYS*` / `CYGWIN*` / `Windows_NT` → **Windows** (sección C, usar PowerShell).

---

## Paso 1 — Instalar el toolchain (según SO)

Se necesitan tres cosas: **Java (JDK)**, el **jar de PlantUML** en `~/.claude/plantuml.jar`
y **Graphviz** (`dot`, para diagramas de clases/componentes/estado).

### A. macOS

```bash
# Java (si falta)
java -version 2>/dev/null || brew install openjdk
# PlantUML jar
mkdir -p ~/.claude
curl -fsSL -o ~/.claude/plantuml.jar \
  https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar
# Graphviz (si falta)
dot -V 2>/dev/null || brew install graphviz
# Verificar
java -jar ~/.claude/plantuml.jar -version && dot -V
```

Si no hay Homebrew: instalarlo desde https://brew.sh o instalar Temurin JDK manualmente.

### B. Linux

Detecta el gestor de paquetes e instala Java + Graphviz:

```bash
mkdir -p ~/.claude
# Debian/Ubuntu:
sudo apt-get update && sudo apt-get install -y default-jdk graphviz
# Fedora/RHEL:   sudo dnf install -y java-latest-openjdk graphviz
# Arch:          sudo pacman -S --noconfirm jdk-openjdk graphviz
# PlantUML jar
curl -fsSL -o ~/.claude/plantuml.jar \
  https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar
# Verificar
java -jar ~/.claude/plantuml.jar -version && dot -V
```

### C. Windows (PowerShell)

```powershell
# Java (JDK)
winget install --id Microsoft.OpenJDK.21 -e --accept-source-agreements
# Carpeta y PlantUML jar
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude" | Out-Null
Invoke-WebRequest -Uri "https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar" `
  -OutFile "$env:USERPROFILE\.claude\plantuml.jar"
# Graphviz
winget install --id Graphviz.Graphviz -e --accept-source-agreements
# Verificar (reabre la terminal para refrescar PATH)
java -jar "$env:USERPROFILE\.claude\plantuml.jar" -version ; dot -V
```

> En Windows, el comando de render usa la ruta completa:
> `java -jar "$env:USERPROFILE\.claude\plantuml.jar" -tpng archivo.puml -o carpeta`

---

## Paso 2 — Escribir el `CLAUDE.md` global (reglas de respuesta)

Escribe el archivo global de Claude Code con **exactamente** este contenido.
Ruta: `~/.claude/CLAUDE.md` (macOS/Linux) o `%USERPROFILE%\.claude\CLAUDE.md` (Windows).
Si ya existe, integra estas reglas sin borrar lo demás.

```markdown
# Preferencias de respuesta (Claude Code dentro de Zed)

- **Respuestas breves.** Al grano, sin relleno ni repeticiones.
- **Preferir lo visual** sobre párrafos largos, cuando lo amerite.
- **Formatos según el caso:**
  - **Tabla** (comparar por atributos) → **ASCII en texto plano**, dentro de un bloque ```text. NUNCA tabla markdown de pipes `|` (Zed la muestra cruda). Nunca como imagen.
  - **Árbol / jerarquía** → **ASCII en texto plano** (```text con `├── └──`).
  - **Diagrama** (flujo, secuencia, arquitectura, máquina de estados, relaciones) → **PNG con PlantUML**. PUML es SOLO para diagramas, no para tablas ni árboles.
  - **Resumen de una línea** (`A → B → C`) en prosa: ok.
- **Diagramas PNG: renderizar SIEMPRE dentro de un subagente** (Zed no puede colapsar tarjetas; si el hilo principal crea el `.puml`, el código queda visible y tapa el dibujo):
  1. Lanzar un subagente (Agent tool) que: escriba el `.puml` con Write, renderice con `java -jar ~/.claude/plantuml.jar -tpng <archivo>.puml -o <dir>`, verifique el PNG y **devuelva solo la ruta absoluta** del PNG (sin incluir el código PUML).
  2. En el hilo principal, **incrustar el PNG** con markdown de ruta local: `![desc](/ruta/absoluta/al.png)`. Zed lo muestra expandido; el PUML queda oculto en el hilo del subagente.
  - NUNCA pegar código PUML en la respuesta ni crear `.puml` desde el hilo principal.
- **Secuenciar el subagente para no partir el texto:** no escribir prosa sustancial en el mismo turno en que se lanza el subagente (Zed intercala su tarjeta y parte el texto). Lanzarlo con texto mínimo, esperar a que termine, y en el turno de completado redactar TODA la respuesta de una sola vez (tabla + árbol + prosa + imagen).
- Graphviz (`dot`) hace falta para diagramas de clases/componentes/estado; secuencia/actividad/mindmap no lo necesitan.
```

> En Windows, dentro del bloque anterior reemplaza `~/.claude/plantuml.jar` por
> `%USERPROFILE%\.claude\plantuml.jar` (o la ruta completa) en el comando de render.

---

## Paso 3 — Verificar de extremo a extremo

Lanza un subagente que renderice un diagrama de prueba a `/tmp/viz/test.png`
(o `%TEMP%\test.png` en Windows) e incrústalo con `![](ruta)`. Debe verse la imagen
**expandida** en el panel y **sin** código PlantUML visible. Si es así, la
configuración quedó lista.

---

## Checklist final

```text
[ ] SO detectado (macOS / Linux / Windows)
[ ] Java instalado           (java -version)
[ ] ~/.claude/plantuml.jar   (java -jar ... -version)
[ ] Graphviz instalado       (dot -V)
[ ] ~/.claude/CLAUDE.md escrito con las reglas
[ ] Prueba: PNG incrustado visible, sin PUML a la vista
```
