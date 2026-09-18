# Contrato — `alimentacion.usp_ConsolidarPlanificacion`

## Propósito

Consolida de forma irreversible una planificación `PUBLICADA_CERRADA`. Crea el
encabezado de consolidación, guarda la fotografía de reservas por menú y cambia
el estado de la planificación a `CONSOLIDADA` en una sola transacción.

Script fuente: `db/migrations/alimentacion/Stores Procedures/013_consolidar_planificacion.sql`.

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y `@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Cuándo ocurre |
|---|---|
| `CONSOLIDATED` | Se creó la consolidación y su snapshot por menú. |
| `VALIDATION_ERROR` | Falta la planificación, el actor o la correlación. |
| `CORRELATION_CONFLICT` | La correlación ya fue usada por otra consolidación. |
| `PLAN_NOT_FOUND` | No existe la planificación. |
| `STATE_CONFLICT` | La planificación fue eliminada. |
| `INVALID_PLAN_STATE` | La planificación no está en `PUBLICADA_CERRADA`. |
| `NOT_FOUND` | El actor de consolidación no existe. |
| `INTERNAL_ERROR` | Ocurrió un error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ConsolidarPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdActorColaborador = @IdColaborador,
    @IdCorrelacion = @IdCorrelacion,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación publicada y cerrada. |
| `@IdActorColaborador` | `BIGINT` | Colaborador existente que realiza la consolidación. |
| `@IdCorrelacion` | `UNIQUEIDENTIFIER` | Correlación única de la operación de consolidación. |

## Reglas y salida

- La consolidación solo procede desde `PUBLICADA_CERRADA`; la transición a `CONSOLIDADA` es terminal.
- Registra una sola `ConsolidacionPlanificacion` por planificación y una fila de `CantidadConsolidadaMenu` por menú activo.
- `CantidadReservas` cuenta exclusivamente reservas en estado `RESERVADA`; excluye las canceladas.
- `IdCorrelacion` debe ser único, para impedir que una misma intención duplique una consolidación.
- Devuelve dos recordsets: cabecera de consolidación y detalle consolidado por menú.
