# Evaluaciones — línea base técnica SQL Server

Estado: Referencia técnica oficial heredada  
Fecha de oficialización: 2026-09-03  
Origen técnico: avance documentado al 2026-07-07

## Propósito

Conservar la estructura SQL desarrollada para Evaluaciones como línea base modificable. Las tablas, scripts y stored procedures aquí descritos pueden evolucionar manualmente; las reglas funcionales oficiales se mantienen en los documentos de `funcionalidades/`.

## Reglas técnicas

- La base se define mediante scripts ubicados históricamente en `back-gtm/SQL`.
- Los scripts se ejecutan de manera explícita y autorizada.
- Los scripts deben ser idempotentes mediante `IF OBJECT_ID`, `IF NOT EXISTS` y `GO`.
- Las variables T-SQL no sobreviven entre lotes separados por `GO`.
- La capa de persistencia utiliza stored procedures y evita SQL inline.

## Secuencia de scripts

1. `001_Evaluacion_BancoPreguntas.sql`
2. `002_Evaluacion_ImportacionBancoPreguntas.sql`
3. `003_Organizacion_Cargos.sql`
4. `004_Evaluacion_Formatos.sql`
5. `005_Evaluacion_Campanas.sql`
6. `006_PersonalSap_Personas.sql`
7. `007_Evaluacion_Periodos_Publicacion.sql`
8. `008_Evaluacion_Evaluaciones_SP.sql`
9. `009_Evaluacion_Periodos_Estados.sql`
10. `010_Evaluacion_CargaMasivaBancoPreguntas_SP.sql`
11. `011_Evaluacion_Preguntas_CRUD_SP.sql`
12. `012_Evaluacion_AreasCargos_SP.sql`
13. `013_Evaluacion_Niveles_SP.sql`
14. `014_Evaluacion_Periodos_CRUD_SP.sql`
15. `015_Evaluacion_Periodos_Publicacion_SP.sql`
16. `016_Evaluacion_MisEvaluaciones_SP.sql`
17. `999_Seed_DatosPrueba.sql`

`998_Reset_Datos_RebuildIndices.sql` es un script especial de limpieza y reconstrucción; no forma parte de la secuencia normal. La plantilla de carga masiva histórica es `PlantillaCargaMasiva.xlsx`.

## Schemas

- `Evaluacion`: banco de preguntas, formatos, campañas, snapshots y respuestas.
- `Organizacion`: unidades organizacionales y cargos.
- `PersonalSap`: personas y asignación persona-cargo actual e histórica.

## Organización y jerarquía

Tablas:

- `Organizacion.UnidadOrganizacional`
- `Organizacion.Cargo`

La jerarquía utiliza `hierarchyid`. `Organizacion.Cargo` conserva `IdCargoPadre`, `RutaJerarquia`, `NivelJerarquia` y `CodigoCargoSAP`. El código SAP es una referencia externa y no obliga a una consulta SAP en tiempo real.

## Banco de preguntas

Scripts asociados:

- `001_Evaluacion_BancoPreguntas.sql`
- `002_Evaluacion_ImportacionBancoPreguntas.sql`
- `010_Evaluacion_CargaMasivaBancoPreguntas_SP.sql`
- `011_Evaluacion_Preguntas_CRUD_SP.sql`

Tablas:

- `Evaluacion.Competencia`
- `Evaluacion.Criterio`
- `Evaluacion.NivelPregunta`
- `Evaluacion.Pregunta`
- `Evaluacion.PreguntaCargoSAP`
- `Evaluacion.ImportacionBancoPreguntas`
- `Evaluacion.ImportacionBancoPreguntasDetalle`
- `Evaluacion.ImportacionBancoPreguntasDetalleCargo`

La carga admite CSV y XLSX. Excel procesa la primera hoja; CSV acepta `;` o `,`; los cargos dentro de una celda se separan con `|`. Los archivos se normalizan a un modelo común antes de procesarse.

## Formatos de evaluación

Scripts asociados:

- `004_Evaluacion_Formatos.sql`
- `008_Evaluacion_Evaluaciones_SP.sql`

Tablas:

- `Evaluacion.FormatoEvaluacion`
- `Evaluacion.FormatoEvaluacionCargo`
- `Evaluacion.FormatoEvaluacionCargoCompetencia`
- `Evaluacion.FormatoEvaluacionCargoCriterio`
- `Evaluacion.FormatoEvaluacionAsignacionCargo`
- `Evaluacion.FormatoEvaluacionReglaJerarquia`

Los estados de formato son `BORRADOR` y `ACTIVO`. La finalización no se permite si existe un criterio sin nivel. La selección de cargos respeta la jerarquía; solo son evaluadores los cargos con subordinados. La asignación de competencias y criterios trabaja con todos los cargos seleccionados.

## Períodos

El concepto de período se almacena históricamente como `Evaluacion.CampanaEvaluacion`.

Scripts asociados:

- `005_Evaluacion_Campanas.sql`
- `007_Evaluacion_Periodos_Publicacion.sql`
- `009_Evaluacion_Periodos_Estados.sql`
- `014_Evaluacion_Periodos_CRUD_SP.sql`
- `015_Evaluacion_Periodos_Publicacion_SP.sql`

Los campos obligatorios son título, descripción, fecha de inicio, fecha de fin y evaluación. `FechaFin` debe ser mayor o igual a `FechaInicio`; es inclusiva hasta el final del día. La eliminación es lógica.

## Estados y sincronización

`EstadoPublicacion` admite `STAGE` y `PUBLICADO`. `EstadoPeriodo` admite `ACTIVO`, `EN_PROGRESO`, `VENCIDO`, `FINALIZADO` y `ANULADO`.

Combinaciones válidas:

- `STAGE + ACTIVO`
- `PUBLICADO + ACTIVO`
- `PUBLICADO + EN_PROGRESO`
- `PUBLICADO + VENCIDO`
- `PUBLICADO + FINALIZADO`
- `PUBLICADO + ANULADO`

Combinaciones inválidas:

- `STAGE + EN_PROGRESO`
- `STAGE + VENCIDO`
- `STAGE + FINALIZADO`
- `STAGE + ANULADO`

La sincronización histórica utiliza `Evaluacion.USP_Periodo_SincronizarEstados` antes de listar u obtener períodos. No modifica períodos `STAGE`, `FINALIZADO` o `ANULADO`. Para períodos publicados usa la fecha y hora de SQL Server en `America/Lima` y aplica las reglas funcionales de estado.

## Snapshot

Tablas:

- `Evaluacion.CampanaEvaluacionCargo`
- `Evaluacion.CampanaEvaluacionCargoCompetencia`
- `Evaluacion.CampanaEvaluacionCargoCriterio`
- `Evaluacion.CampanaEvaluacionCargoPregunta`
- `Evaluacion.CampanaEvaluacionPersona`
- `Evaluacion.CampanaEvaluacionAsignacion`
- `Evaluacion.CampanaEvaluacionRespuesta`
- `Evaluacion.CampanaEvaluacionEscalaValor`

El snapshot se genera al publicar y queda aislado de las tablas maestras. Conserva textos históricos y no utiliza `IdFormatoEvaluacion` como fuente viva de un período publicado. Renombrar competencias, criterios, catálogos o cargos no modifica el período publicado.

Deshabilitar una asignación no elimina a la persona del snapshot. La persona deja de ser visible para el evaluador actual y puede asignarse a otro evaluador.

## PDF de período

- Se genera bajo demanda y no se almacena en base de datos ni filesystem.
- Generarlo no publica el período.
- En `STAGE` se identifica como no oficial y utiliza configuración viva.
- En `PUBLICADO` se identifica como oficial y utiliza exclusivamente el snapshot.
- Publicar confirma la acción, crea el snapshot y después permite generar o descargar el PDF oficial.

## Mis Evaluaciones

El script histórico es `016_Evaluacion_MisEvaluaciones_SP.sql`. El flujo lista períodos publicados, personal agrupado por cargo, detalle de evaluación, avance por competencia y trazabilidad de tiempos.

Los estados de asignación son `PENDIENTE`, `EN_PROGRESO` y `COMPLETADO`. Cada relación evaluador/evaluado es independiente y varias personas pueden ocupar el mismo cargo evaluador.

## Consistencia transaccional

- La publicación debe ejecutarse dentro de una transacción.
- Ante un error se realiza rollback completo.
- Los datos se revalidan al confirmar la publicación.
- El snapshot no se genera al crear el período.
- El PDF no provoca publicación.
- Los períodos publicados no consultan datos maestros vivos para su documento oficial.

## Trazabilidad de origen

- `C:\Users\cavalos\Desktop\Todo Documentaicon\Documentacion Evaluaciones\03_BASE_DE_DATOS.md`

La fuente original permanece sin modificaciones.
