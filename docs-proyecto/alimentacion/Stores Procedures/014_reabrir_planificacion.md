# Contrato — `alimentacion.usp_ReabrirPlanificacion`

## Propósito

Devuelve una planificación `PUBLICADA_CERRADA` a `BORRADOR` para que pueda
editarse y posteriormente publicarse otra vez. No abre reservas: esa apertura
ocurre exclusivamente mediante `alimentacion.usp_PublicarPlanificacion`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/014_reabrir_planificacion.sql`.

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y `@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Cuándo ocurre |
|---|---|
| `REOPENED` | La planificación cerrada volvió a `BORRADOR`. |
| `VALIDATION_ERROR` | Falta la planificación o el actor de reapertura. |
| `PLAN_NOT_FOUND` | No existe la planificación. |
| `STATE_CONFLICT` | La planificación fue eliminada. |
| `PLAN_CONSOLIDATED` | La planificación ya fue consolidada y no puede reabrirse. |
| `INVALID_PLAN_STATE` | La planificación no está en `PUBLICADA_CERRADA`. |
| `NOT_FOUND` | El colaborador que reabre no existe. |
| `INTERNAL_ERROR` | Ocurrió un error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ReabrirPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdColaboradorModificacion = @IdColaborador,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación publicada y cerrada. |
| `@IdColaboradorModificacion` | `BIGINT` | Colaborador existente que realiza la reapertura. |

## Reglas y salida

- Solo permite la transición `PUBLICADA_CERRADA` → `BORRADOR`.
- No permite reabrir una planificación consolidada ni eliminada.
- No modifica reservas ni menús; la planificación permanece sin reservas abiertas hasta una publicación posterior.
- Actualiza actor, versión y fecha de modificación en una transacción bloqueada.
- Devuelve una fila con el UUID, estado, actor, versión y fecha de modificación de la planificación reabierta.
