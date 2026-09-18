# Contrato — `alimentacion.usp_EliminarPlanificacion`

## Propósito

Elimina lógicamente una planificación que se encuentre en `BORRADOR`. La
operación conserva la cabecera, sus menús y cualquier relación histórica: cambia
el estado a `ELIMINADA`, desactiva la planificación y sus menús, aumenta
la versión de los registros modificables y registra la fecha de modificación local.

Script fuente: `db/migrations/alimentacion/Stores Procedures/007_eliminar_planificacion.sql`.

## Contrato de salida

Firma adicional obligatoria: `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`. El recordset de resultado se conserva sin
cambios.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `SUCCESS` | `null` | La planificación fue eliminada lógicamente. |
| `VALIDATION_ERROR` | `El identificador de planificación es obligatorio.` | No se recibió identificador. |
| `PLAN_NOT_FOUND` | `La planificación indicada no existe.` | No existe la planificación. |
| `STATE_CONFLICT` | `La planificación ya fue eliminada.` | La planificación ya está eliminada. |
| `INVALID_PLAN_STATE` | `La planificación no permite esta operación.` | La planificación no está en borrador. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

La eliminación lógica y sus menús se actualizan atómicamente con
`SET XACT_ABORT ON` y `TRY/CATCH`; todo error posterior al inicio revierte solo
si `XACT_STATE() <> 0`.

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_EliminarPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público de la planificación que se retirará. |

## Reglas de negocio

- Solo una planificación con estado `BORRADOR` puede eliminarse.
- La transición es terminal: `BORRADOR` → `ELIMINADA`.
- La misma transacción desactiva los `Menu` asociados; los menús también incrementan su versión y registran su fecha de modificación.
- El procedimiento usa bloqueo de actualización para serializar eliminaciones concurrentes sobre la misma planificación.
- Las planificaciones eliminadas quedan excluidas de los procedimientos de listado, resumen y consulta de menús activos.

## Salida

Devuelve un único recordset con una fila:

| Columna | Tipo lógico backend | Descripción |
|---|---|---|
| `IdPlanificacion` | UUID | Identificador público de la planificación eliminada. |
| `Estado` | string | Siempre `ELIMINADA`. |
| `VersionRegistro` | integer de 64 bits | Versión incrementada tras la eliminación lógica. |
| `FechaModificacion` | timestamp local | Instante local en que se realizó la eliminación. |

## Manejo de errores

| Error SQL | Condición |
|---:|---|
| `VALIDATION_ERROR` | El identificador de planificación es obligatorio. |
| `PLAN_NOT_FOUND` | La planificación indicada no existe. |
| `STATE_CONFLICT` | La planificación ya fue eliminada. |
| `INVALID_PLAN_STATE` | La planificación no permite esta operación. |
| `INTERNAL_ERROR` | No fue posible completar la operación. |
