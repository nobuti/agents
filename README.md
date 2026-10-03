# agents

Skills para Claude Code, pensadas para trabajar con agentes de idea a entrega. Cada skill es una carpeta con un `SKILL.md` (más documentos de apoyo y scripts opcionales). Puedes invocarlas como slash command (`/tdd`, `/triage`…) o dejar que **`/bob`** elija el flujo por ti.

Inspirado en [mattpocock/skills](https://www.aihero.dev/skills) y en el enrutado de [pstack](https://flaviocopes.com/pstack/#what-is-poteto-mode): piezas pequeñas, componibles y editables.

## Instalación

```bash
git clone <este repo> ~/Dev/nobuti/agents
cd ~/Dev/nobuti/agents
scripts/setup.sh
```

Claude Code solo descubre skills en `skills/<nombre>/SKILL.md`, pero aquí están agrupadas por categoría. `scripts/setup.sh` crea un symlink plano `skills/<nombre>` por cada `skills/**/SKILL.md` y regenera `skills/.gitignore`. Vuelve a ejecutarlo cada vez que añadas, muevas, renombres o borres una skill. Si dos skills comparten nombre, salta la segunda y avisa.

## Bob: el punto de entrada

`/bob <lo que quieres hacer>` es un router. Describes el resultado y Bob elige un playbook, lo ejecuta paso a paso y no da nada por terminado sin evidencia. Solo lo invocas tú (`disable-model-invocation`): un router que se dispara solo podría secuestrar una sesión que ya tiene un flujo en curso.

### Cómo se maneja

1. **Pídele algo**: `/bob el endpoint de worklogs devuelve 500 con cantidades vacías`. Sin argumentos, solo pregunta qué quieres hacer.
2. **Revisa la propuesta.** Bob nombra el playbook, explica por qué y muestra la lista de tareas. **Espera tu confirmación** antes de hacer nada. Si duda entre dos playbooks, te nombra los dos.
3. **Corrige antes de aceptar.** Si el playbook no encaja, dilo ahora: "mejor `quick`", "sin prototipo".
4. **Sigue la ejecución.** Bob copia los pasos del playbook tal cual a la lista de tareas. Un paso que se salta sigue visible con el motivo; nunca se descarta ni se reordena en silencio.
5. **Exige evidencia.** Al cerrar, cada criterio de éxito lleva su prueba: comando ejecutado y salida, archivo leído, test en verde. Lo que no se ejecutó ni se leyó se marca como `Unverified`.
6. **Es sticky.** Los mensajes siguientes ("sí, sigue", "cambia esto") se quedan dentro del playbook actual. Para cambiar de tema escribe **"new task"** y Bob vuelve a clasificar.

### Qué delega y a quién

Según [`models.md`](skills/engineering/bob/models.md), Bob implementa con un subagente Sonnet, investiga con Sonnet o Explore, y el modelo principal decide y **revisa**. La revisión lee los archivos y ejecuta los tests; no se fía del resumen del implementador. Un cambio trivial (unas líneas, un archivo) puede hacerlo el modelo principal.

### Playbooks

Cada playbook es un archivo en [`skills/engineering/bob/playbooks/`](skills/engineering/bob/playbooks/) con cuándo usarlo, pasos numerados y la evidencia de éxito.

| Playbook | Cuándo | Pasos |
| --- | --- | --- |
| `feature` | Una idea que construir, de afinarla a entregarla. | `/grill-with-docs` → (`/prototype`) → `/to-spec` → `/to-tickets` → `/implement` o `/implement-spec` → `/retro` |
| `bug` | Algo roto, que lanza error, falla o va lento. | `/diagnosing-bugs` (feedback loop primero) → `/tdd` con test de regresión → `/code-review` |
| `quick` | Cambio pequeño y concreto, sin spec. | `/tdd` → `/code-review`. Escala a `feature` si toca más de ~3 archivos, pide una decisión de diseño, ocupa varias sesiones o hay una duda sin resolver. |
| `triage` | Issues que llegan crudos (reportes, peticiones). Nunca los que salen de `/to-tickets`. | `/triage` con los roles de `<root>/config.md` |
| `wayfinder` | Esfuerzo enorme y difuso, demasiado grande para una sesión. | `/wayfinder` → al despejar el mapa, `/to-spec` y continúa como `feature` |
| `architecture` | Mantenimiento: que el código sea mejor para agentes. | `/improve-codebase-architecture` → eliges un candidato → `feature` desde `/grill-with-docs` |
| `research` | Una pregunta que necesita fuentes primarias antes de decidir. | `/research` en un agente de fondo → lees el resultado → `/grill-with-docs` si hay build |
| `review` | Revisar trabajo ajeno o tu propia rama. Solo lectura. | `/code-review` |

Para añadir uno, crea `playbooks/<nombre>.md` con el mismo formato y enlázalo en [`bob/SKILL.md`](skills/engineering/bob/SKILL.md).

### Comandos

| Comando | Qué hace |
| --- | --- |
| `/bob <petición>` | Clasifica, propone playbook y, tras confirmar, ejecuta. |
| `/bob setup` | Crea o rehace la config del repo actual. |
| `new task` (dentro de una sesión de Bob) | Suelta el playbook actual y vuelve a clasificar. |

## Config por repo

Las skills de engineering necesitan saber dónde está el issue tracker, qué labels usa el triage y dónde viven el glosario y los ADRs. Eso es **por repo**: dos repos no comparten glosario ni tracker. Todo vive en el repo de artifacts, nunca dentro de los proyectos:

```
~/Dev/artifacts/<ruta-del-repo>/        ← <root>
├── config.md        ## Issue tracker, ## Triage labels
├── GLOSSARY.md      un repo, un glosario
├── adr/NNNN-slug.md
└── <feature>/
    ├── spec.md
    └── issues/NN-slug.md
```

- **`<ruta-del-repo>`** sale de `git remote get-url origin` sin host ni `.git` (`firesponse/web/calmapper`). `~/Dev/artifacts/repos.md` permite sobrescribirlo para casos raros. Sin remoto, Bob pregunta una vez.
- **Quién la crea**: solo `/bob`, la primera vez que corre en un repo sin `<root>/config.md`, o con `/bob setup`. Las skills sueltas (`/tdd`, `/triage`…) nunca escriben config.
- **Fallback**: si el repo no tiene config, se lee `~/Dev/artifacts/default/config.md` (solo lectura).
- **Glosario y ADRs** los crea `/domain-modeling` de forma lazy, solo en `<root>`.
- **Cómo la encuentran las skills**: el `CLAUDE.md` global tiene un bloque `## Agent skills` que apunta a la regla de resolución, [`skills/engineering/bob/CONFIG.md`](skills/engineering/bob/CONFIG.md).

## El flujo principal

```
/grill-with-docs → (/prototype) → /to-spec → /to-tickets → /implement | /implement-spec → /retro
                                                              └─ /tdd + /code-review
```

Es el playbook `feature`. Si prefieres conducirlo a mano, estos son los pasos:

1. **Afinar la idea** con `/grill-with-docs`, una entrevista que deja rastro en `<root>/GLOSSARY.md` y `<root>/adr/`.
2. **Prototipar** (opcional) con `/prototype` si la pregunta necesita código ejecutable; `/handoff` hace de puente.
3. **Especificar**: `/to-spec` convierte la conversación en un spec y `/to-tickets` lo parte en tickets *tracer-bullet* con sus dependencias.
4. **Construir**: `/implement` ticket a ticket, o `/implement-spec` para orquestar subagentes en paralelo sobre una rama de integración. Ambos usan `/tdd` y cierran con `/code-review`.
5. **Cerrar el ciclo** con `/retro`, que propone mejoras al *entorno* del agente (checks, estándares, punteros), no al código.

Mantén los pasos 1-4 en una sola ventana de contexto. La higiene de contexto y el árbol de decisión entre `/clear`, `/compact`, `/handoff` y subagentes están en [`FLOWS.md`](skills/engineering/bob/FLOWS.md) y [`PHASE-BOUNDARIES.md`](skills/engineering/bob/PHASE-BOUNDARIES.md).

## Skills

### Engineering — `skills/engineering/`

| Skill | Qué hace |
| --- | --- |
| `bob` | Router con playbooks: propone el flujo que encaja, lo ejecuta con evidencia y configura el repo (`/bob setup`). |
| `grill-with-docs` | Entrevista implacable que afina un plan y crea ADRs y glosario sobre la marcha. |
| `to-spec` | Sintetiza la conversación en un spec y lo publica en el tracker. |
| `to-tickets` | Divide un plan en tickets tracer-bullet con aristas de bloqueo. |
| `implement` | Implementa un ticket o spec con `/tdd` y `/code-review`. |
| `implement-spec` | Implementa un spec completo: subagentes en paralelo sobre el grafo de tareas. |
| `tdd` | Desarrollo test-first, un slice red-green cada vez. |
| `code-review` | Revisa un diff en dos ejes (estándares y spec) con subagentes paralelos. |
| `pr` | Cómo escribir el cuerpo de una PR: visual mínimo, evidencia antes/después, puerta de una o dos vías. |
| `retro` | Retrospectiva de una sesión; sugiere cambios en el entorno del agente. |
| `triage` | Máquina de estados para issues entrantes; produce briefs listos para agente. |
| `diagnosing-bugs` | Bucle de diagnóstico para bugs y regresiones de rendimiento. |
| `wayfinder` | Planifica trabajo enorme como mapa de tickets de decisión. |
| `prototype` | Prototipo desechable para responder una duda de diseño (lógica o UI). |
| `research` | Investiga contra fuentes primarias en un agente de fondo y deja un Markdown citado. |
| `improve-codebase-architecture` | Busca oportunidades de "profundizar" módulos y las presenta en un informe HTML. |
| `codebase-design` | Vocabulario de módulos profundos (interfaz, seam, adapter, leverage…). |
| `domain-modeling` | Afina el lenguaje de dominio: `GLOSSARY.md` y ADRs (en `<root>`). |

### Productivity — `skills/productivity/`

| Skill | Qué hace |
| --- | --- |
| `grilling` | La primitiva de entrevista que usan las demás skills. |
| `grill-me` | Lo mismo, sin estado, para cuando no hay repo. |
| `handoff` | Compacta la conversación en un documento para otro agente, directorio o persona. |
| `wait-what` | "Eso no se entendió": el agente vuelve a explicar el último mensaje en lenguaje llano. |
| `writing-for-agents` | Referencia para escribir skills, `AGENTS.md` y `CLAUDE.md`. |

### Misc — `skills/misc/`

| Skill | Qué hace |
| --- | --- |
| `git-guardrails-claude-code` | Instala un hook que bloquea comandos git destructivos (`push`, `reset --hard`, `clean -f`, `branch -D`…). |
| `writer-persona` | Escribe con la voz personal del autor: conversacional, honesta, sin hype. |

### Sueltas — `skills/`

| Skill | Qué hace |
| --- | --- |
| `explain-codebase` | Mapa conceptual compacto o traza profunda con informe citado. Solo lectura. |
| `artifact` | Genera un HTML autocontenido y visual para aprender (diagramas, repo overview). |

## Scripts

| Script | Para qué sirve |
| --- | --- |
| `scripts/setup.sh` | Aplana `skills/**/SKILL.md` en symlinks `skills/<nombre>` y regenera `skills/.gitignore`. |
| `skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh` | Hook `PreToolUse`: lee el comando por stdin, sale con código 2 si coincide con un patrón git peligroso. |
| `skills/engineering/diagnosing-bugs/scripts/hitl-loop.template.sh` | Plantilla de bucle de reproducción con humano en el loop (`step`, `capture`). |

## Estructura de una skill

```
skills/<categoría>/<nombre>/
├── SKILL.md        # frontmatter (name, description) + instrucciones
├── *.md            # documentos de apoyo que SKILL.md referencia
└── scripts/        # opcional: comprobaciones o plantillas deterministas
```

La `description` decide cuándo se carga la skill, así que dice *qué hace* y *cuándo usarla*. Las que llevan `disable-model-invocation: true` (p. ej. `bob`) solo se ejecutan si las invocas tú. Consulta `/writing-for-agents` antes de crear o editar una.

## Créditos

`skills/engineering/pr` reproduce el menú de visuales de la skill `show-me` de [Dex Horthy](https://github.com/dexhorthy); ver [`CREDITS.md`](skills/engineering/pr/CREDITS.md).
