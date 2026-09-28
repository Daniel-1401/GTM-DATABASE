# Contrato — `alimentacion.usp_PublicarPlanificacion`

## Propósito

Publica una planificación en `BORRADOR` y abre la recepción de reservas al
transicionar su estado a `PUBLICADA_ABIERTA`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/011_publicar_planificacion.sql`.

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
| `PUBLISHED` | La planificación fue publicada y las reservas quedan abiertas. |
| `VALIDATION_ERROR` | Falta la planificación o el UUID del actor corporativo de publicación. |
| `PLAN_NOT_FOUND` | No existe la planificación. |
| `STATE_CONFLICT` | La planificación fue eliminada. |
| `INVALID_PLAN_STATE` | La planificación no está en `BORRADOR`. |
| `PLAN_WITHOUT_MENUS` | No hay menús activos que puedan publicarse. |
| `INTERNAL_ERROR` | Ocurrió un error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_PublicarPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdColaboradorModificacionCorporativo = @IdColaboradorModificacionCorporativo,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación en borrador. |
| `@IdColaboradorModificacionCorporativo` | `UNIQUEIDENTIFIER` | UUID corporativo del actor autorizado, proporcionado por el backend. |

## Reglas y salida

- Requiere al menos un `Menu` activo; un servicio sin atención es un menú válido.
- El backend entrega el UUID corporativo autorizado; el procedimiento solo exige que no sea nulo y no consulta CO ni `rrhh` local.
- Actualiza `IdColaboradorModificacionCorporativo`, `VersionRegistro` y `FechaModificacion`.
- Bloquea la planificación y sus menús durante la transición.
- Devuelve una fila con el UUID, estado, `IdColaboradorModificacionCorporativo`, versión y fecha de modificación de la planificación publicada.
