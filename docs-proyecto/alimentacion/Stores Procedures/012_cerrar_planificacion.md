# Contrato — `alimentacion.usp_CerrarPlanificacion`

## Propósito

Cierra la recepción de reservas de una planificación publicada, transicionándola
de `PUBLICADA_ABIERTA` a `PUBLICADA_CERRADA`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/012_cerrar_planificacion.sql`.

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y `@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Cuándo ocurre |
|---|---|
| `CLOSED` | La planificación fue cerrada. |
| `VALIDATION_ERROR` | Falta la planificación o el actor de cierre. |
| `PLAN_NOT_FOUND` | No existe la planificación. |
| `STATE_CONFLICT` | La planificación fue eliminada. |
| `INVALID_PLAN_STATE` | La planificación no está en `PUBLICADA_ABIERTA`. |
| `NOT_FOUND` | El colaborador que cierra no existe. |
| `INTERNAL_ERROR` | Ocurrió un error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_CerrarPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdColaboradorModificacion = @IdColaborador,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación con reservas abiertas. |
| `@IdColaboradorModificacion` | `BIGINT` | Colaborador existente que realiza el cierre. |

## Reglas y salida

- El cierre es manual; no aplica una hora de corte automática.
- Actualiza actor, versión y fecha de modificación dentro de una transacción bloqueada.
- Tras el cierre, los stores de reserva deben rechazar nuevas reservas y cancelaciones hasta una reapertura futura.
- Devuelve una fila con el UUID, estado, actor, versión y fecha de modificación de la planificación cerrada.
