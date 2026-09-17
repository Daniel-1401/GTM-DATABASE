# Contrato — `alimentacion.usp_ActualizarNombreSedePlanificacion`

## Propósito

Actualiza el nombre y la sede de una planificación en estado `BORRADOR`.
Los espacios externos del nombre se eliminan antes de persistirlo.

Script fuente: `db/migrations/alimentacion/Stores Procedures/008_actualizar_nombre_sede_planificacion.sql`.

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `UPDATED` | `null` | El nombre y la sede fueron actualizados. |
| `VALIDATION_ERROR` | Mensaje de validación seguro | Falta el identificador, la sede, el nombre o el colaborador modificador. |
| `PLAN_NOT_FOUND` | `La planificación indicada no existe.` | No existe la planificación. |
| `STATE_CONFLICT` | `La planificación ya fue eliminada.` | La planificación fue eliminada. |
| `INVALID_PLAN_STATE` | `La planificación no permite esta operación.` | La planificación no está en borrador. |
| `NOT_FOUND` | `La sede indicada no existe o está inactiva.` | No existe la sede o no está activa. |
| `NOT_FOUND` | `El colaborador que realiza la modificación no existe.` | No existe el colaborador modificador. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ActualizarNombreSedePlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdSede = @IdSede,
    @Nombre = @Nombre,
    @IdColaboradorModificacion = @IdColaboradorModificacion,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público de la planificación. |
| `@IdSede` | `INT` | Sí | Sede existente y activa que se asignará. |
| `@Nombre` | `NVARCHAR(200)` | Sí | Nombre funcional; se eliminan espacios externos. |
| `@IdColaboradorModificacion` | `BIGINT` | Sí | Colaborador que realiza la modificación. |

## Reglas de negocio

- Solo una planificación con estado `BORRADOR` puede editarse.
- La sede destino debe existir y estar activa.
- El colaborador que realiza la modificación debe existir.
- La actualización incrementa `VersionRegistro` y registra `FechaModificacion`.
- El procedimiento bloquea la planificación durante la operación para serializar cambios concurrentes.

## Salida

Devuelve una fila con `IdPlanificacion`, `IdSede`, `Nombre`,
`IdColaboradorModificacion`, `Estado`, `VersionRegistro` y `FechaModificacion`.
