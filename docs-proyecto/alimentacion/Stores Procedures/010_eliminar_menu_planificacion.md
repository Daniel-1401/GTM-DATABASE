# Contrato — `alimentacion.usp_EliminarMenuPlanificacion`

## Propósito

Elimina un menú de una planificación que se encuentre en `BORRADOR`. La
eliminación es física para que la combinación planificación–fecha–tipo de
servicio quede libre y pueda configurarse nuevamente.

Script fuente: `db/migrations/alimentacion/Stores Procedures/010_eliminar_menu_planificacion.sql`.

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y
`@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `SUCCESS` | `null` | El menú fue eliminado. |
| `VALIDATION_ERROR` | Mensaje de validación seguro. | Falta un identificador requerido. |
| `PLAN_NOT_FOUND` | `La planificación indicada no existe.` | No existe la planificación. |
| `STATE_CONFLICT` | `La planificación ya fue eliminada.` | La planificación fue eliminada. |
| `INVALID_PLAN_STATE` | `La planificación no permite eliminar menús.` | La planificación no está en borrador. |
| `MENU_NOT_FOUND` | `El menú indicado no existe en la planificación.` | El menú no existe o no pertenece a la planificación. |
| `INTERNAL_ERROR` | `No fue posible completar la operación.` | Error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_EliminarMenuPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdMenu = @IdMenu,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Obligatorio | Descripción |
|---|---|---:|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | Sí | UUID público de la planificación en borrador. |
| `@IdMenu` | `UNIQUEIDENTIFIER` | Sí | UUID público del menú que se eliminará. |

## Reglas de negocio

- Solo se puede eliminar un menú de una planificación en estado `BORRADOR`.
- El menú debe pertenecer a la planificación indicada.
- La operación elimina físicamente la fila, por lo que la misma fecha y tipo de servicio pueden volver a configurarse.
- La planificación y el menú se bloquean durante la transacción para serializar operaciones concurrentes.

## Salida

En una operación exitosa devuelve una fila con `IdMenu`, `IdPlanificacion`,
`FechaServicio` y `TipoServicio` del menú eliminado.
