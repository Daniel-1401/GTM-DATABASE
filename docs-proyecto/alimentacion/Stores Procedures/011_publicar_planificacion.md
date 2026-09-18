# Contrato — `alimentacion.usp_PublicarPlanificacion`

## Propósito

Publica una planificación en `BORRADOR` y abre la recepción de reservas al
transicionar su estado a `PUBLICADA_ABIERTA`.

Script fuente: `db/migrations/alimentacion/Stores Procedures/011_publicar_planificacion.sql`.

## Contrato de salida

La firma termina con `@Codigo NVARCHAR(50) OUTPUT` y `@Mensaje NVARCHAR(500) OUTPUT`.

| Código | Cuándo ocurre |
|---|---|
| `PUBLISHED` | La planificación fue publicada y las reservas quedan abiertas. |
| `VALIDATION_ERROR` | Falta la planificación o el actor de publicación. |
| `PLAN_NOT_FOUND` | No existe la planificación. |
| `STATE_CONFLICT` | La planificación fue eliminada. |
| `INVALID_PLAN_STATE` | La planificación no está en `BORRADOR`. |
| `NOT_FOUND` | El colaborador que publica no existe. |
| `PLAN_WITHOUT_MENUS` | No hay menús activos que puedan publicarse. |
| `INTERNAL_ERROR` | Ocurrió un error inesperado. |

## Ejecución

```sql
DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
EXEC [alimentacion].[usp_PublicarPlanificacion]
    @IdPlanificacion = @IdPlanificacion,
    @IdColaboradorModificacion = @IdColaborador,
    @Codigo = @Codigo OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
```

## Parámetros de entrada

| Parámetro | Tipo SQL | Descripción |
|---|---|---|
| `@IdPlanificacion` | `UNIQUEIDENTIFIER` | UUID público de la planificación en borrador. |
| `@IdColaboradorModificacion` | `BIGINT` | Colaborador existente que realiza la publicación. |

## Reglas y salida

- Requiere al menos un `Menu` activo; un servicio sin atención es un menú válido.
- Actualiza `IdColaboradorModificacion`, `VersionRegistro` y `FechaModificacion`.
- Bloquea la planificación y sus menús durante la transición.
- Devuelve una fila con el UUID, estado, actor, versión y fecha de modificación de la planificación publicada.
