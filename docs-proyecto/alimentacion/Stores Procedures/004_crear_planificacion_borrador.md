# Contrato — `alimentacion.usp_CrearPlanificacionBorrador`

## Propósito

Crea la cabecera de una planificación con estado inicial `BORRADOR`. El UUID
devuelto debe usarse al registrar sus menús.

Script fuente: `db/migrations/alimentacion/Stores Procedures/004_crear_planificacion_borrador.sql`.

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`. El recordset de creación se conserva sin
cambios.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `CREATED` | `null` | La planificación fue creada. |
| `VALIDATION_ERROR` | Mensaje de validación seguro | Falta un dato requerido o el período es inválido. |
| `NOT_FOUND` | `La sede indicada no existe.` | No existe la sede recibida. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

La inserción se ejecuta de forma atómica con `SET XACT_ABORT ON` y `TRY/CATCH`.
Ante un error inesperado se revierte solo si `XACT_STATE() <> 0`. La existencia
del colaborador no se valida en este procedimiento.

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdSede` | `INT` | Sí | Sede existente para la planificación. |
| `@IdColaboradorRegistro` | `BIGINT` | Sí | Identificador del colaborador que registra la planificación. |
| `@Nombre` | `NVARCHAR(200)` | Sí | Nombre funcional; se eliminan espacios externos. |
| `@FechaInicio` | `DATE` | Sí | Inicio inclusivo del período. |
| `@FechaFin` | `DATE` | Sí | Fin inclusivo; no puede ser anterior al inicio. |

## Salida

Devuelve una fila con `IdPlanificacion` (UUID público), sede, nombre, período,
estado `BORRADOR`, vigencia, colaborador registrador, versión y fecha de creación local.

## Errores SQL

| Error SQL | Condición |
|---:|---|
| `VALIDATION_ERROR` | Sede, nombre, colaborador o fechas ausentes; o fecha final anterior a la inicial. |
| `NOT_FOUND` | La sede indicada no existe. |
| `INTERNAL_ERROR` | No fue posible completar la operación. |
