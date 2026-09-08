# Graph Report - gtm-database  (2026-09-07)

## Corpus Check
- 38 files · ~25,744 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 221 nodes · 201 edges · 31 communities (21 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ddceeb35`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Colaborador Entity
- Alimentación — baseline conceptual de SQL Server
- Alimentación — roles y permisos
- Catálogo oficial de tablas y objetos programables pendientes — Alimentación
- DB Restructuring Proposal
- Evaluaciones — línea base técnica SQL Server
- Alimentación — contexto y alcance
- Funcionalidad — formatos de evaluación
- Área lógica de Alimentación
- Evaluaciones Module Governance
- Estado oficial de objetos de base de datos
- 010_crear_planificaciones_menus_y_consolidacion.sql
- 003_crear_personas_colaboradores_e_identidad_microsoft.sql
- 004_crear_organizacion_y_centros_costo_sap.sql
- Diagrama ER físico v1 — núcleo general GTM
- Q: tienes acceso al proyecto de projects\gtm-database necesito que me expliques como funciona el nuclio, sin incluir modulo de evaluaciones.
- Funcionalidad — períodos de evaluación
- Registro de scripts DB — GTM
- Q: explicame como funciona la tabla CuentaMicrosoftCorporativa
- 009_crear_schema_y_configuracion_alimentacion.sql
- 011_crear_reservas_qr_y_entregas.sql
- 002_crear_catalogos_identidad_y_jefatura.sql
- 007_crear_horarios_laborales_y_vigencias.sql
- 017_crear_validacion_entrega.sql
- 005_crear_relaciones_laborales_y_referencias_empleado_sap.sql
- 006_crear_asignaciones_organizacionales_y_referencias_posicion_sap.sql
- 008_crear_jefaturas_relaciones_laborales.sql
- ER físico v1 — módulo Alimentación

## God Nodes (most connected - your core abstractions)
1. `Alimentación — baseline conceptual de SQL Server` - 17 edges
2. `Evaluaciones — línea base técnica SQL Server` - 15 edges
3. `Alimentación — contexto y alcance` - 13 edges
4. `Alimentación — roles y permisos` - 12 edges
5. `ER físico v1 — módulo Alimentación` - 8 edges
6. `Área lógica de Alimentación` - 8 edges
7. `Funcionalidad — formatos de evaluación` - 8 edges
8. `Diagrama ER físico v1 — núcleo general GTM` - 7 edges
9. `Funcionalidad — períodos de evaluación` - 7 edges
10. `Evaluaciones Module Governance` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Evaluaciones Module Governance` --references--> `Colaborador Entity`  [EXTRACTED]
  lineamiento/referencias-modulos/Evaluaciones/00_INDICE_Y_GOBIERNO.md → docs-proyecto/requirements.md
- `Alimentación Module Governance` --references--> `Colaborador Entity`  [EXTRACTED]
  lineamiento/referencias-modulos/Alimentacion/00_INDICE_Y_GOBIERNO.md → docs-proyecto/requirements.md
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

## Communities (31 total, 7 thin omitted)

### Community 0 - "Colaborador Entity"
Cohesion: 0.15
Nodes (11): Definition of Done - Analyst Stage, Conceptual ER Diagram v1, GTM Core Requirements, Confirmed Technology Stack, SAP System, External Security System, Colaborador Entity, Persona Entity (+3 more)

### Community 1 - "Alimentación — baseline conceptual de SQL Server"
Cohesion: 0.12
Nodes (16): Alimentación — baseline conceptual de SQL Server, Criterios para el futuro diagrama ER, Decisiones aprobadas, Decisión de primera versión, Flujo futuro con el Orquestador, Fuentes trazadas, Invariantes obligatorias, Límites de esta oficialización (+8 more)

### Community 2 - "Alimentación — roles y permisos"
Cohesion: 0.13
Nodes (15): Alimentación — roles y permisos, Aplicación operativa de A&B, Autenticación y fuentes de autorización, Consulta del colaborador durante el retiro, Contextos de aplicación, Decisiones aprobadas, Fuentes trazadas, GoldenGtm móvil (+7 more)

### Community 3 - "Catálogo oficial de tablas y objetos programables pendientes — Alimentación"
Cohesion: 0.09
Nodes (22): 1. Propósito, 2. Objetos programables pendientes de definición, 3. Dependencias del núcleo, 4.1 Configuración operativa, 4.2 Planificación y menú, 4.3 Consolidación, 4.4 Reserva, QR y entrega, 4. Catálogo físico de tablas (+14 more)

### Community 5 - "Evaluaciones — línea base técnica SQL Server"
Cohesion: 0.13
Nodes (15): Banco de preguntas, Consistencia transaccional, Estados y sincronización, Evaluaciones — línea base técnica SQL Server, Formatos de evaluación, Mis Evaluaciones, Organización y jerarquía, PDF de período (+7 more)

### Community 6 - "Alimentación — contexto y alcance"
Cohesion: 0.15
Nodes (13): Actores conceptuales, Alcance general, Alimentación — contexto y alcance, Canales y responsabilidades generales, Ciclo funcional de publicación y reservas, Colaborador y tipo de servicio, Configuración operativa fuera de la aplicación, Fuera de alcance (+5 more)

### Community 7 - "Funcionalidad — formatos de evaluación"
Cohesion: 0.25
Nodes (8): Capacidades, Composición, Estados, Funcionalidad — formatos de evaluación, Origen, Propósito, Relación con períodos, Selección de cargos

### Community 8 - "Área lógica de Alimentación"
Cohesion: 0.25
Nodes (8): Auditoría, Configuración operativa, Entrega, Idempotencia, Planificación y menú, QR, Reserva, Área lógica de Alimentación

### Community 9 - "Evaluaciones Module Governance"
Cohesion: 0.09
Nodes (16): Evaluaciones Module Governance, Actores, Capacidades incluidas, Evaluaciones — contexto y alcance, Límite documental, Objetivo, Origen, Evaluaciones — roles y permisos (+8 more)

### Community 10 - "Estado oficial de objetos de base de datos"
Cohesion: 0.29
Nodes (6): 1. Decisión vigente, 2. Catálogo oficial de tablas, 3. Objetos no definidos, 4. Próximo gate, 5. Lectura de los demás documentos, Estado oficial de objetos de base de datos

### Community 11 - "010_crear_planificaciones_menus_y_consolidacion.sql"
Cohesion: 0.47
Nodes (5): alimentacion].[CantidadConsolidadaMenu, alimentacion].[ComponenteMenu, alimentacion].[ConsolidacionPlanificacion, alimentacion].[Menu, alimentacion].[Planificacion

### Community 12 - "003_crear_personas_colaboradores_e_identidad_microsoft.sql"
Cohesion: 0.40
Nodes (4): integracion].[CuentaMicrosoftCorporativa, rrhh].[Colaborador, rrhh].[DocumentoPersona, rrhh].[Persona

### Community 13 - "004_crear_organizacion_y_centros_costo_sap.sql"
Cohesion: 0.40
Nodes (4): organizacion].[Area, organizacion].[Cargo, organizacion].[Empresa, organizacion].[Sede

### Community 14 - "Diagrama ER físico v1 — núcleo general GTM"
Cohesion: 0.25
Nodes (7): 1. Estado y alcance, 2. Modelo físico oficial, 3. Convenciones físicas, 4. Invariantes materializadas, 5. Decisiones diferidas preservadas, 6. Invariantes pendientes de fase posterior, Diagrama ER físico v1 — núcleo general GTM

### Community 15 - "Q: tienes acceso al proyecto de projects\gtm-database necesito que me expliques como funciona el nuclio, sin incluir modulo de evaluaciones."
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: tienes acceso al proyecto de projects\gtm-database necesito que me expliques como funciona el nuclio, sin incluir modulo de evaluaciones., Source Nodes

### Community 16 - "Funcionalidad — períodos de evaluación"
Cohesion: 0.29
Nodes (7): Acciones por estado, Funcionalidad — períodos de evaluación, Origen, PDF de resumen, Publicación, Reglas, Sincronización automática de estados

### Community 17 - "Registro de scripts DB — GTM"
Cohesion: 0.50
Nodes (3): 017_crear_validacion_entrega.sql — 2026-09-04, Ajustes de auditoría DB-NUCLEO-002, Registro de scripts DB — GTM

### Community 18 - "Q: explicame como funciona la tabla CuentaMicrosoftCorporativa"
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: explicame como funciona la tabla CuentaMicrosoftCorporativa, Source Nodes

### Community 19 - "009_crear_schema_y_configuracion_alimentacion.sql"
Cohesion: 0.50
Nodes (3): alimentacion].[BeaconAutorizado, alimentacion].[ConfiguracionProximidadBeacon, alimentacion].[VentanaRetiroServicio

### Community 20 - "011_crear_reservas_qr_y_entregas.sql"
Cohesion: 0.50
Nodes (3): alimentacion].[CodigoQR, alimentacion].[Entrega, alimentacion].[Reserva

### Community 29 - "ER físico v1 — módulo Alimentación"
Cohesion: 0.22
Nodes (8): 1. Límites y fuentes, 2. Diagrama, 3. Inventario físico, 4. Estados y temporalidad, 5. Invariantes declarativas, 6. Límites transaccionales, 7. Reproducibilidad y reversión, ER físico v1 — módulo Alimentación

## Knowledge Gaps
- **158 isolated node(s):** `alimentacion].[VentanaRetiroServicio`, `alimentacion].[BeaconAutorizado`, `alimentacion].[ConfiguracionProximidadBeacon`, `alimentacion].[Planificacion`, `alimentacion].[ComponenteMenu` (+153 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 172 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Evaluaciones Module Governance` connect `Evaluaciones Module Governance` to `Colaborador Entity`?**
  _High betweenness centrality (0.183) - this node is a cross-community bridge._
- **Why does `Colaborador Entity` connect `Colaborador Entity` to `Evaluaciones Module Governance`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **What connects `alimentacion].[VentanaRetiroServicio`, `alimentacion].[BeaconAutorizado`, `alimentacion].[ConfiguracionProximidadBeacon` to the rest of the system?**
  _158 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Alimentación — baseline conceptual de SQL Server` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Alimentación — roles y permisos` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `Catálogo oficial de tablas y objetos programables pendientes — Alimentación` be split into smaller, more focused modules?**
  _Cohesion score 0.08695652173913043 - nodes in this community are weakly interconnected._
- **Should `Evaluaciones — línea base técnica SQL Server` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._