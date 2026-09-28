# Contrato — `alimentacion.usp_ConsolidarPlanificacion`

## Propósito

Consolida de forma irreversible una planificación `PUBLICADA_CERRADA`. Crea el
encabezado de consolidación, guarda la fotografía de reservas por menú y cambia
el estado de la planificación a `CONSOLIDADA` en una sola transacción.

Script fuente: `db/migrations/alimentacion/Stores Procedures/013_consolidar_planificacion.sql`.

## Firma

```sql
@IdPlanificacion UNIQUEIDENTIFIER,
@IdActorColaboradorCorporativo UNIQUEIDENTIFIER,
@IdCorrelacion UNIQUEIDENTIFIER,
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

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
| `INTERNAL_ERROR` | Ocurrió un error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_ConsolidarPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdActorColaboradorCorporativo = @IdActorColaboradorCorporativo,
    @IdCorrelacion = @IdCorrelacion,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación publicada y cerrada. |
| `@IdActorColaboradorCorporativo` | `UNIQUEIDENTIFIER` | UUID corporativo del actor autorizado, proporcionado por el backend. |
| `@IdCorrelacion` | `UNIQUEIDENTIFIER` | Correlación única de la operación de consolidación. |

## Reglas y salida

- La consolidación solo procede desde `PUBLICADA_CERRADA`; la transición a `CONSOLIDADA` es terminal.
- Registra una sola `ConsolidacionPlanificacion` por planificación y una fila de `CantidadConsolidadaMenu` por menú activo.
- `CantidadReservas` cuenta exclusivamente reservas en estado `RESERVADA`; excluye las canceladas.
- `IdCorrelacion` debe ser único, para impedir que una misma intención duplique una consolidación.
- El backend entrega el UUID corporativo autorizado; el procedimiento solo exige que no sea nulo y no consulta CO ni `rrhh` local.
- Inserta y devuelve `IdActorColaboradorCorporativo`; actualiza `Planificacion.IdColaboradorModificacionCorporativo` con el mismo UUID.
- Devuelve dos recordsets: cabecera de consolidación (incluido `IdActorColaboradorCorporativo`) y detalle consolidado por menú.
