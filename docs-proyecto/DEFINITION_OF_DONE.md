# Definition of Done — etapa Analyst del núcleo general GTM

## Alcance de esta instancia

Esta instancia aplica únicamente a la etapa Analyst solicitada. Adapta las
categorías 1, 2 y 6 de la plantilla del framework. No evalúa código, schema
físico, migraciones, backend, frontend ni seguridad implementada.

Los criterios automáticos no sustituyen el checkpoint humano de stack y modelo
conceptual.

## 1. Cobertura funcional documental

- [x] Existen `requirements.md`, `STACK.md`, `DEFINITION_OF_DONE.md` y
  `er-diagram-v1.md` — verificado por: `Test-Path` — owner: Analyst Agent.
- [x] `requirements.md` contiene entidades, flujos, reglas de negocio, actores y
  permisos, estados, criterios de aceptación y plataformas aplicables —
  verificado por: `Select-String` sobre encabezados — owner: Analyst Agent.
- [x] Los trece archivos presentes en `lineamiento/` están inventariados en
  `requirements.md` y las referencias modulares no se convierten en alcance
  interno — verificado por: comparación del inventario de archivos y revisión
  estática de secciones 2, 3, 9 y 12 — owner: Analyst Agent.
- [x] Las preguntas materiales permanecen visibles y no están resueltas por
  supuesto — verificado por: existencia y contenido de
  `requirements.md` sección 13 — owner: Analyst Agent.
- [x] El stack documentado coincide con las decisiones confirmadas: SQL Server
  2017, NestJS/TypeScript, Angular, Kotlin/Jetpack Compose, REST/OpenAPI y
  monolito modular — verificado por: `Select-String` en `STACK.md` — owner:
  Analyst Agent.

## 2. Base de datos — solo modelo conceptual

- [x] El ER conceptual representa Persona, Colaborador, relaciones laborales
  simultáneas, reingresos históricos, asignaciones, organización, jefaturas,
  horarios y `CodigoSAP` en Colaborador, sin tablas SAP — verificado por: inspección estática del bloque
  Mermaid y matriz de cobertura — owner: Analyst Agent.
- [x] El ER expresa cardinalidades y distingue entidades del núcleo de sistemas
  y módulos frontera — verificado por: presencia de `erDiagram`, relaciones y
  diagrama de contexto en `er-diagram-v1.md` — owner: Analyst Agent.
- [x] Alimentación y Evaluaciones aparecen solo como consumidores, sin sus
  entidades internas — verificado por: revisión estática de
  `er-diagram-v1.md` — owner: Analyst Agent.
- [x] Seguridad, SAP, Microsoft/Entra, marcaciones y A&B están identificados
  como límites externos y no como modelos físicos internos — verificado por:
  revisión estática de fronteras y notas — owner: Analyst Agent.
- [x] La entrega Analyst no contiene schema físico, SQL, DDL, DML, stored
  procedures o migraciones — verificado por: inventario del workspace y revisión
  de artefactos entregados — owner: Orquestador.

Los criterios de schema, migraciones limpias y aprobación de schema de la
plantilla general se difieren expresamente a una futura tarea DB. No están
cumplidos ni autorizados por este documento.

## 6. Documentación y trazabilidad

- [x] Los cuatro artefactos están dentro de `docs-proyecto/` y no se escribió
  fuera del ownership del Analyst — verificado por: `git status --short` —
  owner: Orquestador.
- [x] Los archivos Markdown no presentan errores de whitespace — verificado
  por: `git diff --check` — owner: Orquestador.
- [x] El grafo del proyecto se actualizó después de persistir los artefactos y
  no presenta extremos faltantes ni auto-relaciones — verificado por:
  `graphify update .`, 120 nodos, 109 relaciones, 13 comunidades y cobertura de
  fuentes 18/18 — owner: Orquestador.

Advertencia no bloqueante: `GRAPH_REPORT.md` señala alta cantidad de nodos de
baja conectividad y dos comunidades delgadas. El grafo se conserva como índice
estático de navegación; los documentos aprobados continúan siendo la fuente de
verdad.

## Checkpoint humano obligatorio — no automatizable

- Estado: **aprobado el 2026-09-04**.
- Nombre: confirmación de stack y aprobación del modelo conceptual v1.
- Artefactos: `STACK.md`, `requirements.md` y `er-diagram-v1.md`.
- Decisión registrada: el usuario aprobó el stack y modelo conceptual v1,
  difirió expresamente las preguntas materiales e indicó no iniciar DB Agent.
- `strict`: `false`, porque el stack fue definido expresamente por el usuario.

La aprobación quedó trazada en `approvals-log.md`. Ningún DB Agent puede iniciar
sin una instrucción humana posterior que autorice expresamente esa etapa.

## Condición de cierre de la etapa Analyst

La entrega documental del Analyst queda lista cuando todos los criterios
automáticos anteriores estén marcados `[x]`. El paso hacia DB permanece
bloqueado hasta que el Orquestador registre la respuesta humana explícita al
checkpoint.
