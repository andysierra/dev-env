# Preferencias de respuesta (Claude Code — terminal/CLI y Zed)

- **Respuestas breves.** Al grano, sin relleno ni repeticiones.
- **Preferir lo visual** sobre párrafos largos, cuando lo amerite.
- **Formatos según el caso:**
  - **Tabla** (comparar por atributos) → **ASCII en texto plano** dentro de un bloque ```text. La terminal la alinea de forma nativa (monoespaciada) y Zed la respeta. Nunca tabla markdown de pipes `|` (Zed la muestra cruda). Nunca como diagrama.
  - **Árbol / jerarquía** → **ASCII en texto plano** (```text con `├── └──`). No es un diagrama; nunca en Mermaid.
  - **Diagrama** (flujo, secuencia, arquitectura, máquina de estados, relaciones, clases, componentes) → **SIEMPRE en Mermaid**, escrito como bloque ```mermaid inline. Nunca ASCII, nunca PUML/PNG. No confundir diagrama con tabla ni con árbol: esos siguen en ASCII.
  - **Resumen de una línea** (`A → B → C`) en prosa: ok.
- **Estilo "parafernalia" rico (preferido).** Cuando el tema lo amerite, no te limites a un solo diagrama: combina VARIOS tipos de Mermaid (flowchart, sequence, state, class, ER, mindmap, etc.) junto con tablas y árboles en ASCII, priorizando lo visual sobre la prosa. Elige cada tipo según lo que mejor explique cada faceta del tema.
- **Mostrar los diagramas Mermaid renderizados en el chat** cuando el cliente los soporte (Zed, claude.ai, extensiones IDE): escribir el bloque ```mermaid directamente en la respuesta (no en un subagente, no como imagen). En una terminal pura el bloque ```mermaid es el entregable (portable a cualquier visor Mermaid). Al renderizar archivos `.md` que contengan Mermaid, mostrarlos siempre renderizados en el chat.
- **Sin toolchain:** Mermaid no necesita Java, PlantUML ni Graphviz. Para PNG en terminal pura (opcional): `mmdc` de `@mermaid-js/mermaid-cli`.
