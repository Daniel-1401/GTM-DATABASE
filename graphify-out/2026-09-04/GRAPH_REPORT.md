# Graph Report - gtm-database  (2026-09-04)

## Corpus Check
- 52 files · ~32,766 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 217 nodes · 172 edges · 47 communities (43 shown, 4 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Colaborador Entity
- Alimentación — baseline conceptual de SQL Server
- Alimentación — roles y permisos
- Approvals Log
- DB Restructuring Proposal
- Evaluaciones — línea base técnica SQL Server
- Alimentación — contexto y alcance
- Funcionalidad — formatos de evaluación
- Área lógica de Alimentación
- Funcionalidad — períodos de evaluación
- Evaluaciones — contexto y alcance
- Funcionalidad — Mis Evaluaciones
- Evaluaciones — roles y permisos
- Definition of Done — etapa DB del núcleo general GTM
- Diagrama ER físico v1 — núcleo general GTM
- Auditoría estática DB-NUCLEO-002
- Paquete de base de datos GTM
- Registro de scripts DB — GTM
- ER físico v1 — módulo Alimentación
- Definition of Done — DB módulo Alimentación
- Auditoría estática DB-ALIMENTACION-009
- Gate Review — DB Alimentación
- Gate Review estático — núcleo GTM
- Checklist urgente para llegar a pruebas — Alimentación
- procedures/README.md

## God Nodes (most connected - your core abstractions)
1. `Alimentación — baseline conceptual de SQL Server` - 17 edges
2. `Evaluaciones — línea base técnica SQL Server` - 15 edges
3. `Alimentación — contexto y alcance` - 13 edges
4. `Alimentación — roles y permisos` - 12 edges
5. `ER físico v1 — módulo Alimentación` - 9 edges
6. `Área lógica de Alimentación` - 8 edges
7. `Funcionalidad — formatos de evaluación` - 8 edges
8. `Definition of Done — etapa DB del núcleo general GTM` - 7 edges
9. `Definition of Done — DB módulo Alimentación` - 7 edges
10. `Diagrama ER físico v1 — núcleo general GTM` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Alimentación Module Governance` --references--> `Colaborador Entity`  [EXTRACTED]
  lineamiento/referencias-modulos/Alimentacion/00_INDICE_Y_GOBIERNO.md → docs-proyecto/requirements.md
- `Evaluaciones Module Governance` --references--> `Colaborador Entity`  [EXTRACTED]
  lineamiento/referencias-modulos/Evaluaciones/00_INDICE_Y_GOBIERNO.md → docs-proyecto/requirements.md
- `GTM Core Requirements` --cites--> `Core HR Decisions Guideline`  [EXTRACTED]
  docs-proyecto/requirements.md → lineamiento/00_DECISIONES_NUCLEO_RRHH.md
- `Definition of Done - Analyst Stage` --references--> `Conceptual ER Diagram v1`  [EXTRACTED]
  docs-proyecto/DEFINITION_OF_DONE.md → docs-proyecto/er-diagram-v1.md
- `Definition of Done - Analyst Stage` --references--> `GTM Core Requirements`  [EXTRACTED]
  docs-proyecto/DEFINITION_OF_DONE.md → docs-proyecto/requirements.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Analyst Stage Deliverables** — docs_proyecto_requirements, docs_proyecto_stack, docs_proyecto_er_diagram_v1, docs_proyecto_definition_of_done [EXTRACTED 1.00]
- **GTM Identity Model** — gtm_core_persona, gtm_core_colaborador, gtm_core_relacion_laboral [EXTRACTED 1.00]

## Communities (47 total, 4 thin omitted)

### Community 0 - "Colaborador Entity"
Cohesion: 0.18
Nodes (12): Definition of Done - Analyst Stage, Conceptual ER Diagram v1, GTM Core Requirements, Confirmed Technology Stack, SAP System, External Security System, Colaborador Entity, Persona Entity (+4 more)

### Community 1 - "Alimentación — baseline conceptual de SQL Server"
Cohesion: 0.12
Nodes (16): Alimentación — baseline conceptual de SQL Server, Criterios para el futuro diagrama ER, Decisiones aprobadas, Decisión de primera versión, Flujo futuro con el Orquestador, Fuentes trazadas, Invariantes obligatorias, Límites de esta oficialización (+8 more)

### Community 2 - "Alimentación — roles y permisos"
Cohesion: 0.12
Nodes (15): Alimentación — roles y permisos, Aplicación operativa de A&B, Autenticación y fuentes de autorización, Consulta del colaborador durante el retiro, Contextos de aplicación, Decisiones aprobadas, Fuentes trazadas, GoldenGtm móvil (+7 more)

### Community 5 - "Evaluaciones — línea base técnica SQL Server"
Cohesion: 0.12
Nodes (15): Banco de preguntas, Consistencia transaccional, Estados y sincronización, Evaluaciones — línea base técnica SQL Server, Formatos de evaluación, Mis Evaluaciones, Organización y jerarquía, PDF de período (+7 more)

### Community 6 - "Alimentación — contexto y alcance"
Cohesion: 0.14
Nodes (13): Actores conceptuales, Alcance general, Alimentación — contexto y alcance, Canales y responsabilidades generales, Ciclo funcional de publicación y reservas, Colaborador y tipo de servicio, Configuración operativa fuera de la aplicación, Fuera de alcance (+5 more)

### Community 7 - "Funcionalidad — formatos de evaluación"
Cohesion: 0.22
Nodes (8): Capacidades, Composición, Estados, Funcionalidad — formatos de evaluación, Origen, Propósito, Relación con períodos, Selección de cargos

### Community 8 - "Área lógica de Alimentación"
Cohesion: 0.25
Nodes (8): Auditoría, Configuración operativa, Entrega, Idempotencia, Planificación y menú, QR, Reserva, Área lógica de Alimentación

### Community 9 - "Funcionalidad — períodos de evaluación"
Cohesion: 0.25
Nodes (7): Acciones por estado, Funcionalidad — períodos de evaluación, Origen, PDF de resumen, Publicación, Reglas, Sincronización automática de estados

### Community 10 - "Evaluaciones — contexto y alcance"
Cohesion: 0.29
Nodes (6): Actores, Capacidades incluidas, Evaluaciones — contexto y alcance, Límite documental, Objetivo, Origen

### Community 11 - "Funcionalidad — Mis Evaluaciones"
Cohesion: 0.33
Nodes (5): Flujo, Funcionalidad — Mis Evaluaciones, Operaciones REST confirmadas, Origen, Reglas

### Community 12 - "Evaluaciones — roles y permisos"
Cohesion: 0.40
Nodes (4): Evaluaciones — roles y permisos, Matriz oficial, Origen, Reglas generales

### Community 13 - "Definition of Done — etapa DB del núcleo general GTM"
Cohesion: 0.25
Nodes (7): 1. Cobertura del schema, 2. Migraciones y reversión, 3. Integridad y límites, 4. Documentación y trazabilidad, 5. Checkpoints humanos no automatizables, Condición de esta entrega, Definition of Done — etapa DB del núcleo general GTM

### Community 14 - "Diagrama ER físico v1 — núcleo general GTM"
Cohesion: 0.25
Nodes (7): 1. Estado y alcance, 2. Modelo físico propuesto, 3. Convenciones físicas, 4. Invariantes materializadas, 5. Decisiones diferidas preservadas, 6. Invariantes pendientes de fase posterior, Diagrama ER físico v1 — núcleo general GTM

### Community 15 - "Auditoría estática DB-NUCLEO-002"
Cohesion: 0.29
Nodes (6): Auditoría estática DB-NUCLEO-002, Cierre de findings DB-NUCLEO-002-CORR-1, Cierre de findings DB-NUCLEO-002-CORR-2, Controles ejecutados, Resultado por migración, Riesgos y validaciones pendientes

### Community 16 - "Paquete de base de datos GTM"
Cohesion: 0.29
Nodes (6): Alcance, Extensión del módulo Alimentación, Paquete de base de datos GTM, Reversión, Secuencia reproducible, Validación disponible sin instancia

### Community 29 - "ER físico v1 — módulo Alimentación"
Cohesion: 0.20
Nodes (9): 1. Límites y fuentes, 2. Diagrama, 3. Inventario físico, 4. Estados y temporalidad, 5. Invariantes declarativas, 6. Límites transaccionales, 7. Idempotencia, 8. Reproducibilidad y reversión (+1 more)

### Community 30 - "Definition of Done — DB módulo Alimentación"
Cohesion: 0.25
Nodes (7): 1. Modelo y alcance, 2. Migraciones y reversión, 3. Integridad, 4. Trazabilidad y validación, 5. Gates humanos, Condición, Definition of Done — DB módulo Alimentación

### Community 31 - "Auditoría estática DB-ALIMENTACION-009"
Cohesion: 0.29
Nodes (6): Auditoría estática DB-ALIMENTACION-009, Checkpoints, Controles estáticos ejecutados, Límites y riesgos visibles, Resultado, Trazabilidad funcional

### Community 32 - "Gate Review — DB Alimentación"
Cohesion: 0.40
Nodes (4): Blockers, Estado de corrección, Gate Review — DB Alimentación, Warnings

### Community 33 - "Gate Review estático — núcleo GTM"
Cohesion: 0.50
Nodes (3): Alcance verificado, Finding no bloqueante, Gate Review estático — núcleo GTM

### Community 41 - "Checklist urgente para llegar a pruebas — Alimentación"
Cohesion: 0.33
Nodes (5): Checklist urgente para llegar a pruebas — Alimentación, Checkpoints humanos pendientes, Condición de “listo para pruebas”, P0 — Bloqueantes antes de desplegar en Local, P1 — Preparar ejecución y datos de prueba

## Knowledge Gaps
- **147 isolated node(s):** `Alcance`, `Secuencia reproducible`, `Reversión`, `Validación disponible sin instancia`, `Extensión del módulo Alimentación` (+142 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Alimentación — baseline conceptual de SQL Server` connect `Alimentación — baseline conceptual de SQL Server` to `Área lógica de Alimentación`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `Área lógica de Alimentación` connect `Área lógica de Alimentación` to `Alimentación — baseline conceptual de SQL Server`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `Alcance`, `Secuencia reproducible`, `Reversión` to the rest of the system?**
  _147 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Alimentación — baseline conceptual de SQL Server` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Should `Alimentación — roles y permisos` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Evaluaciones — línea base técnica SQL Server` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Alimentación — contexto y alcance` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._