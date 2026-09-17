# Contrato — `alimentacion.usp_CrearPlanificacionBorrador`

## Propósito

Crea la cabecera de una planificación con estado inicial `BORRADOR`. El UUID
devuelto debe usarse al registrar sus menús.

Script fuente: `db/migrations/alimentacion/Stores Procedures/004_crear_planificacion_borrador.sql`.

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdSede` | `INT` | Sí | Sede existente para la planificación. |
| `@IdColaboradorRegistro` | `BIGINT` | Sí | Colaborador existente que registra la planificación. |
| `@Nombre` | `NVARCHAR(200)` | Sí | Nombre funcional; se eliminan espacios externos. |
| `@FechaInicio` | `DATE` | Sí | Inicio inclusivo del período. |
| `@FechaFin` | `DATE` | Sí | Fin inclusivo; no puede ser anterior al inicio. |

## Salida

Devuelve una fila con `IdPlanificacion` (UUID público), sede, nombre, período,
estado `BORRADOR`, vigencia, colaborador registrador, versión y fecha de creación local.

## Errores SQL

| Error SQL | Condición |
|---:|---|
| `50200` | Sede ausente. |
| `50201` | Nombre ausente o vacío. |
| `50202` | Una o ambas fechas ausentes. |
| `50203` | Fecha final anterior a la inicial. |
| `50204` | Sede inexistente. |
| `50205` | Colaborador registrador ausente. |
| `50206` | Colaborador registrador inexistente. |
