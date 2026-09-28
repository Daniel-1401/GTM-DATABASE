# Contrato — `alimentacion.usp_ReabrirPlanificacion`

## Propósito

Devuelve una planificación `PUBLICADA_CERRADA` a `BORRADOR` para que pueda
editarse y posteriormente publicarse otra vez. No abre reservas: esa apertura
ocurre exclusivamente mediante `alimentacion.usp_PublicarPlanificacion`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/014_reabrir_planificacion.sql`.

## Firma

```sql
@IdPlanificacion UNIQUEIDENTIFIER,
@IdColaboradorModificacionCorporativo UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y `@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Cuándo ocurre |
|---|---|
| `REOPENED` | La planificación cerrada volvió a `BORRADOR`. |
| `VALIDATION_ERROR` | Falta la planificación o el UUID del actor corporativo de reapertura. |
| `PLAN_NOT_FOUND` | No existe la planificación. |
| `STATE_CONFLICT` | La planificación fue eliminada. |
| `PLAN_CONSOLIDATED` | La planificación ya fue consolidada y no puede reabrirse. |
| `INVALID_PLAN_STATE` | La planificación no está en `PUBLICADA_CERRADA`. |
| `INTERNAL_ERROR` | Ocurrió un error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ReabrirPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdColaboradorModificacionCorporativo = @IdColaboradorModificacionCorporativo,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación publicada y cerrada. |
| `@IdColaboradorModificacionCorporativo` | `UNIQUEIDENTIFIER` | UUID corporativo del actor autorizado, proporcionado por el backend. |

## Reglas y salida

- Solo permite la transición `PUBLICADA_CERRADA` → `BORRADOR`.
- No permite reabrir una planificación consolidada ni eliminada.
- No modifica reservas ni menús; la planificación permanece sin reservas abiertas hasta una publicación posterior.
- El backend entrega el UUID corporativo autorizado; el procedimiento solo exige que no sea nulo y no consulta CO ni `rrhh` local.
- Actualiza `IdColaboradorModificacionCorporativo`, versión y fecha de modificación en una transacción bloqueada.
- Devuelve una fila con el UUID, estado, `IdColaboradorModificacionCorporativo`, versión y fecha de modificación de la planificación reabierta.
